import CoreGraphics
import Testing

@testable import MacWindowCore

@Suite("Screen coordinates")
struct ScreenCoordinatesTests {
    @Test("The primary screen's own frame is unchanged by the flip")
    func primaryScreen() {
        let primary = CGRect(x: 0, y: 0, width: 1440, height: 900)

        #expect(ScreenCoordinates.flipped(primary, inPrimaryHeight: 900) == primary)
    }

    @Test("A screen sitting above the primary one lands at a negative Y")
    func screenAbove() {
        let above = CGRect(x: 0, y: 900, width: 1440, height: 900)

        #expect(
            ScreenCoordinates.flipped(above, inPrimaryHeight: 900)
                == CGRect(x: 0, y: -900, width: 1440, height: 900))
    }

    @Test("Flipping twice gives back what was flipped")
    func isItsOwnInverse() {
        let rect = CGRect(x: 120, y: 340, width: 500, height: 400)

        let there = ScreenCoordinates.flipped(rect, inPrimaryHeight: 900)

        #expect(ScreenCoordinates.flipped(there, inPrimaryHeight: 900) == rect)
    }
}
