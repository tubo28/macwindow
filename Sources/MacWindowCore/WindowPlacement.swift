import CoreGraphics

/// Where a window is going, and what to remember about having put it there.
public struct Placement: Equatable, Sendable {
    public let frame: CGRect
    /// Not always the action that was asked for: walking onto the next display records the opposite one.
    public let action: WindowAction
    public let acrossDisplays: Bool

    public init(frame: CGRect, action: WindowAction, acrossDisplays: Bool) {
        self.frame = frame
        self.action = action
        self.acrossDisplays = acrossDisplays
    }
}

public struct LastPlacement: Equatable, Sendable {
    public let action: WindowAction
    public let frame: CGRect

    public init(action: WindowAction, frame: CGRect) {
        self.action = action
        self.frame = frame
    }
}

public enum WindowPlacement {
    /// Pressing a shortcut once puts the window in that half of the display it is on. Pressing the
    /// same one again — with the window still where it was left — carries it onto the neighbouring
    /// display and into the far half, so that repeated presses walk it across the desk.
    public static func placement(
        for action: WindowAction, window: CGRect, displays: [Display], last: LastPlacement?
    ) -> Placement? {
        guard let current = Display.containing(window, in: displays) else { return nil }

        let pressedAgain = last.map { $0.action == action && $0.frame.isNearly(window) } ?? false

        guard pressedAgain,
            let neighbour = Display.adjacent(to: current, in: displays, towards: direction(of: action))
        else {
            return Placement(
                frame: WindowFrame.frame(for: action, in: current.visibleFrame),
                action: action, acrossDisplays: false)
        }

        // Arriving at the far edge of the next display is what makes the following press start a
        // fresh half on that display rather than turning straight back.
        let arriving = action.opposite
        return Placement(
            frame: WindowFrame.frame(for: arriving, in: neighbour.visibleFrame),
            action: arriving, acrossDisplays: true)
    }

    private static func direction(of action: WindowAction) -> Display.Direction {
        action == .left ? .previous : .next
    }
}
