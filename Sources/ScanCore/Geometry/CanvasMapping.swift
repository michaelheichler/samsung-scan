import Foundation

public struct CanvasMapping: Hashable, Sendable {
    public let area: ScanArea
    public let glass: CGRect
    public let pointsPerMillimeter: Double

    // So that the glass keeps the true aspect ratio of the scan area.
    public init(area: ScanArea, bounds: CGRect) {
        let bounds = bounds.isNull ? CGRect.zero : bounds.standardized
        let fit = min(bounds.width / area.widthMillimeters, bounds.height / area.heightMillimeters)
        let scale = fit.isFinite ? max(fit, 0) : 0
        let width = area.widthMillimeters * scale
        let height = area.heightMillimeters * scale
        self.area = area
        pointsPerMillimeter = scale
        glass = CGRect(x: bounds.midX - width / 2, y: bounds.midY - height / 2, width: width, height: height)
    }

    public func points(_ millimeters: Double) -> Double {
        millimeters * pointsPerMillimeter
    }

    public func millimeters(_ points: Double) -> Double {
        pointsPerMillimeter > 0 ? points / pointsPerMillimeter : 0
    }

    public func point(x: Double, y: Double) -> CGPoint {
        CGPoint(x: glass.minX + points(x), y: glass.minY + points(y))
    }

    public func millimeters(at point: CGPoint) -> (x: Double, y: Double) {
        (
            x: min(max(millimeters(point.x - glass.minX), 0), area.widthMillimeters),
            y: min(max(millimeters(point.y - glass.minY), 0), area.heightMillimeters)
        )
    }

    public func rect(for region: ScanRegion) -> CGRect {
        CGRect(
            origin: point(x: region.leftMillimeters, y: region.topMillimeters),
            size: CGSize(width: points(region.widthMillimeters), height: points(region.heightMillimeters))
        )
    }

    public func handlePoint(_ handle: RegionHandle, of region: ScanRegion) -> CGPoint {
        let frame = rect(for: region)
        return CGPoint(x: frame.minX + frame.width * handle.unitX, y: frame.minY + frame.height * handle.unitY)
    }

    // Because corners come first in allCases, a corner wins a tie with an edge.
    public func hit(_ point: CGPoint, on region: ScanRegion?, radius: Double) -> RegionHit {
        guard let region else { return .draw }
        let nearest = RegionHandle.allCases
            .map { (handle: $0, distance: Self.distance(point, handlePoint($0, of: region))) }
            .filter { $0.distance <= radius }
            .min { $0.distance < $1.distance }
        if let nearest { return .resize(nearest.handle) }
        return rect(for: region).contains(point) ? .move : .draw
    }

    public func region(
        dragging hit: RegionHit,
        of region: ScanRegion,
        from start: CGPoint,
        to end: CGPoint,
        minimumSide: Double
    ) -> ScanRegion {
        let dx = millimeters(end.x - start.x)
        let dy = millimeters(end.y - start.y)
        switch hit {
        case .draw:
            return spanning(start, end)
        case .move:
            return region.moved(dx: dx, dy: dy, within: area)
        case .resize(let handle):
            return region.resized(handle, dx: dx, dy: dy, within: area, minimumSide: minimumSide)
        }
    }

    private func spanning(_ start: CGPoint, _ end: CGPoint) -> ScanRegion {
        let first = millimeters(at: start)
        let second = millimeters(at: end)
        return ScanRegion(
            leftMillimeters: min(first.x, second.x),
            topMillimeters: min(first.y, second.y),
            widthMillimeters: abs(first.x - second.x),
            heightMillimeters: abs(first.y - second.y)
        )
    }

    private static func distance(_ first: CGPoint, _ second: CGPoint) -> Double {
        hypot(first.x - second.x, first.y - second.y)
    }
}
