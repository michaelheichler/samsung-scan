import CoreGraphics
import CoreText
import Foundation
import Vision

public enum TextRecognizer {
    @concurrent
    public static func recognize(fileAt file: URL) async throws -> PageText {
        try Task.checkCancellation()
        let observations = try await request.perform(on: file)
        try Task.checkCancellation()
        let texts = observations.map(\.document.text)
        return PageText(
            transcript: texts.map(\.transcript).joined(separator: "\n"),
            lines: texts.flatMap(\.lines).map(line(from:)))
    }

    // Because Vision loads its model on the first call, which takes about 25 s.
    @concurrent
    public static func warmUp() async {
        guard let image = warmUpImage() else { return }
        _ = try? await request.perform(on: image)
    }

    private static var request: RecognizeDocumentsRequest {
        var request = RecognizeDocumentsRequest()
        request.textRecognitionOptions.automaticallyDetectLanguage = true
        return request
    }

    private static func line(from observation: RecognizedTextObservation) -> RecognizedLine {
        RecognizedLine(
            text: observation.transcript,
            topLeft: observation.topLeft.cgPoint,
            topRight: observation.topRight.cgPoint,
            bottomRight: observation.bottomRight.cgPoint,
            bottomLeft: observation.bottomLeft.cgPoint)
    }

    // So that the warm-up reaches the text model, the image holds a word.
    private static func warmUpImage() -> CGImage? {
        guard let context = CGContext(
            data: nil, width: 320, height: 80, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 320, height: 80))
        let font = CTFontCreateWithName("Helvetica" as CFString, 36, nil)
        let word = NSAttributedString(string: "Scan", attributes: [.init(kCTFontAttributeName as String): font])
        context.textPosition = CGPoint(x: 20, y: 25)
        CTLineDraw(CTLineCreateWithAttributedString(word), context)
        return context.makeImage()
    }
}
