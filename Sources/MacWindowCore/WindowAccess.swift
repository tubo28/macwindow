import AppKit
import ApplicationServices

/// The frontmost window, as far as this tool cares: a frame that can be read and written.
@MainActor
public protocol Window: AnyObject {
    /// Where the window is now, in accessibility coordinates.
    var frame: CGRect? { get }
    func setFrame(_ frame: CGRect)
    func raise()
    /// Whether this handle and another stand for the same window on screen.
    func isSame(as other: any Window) -> Bool
}

extension Window {
    public func isSame(as other: any Window) -> Bool { self === other }
}

/// The boundary between this tool and the windows it moves.
@MainActor
public protocol WindowAccess {
    func focusedWindow() -> (any Window)?
}

/// Reaches the frontmost application's focused window through the accessibility API.
@MainActor
public struct AccessibilityWindowAccess: WindowAccess {
    /// An unresponsive app must not take the resident agent down with it.
    private static let messagingTimeout: Float = 1.0

    public init() {}

    public func focusedWindow() -> (any Window)? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }

        let application = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(application, Self.messagingTimeout)

        guard let element = focusedWindow(of: application) ?? firstWindow(of: application) else {
            return nil
        }
        guard copy(element, kAXRoleAttribute) as? String != kAXSheetRole else { return nil }

        return AccessibilityWindow(element: element, application: application)
    }

    private func focusedWindow(of application: AXUIElement) -> AXUIElement? {
        guard let value = copy(application, kAXFocusedWindowAttribute), CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (value as! AXUIElement)
    }

    private func firstWindow(of application: AXUIElement) -> AXUIElement? {
        guard let windows = copy(application, kAXWindowsAttribute) as? [AXUIElement] else { return nil }
        return windows.first
    }

    private func copy(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value
    }
}

/// One window behind the accessibility API.
@MainActor
final class AccessibilityWindow: Window {
    private let element: AXUIElement
    private let application: AXUIElement

    init(element: AXUIElement, application: AXUIElement) {
        self.element = element
        self.application = application
    }

    var frame: CGRect? {
        guard let position: CGPoint = value(kAXPositionAttribute, .cgPoint),
            let size: CGSize = value(kAXSizeAttribute, .cgSize)
        else { return nil }
        return CGRect(origin: position, size: size)
    }

    func setFrame(_ frame: CGRect) {
        withPlainUserInterface {
            // Shrink first so the window fits wherever it is going, move, then take the size it was
            // refused while it was still on the old screen.
            set(kAXSizeAttribute, frame.size)
            set(kAXPositionAttribute, frame.origin)
            set(kAXSizeAttribute, frame.size)
        }
    }

    func raise() {
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)
    }

    func isSame(as other: any Window) -> Bool {
        guard let other = other as? AccessibilityWindow else { return false }
        return CFEqual(element, other.element)
    }

    /// Electron and Office windows bounce off the requested frame while the app advertises an
    /// enhanced interface, so it is put down for the length of the move and handed back after.
    private func withPlainUserInterface(_ body: () -> Void) {
        let enhanced = value(of: application, "AXEnhancedUserInterface") as? Bool ?? false
        if enhanced { AXUIElementSetAttributeValue(application, "AXEnhancedUserInterface" as CFString, false as CFTypeRef) }
        body()
        if enhanced { AXUIElementSetAttributeValue(application, "AXEnhancedUserInterface" as CFString, true as CFTypeRef) }
    }

    private func set(_ attribute: String, _ point: CGPoint) {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return }
        AXUIElementSetAttributeValue(element, attribute as CFString, value)
    }

    private func set(_ attribute: String, _ size: CGSize) {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(element, attribute as CFString, value)
    }

    private func value<T>(_ attribute: String, _ type: AXValueType) -> T? {
        guard let raw = value(of: element, attribute), CFGetTypeID(raw) == AXValueGetTypeID() else {
            return nil
        }
        let result = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { result.deallocate() }
        guard AXValueGetValue(raw as! AXValue, type, result) else { return nil }
        return result.pointee
    }

    private func value(of element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value
    }
}
