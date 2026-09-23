import ApplicationServices

/// Moving another application's windows needs the user's consent, granted in System Settings.
public enum Accessibility {
    public static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Asks once, showing the system's own prompt. Silent if consent has already been given.
    @discardableResult
    public static func requestTrust() -> Bool {
        // Spelled out rather than read from `kAXTrustedCheckOptionPrompt`, which the SDK exposes as
        // a mutable global and so cannot be touched from concurrent code.
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
}
