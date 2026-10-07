import Foundation

enum PagePairSampleChecks {
    static func run() async {
        guard LanguageModelAvailability.current.isAvailable else {
            print("skip  page pair samples: Apple Intelligence is not available")
            return
        }
        guard await VisionProbe.canReadText(for: "page pair samples") else { return }
        await modelJoinsEveryContinuationAndFindsMostNewDocuments()
    }

    static func modelJoinsEveryContinuationAndFindsMostNewDocuments() async {
        let pairs = PagePairSamples.pairs
        let answers = await modelAnswers(for: pairs)
        let labeled = zip(pairs, answers)
        let splitContinuations = labeled.filter { !$0.0.startsNewDocument && $0.1 != false }.map(\.0.name)
        let wrong = labeled.filter { $0.1 != $0.0.startsNewDocument }.map(\.0.name)
        let right = pairs.count - wrong.count
        expect(
            splitContinuations.isEmpty && right >= 6,
            "the on-device model joins every continuation and gets \(right) of \(pairs.count) sample pairs right "
                + "(at least 6 needed), wrong: \(wrong)")
    }

    private static func modelAnswers(for pairs: [LabeledPagePair]) async -> [Bool?] {
        let folder = TemporaryFolder.make()
        let model = FoundationModelsClient()
        var answers: [Bool?] = []
        for (index, pair) in pairs.enumerated() {
            let pageA = PagePairSamples.render(pair.endOfA, atBottom: true, named: "\(index)a", in: folder)
            let pageB = PagePairSamples.render(pair.startOfB, atBottom: false, named: "\(index)b", in: folder)
            let textA = (try? await TextRecognizer.recognize(fileAt: pageA)) ?? PageText(transcript: "", lines: [])
            let textB = (try? await TextRecognizer.recognize(fileAt: pageB)) ?? PageText(transcript: "", lines: [])
            let question = await PagePairQuestion(between: textA, and: textB)
            answers.append(await question.startsNewDocument(using: model))
        }
        return answers
    }
}
