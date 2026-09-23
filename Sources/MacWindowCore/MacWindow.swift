import AppKit
import Foundation

/// Carries out a ``Command``.
@MainActor
public struct MacWindow {
    private let mover: WindowMover
    private let runner: CommandRunner
    private let executablePath: String
    private let write: (String) -> Void
    private let warn: (String) -> Void

    public init(
        mover: WindowMover = WindowMover(),
        runner: CommandRunner = ProcessCommandRunner(),
        executablePath: String,
        write: @escaping (String) -> Void = { print($0) },
        warn: @escaping (String) -> Void = { FileHandle.standardError.write(Data("macwindow: \($0)\n".utf8)) }
    ) {
        self.mover = mover
        self.runner = runner
        self.executablePath = executablePath
        self.write = write
        self.warn = warn
    }

    public func run(_ command: Command) throws {
        switch command {
        case let .move(action):
            warnUnlessTrusted()
            mover.move(action)

        case .status:
            Status.lines(
                trusted: Accessibility.isTrusted,
                installed: LaunchAgent.isInstalled,
                agent: AgentRecord.current()
            ).forEach(write)

        case .watch:
            watch()

        case .install:
            try LaunchAgent.install(executablePath: executablePath, runner: runner)
            write("installed \(LaunchAgent.plistURL.path)")
            // Not asking for consent here: this process answers for the terminal that ran it, so
            // the grant would land on the terminal. The agent, just bootstrapped, asks for itself.
            write("run 'macwindow status' to see whether the agent may move windows")

        case .uninstall:
            try LaunchAgent.uninstall(runner: runner)
            write("uninstalled \(LaunchAgent.label)")

        case .help:
            write(usage)
        }
    }

    private func watch() -> Never {
        requestTrust()
        AgentRecord(pid: getpid(), executablePath: executablePath, trusted: Accessibility.isTrusted)
            .save()

        let registry = HotkeyRegistry { [mover] action in mover.move(action) }
        for refused in registry.start() {
            warn("another app already holds the shortcut for '\(refused.rawValue)'")
        }

        // Carbon hot keys arrive through the application's event dispatcher, so the run loop has to
        // be an application's. `.accessory` keeps it out of the Dock and the ⌘⇥ switcher.
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        withExtendedLifetime(registry) { application.run() }

        fatalError("run loop stopped unexpectedly")
    }

    private func warnUnlessTrusted() {
        guard !Accessibility.isTrusted else { return }
        warn(
            "no accessibility permission; windows will not move. "
                + "Add \(executablePath) under System Settings → Privacy & Security → Accessibility.")
    }

    /// Consent is recorded against whoever is responsible for this process — the agent itself when
    /// launchd started it. So the agent has to do its own asking; nobody can do it on its behalf.
    private func requestTrust() {
        guard !Accessibility.isTrusted else { return }
        Accessibility.requestTrust()
        warnUnlessTrusted()
    }
}
