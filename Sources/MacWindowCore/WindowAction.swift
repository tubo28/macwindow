/// A key press this tool answers to: a virtual key code with Carbon's modifier mask.
public struct Shortcut: Equatable, Sendable {
    public let keyCode: UInt32
    public let modifiers: UInt32

    public init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

extension Shortcut {
    /// `controlKey | optionKey`, spelled out so that Carbon is not needed to read this file.
    public static let controlOption: UInt32 = 0x1800

    public static let controlOptionLeft = Shortcut(keyCode: 0x7B, modifiers: controlOption)
    public static let controlOptionRight = Shortcut(keyCode: 0x7C, modifiers: controlOption)
    public static let controlOptionUp = Shortcut(keyCode: 0x7E, modifiers: controlOption)
}

/// One of the three placements this tool can make.
public enum WindowAction: String, CaseIterable, Equatable, Sendable {
    case left
    case right
    case maximize

    public var shortcut: Shortcut {
        switch self {
        case .left: return .controlOptionLeft
        case .right: return .controlOptionRight
        case .maximize: return .controlOptionUp
        }
    }

    /// What the same key does on the display it has just walked onto.
    public var opposite: WindowAction {
        switch self {
        case .left: return .right
        case .right: return .left
        case .maximize: return .maximize
        }
    }
}
