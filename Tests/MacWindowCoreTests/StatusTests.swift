import Testing

@testable import MacWindowCore

@Suite("Reporting what works")
struct StatusTests {
    private func record(trusted: Bool) -> AgentRecord {
        AgentRecord(pid: 4242, executablePath: "/usr/local/bin/macwindow", trusted: trusted)
    }

    @Test("Tells apart the consent this process has from the one the agent has")
    func separateGrants() {
        let lines = Status.lines(trusted: true, installed: true, agent: record(trusted: false))

        #expect(lines[0] == "accessibility (this process): granted")
        #expect(lines.contains("accessibility (login agent): not granted"))
    }

    @Test("Says which binary to register when the agent is the one without consent")
    func hintsAtTheAgentsBinary() {
        let lines = Status.lines(trusted: true, installed: true, agent: record(trusted: false))

        #expect(lines.contains { $0.contains("/usr/local/bin/macwindow") })
        #expect(lines.contains { $0.contains("launchctl kickstart") })
    }

    @Test("Keeps quiet about registering once the agent has consent")
    func noHintWhenGranted() {
        let lines = Status.lines(trusted: true, installed: true, agent: record(trusted: true))

        #expect(lines == [
            "accessibility (this process): granted",
            "login agent: running (pid 4242)",
            "accessibility (login agent): granted",
        ])
    }

    @Test("An installed agent that left no record is reported as not running")
    func installedButSilent() {
        let lines = Status.lines(trusted: false, installed: true, agent: nil)

        #expect(lines == [
            "accessibility (this process): not granted",
            "login agent: installed, not running",
        ])
    }

    @Test("Without the agent there is nothing to say about it")
    func notInstalled() {
        let lines = Status.lines(trusted: true, installed: false, agent: record(trusted: true))

        #expect(lines == [
            "accessibility (this process): granted",
            "login agent: not installed",
        ])
    }
}
