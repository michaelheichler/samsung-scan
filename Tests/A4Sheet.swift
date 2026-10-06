import AppKit
import Foundation

// So that every drawn page matches an A4 scan at 150 dpi.
enum A4Sheet {
    static let width = 1240
    static let height = 1754
    static let resolution = 150

    // Because an RGB bitmap without alpha gives no graphics context.
    static func jpeg(named name: String, in folder: URL, drawing draw: (CGContext) -> Void) -> URL {
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = NSSize(width: width, height: height)
        let context = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.cgContext.setFillColor(gray: 1, alpha: 1)
        context.cgContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
        draw(context.cgContext)
        NSGraphicsContext.restoreGraphicsState()
        let url = folder.appending(path: "\(name).jpg")
        try! bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])!.write(to: url)
        return url
    }

    // So that a check can name a rect the way CGImage.cropping(to:) counts rows.
    static func fillFromTop(_ rect: CGRect, in context: CGContext) {
        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(x: rect.minX, y: Double(height) - rect.maxY, width: rect.width, height: rect.height))
    }
}
