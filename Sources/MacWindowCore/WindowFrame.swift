import Foundation

/// The frames themselves: where an action puts a window, and how a stray window is brought back.
public enum WindowFrame {
    public static func frame(for action: WindowAction, in visibleFrame: CGRect) -> CGRect {
        switch action {
        case .maximize:
            return visibleFrame
        case .left, .right:
            // The nudge saves a point on a width whose half lands a hair below a whole number.
            let width = floor(visibleFrame.width * 0.5 + 0.0001)
            let x = action == .left ? visibleFrame.minX : visibleFrame.maxX - width
            return CGRect(x: x, y: visibleFrame.minY, width: width, height: visibleFrame.height)
        }
    }

    /// Slides a window back inside a screen without resizing it. One too big for the screen ends up
    /// in its top left corner, since shrinking it is the caller's business and not always possible.
    public static func shoved(_ window: CGRect, into bounds: CGRect) -> CGRect {
        CGRect(
            x: max(bounds.minX, min(window.minX, bounds.maxX - window.width)),
            y: max(bounds.minY, min(window.minY, bounds.maxY - window.height)),
            width: window.width,
            height: window.height)
    }
}

extension CGRect {
    /// Windows come back from the accessibility API a fraction off what was asked for, and one that
    /// is a point out is still where it was put.
    func isNearly(_ other: CGRect, tolerance: CGFloat = 1) -> Bool {
        abs(minX - other.minX) <= tolerance && abs(minY - other.minY) <= tolerance
            && size.isNearly(other.size, tolerance: tolerance)
    }
}

extension CGSize {
    func isNearly(_ other: CGSize, tolerance: CGFloat = 1) -> Bool {
        abs(width - other.width) <= tolerance && abs(height - other.height) <= tolerance
    }
}
