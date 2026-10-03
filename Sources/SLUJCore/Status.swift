public enum Status: Sendable, Equatable {
    case fine, warm, heavy
}

public struct Limits: Sendable, Equatable {
    public var cpuWarm: Double = 30
    public var cpuHeavy: Double = 80
    /// CPU must stay over a limit this long before the status changes, so a
    /// spike while loading doesn't count.
    public var sustainSeconds: Double = 10
    public var memoryWarm: UInt64 = 1 << 30
    public var memoryHeavy: UInt64 = 3 << 30

    public init() {}

    public static let standard = Limits()
}

/// Memory is judged instantly; CPU only once it has stayed high.
public struct StatusTracker: Sendable {
    public var limits: Limits
    private var warmSince: Double?
    private var heavySince: Double?

    public init(limits: Limits = .standard) {
        self.limits = limits
    }

    public mutating func reset() {
        warmSince = nil
        heavySince = nil
    }

    /// `time` is any monotonic clock in seconds.
    public mutating func update(_ total: Reading, at time: Double) -> Status {
        warmSince = total.cpuPercent > limits.cpuWarm ? (warmSince ?? time) : nil
        heavySince = total.cpuPercent > limits.cpuHeavy ? (heavySince ?? time) : nil

        let cpuHeavy = heavySince.map { time - $0 >= limits.sustainSeconds } ?? false
        let cpuWarm = warmSince.map { time - $0 >= limits.sustainSeconds } ?? false

        if cpuHeavy || total.memoryBytes > limits.memoryHeavy { return .heavy }
        if cpuWarm || total.memoryBytes > limits.memoryWarm { return .warm }
        return .fine
    }
}
