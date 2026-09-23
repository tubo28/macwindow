import Foundation
import Testing

@testable import MacWindowCore

@Suite("What the agent writes down about itself")
struct AgentRecordTests {
    @Test("Survives the trip through the file it is stored in")
    func roundTrip() throws {
        let record = AgentRecord(pid: 7, executablePath: "/usr/local/bin/macwindow", trusted: true)

        let restored = try JSONDecoder().decode(AgentRecord.self, from: JSONEncoder().encode(record))

        #expect(restored == record)
    }

    @Test("A record left behind by a process that is gone counts as stale")
    func staleRecord() {
        let mine = AgentRecord(pid: getpid(), executablePath: "/usr/local/bin/macwindow", trusted: true)
        let gone = AgentRecord(pid: .max, executablePath: "/usr/local/bin/macwindow", trusted: true)

        #expect(mine.isRunning)
        #expect(!gone.isRunning)
    }
}
