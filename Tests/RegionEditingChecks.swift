import Foundation

enum RegionEditingChecks {
    static func run() {
        rightAndBottomFollowSize()
        movePastRightEdgeStopsAtEdge()
        movePastTopLeftStopsAtCorner()
        moveShrinksOversizedRegionToArea()
        leftHandleStopsBeforeRightEdge()
        rightHandleStopsAfterLeftEdge()
        cornerHandleStopsAtAreaEdges()
        topHandleIgnoresSidewaysDrag()
        areaLimitsOversizedMinimumSide()
        tooNarrowOrTooShortIsTooSmall()
        imageSizeBecomesRegion()
        zeroResolutionGivesEmptyRegion()
    }

    private static let area = CanvasMappingChecks.area
    private static let region = CanvasMappingChecks.region

    private static func box(_ left: Double, _ top: Double, _ width: Double, _ height: Double) -> ScanRegion {
        ScanRegion(leftMillimeters: left, topMillimeters: top, widthMillimeters: width, heightMillimeters: height)
    }

    private static func resized(_ handle: RegionHandle, dx: Double, dy: Double = 0) -> ScanRegion {
        region.resized(handle, dx: dx, dy: dy, within: area, minimumSide: 5)
    }

    static func rightAndBottomFollowSize() {
        expect(region.rightMillimeters == 60 && region.bottomMillimeters == 60, "a region at 10,20 sized 50 x 40 ends at 60,60")
    }

    static func movePastRightEdgeStopsAtEdge() {
        expect(region.moved(dx: 500, dy: 0, within: area) == box(150, 20, 50, 40), "a move past the right edge stops at the edge")
    }

    static func movePastTopLeftStopsAtCorner() {
        expect(region.moved(dx: -500, dy: -500, within: area) == box(0, 0, 50, 40), "a move past the top left stops at the corner")
    }

    static func moveShrinksOversizedRegionToArea() {
        let moved = box(10, 10, 250, 400).moved(dx: 0, dy: 0, within: area)
        expect(moved == box(0, 0, 200, 300), "a region larger than the area shrinks to the area")
    }

    static func leftHandleStopsBeforeRightEdge() {
        expect(resized(.left, dx: 500) == box(55, 20, 5, 40), "the left handle stops 5 mm before the right edge and never flips")
    }

    static func rightHandleStopsAfterLeftEdge() {
        expect(resized(.right, dx: -500) == box(10, 20, 5, 40), "the right handle stops 5 mm after the left edge")
    }

    static func cornerHandleStopsAtAreaEdges() {
        let grown = resized(.bottomRight, dx: 500, dy: 500)
        expect(grown.rightMillimeters == 200 && grown.bottomMillimeters == 300, "the bottom right handle stops at the area edges")
    }

    static func topHandleIgnoresSidewaysDrag() {
        expect(resized(.top, dx: 30, dy: -5) == box(10, 15, 50, 45), "the top handle moves only the top edge")
    }

    static func areaLimitsOversizedMinimumSide() {
        let narrow = ScanArea(widthMillimeters: 100, heightMillimeters: 300)
        let shrunk = region.resized(.right, dx: -500, dy: 0, within: narrow, minimumSide: 500)
        expect(shrunk.rightMillimeters == 100, "a minimum side wider than the area stops the right edge at the area edge")
    }

    static func tooNarrowOrTooShortIsTooSmall() {
        expect(!box(0, 0, 4, 50).isAtLeast(5), "a region 4 mm wide is smaller than 5 mm")
        expect(!box(0, 0, 50, 4).isAtLeast(5), "a region 4 mm high is smaller than 5 mm")
        expect(box(0, 0, 5, 5).isAtLeast(5), "a 5 x 5 mm region is at least 5 mm")
    }

    static func imageSizeBecomesRegion() {
        let extent = ScanRegion(pixelWidth: 637, pixelHeight: 892, dotsPerInch: 75)
        let size = abs(extent.widthMillimeters - 215.73) < 0.01 && abs(extent.heightMillimeters - 302.09) < 0.01
        expect(size, "a 637 x 892 px image at 75 dpi covers 215.73 x 302.09 mm")
        expect(extent.leftMillimeters == 0 && extent.topMillimeters == 0, "an image region starts at the glass corner")
    }

    static func zeroResolutionGivesEmptyRegion() {
        let zero = ScanRegion(pixelWidth: 637, pixelHeight: 892, dotsPerInch: 0)
        let negative = ScanRegion(pixelWidth: 637, pixelHeight: 892, dotsPerInch: -75)
        expect(zero.widthMillimeters == 0 && zero.heightMillimeters == 0, "an image at 0 dpi covers no area")
        expect(negative.widthMillimeters == 0 && negative.heightMillimeters == 0, "an image at negative dpi covers no area")
    }
}
