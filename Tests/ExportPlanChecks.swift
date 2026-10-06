import Foundation

enum ExportPlanChecks {
    static func run() {
        rangesGiveOneNamedDocumentEach()
        documentsWithoutPagesAreDropped()
        keepingLeavesPickedPagesInTheirDocuments()
        keepingDropsADocumentWithNoPickedPage()
        joinedGivesOneDocumentNamedAfterTheFirst()
        joiningAnEmptyPlanGivesAnEmptyPlan()
        planFromSplitsDividesOnlyAtConfirmedSplits()
        currentPlanTakesCorrectedPagesAndDropsDeletedOnes()
        checkSeveralFiles(.pdf, documents: [[0], [1]], expected: true, "a PDF export of two documents writes several files")
        checkSeveralFiles(.pdf, documents: [[0, 1, 2]], expected: false, "a PDF export of one document writes one file")
        checkSeveralFiles(.png, documents: [[0, 1]], expected: true, "a PNG export of two pages writes several files")
        checkSeveralFiles(.jpeg, documents: [[0]], expected: false, "a JPEG export of one page writes one file")
    }

    private static let pages = (0..<5).map { ScannedPage(file: URL(filePath: "/scan/page\($0).jpg"), resolution: 75) }

    private static func name(_ hour: Int) -> ExportFileName {
        ExportFileName(date: Date(timeIntervalSince1970: Double(hour) * 3600), timeZone: .gmt)
    }

    private static func document(_ indices: [Int], named hour: Int) -> ExportDocument {
        ExportDocument(pages: indices.map { pages[$0] }, name: name(hour))
    }

    private static func twoDocuments() -> ExportPlan {
        ExportPlan(documents: [document([0, 1], named: 1), document([2, 3, 4], named: 2)])
    }

    private static func ids(_ indices: [Int]) -> Set<ScannedPage.ID> {
        Set(indices.map { pages[$0].id })
    }

    static func rangesGiveOneNamedDocumentEach() {
        let plan = ExportPlan(pages: pages, ranges: [0..<2, 2..<5]) { name($0.lowerBound) }
        expect(
            plan.documents == [document([0, 1], named: 0), document([2, 3, 4], named: 2)],
            "a plan built from two ranges holds two documents, each named for its range")
    }

    static func documentsWithoutPagesAreDropped() {
        let plan = ExportPlan(documents: [document([], named: 1), document([0], named: 2), document([], named: 3)])
        expect(plan.documents == [document([0], named: 2)], "a plan leaves out documents that have no pages")
    }

    static func keepingLeavesPickedPagesInTheirDocuments() {
        let kept = twoDocuments().keeping(ids([1, 3]))
        expect(
            kept.documents == [document([1], named: 1), document([3], named: 2)],
            "picked pages from two documents stay in the document they came from")
    }

    static func keepingDropsADocumentWithNoPickedPage() {
        let kept = twoDocuments().keeping(ids([2, 4]))
        expect(kept.documents == [document([2, 4], named: 2)], "a document with no picked page leaves the plan")
    }

    static func joinedGivesOneDocumentNamedAfterTheFirst() {
        let joined = twoDocuments().joined()
        expect(
            joined.documents == [document([0, 1, 2, 3, 4], named: 1)],
            "joining two documents gives one document with every page under the first name")
    }

    static func joiningAnEmptyPlanGivesAnEmptyPlan() {
        expect(ExportPlan(documents: []).joined().documents.isEmpty, "joining a plan without documents gives no document")
    }

    static func planFromSplitsDividesOnlyAtConfirmedSplits() {
        var splits = DocumentSplits()
        splits.suggest([pages[2].id: .newLetterhead])
        splits.confirm(at: pages[4].id)
        let plan = ExportPlan(pages: pages, splits: splits) { name($0.lowerBound) }
        expect(
            plan.documents == [document([0, 1, 2, 3], named: 0), document([4], named: 4)],
            "an export plan splits the stack only at the confirmed split, not at an open suggestion")
    }

    static func currentPlanTakesCorrectedPagesAndDropsDeletedOnes() {
        let corrected = pages[1].replacingFile(with: URL(filePath: "/scan/page1-corrected.jpg"), region: nil)
        let stack = [pages[0], corrected, pages[2], pages[4]]
        let expected = [
            ExportDocument(pages: [pages[0], corrected], name: name(1)),
            ExportDocument(pages: [pages[2], pages[4]], name: name(2)),
        ]
        expect(
            twoDocuments().current(in: stack).documents == expected,
            "a plan brought up to date exports the corrected page and leaves out the deleted one")
    }

    private static func checkSeveralFiles(_ format: ExportFormat, documents: [[Int]], expected: Bool, _ name: String) {
        let plan = ExportPlan(documents: documents.enumerated().map { document($0.element, named: $0.offset) })
        expect(plan.writesSeveralFiles(as: format) == expected, name)
    }
}
