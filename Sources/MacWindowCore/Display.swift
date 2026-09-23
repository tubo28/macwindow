import CoreGraphics

/// A screen, in accessibility coordinates: origin at the top left of the primary display, Y downwards.
public struct Display: Equatable, Sendable {
    /// The whole screen.
    public let frame: CGRect
    /// The part left over once the menu bar and the Dock have taken theirs. Windows go here.
    public let visibleFrame: CGRect

    public init(frame: CGRect, visibleFrame: CGRect) {
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}

extension Display {
    public enum Direction: Equatable, Sendable {
        case previous
        case next
    }

    /// Reading order: the top row first, and within a row from left to right.
    public static func ordered(_ displays: [Display]) -> [Display] {
        displays.sorted {
            $0.frame.minY == $1.frame.minY
                ? $0.frame.minX < $1.frame.minX : $0.frame.minY < $1.frame.minY
        }
    }

    /// The display a window sits on: the one it overlaps most, falling back to the first.
    ///
    /// Raw overlap rather than a proportion of the window, which says the same thing about which
    /// display wins and needs no screen or window area to divide by.
    public static func containing(_ window: CGRect, in displays: [Display]) -> Display? {
        guard let first = displays.first else { return nil }
        if let whole = displays.first(where: { $0.frame.contains(window) }) { return whole }

        return displays
            .map { ($0, $0.frame.intersection(window)) }
            .filter { !$0.1.isNull }
            .map { ($0.0, $0.1.width * $0.1.height) }
            .reduce((first, CGFloat(0))) { best, candidate in candidate.1 > best.1 ? candidate : best }
            .0
    }

    /// The neighbour in reading order, wrapping around at the ends. A lone display has no neighbour,
    /// which is what keeps a window on a single screen in the same half.
    public static func adjacent(
        to display: Display, in displays: [Display], towards direction: Direction
    ) -> Display? {
        guard displays.count > 1, let index = displays.firstIndex(of: display) else { return nil }

        let step = direction == .next ? 1 : displays.count - 1
        return displays[(index + step) % displays.count]
    }
}
