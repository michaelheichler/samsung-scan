import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// So that Undo can return to the scan, a correction always writes a new file.
enum CorrectedPageFile {
    // So that PDFWriter can pass the JPEG through without a visible loss.
    static let jpegQuality = 0.92

    static func image(at file: URL) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(file as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return image
    }

    static func write(_ image: CGImage, resolution: Int, into folder: URL) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "\(UUID().uuidString).jpg")
        guard let target = CGImageDestinationCreateWithURL(file as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw CocoaError(.fileWriteUnknown) }
        let properties: [CFString: Any] = [
            kCGImagePropertyDPIWidth: resolution,
            kCGImagePropertyDPIHeight: resolution,
            kCGImageDestinationLossyCompressionQuality: jpegQuality,
        ]
        CGImageDestinationAddImage(target, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(target) else { throw CocoaError(.fileWriteUnknown) }
        return file
    }
}
