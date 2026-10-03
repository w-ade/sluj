import Darwin
import Foundation
import IOKit

/// Reads every process on the Mac. Read-only: it only asks the kernel and the
/// IORegistry for numbers they already keep, and works without admin rights
/// for processes owned by the current user.
public enum ProcessTable {
    public static func snapshot() -> [Int32: ProcessSnapshot] {
        let gpu = gpuTimes()
        var table: [Int32: ProcessSnapshot] = [:]
        for pid in allPids() {
            if let process = read(pid, gpuTimeNs: gpu[pid] ?? 0) {
                table[pid] = process
            }
        }
        return table
    }

    public static func workingDirectory(of pid: Int32) -> String? {
        var info = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &info, size) == size else { return nil }
        let path = withUnsafeBytes(of: info.pvi_cdir.vip_path) { cString($0) }
        return path.isEmpty ? nil : path
    }

    /// The process's argv, without the executable path that precedes it.
    public static func arguments(of pid: Int32) -> [String] {
        var argMax: Int32 = 0
        var argMaxSize = MemoryLayout<Int32>.size
        var argMaxMib: [Int32] = [CTL_KERN, KERN_ARGMAX]
        guard sysctl(&argMaxMib, 2, &argMax, &argMaxSize, nil, 0) == 0, argMax > 0 else { return [] }

        var buffer = [UInt8](repeating: 0, count: Int(argMax))
        var size = buffer.count
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else { return [] }

        // Layout: argc, executable path, padding NULs, then argc NUL-terminated strings.
        let argc = buffer.withUnsafeBytes { $0.loadUnaligned(as: Int32.self) }
        var index = MemoryLayout<Int32>.size
        while index < size, buffer[index] != 0 { index += 1 }
        while index < size, buffer[index] == 0 { index += 1 }

        var arguments: [String] = []
        while arguments.count < argc, index < size {
            let start = index
            while index < size, buffer[index] != 0 { index += 1 }
            arguments.append(String(decoding: buffer[start..<index], as: UTF8.self))
            index += 1
        }
        return arguments
    }

    // MARK: - Reading one process

    static func allPids() -> [Int32] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: Int(count) + 64)
        let filled = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<Int32>.size))
        return pids.prefix(Int(max(0, filled))).filter { $0 > 0 }
    }

    static func read(_ pid: Int32, gpuTimeNs: UInt64) -> ProcessSnapshot? {
        var info = proc_bsdinfo()
        let infoSize = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, infoSize) == infoSize else { return nil }

        var usage = rusage_info_v6()
        let status = withUnsafeMutablePointer(to: &usage) {
            $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_V6, $0)
            }
        }
        guard status == 0 else { return nil }

        let path = executablePath(pid)
        let name = path.map { ($0 as NSString).lastPathComponent } ?? shortName(pid)

        return ProcessSnapshot(
            pid: pid,
            parentPid: Int32(info.pbi_ppid),
            responsiblePid: responsiblePid(pid),
            name: name,
            path: path ?? "",
            startTime: Double(info.pbi_start_tvsec) + Double(info.pbi_start_tvusec) / 1_000_000,
            // rusage CPU times are in Mach ticks, not nanoseconds, on Apple Silicon.
            cpuTimeNs: UInt64(Double(usage.ri_user_time + usage.ri_system_time) * nanosecondsPerTick),
            memoryBytes: usage.ri_phys_footprint,
            energyNj: usage.ri_energy_nj,
            gpuTimeNs: gpuTimeNs
        )
    }

    private static func executablePath(_ pid: Int32) -> String? {
        var buffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return buffer.withUnsafeBytes { cString($0) }
    }

    private static func shortName(_ pid: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 64)
        proc_name(pid, &buffer, UInt32(buffer.count))
        return buffer.withUnsafeBytes { cString($0) }
    }

    private static func cString(_ bytes: UnsafeRawBufferPointer) -> String {
        String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }

    private static let nanosecondsPerTick: Double = {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        return Double(timebase.numer) / Double(timebase.denom)
    }()

    // MARK: - Responsibility

    private typealias ResponsibleFunction = @convention(c) (pid_t) -> pid_t

    /// Private libsystem call Activity Monitor uses to group helpers with
    /// their app. Looked up at runtime so a missing symbol degrades to
    /// "every process is responsible for itself" instead of a crash.
    private static let responsibleFunction: ResponsibleFunction? = {
        let defaultHandle = UnsafeMutableRawPointer(bitPattern: -2)  // RTLD_DEFAULT
        guard let symbol = dlsym(defaultHandle, "responsibility_get_pid_responsible_for_pid") else { return nil }
        return unsafeBitCast(symbol, to: ResponsibleFunction.self)
    }()

    private static func responsiblePid(_ pid: Int32) -> Int32 {
        guard let responsibleFunction else { return pid }
        let responsible = responsibleFunction(pid)
        return responsible > 0 ? responsible : pid
    }

    // MARK: - GPU

    /// Total GPU time per pid, from the Apple GPU driver's per-client
    /// counters (the same source Activity Monitor's "% GPU" uses).
    static func gpuTimes() -> [Int32: UInt64] {
        var result: [Int32: UInt64] = [:]
        var accelerators: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &accelerators) == KERN_SUCCESS else {
            return result
        }
        defer { IOObjectRelease(accelerators) }

        var accelerator = IOIteratorNext(accelerators)
        while accelerator != 0 {
            var clients: io_iterator_t = 0
            if IORegistryEntryGetChildIterator(accelerator, kIOServicePlane, &clients) == KERN_SUCCESS {
                var client = IOIteratorNext(clients)
                while client != 0 {
                    if let (pid, nanoseconds) = gpuUsage(of: client) {
                        result[pid, default: 0] += nanoseconds
                    }
                    IOObjectRelease(client)
                    client = IOIteratorNext(clients)
                }
                IOObjectRelease(clients)
            }
            IOObjectRelease(accelerator)
            accelerator = IOIteratorNext(accelerators)
        }
        return result
    }

    private static func gpuUsage(of entry: io_registry_entry_t) -> (Int32, UInt64)? {
        guard
            let creator = IORegistryEntryCreateCFProperty(entry, "IOUserClientCreator" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? String,
            let usage = IORegistryEntryCreateCFProperty(entry, "AppUsage" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? [[String: Any]]
        else { return nil }

        // Formatted "pid 392, WindowServer".
        guard creator.hasPrefix("pid "), let pid = Int32(creator.dropFirst(4).prefix { $0.isNumber }) else { return nil }
        let nanoseconds = usage.reduce(UInt64(0)) { total, entry in
            total + ((entry["accumulatedGPUTime"] as? NSNumber)?.uint64Value ?? 0)
        }
        return (pid, nanoseconds)
    }
}
