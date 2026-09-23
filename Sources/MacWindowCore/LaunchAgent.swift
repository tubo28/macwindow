import Foundation

public enum LaunchAgentError: Error, CustomStringConvertible {
    case launchctlFailed(arguments: [String], status: Int32, message: String)

    public var description: String {
        switch self {
        case let .launchctlFailed(arguments, status, message):
            let detail = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return "launchctl \(arguments.joined(separator: " ")) exited with \(status)"
                + (detail.isEmpty ? "" : ": \(detail)")
        }
    }
}

/// The per-user agent that keeps the shortcuts listening from login onwards.
public enum LaunchAgent {
    public static let label = "com.github.tubo28.macwindow"

    private static let launchctl = "/bin/launchctl"

    public static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    public static func plist(executablePath: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
                <string>watch</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
        </dict>
        </plist>

        """
    }

    public static func install(executablePath: String, runner: CommandRunner) throws {
        let url = plistURL
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(plist(executablePath: executablePath).utf8).write(to: url, options: .atomic)

        // An earlier copy may still be loaded; booting it out first makes install idempotent.
        _ = try? runner.run(launchctl, ["bootout", serviceTarget])
        try launch(["bootstrap", domainTarget, url.path], with: runner)
    }

    public static func uninstall(runner: CommandRunner) throws {
        _ = try? runner.run(launchctl, ["bootout", serviceTarget])
        try? FileManager.default.removeItem(at: plistURL)
    }

    public static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    private static var domainTarget: String { "gui/\(getuid())" }
    private static var serviceTarget: String { "\(domainTarget)/\(label)" }

    private static func launch(_ arguments: [String], with runner: CommandRunner) throws {
        let result = try runner.run(launchctl, arguments)
        guard result.status == 0 else {
            throw LaunchAgentError.launchctlFailed(
                arguments: arguments, status: result.status, message: result.standardError)
        }
    }
}
