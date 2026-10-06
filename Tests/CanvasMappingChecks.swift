import Foundation

enum CanvasMappingChecks {
    static func run() {
        wideViewCentersGlassHorizontally()
        tallViewCentersGlassVertically()
        insetViewFitsGlassInside()
        nullViewHasNoScale()
        emptyViewHasNoScale()
        emptyAreaHasNoScale()
        zeroScaleGivesZeroMillimeters()
        glassCornerIsOriginPoint()
        pointConvertsToMillimeters()
        pointAboveLeftClampsToCorner()
        pointBeyondGlassClampsToAreaSize()
        regionRectRoundTripsToRegionCorner()
        handlesSitOnCornersAndEdgeMiddles()
    }

    static let area = ScanArea(widthMillimeters: 200, heightMillimeters: 300)
    static let mapping = CanvasMapping(area: area, bounds: CGRect(x: 0, y: 0, width: 800, height: 600))
    static let region = ScanRegion(leftMillimeters: 10, topMillimeters: 20, widthMillimeters: 50, heightMillimeters: 40)

    static func isClose(_ value: Double, _ expected: Double) -> Bool {
        abs(value - expected) < 0.0005
    }

    static func isClose(_ rect: CGRect, _ expected: CGRect) -> Bool {
        isClose(rect.minX, expected.minX) && isClose(rect.minY, expected.minY)
            && isClose(rect.width, expected.width) && isClose(rect.height, expected.height)
    }

    private static func mapping(in bounds: CGRect) -> CanvasMapping {
        CanvasMapping(area: area, bounds: bounds)
    }

    static func wideViewCentersGlassHorizontally() {
        expect(mapping.pointsPerMillimeter == 2, "a 200 x 300 mm glass in an 800 x 600 view uses 2 points per mm")
        expect(isClose(mapping.glass, CGRect(x: 200, y: 0, width: 400, height: 600)), "a wide view centers the glass left to right")
    }

    static func tallViewCentersGlassVertically() {
        let glass = mapping(in: CGRect(x: 0, y: 0, width: 400, height: 1000)).glass
        expect(isClose(glass, CGRect(x: 0, y: 200, width: 400, height: 600)), "a tall view centers the glass top to bottom")
    }

    static func insetViewFitsGlassInside() {
        let inset = mapping(in: CGRect(x: 20, y: 20, width: 360, height: 560))
        expect(isClose(inset.pointsPerMillimeter, 1.8), "an inset 360 x 560 view uses 1.8 points per mm")
        expect(isClose(inset.glass, CGRect(x: 20, y: 30, width: 360, height: 540)), "an inset view keeps the glass inside its bounds")
    }

    static func nullViewHasNoScale() {
        expect(mapping(in: .null).pointsPerMillimeter == 0, "a null view has a scale of 0")
    }

    static func emptyViewHasNoScale() {
        expect(mapping(in: .zero).pointsPerMillimeter == 0, "an empty view has a scale of 0")
    }

    static func emptyAreaHasNoScale() {
        let empty = CanvasMapping(area: ScanArea(widthMillimeters: 0, heightMillimeters: 0), bounds: mapping.glass)
        expect(empty.pointsPerMillimeter == 0, "an empty scan area has a scale of 0, not infinity")
    }

    static func zeroScaleGivesZeroMillimeters() {
        expect(mapping(in: .zero).millimeters(100) == 0, "a scale of 0 turns any distance into 0 mm, not NaN")
    }

    static func glassCornerIsOriginPoint() {
        expect(mapping.point(x: 0, y: 0) == CGPoint(x: 200, y: 0), "0,0 mm is the top left corner of the glass")
    }

    static func pointConvertsToMillimeters() {
        let millimeters = mapping.millimeters(at: CGPoint(x: 300, y: 100))
        expect(millimeters == (x: 50, y: 50), "a point 100 pt into the glass is 50 mm in")
    }

    static func pointAboveLeftClampsToCorner() {
        let millimeters = mapping.millimeters(at: CGPoint(x: 0, y: -50))
        expect(millimeters == (x: 0, y: 0), "a point above and left of the glass clamps to 0,0 mm")
    }

    static func pointBeyondGlassClampsToAreaSize() {
        let millimeters = mapping.millimeters(at: CGPoint(x: 900, y: 700))
        expect(millimeters == (x: 200, y: 300), "a point beyond the glass clamps to the area size")
    }

    static func regionRectRoundTripsToRegionCorner() {
        let rect = mapping.rect(for: region)
        expect(isClose(rect, CGRect(x: 220, y: 40, width: 100, height: 80)), "a region of 10,20 50 x 40 mm draws at 220,40 100 x 80 pt")
        expect(mapping.millimeters(at: rect.origin) == (x: 10, y: 20), "the drawn region corner converts back to 10,20 mm")
    }

    static func handlesSitOnCornersAndEdgeMiddles() {
        let handles = Dictionary(uniqueKeysWithValues: RegionHandle.allCases.map { ($0, mapping.handlePoint($0, of: region)) })
        let expected: [RegionHandle: CGPoint] = [
            .topLeft: CGPoint(x: 220, y: 40), .top: CGPoint(x: 270, y: 40), .topRight: CGPoint(x: 320, y: 40),
            .left: CGPoint(x: 220, y: 80), .right: CGPoint(x: 320, y: 80),
            .bottomLeft: CGPoint(x: 220, y: 120), .bottom: CGPoint(x: 270, y: 120), .bottomRight: CGPoint(x: 320, y: 120),
        ]
        expect(handles == expected, "the eight handles sit on the corners and edge middles of the region")
    }
}
