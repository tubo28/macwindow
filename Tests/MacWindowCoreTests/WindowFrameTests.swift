import CoreGraphics
import Testing

@testable import MacWindowCore

@Suite("The frames an action asks for")
struct WindowFrameTests {
    private let visible = CGRect(x: 0, y: 25, width: 1440, height: 875)

    @Test("A half is the full height and one side of the width")
    func halves() {
        #expect(
            WindowFrame.frame(for: .left, in: visible) == CGRect(x: 0, y: 25, width: 720, height: 875))
        #expect(
            WindowFrame.frame(for: .right, in: visible)
                == CGRect(x: 720, y: 25, width: 720, height: 875))
    }

    @Test("An odd width is halved short, with the right half kept against the right edge")
    func oddWidth() {
        let odd = CGRect(x: 0, y: 0, width: 1441, height: 900)

        #expect(WindowFrame.frame(for: .left, in: odd).width == 720)
        #expect(WindowFrame.frame(for: .right, in: odd) == CGRect(x: 721, y: 0, width: 720, height: 900))
    }

    @Test("A width that halves just short of a whole point does not lose one")
    func floatingPointSlack() {
        let almost = CGRect(x: 0, y: 0, width: 1439.9999, height: 900)

        #expect(WindowFrame.frame(for: .left, in: almost).width == 720)
    }

    @Test("Maximizing takes the whole of what the screen offers")
    func maximize() {
        #expect(WindowFrame.frame(for: .maximize, in: visible) == visible)
    }

    @Test("A window hanging off the screen is slid back, keeping its size")
    func shovedBackOn() {
        let hangingOffTheRight = CGRect(x: 1300, y: 30, width: 400, height: 300)

        #expect(
            WindowFrame.shoved(hangingOffTheRight, into: visible)
                == CGRect(x: 1040, y: 30, width: 400, height: 300))
    }

    @Test("A window already inside is left where it is")
    func leavesWindowsAlone() {
        let inside = CGRect(x: 100, y: 100, width: 400, height: 300)

        #expect(WindowFrame.shoved(inside, into: visible) == inside)
    }

    @Test("A window too big for the screen is put in the corner rather than shrunk")
    func tooBigToFit() {
        let oversized = CGRect(x: 200, y: 200, width: 2000, height: 1200)

        #expect(
            WindowFrame.shoved(oversized, into: visible)
                == CGRect(x: 0, y: 25, width: 2000, height: 1200))
    }
}
