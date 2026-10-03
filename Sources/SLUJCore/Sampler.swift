public struct Reading: Sendable, Equatable {
    public var cpuPercent: Double
    public var memoryBytes: UInt64
    public var watts: Double
    public var gpuPercent: Double

    public init(cpuPercent: Double = 0, memoryBytes: UInt64 = 0, watts: Double = 0, gpuPercent: Double = 0) {
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
        self.watts = watts
        self.gpuPercent = gpuPercent
    }

    public static let zero = Reading()

    public static func + (lhs: Reading, rhs: Reading) -> Reading {
        Reading(
            cpuPercent: lhs.cpuPercent + rhs.cpuPercent,
            memoryBytes: lhs.memoryBytes + rhs.memoryBytes,
            watts: lhs.watts + rhs.watts,
            gpuPercent: lhs.gpuPercent + rhs.gpuPercent
        )
    }
}

public struct ProcessReading: Sendable, Identifiable {
    public var id: Int32 { snapshot.pid }
    public let snapshot: ProcessSnapshot
    public let reading: Reading
}

/// Turns consecutive snapshots into rates. CPU, energy and GPU are averages
/// since the previous sample, so a process's first sample reads zero for them.
public struct Sampler: Sendable {
    private var previous: [Int32: ProcessSnapshot] = [:]
    private var previousTime: Double?

    public init() {}

    /// True once at least one sample exists to measure rates against.
    public var hasBaseline: Bool { previousTime != nil }

    public mutating func reset() {
        previous = [:]
        previousTime = nil
    }

    /// `time` is any monotonic clock in seconds.
    public mutating func sample(_ table: [Int32: ProcessSnapshot], members: [Int32], at time: Double) -> [ProcessReading] {
        let elapsedNs = previousTime.map { (time - $0) * 1_000_000_000 } ?? 0
        var readings: [ProcessReading] = []
        var next: [Int32: ProcessSnapshot] = [:]

        for pid in members {
            guard let now = table[pid] else { continue }
            next[pid] = now
            var reading = Reading(memoryBytes: now.memoryBytes)
            if elapsedNs > 0, let before = previous[pid], before.startTime == now.startTime {
                reading.cpuPercent = Self.delta(now.cpuTimeNs, before.cpuTimeNs) / elapsedNs * 100
                // Nanojoules per nanosecond is watts.
                reading.watts = Self.delta(now.energyNj, before.energyNj) / elapsedNs
                reading.gpuPercent = Self.delta(now.gpuTimeNs, before.gpuTimeNs) / elapsedNs * 100
            }
            readings.append(ProcessReading(snapshot: now, reading: reading))
        }

        previous = next
        previousTime = time
        return readings
    }

    /// Counters can go backwards when a GPU client closes; treat that as no work.
    private static func delta(_ now: UInt64, _ before: UInt64) -> Double {
        now > before ? Double(now - before) : 0
    }
}
