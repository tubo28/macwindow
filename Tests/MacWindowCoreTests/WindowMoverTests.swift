import CoreGraphics
import Testing

@testable import MacWindowCore

/// A window that, like a real one, may refuse to become as small as it is asked to be.
@MainActor
final class FakeWindow: Window {
    var frame: CGRect?
    var minimumSize: CGSize = .zero
    private(set) var requested: [CGRect] = []
    private(set) var raises = 0

    init(frame: CGRect) {
        self.frame = frame
    }

    func setFrame(_ frame: CGRect) {
        requested.append(frame)
        self.frame = CGRect(
            origin: frame.origin,
            size: CGSize(
                width: max(frame.width, minimumSize.width),
                height: max(frame.height, minimumSize.height)))
    }

    func raise() {
        raises += 1
    }
}

struct FakeScreens: ScreenProvider {
    let all: [Display]

    func displays() -> [Display] { all }
}

struct FakeFocus: WindowAccess {
    let window: (any Window)?

    func focusedWindow() -> (any Window)? { window }
}

@MainActor
@Suite("Moving the window that is in front")
struct WindowMoverTests {
    private func mover(
        _ window: FakeWindow?, on displays: [Display], retry: @escaping (@escaping @MainActor () -> Void) -> Void = { _ in }
    ) -> WindowMover {
        WindowMover(screens: FakeScreens(all: displays), windows: FakeFocus(window: window), retry: retry)
    }

    @Test("The window is put in the half of the screen it is on")
    func firstMove() {
        let window = FakeWindow(frame: CGRect(x: 300, y: 200, width: 800, height: 600))

        mover(window, on: [Screens.a]).move(.right)

        #expect(window.frame == Screens.half(.right, of: Screens.a))
    }

    @Test("A window that will not shrink is kept on the screen it was put on")
    func staysOnScreen() {
        let window = FakeWindow(frame: CGRect(x: 300, y: 200, width: 800, height: 600))
        window.minimumSize = CGSize(width: 800, height: 0)

        mover(window, on: [Screens.a, Screens.b]).move(.right)

        #expect(window.frame == CGRect(x: 640, y: 25, width: 800, height: 875))
    }

    @Test("What the window actually did, not what it was asked to do, is what the next press reads")
    func remembersWhatWasAchieved() {
        let window = FakeWindow(frame: CGRect(x: 300, y: 200, width: 800, height: 600))
        window.minimumSize = CGSize(width: 800, height: 0)
        let mover = mover(window, on: [Screens.a, Screens.b])

        mover.move(.right)
        mover.move(.right)

        #expect(window.frame?.minX == Screens.half(.left, of: Screens.b).minX)
    }

    @Test("A window that lands on the next screen at the wrong size is asked again, twice")
    func retriesAfterCrossing() {
        let window = FakeWindow(frame: CGRect(x: 300, y: 200, width: 800, height: 600))
        var delayed = 0
        let mover = mover(window, on: [Screens.a, Screens.b], retry: { work in
            delayed += 1
            work()
        })

        mover.move(.right)
        window.minimumSize = CGSize(width: 1000, height: 0)
        mover.move(.right)

        #expect(window.requested.count == 4)
        #expect(delayed == 1)
        #expect(window.raises == 1)
    }

    @Test("Staying on the same screen needs no retry and no raise")
    func noRetryWithoutCrossing() {
        let window = FakeWindow(frame: CGRect(x: 300, y: 200, width: 800, height: 600))
        var delayed = 0
        let mover = mover(window, on: [Screens.a], retry: { _ in delayed += 1 })

        mover.move(.right)
        mover.move(.right)

        #expect(delayed == 0)
        #expect(window.raises == 0)
    }

    @Test("With nothing in front there is nothing to move")
    func nothingFocused() {
        mover(nil, on: [Screens.a]).move(.left)
    }
}
