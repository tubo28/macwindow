import Foundation

/// What the running agent knows about itself and a `status` run from a terminal cannot see.
///
/// macOS grants accessibility to the *responsible* process: a terminal run answers for the
/// terminal, the agent answers for the binary launchd started. Only the agent can tell whether
/// the shortcuts will move anything, so it writes down the answer for `status` to read.
public struct AgentRecord: Codable, Equatable, Sendable {
    public let pid: Int32
    public let executablePath: String
    public let trusted: Bool

    public init(pid: Int32, executablePath: String, trusted: Bool) {
        self.pid = pid
        self.executablePath = executablePath
        self.trusted = trusted
    }

    /// Signal 0 asks about the process without disturbing it; `EPERM` means it is there but ours to
    /// look at only.
    public var isRunning: Bool { kill(pid, 0) == 0 || errno == EPERM }

    public static var url: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/macwindow/agent.json")
    }

    /// The record of the agent that is still running, if there is one.
    public static func current() -> AgentRecord? {
        guard
            let data = try? Data(contentsOf: url),
            let record = try? JSONDecoder().decode(AgentRecord.self, from: data),
            record.isRunning
        else { return nil }
        return record
    }

    /// Written once, when the agent starts. A consent given afterwards only reaches the process
    /// when it is restarted, which is what `status` tells the user to do.
    public func save() {
        let url = Self.url
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(self).write(to: url, options: .atomic)
    }

    public static func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
