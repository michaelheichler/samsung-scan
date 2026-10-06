import Foundation

enum RegionHitChecks {
    static func run() {
        noRegionMeansDraw()
        nearCornerResizesCorner()
        topMiddleResizesTop()
        justOutsideEdgeStillResizes()
        pressExactlyAtRadiusResizes()
        centerMoves()
        farAwayDraws()
        cornerWinsTieWithEdge()
        drawingBackwardGivesPositiveSize()
        drawingPastGlassClampsToArea()
        movingShiftsRegion()
        resizingRightWidensRegion()
    }

    private static let mapping = CanvasMappingChecks.mapping
    private static let region = CanvasMappingChecks.region

    private static func hit(_ x: Double, _ y: Double, radius: Double = 9) -> RegionHit {
        mapping.hit(CGPoint(x: x, y: y), on: region, radius: radius)
    }

    private static func dragged(_ hit: RegionHit, from start: CGPoint, to end: CGPoint) -> ScanRegion {
        mapping.region(dragging: hit, of: region, from: start, to: end, minimumSide: 5)
    }

    static func noRegionMeansDraw() {
        expect(mapping.hit(CGPoint(x: 270, y: 80), on: nil, radius: 9) == .draw, "without a region every press starts a new region")
    }

    static func nearCornerResizesCorner() {
        expect(hit(223, 43) == .resize(.topLeft), "a press 3 pt from the top left corner resizes that corner")
    }

    static func topMiddleResizesTop() {
        expect(hit(270, 40) == .resize(.top), "a press on the top edge middle resizes the top edge")
    }

    static func justOutsideEdgeStillResizes() {
        expect(hit(325, 80) == .resize(.right), "a press 5 pt outside the right edge middle still resizes it")
    }

    static func pressExactlyAtRadiusResizes() {
        expect(hit(329, 80) == .resize(.right), "a press exactly 9 pt from the right handle still resizes it")
    }

    static func centerMoves() {
        expect(hit(270, 80) == .move, "a press in the region center moves the region")
    }

    static func farAwayDraws() {
        expect(hit(500, 300) == .draw, "a press away from the region and its handles draws a new region")
    }

    static func cornerWinsTieWithEdge() {
        expect(hit(245, 40, radius: 30) == .resize(.topLeft), "a press as close to a corner as to an edge resizes the corner")
    }

    static func drawingBackwardGivesPositiveSize() {
        let drawn = dragged(.draw, from: CGPoint(x: 320, y: 120), to: CGPoint(x: 220, y: 40))
        expect(drawn == region, "drawing from bottom right to top left gives the region 10,20 50 x 40 mm")
    }

    static func drawingPastGlassClampsToArea() {
        let drawn = dragged(.draw, from: CGPoint(x: 300, y: 100), to: CGPoint(x: 900, y: 700))
        let expected = ScanRegion(leftMillimeters: 50, topMillimeters: 50, widthMillimeters: 150, heightMillimeters: 250)
        expect(drawn == expected, "drawing past the glass stops at the area edge")
    }

    static func movingShiftsRegion() {
        let moved = dragged(.move, from: CGPoint(x: 270, y: 80), to: CGPoint(x: 290, y: 80))
        let expected = ScanRegion(leftMillimeters: 20, topMillimeters: 20, widthMillimeters: 50, heightMillimeters: 40)
        expect(moved == expected, "moving 20 pt right shifts the region 10 mm and keeps its size")
    }

    static func resizingRightWidensRegion() {
        let resized = dragged(.resize(.right), from: CGPoint(x: 320, y: 80), to: CGPoint(x: 340, y: 80))
        let expected = ScanRegion(leftMillimeters: 10, topMillimeters: 20, widthMillimeters: 60, heightMillimeters: 40)
        expect(resized == expected, "dragging the right edge 20 pt widens the region by 10 mm")
    }
}
