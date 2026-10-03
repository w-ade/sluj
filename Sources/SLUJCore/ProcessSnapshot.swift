/// One process at one moment. Counters (`cpuTimeNs`, `energyNj`, `gpuTimeNs`)
/// only mean something as the difference between two snapshots; `Sampler`
/// turns them into rates.
public struct ProcessSnapshot: Sendable, Equatable {
    public var pid: Int32
    public var parentPid: Int32
    /// The process macOS holds responsible for this one. WebKit and other XPC
    /// helpers point here at the app that asked for them, or at the terminal
    /// when that app was launched from one.
    public var responsiblePid: Int32
    public var name: String
    public var path: String
    /// Seconds since 1970. Distinguishes a reused pid from the original.
    public var startTime: Double
    public var cpuTimeNs: UInt64
    /// Physical footprint, the figure Activity Monitor shows as "Memory".
    public var memoryBytes: UInt64
    public var energyNj: UInt64
    public var gpuTimeNs: UInt64

    public init(
        pid: Int32, parentPid: Int32, responsiblePid: Int32, name: String, path: String,
        startTime: Double, cpuTimeNs: UInt64 = 0, memoryBytes: UInt64 = 0,
        energyNj: UInt64 = 0, gpuTimeNs: UInt64 = 0
    ) {
        self.pid = pid
        self.parentPid = parentPid
        self.responsiblePid = responsiblePid
        self.name = name
        self.path = path
        self.startTime = startTime
        self.cpuTimeNs = cpuTimeNs
        self.memoryBytes = memoryBytes
        self.energyNj = energyNj
        self.gpuTimeNs = gpuTimeNs
    }
}
