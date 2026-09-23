import Testing

@testable import MacWindowCore

@Suite("The three shortcuts")
struct WindowActionTests {
    @Test("Each action answers to control-option and an arrow key")
    func shortcuts() {
        #expect(WindowAction.left.shortcut == Shortcut(keyCode: 0x7B, modifiers: 0x1800))
        #expect(WindowAction.right.shortcut == Shortcut(keyCode: 0x7C, modifiers: 0x1800))
        #expect(WindowAction.maximize.shortcut == Shortcut(keyCode: 0x7E, modifiers: 0x1800))
    }

    @Test("Halves face each other; maximizing has no other side")
    func opposites() {
        #expect(WindowAction.left.opposite == .right)
        #expect(WindowAction.right.opposite == .left)
        #expect(WindowAction.maximize.opposite == .maximize)
    }
}
