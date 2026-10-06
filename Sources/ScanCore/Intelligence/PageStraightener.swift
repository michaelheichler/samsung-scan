import CoreGraphics
import CoreImage
import Foundation

public enum PageStraightener {
    @concurrent
    public static func straighten(_ page: ScannedPage, text: PageText, into folder: URL) async throws -> URL? {
        try Task.checkCancellation()
        let image = try CorrectedPageFile.image(at: page.file)
        guard let skew = PageSkew.degrees(of: text, pixelWidth: image.width, pixelHeight: image.height) else {
            return nil
        }
        let straight = try rotated(image, byDegrees: -skew)
        try Task.checkCancellation()
        return try CorrectedPageFile.write(straight, resolution: page.resolution, into: folder)
    }

    // So that a letter keeps its A4 size, the turned page keeps the scan size.
    static func rotated(_ image: CGImage, byDegrees degrees: Double) throws -> CGImage {
        let input = CIImage(cgImage: image)
        let extent = input.extent
        let turn = CGAffineTransform(translationX: extent.midX, y: extent.midY)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -extent.midX, y: -extent.midY)
        let paper = CIImage(color: .white).cropped(to: extent)
        let composed = input.transformed(by: turn, highQualityDownsample: true).composited(over: paper)
        guard let output = CIContext().createCGImage(composed, from: extent) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return output
    }
}
