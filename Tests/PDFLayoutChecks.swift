import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PDFLayoutChecks {
    static func run() {
        extraLinesFallOffBottomOfPage()
    }

    private struct Pixels {
        let bytes: [UInt8]
        let width: Int
        let height: Int

        func color(row: Int, column: Int) -> (red: Int, green: Int, blue: Int) {
            let offset = (row * width + column) * 4
            return (Int(bytes[offset]), Int(bytes[offset + 1]), Int(bytes[offset + 2]))
        }

        func rows(_ range: Range<Int>) -> [(red: Int, green: Int, blue: Int)] {
            range.flatMap { row in (0..<width).map { color(row: row, column: $0) } }
        }
    }

    private static func bandedA4Scan(in folder: URL) -> URL {
        let context = CGContext(
            data: nil, width: 620, height: 891, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 620, height: 891))
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 881, width: 620, height: 10))
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 620, height: 14))
        let url = folder.appending(path: "page001.jpg")
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
        let properties = [kCGImagePropertyDPIWidth: 75, kCGImagePropertyDPIHeight: 75, kCGImageDestinationLossyCompressionQuality: 1.0]
        CGImageDestinationAddImage(destination, context.makeImage()!, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return url
    }

    private static func rendered(_ pdf: URL?) -> Pixels? {
        guard let pdf, let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return nil }
        let box = page.getBoxRect(.mediaBox)
        let width = Int(box.width.rounded(.down))
        let height = Int(box.height.rounded(.down))
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.drawPDFPage(page)
        }
        return Pixels(bytes: bytes, width: width, height: height)
    }

    static func extraLinesFallOffBottomOfPage() {
        let folder = TemporaryFolder.make()
        let page = ScannedPage(file: bandedA4Scan(in: folder), resolution: 75, region: TestImage.a4Region)
        let pdf = folder.appending(path: "scan.pdf")
        try? PDFWriter.write([page], to: pdf)
        let pixels = rendered(pdf)
        let topRows = pixels?.rows(2..<7) ?? []
        let allRows = pixels.map { $0.rows(0..<$0.height) } ?? []
        expect(!topRows.isEmpty && topRows.allSatisfy { $0.red + $0.green + $0.blue < 180 }, "the top of the scan stays at the top of the PDF page")
        expect(!allRows.isEmpty && !allRows.contains { $0.red > 200 && $0.green < 80 && $0.blue < 80 }, "the extra scanned lines fall off the bottom of the PDF page")
    }
}
