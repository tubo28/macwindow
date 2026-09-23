import CoreGraphics

@testable import MacWindowCore

/// Three screens in a row, in accessibility coordinates: A leftmost, then B, then C.
enum Screens {
    static let a = Display(
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 875))
    static let b = Display(
        frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 1440, y: 25, width: 1920, height: 1055))
    static let c = Display(
        frame: CGRect(x: 3360, y: 0, width: 1280, height: 800),
        visibleFrame: CGRect(x: 3360, y: 25, width: 1280, height: 775))

    static func half(_ action: WindowAction, of display: Display) -> CGRect {
        WindowFrame.frame(for: action, in: display.visibleFrame)
    }
}
