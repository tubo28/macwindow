import Foundation

/// The wiring: reads the world, asks ``WindowPlacement`` where the window goes, and writes it back.
///
/// The one mutable thing in this tool lives here — what was done to which window last time.
@MainActor
public final class WindowMover {
    private let screens: any ScreenProvider
    private let windows: any WindowAccess
    private let retry: (@escaping @MainActor () -> Void) -> Void
    private var last: Record?

    private struct Record {
        let window: any Window
        let action: WindowAction
        let frame: CGRect
    }

    public init(
        screens: any ScreenProvider = NSScreenProvider(),
        windows: any WindowAccess = AccessibilityWindowAccess(),
        retry: @escaping (@escaping @MainActor () -> Void) -> Void = { work in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(25)) { MainActor.assumeIsolated(work) }
        }
    ) {
        self.screens = screens
        self.windows = windows
        self.retry = retry
    }

    public func move(_ action: WindowAction) {
        guard let window = windows.focusedWindow(), let current = window.frame else { return }

        let displays = screens.displays()
        guard
            let placement = WindowPlacement.placement(
                for: action, window: current, displays: displays, last: remembered(about: window))
        else { return }

        var achieved = apply(placement.frame, to: window, on: displays)

        if placement.acrossDisplays {
            window.raise()
            if !achieved.size.isNearly(placement.frame.size) {
                achieved = apply(placement.frame, to: window, on: displays)
            }
        }

        // What the window actually did, not what it was asked to do: an app that will not shrink
        // still has to be recognised as sitting where it was put when the shortcut comes again.
        last = Record(window: window, action: placement.action, frame: achieved)

        guard placement.acrossDisplays, !achieved.size.isNearly(placement.frame.size) else { return }
        // Some apps only accept the new display's size once they have finished arriving on it.
        retry { [self] in
            let retried = apply(placement.frame, to: window, on: displays)
            last = Record(window: window, action: placement.action, frame: retried)
        }
    }

    private func apply(_ frame: CGRect, to window: any Window, on displays: [Display]) -> CGRect {
        window.setFrame(frame)
        guard let landed = window.frame else { return frame }

        guard let display = Display.containing(landed, in: displays) else { return landed }
        let shoved = WindowFrame.shoved(landed, into: display.visibleFrame)
        guard shoved != landed else { return landed }

        window.setFrame(shoved)
        return window.frame ?? shoved
    }

    private func remembered(about window: any Window) -> LastPlacement? {
        guard let last, last.window.isSame(as: window) else { return nil }
        return LastPlacement(action: last.action, frame: last.frame)
    }
}
