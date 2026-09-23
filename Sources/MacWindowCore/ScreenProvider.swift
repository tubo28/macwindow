import AppKit

/// The boundary between this tool and the screens it lays windows out on.
@MainActor
public protocol ScreenProvider {
    /// Every screen, in reading order, in accessibility coordinates.
    func displays() -> [Display]
}

public enum ScreenCoordinates {
    /// Turns Cocoa's bottom-left origin into the accessibility API's top-left one, and back again:
    /// the flip is its own inverse, so the same call serves both directions.
    public static func flipped(_ rect: CGRect, inPrimaryHeight primaryHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    }
}

public struct NSScreenProvider: ScreenProvider {
    public init() {}

    public func displays() -> [Display] {
        guard let primary = NSScreen.screens.first else { return [] }
        let height = primary.frame.maxY

        return Display.ordered(
            NSScreen.screens.map {
                Display(
                    frame: ScreenCoordinates.flipped($0.frame, inPrimaryHeight: height),
                    visibleFrame: ScreenCoordinates.flipped($0.visibleFrame, inPrimaryHeight: height))
            })
    }
}
