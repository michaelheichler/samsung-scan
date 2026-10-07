import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PageStraightenerChecks {
    static func run() async {
        let letter = LetterPage.jpeg(in: TemporaryFolder.make())
        await straightenedPageIsSameSizeJpeg(letter)
        await straighteningLeavesTheScanAsItWas(letter)
        guard await VisionProbe.canReadText(for: "page straightener on recognized letters") else { return }
        await turnedLetterMeasuresItsAngle(letter, turnedBy: 1.5)
        await turnedLetterMeasuresItsAngle(letter, turnedBy: 3.0)
        await turnedLetterMeasuresItsAngle(letter, turnedBy: -3.0)
        await turnedLetterMeasuresItsAngle(letter, turnedBy: -4.0)
        await straightenedLetterReadsStraight(letter)
        await nearlyStraightLetterGetsNoNewFile(letter)
    }

    static func turnedLetterMeasuresItsAngle(_ letter: URL, turnedBy degrees: Double) async {
        let page = turned(letter, by: degrees)
        let text = try? await TextRecognizer.recognize(fileAt: page.file)
        let skew = text.flatMap { PageSkew.degrees(of: $0, pixelWidth: A4Sheet.width, pixelHeight: A4Sheet.height) }
        expect(
            skew.map { abs($0 - degrees) <= 0.5 } == true,
            "a letter turned \(degrees) deg counterclockwise measures within 0.5 deg of \(degrees)")
    }

    static func straightenedLetterReadsStraight(_ letter: URL) async {
        let reread = try? await rereadAfterStraightening(turned(letter, by: 3))
        let residual = reread.flatMap { PageSkew.degrees(of: $0, pixelWidth: A4Sheet.width, pixelHeight: A4Sheet.height) } ?? 0
        expect(
            longLineCount(reread) >= 5 && abs(residual) <= 0.5,
            "a letter turned 3 deg reads within 0.5 deg of straight after straightening")
    }

    static func nearlyStraightLetterGetsNoNewFile(_ letter: URL) async {
        let page = turned(letter, by: 0.1)
        let output = TemporaryFolder.make()
        let text = try? await TextRecognizer.recognize(fileAt: page.file)
        let straight = try? await PageStraightener.straighten(
            page, text: text ?? PageText(transcript: "", lines: []), into: output)
        let written = (try? FileManager.default.contentsOfDirectory(atPath: output.path())) ?? []
        expect(
            longLineCount(text) >= 5 && straight == .some(nil) && written.isEmpty,
            "a letter turned 0.1 deg is left as it is and no new file is written")
    }

    static func straightenedPageIsSameSizeJpeg(_ letter: URL) async {
        let page = ScannedPage(file: letter, resolution: A4Sheet.resolution)
        let straight = try? await PageStraightener.straighten(
            page, text: SkewedLines.text(6, atDegrees: 3), into: TemporaryFolder.make())
        let file = straight.flatMap { $0 }
        let type = file.flatMap { CGImageSourceCreateWithURL($0 as CFURL, nil) }.flatMap { CGImageSourceGetType($0) }
        let size = file.flatMap { TestImage.pixelSize(of: $0) }
        expect(
            type as String? == UTType.jpeg.identifier && size?.width == A4Sheet.width && size?.height == A4Sheet.height,
            "a straightened page is a new JPEG with the pixel size of the scan")
    }

    static func straighteningLeavesTheScanAsItWas(_ letter: URL) async {
        let page = ScannedPage(file: letter, resolution: A4Sheet.resolution)
        let before = try? Data(contentsOf: letter)
        let straight = try? await PageStraightener.straighten(
            page, text: SkewedLines.text(6, atDegrees: 3), into: TemporaryFolder.make())
        let after = try? Data(contentsOf: letter)
        expect(
            straight.flatMap { $0 } != nil && before != nil && before == after,
            "straightening a page leaves the scanned file as it was")
    }

    private static func turned(_ letter: URL, by degrees: Double) -> ScannedPage {
        let image = try! CorrectedPageFile.image(at: letter)
        let turned = try! PageStraightener.rotated(image, byDegrees: degrees)
        let file = try! CorrectedPageFile.write(turned, resolution: A4Sheet.resolution, into: TemporaryFolder.make())
        return ScannedPage(file: file, resolution: A4Sheet.resolution)
    }

    private static func rereadAfterStraightening(_ page: ScannedPage) async throws -> PageText? {
        let text = try await TextRecognizer.recognize(fileAt: page.file)
        guard let straight = try await PageStraightener.straighten(page, text: text, into: TemporaryFolder.make()) else {
            return nil
        }
        return try await TextRecognizer.recognize(fileAt: straight)
    }

    // So that a nil skew cannot pass on a page where Vision found too little text.
    private static func longLineCount(_ text: PageText?) -> Int {
        text?.lines.count { $0.bottomRight.x - $0.bottomLeft.x > 0.2 } ?? 0
    }
}
