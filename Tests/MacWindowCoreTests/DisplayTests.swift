import CoreGraphics
import Testing

@testable import MacWindowCore

@Suite("Reading the arrangement of screens")
struct DisplayTests {
    @Test("Screens come out in reading order: the top row first, then left to right")
    func readingOrder() {
        let stacked = Display(
            frame: CGRect(x: 200, y: -900, width: 1440, height: 900),
            visibleFrame: CGRect(x: 200, y: -900, width: 1440, height: 900))

        #expect(Display.ordered([Screens.b, Screens.a]) == [Screens.a, Screens.b])
        #expect(Display.ordered([Screens.a, stacked, Screens.b]) == [stacked, Screens.a, Screens.b])
    }

    @Test("A window belongs to the screen it covers most of")
    func mostlyOverlapping() {
        let mostlyOnA = CGRect(x: 1000, y: 100, width: 600, height: 400)

        #expect(Display.containing(mostlyOnA, in: [Screens.a, Screens.b]) == Screens.a)
        #expect(
            Display.containing(mostlyOnA.offsetBy(dx: 300, dy: 0), in: [Screens.a, Screens.b])
                == Screens.b)
    }

    @Test("A window wholly on one screen belongs to it")
    func whollyInside() {
        let onB = CGRect(x: 1500, y: 100, width: 600, height: 400)

        #expect(Display.containing(onB, in: [Screens.a, Screens.b]) == Screens.b)
    }

    @Test("A window on no screen at all falls back to the first")
    func offEveryScreen() {
        let nowhere = CGRect(x: -5000, y: -5000, width: 100, height: 100)

        #expect(Display.containing(nowhere, in: [Screens.a, Screens.b]) == Screens.a)
        #expect(Display.containing(nowhere, in: []) == nil)
    }

    @Test("A lone screen has no neighbour, which is what keeps a window on it")
    func loneScreen() {
        #expect(Display.adjacent(to: Screens.a, in: [Screens.a], towards: .next) == nil)
        #expect(Display.adjacent(to: Screens.a, in: [Screens.a], towards: .previous) == nil)
    }

    @Test("With two screens either direction reaches the other one")
    func twoScreens() {
        let pair = [Screens.a, Screens.b]

        #expect(Display.adjacent(to: Screens.a, in: pair, towards: .next) == Screens.b)
        #expect(Display.adjacent(to: Screens.a, in: pair, towards: .previous) == Screens.b)
        #expect(Display.adjacent(to: Screens.b, in: pair, towards: .next) == Screens.a)
    }

    @Test("With three screens the neighbours follow the order and wrap round at the ends")
    func threeScreens() {
        let row = [Screens.a, Screens.b, Screens.c]

        #expect(Display.adjacent(to: Screens.b, in: row, towards: .next) == Screens.c)
        #expect(Display.adjacent(to: Screens.b, in: row, towards: .previous) == Screens.a)
        #expect(Display.adjacent(to: Screens.c, in: row, towards: .next) == Screens.a)
        #expect(Display.adjacent(to: Screens.a, in: row, towards: .previous) == Screens.c)
    }
}
