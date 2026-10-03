import Testing
@testable import SLUJCore

private func snapshot(_ pid: Int32 = 1, start: Double = 0, cpu: UInt64 = 0, memory: UInt64 = 0, energy: UInt64 = 0, gpu: UInt64 = 0) -> ProcessSnapshot {
    ProcessSnapshot(pid: pid, parentPid: 0, responsiblePid: pid, name: "p", path: "/p", startTime: start,
                    cpuTimeNs: cpu, memoryBytes: memory, energyNj: energy, gpuTimeNs: gpu)
}

@Test func firstSampleHasMemoryButNoRates() {
    var sampler = Sampler()
    let readings = sampler.sample([1: snapshot(cpu: 5_000_000_000, memory: 100)], members: [1], at: 0)
    #expect(readings.first?.reading == Reading(memoryBytes: 100))
    #expect(sampler.hasBaseline)
}

@Test func ratesAreAveragedOverTheInterval() {
    var sampler = Sampler()
    _ = sampler.sample([1: snapshot()], members: [1], at: 0)
    // Over 2 seconds: 1s of CPU, 3 J of energy, 0.5s of GPU.
    let readings = sampler.sample(
        [1: snapshot(cpu: 1_000_000_000, energy: 3_000_000_000, gpu: 500_000_000)], members: [1], at: 2
    )
    let reading = try! #require(readings.first).reading
    #expect(reading.cpuPercent == 50)
    #expect(reading.watts == 1.5)
    #expect(reading.gpuPercent == 25)
}

@Test func reusedPidStartsOver() {
    var sampler = Sampler()
    _ = sampler.sample([1: snapshot(start: 0)], members: [1], at: 0)
    let readings = sampler.sample([1: snapshot(start: 9, cpu: 1_000_000_000)], members: [1], at: 1)
    #expect(readings.first?.reading.cpuPercent == 0)
}

@Test func countersGoingBackwardsReadAsZero() {
    var sampler = Sampler()
    _ = sampler.sample([1: snapshot(gpu: 900)], members: [1], at: 0)
    let readings = sampler.sample([1: snapshot(gpu: 100)], members: [1], at: 1)
    #expect(readings.first?.reading.gpuPercent == 0)
}

@Test func statusNeedsSustainedCPU() {
    var tracker = StatusTracker()
    #expect(tracker.update(Reading(cpuPercent: 95), at: 0) == .fine)
    #expect(tracker.update(Reading(cpuPercent: 95), at: 9) == .fine)
    #expect(tracker.update(Reading(cpuPercent: 95), at: 10) == .heavy)
    // Dropping between the limits keeps the warm timer that started at 0.
    #expect(tracker.update(Reading(cpuPercent: 50), at: 11) == .warm)
    #expect(tracker.update(Reading(cpuPercent: 5), at: 12) == .fine)
}

@Test func statusJudgesMemoryInstantly() {
    var tracker = StatusTracker()
    #expect(tracker.update(Reading(memoryBytes: 2 << 30), at: 0) == .warm)
    #expect(tracker.update(Reading(memoryBytes: 4 << 30), at: 1) == .heavy)
}

@Test func formatting() {
    #expect(Format.bytes(184 * 1_048_576) == "184 MB")
    #expect(Format.bytes(1536 * 1_048_576) == "1.5 GB")
    #expect(Format.watts(0.047) == "47 mW")
    #expect(Format.watts(1.5) == "1.50 W")
    #expect(Format.watts(12.34) == "12.3 W")
    #expect(ProcessName.display(name: "node", arguments: ["node", "/x/node_modules/.bin/vite"]) == "vite (node)")
    #expect(ProcessName.display(name: "node", arguments: ["node", "/x/node_modules/vite/bin/vite.js", "--port", "5760"]) == "vite (node)")
    #expect(ProcessName.display(name: "node", arguments: ["node", "/x/node_modules/@tauri-apps/cli/main.js"]) == "cli (node)")
    #expect(ProcessName.display(name: "node", arguments: ["npm run app", "", ""]) == "npm run app")
    #expect(ProcessName.display(name: "node", arguments: ["node", ""]) == "node")
    #expect(ProcessName.display(name: "com.apple.WebKit.WebContent", arguments: []) == "Web Content")
}
