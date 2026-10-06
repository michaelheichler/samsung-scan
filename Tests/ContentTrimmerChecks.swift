import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ContentTrimmerChecks {
    // Because a block above the middle shows a flipped y axis.
    static let block = CGRect(x: 300, y: 200, width: 500, height: 600)
    static let fiveMillimetersAt150Dpi = 5 / 25.4 * 150

    static func run() async {
        let folder = TemporaryFolder.make()
        boundsHoldTheBlockAndFiveMillimeters(in: folder)
        await trimmedPageIsBlockPlusMarginJpeg(in: folder)
        await nearlyFullPageIsNotTrimmed(in: folder)
        await whitePageIsNotTrimmed(in: folder)
        await overscanRowsBelowTheRegionAreNotKept(in: folder)
    }

    static func overscanRowsBelowTheRegionAreNotKept(in folder: URL) async {
        let shortRegion = ScanRegion(widthMillimeters: 210, heightMillimeters: 288)
        let regionRows = shortRegion.pixelSize(resolution: A4Sheet.resolution).height
        let file = A4Sheet.jpeg(named: "overscan", in: folder) { context in
            A4Sheet.fillFromTop(block, in: context)
            A4Sheet.fillFromTop(CGRect(x: 100, y: regionRows + 20, width: 1040, height: 20), in: context)
        }
        let page = ScannedPage(file: file, resolution: A4Sheet.resolution, region: shortRegion)
        let trimmed = try? await ContentTrimmer.trim(page, into: TemporaryFolder.make())
        let size = trimmed.flatMap { $0 }.flatMap { TestImage.pixelSize(of: $0) }
        let width = block.width + 2 * fiveMillimetersAt150Dpi
        let height = block.height + 2 * fiveMillimetersAt150Dpi
        expect(
            size.map { abs(Double($0.width) - width) <= 6 && abs(Double($0.height) - height) <= 6 } == true,
            "a dark bar in the overscan rows below the region stays out of the trimmed page")
    }

    static func boundsHoldTheBlockAndFiveMillimeters(in folder: URL) {
        let image = try! CorrectedPageFile.image(at: blockPage(in: folder))
        let bounds = ContentTrimmer.contentBounds(of: image, marginPixels: Int(fiveMillimetersAt150Dpi.rounded()))
        let inner = block.insetBy(dx: 3 - fiveMillimetersAt150Dpi, dy: 3 - fiveMillimetersAt150Dpi)
        let outer = block.insetBy(dx: -3 - fiveMillimetersAt150Dpi, dy: -3 - fiveMillimetersAt150Dpi)
        expect(
            bounds.map { $0.contains(inner) && outer.contains($0) } == true,
            "the bounds of a block on white paper hold the block and 5 mm around it, rows counted from the top")
    }

    static func trimmedPageIsBlockPlusMarginJpeg(in folder: URL) async {
        let page = ScannedPage(file: blockPage(in: folder), resolution: A4Sheet.resolution, region: TestImage.a4Region)
        let trimmed = try? await ContentTrimmer.trim(page, into: TemporaryFolder.make())
        let file = trimmed.flatMap { $0 }
        let type = file.flatMap { CGImageSourceCreateWithURL($0 as CFURL, nil) }.flatMap { CGImageSourceGetType($0) }
        let size = file.flatMap { TestImage.pixelSize(of: $0) }
        let width = block.width + 2 * fiveMillimetersAt150Dpi
        let height = block.height + 2 * fiveMillimetersAt150Dpi
        expect(
            type as String? == UTType.jpeg.identifier
                && size.map { abs(Double($0.width) - width) <= 6 && abs(Double($0.height) - height) <= 6 } == true
                && file.flatMap { TestImage.resolution(of: $0) } == A4Sheet.resolution,
            "trimming a block on white paper writes a 150 dpi JPEG the size of the block plus 5 mm per side")
    }

    static func nearlyFullPageIsNotTrimmed(in folder: URL) async {
        let file = A4Sheet.jpeg(named: "full", in: folder) { context in
            for top in stride(from: 20, to: A4Sheet.height - 30, by: 24) {
                A4Sheet.fillFromTop(CGRect(x: 20, y: top, width: A4Sheet.width - 40, height: 8), in: context)
            }
        }
        let page = ScannedPage(file: file, resolution: A4Sheet.resolution)
        let trimmed = try? await ContentTrimmer.trim(page, into: TemporaryFolder.make())
        expect(trimmed == .some(nil), "a page with text lines up to 20 px from every edge is not trimmed")
    }

    static func whitePageIsNotTrimmed(in folder: URL) async {
        let page = ScannedPage(file: A4Sheet.jpeg(named: "white", in: folder) { _ in }, resolution: A4Sheet.resolution)
        let trimmed = try? await ContentTrimmer.trim(page, into: TemporaryFolder.make())
        expect(trimmed == .some(nil), "a white page is not trimmed")
    }

    private static func blockPage(in folder: URL) -> URL {
        A4Sheet.jpeg(named: "block", in: folder) { A4Sheet.fillFromTop(block, in: $0) }
    }
}
