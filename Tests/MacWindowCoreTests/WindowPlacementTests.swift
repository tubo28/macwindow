import CoreGraphics
import Testing

@testable import MacWindowCore

@Suite("Where a window goes when the shortcut is pressed again")
struct WindowPlacementTests {
    /// Presses the same shortcut `times` over, each press finding the window where the last one left it.
    private func walk(
        _ action: WindowAction, from start: CGRect, across displays: [Display], times: Int
    ) -> [CGRect] {
        var window = start
        var last: LastPlacement?

        return (0..<times).compactMap { _ in
            guard
                let placement = WindowPlacement.placement(
                    for: action, window: window, displays: displays, last: last)
            else { return nil }

            window = placement.frame
            last = LastPlacement(action: placement.action, frame: placement.frame)
            return placement.frame
        }
    }

    private let onA = CGRect(x: 300, y: 200, width: 800, height: 600)

    @Test("One screen: the window stays in the half it was put in")
    func oneScreen() {
        let walked = walk(.right, from: onA, across: [Screens.a], times: 3)

        #expect(walked == Array(repeating: Screens.half(.right, of: Screens.a), count: 3))
    }

    @Test("Two screens: pressing right walks the window rightwards and round again")
    func twoScreensRightwards() {
        let walked = walk(.right, from: onA, across: [Screens.a, Screens.b], times: 5)

        #expect(
            walked == [
                Screens.half(.right, of: Screens.a),
                Screens.half(.left, of: Screens.b),
                Screens.half(.right, of: Screens.b),
                Screens.half(.left, of: Screens.a),
                Screens.half(.right, of: Screens.a),
            ])
    }

    @Test("Two screens: pressing left walks the same slots the other way")
    func twoScreensLeftwards() {
        let walked = walk(.left, from: onA, across: [Screens.a, Screens.b], times: 5)

        #expect(
            walked == [
                Screens.half(.left, of: Screens.a),
                Screens.half(.right, of: Screens.b),
                Screens.half(.left, of: Screens.b),
                Screens.half(.right, of: Screens.a),
                Screens.half(.left, of: Screens.a),
            ])
    }

    @Test("Three screens: every half is visited once before coming back")
    func threeScreens() {
        let walked = walk(.right, from: onA, across: [Screens.a, Screens.b, Screens.c], times: 7)

        #expect(
            walked == [
                Screens.half(.right, of: Screens.a),
                Screens.half(.left, of: Screens.b),
                Screens.half(.right, of: Screens.b),
                Screens.half(.left, of: Screens.c),
                Screens.half(.right, of: Screens.c),
                Screens.half(.left, of: Screens.a),
                Screens.half(.right, of: Screens.a),
            ])
    }

    @Test("Walking onto the next screen is remembered as the opposite action")
    func recordsTheOppositeAction() {
        let displays = [Screens.a, Screens.b]
        let last = LastPlacement(action: .right, frame: Screens.half(.right, of: Screens.a))

        let placement = WindowPlacement.placement(
            for: .right, window: Screens.half(.right, of: Screens.a), displays: displays, last: last)

        #expect(placement?.action == .left)
        #expect(placement?.acrossDisplays == true)
    }

    @Test("A first press does not count as crossing")
    func firstPressStaysPut() {
        let placement = WindowPlacement.placement(
            for: .right, window: onA, displays: [Screens.a, Screens.b], last: nil)

        #expect(placement?.acrossDisplays == false)
    }

    @Test("Moving the window by hand starts the walk over")
    func movedByHand() {
        let last = LastPlacement(action: .right, frame: Screens.half(.right, of: Screens.a))

        let placement = WindowPlacement.placement(
            for: .right, window: onA, displays: [Screens.a, Screens.b], last: last)

        #expect(placement?.frame == Screens.half(.right, of: Screens.a))
        #expect(placement?.acrossDisplays == false)
    }

    @Test("A window a point or two off where it was put still counts as being there")
    func toleratesAPointOrTwo() {
        let placed = Screens.half(.right, of: Screens.a)
        let last = LastPlacement(action: .right, frame: placed)

        let placement = WindowPlacement.placement(
            for: .right, window: placed.offsetBy(dx: 0.5, dy: -0.5),
            displays: [Screens.a, Screens.b], last: last)

        #expect(placement?.acrossDisplays == true)
    }

    @Test("Maximizing again carries the window to the next screen")
    func maximizeTours() {
        let walked = walk(.maximize, from: onA, across: [Screens.a, Screens.b, Screens.c], times: 4)

        #expect(
            walked == [
                Screens.a.visibleFrame, Screens.b.visibleFrame, Screens.c.visibleFrame,
                Screens.a.visibleFrame,
            ])
    }

    @Test("With no screens there is nowhere to put anything")
    func noScreens() {
        #expect(WindowPlacement.placement(for: .left, window: onA, displays: [], last: nil) == nil)
    }
}
