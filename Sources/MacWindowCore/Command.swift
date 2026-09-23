public enum CommandError: Error, CustomStringConvertible {
    case unknownArgument(String)

    public var description: String {
        switch self {
        case let .unknownArgument(argument):
            return "unknown argument '\(argument)'. Run 'macwindow --help' for usage."
        }
    }
}

public enum Command: Equatable, Sendable {
    case move(WindowAction)
    case status
    case watch
    case install
    case uninstall
    case help

    public static func parse(_ arguments: [String]) throws -> Command {
        guard let name = arguments.first else { return .help }
        if let unexpected = arguments.dropFirst().first {
            throw CommandError.unknownArgument(unexpected)
        }

        if let action = WindowAction(rawValue: name) { return .move(action) }

        switch name {
        case "status": return .status
        case "watch": return .watch
        case "install": return .install
        case "uninstall": return .uninstall
        case "help", "--help", "-h": return .help
        default: throw CommandError.unknownArgument(name)
        }
    }
}

public let usage = """
    macwindow — puts the frontmost window where Rectangle would, without the extra app.

      ⌃⌥←  left half     ⌃⌥→  right half     ⌃⌥↑  maximize

    Pressing the same shortcut again walks the window onto the next display.

    Usage:
      macwindow left            move the frontmost window to the left half
      macwindow right           move the frontmost window to the right half
      macwindow maximize        fill the display with the frontmost window
      macwindow status          show whether the shortcuts can work
      macwindow watch           listen for the shortcuts until stopped
      macwindow install         install and start the login agent that runs 'watch'
      macwindow uninstall       stop the login agent
    """
