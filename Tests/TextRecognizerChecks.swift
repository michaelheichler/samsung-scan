import Foundation

enum TextRecognizerChecks {
    static func run() async {
        let folder = TemporaryFolder.make()
        let page = SamplePage.render(in: folder)
        await recognizedPageHoldsEveryDrawnLine(page)
        await recognizedLinesSitWhereTheyWereDrawn(page)
        await cancelledRecognitionThrowsCancellationError(page)
    }

    static func recognizedPageHoldsEveryDrawnLine(_ page: URL) async {
        let text = try? await TextRecognizer.recognize(fileAt: page)
        let transcript = text?.transcript ?? ""
        let recognized = text?.lines.map(\.text).sorted() ?? []
        expect(
            SamplePage.lines.allSatisfy { transcript.contains($0.text) },
            "the transcript of a German and English page holds every drawn line")
        expect(
            recognized == SamplePage.lines.map(\.text).sorted(),
            "every drawn line comes back as one recognized line with the same text")
    }

    static func recognizedLinesSitWhereTheyWereDrawn(_ page: URL) async {
        let recognized = (try? await TextRecognizer.recognize(fileAt: page))?.lines ?? []
        let placed = SamplePage.lines.allSatisfy { drawn in
            recognized.contains { $0.text == drawn.text && sits($0, at: drawn) }
        }
        expect(placed, "each recognized line starts at the drawn x and baseline, origin bottom left")
        expect(
            !recognized.isEmpty && recognized.allSatisfy(isUpright),
            "each recognized line has its top corners above and its right corners right of the others")
    }

    static func cancelledRecognitionThrowsCancellationError(_ page: URL) async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await TextRecognizer.recognize(fileAt: page)
        }
        let error = await caughtError { _ = try await task.value }
        expect(error is CancellationError, "recognition inside a cancelled task throws CancellationError")
    }

    // So that descenders and box padding pass, a corner may miss by one font size.
    private static func sits(_ line: RecognizedLine, at drawn: SamplePage.Line) -> Bool {
        func near(_ corner: Double, _ drawn: Double, on side: Double) -> Bool {
            abs(corner * side - drawn) < SamplePage.fontSize
        }
        return near(line.bottomLeft.x, drawn.x, on: SamplePage.width) && near(line.topLeft.x, drawn.x, on: SamplePage.width)
            && near(line.bottomLeft.y, drawn.baseline, on: SamplePage.height)
            && near(line.bottomRight.y, drawn.baseline, on: SamplePage.height)
    }

    private static func isUpright(_ line: RecognizedLine) -> Bool {
        line.topLeft.y > line.bottomLeft.y && line.topRight.y > line.bottomRight.y
            && line.topRight.x > line.topLeft.x && line.bottomRight.x > line.bottomLeft.x
    }
}
