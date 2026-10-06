import Foundation

@MainActor
enum PageCorrectionsChecks {
    nonisolated static let scan = URL(filePath: "/samsungscan-checks/scan.jpg")
    nonisolated static let straightFile = URL(filePath: "/samsungscan-checks/straight.jpg")
    nonisolated static let trimmedFile = URL(filePath: "/samsungscan-checks/trimmed.jpg")
    nonisolated static let noText = PageText(transcript: "", lines: [])

    static func run() async {
        await straightenedPageKeepsIDAndRegion()
        await trimmedPageKeepsIDAndDropsRegion()
        await trimWithoutChangeRecordsNothing()
        await failedStraighteningThrowsAndRecordsNothing()
        await restoreReturnsTheScanAfterTwoCorrections()
        await forgottenPageHasNoOriginal()
    }

    static func straightenedPageKeepsIDAndRegion() async {
        let page = a4Page()
        let corrections = PageCorrections(folder: TemporaryFolder.make(), straighten: { _, _, _ in straightFile })
        let straight = try? await corrections.straightened(page, text: noText)
        expect(
            straight?.id == page.id && straight?.region == page.region && straight?.file == straightFile,
            "a straightened page keeps its ID and paper region and shows the new file")
    }

    static func trimmedPageKeepsIDAndDropsRegion() async {
        let page = a4Page()
        let corrections = PageCorrections(folder: TemporaryFolder.make(), trim: { _, _ in trimmedFile })
        let trimmed = try? await corrections.trimmed(page)
        expect(
            trimmed?.id == page.id && trimmed?.file == trimmedFile && trimmed?.region == nil
                && corrections.trimmedIDs == [page.id],
            "a trimmed page keeps its ID, drops its paper region, and counts as trimmed")
    }

    static func trimWithoutChangeRecordsNothing() async {
        let page = a4Page()
        let corrections = PageCorrections(folder: TemporaryFolder.make(), trim: { _, _ in nil })
        let trimmed = try? await corrections.trimmed(page)
        expect(
            trimmed == .some(nil) && corrections.originals.isEmpty && corrections.trimmedIDs.isEmpty,
            "a trim that finds nothing to cut keeps no original and marks nothing as trimmed")
    }

    static func failedStraighteningThrowsAndRecordsNothing() async {
        let page = a4Page()
        let corrections = PageCorrections(
            folder: TemporaryFolder.make(), straighten: { _, _, _ in throw CocoaError(.fileWriteUnknown) })
        let error = await caughtError { _ = try await corrections.straightened(page, text: noText) }
        expect(
            error != nil && corrections.originals.isEmpty && corrections.runningIDs.isEmpty,
            "a straightening that fails throws, keeps no original, and stops running")
    }

    static func restoreReturnsTheScanAfterTwoCorrections() async {
        let page = a4Page()
        let corrections = PageCorrections(
            folder: TemporaryFolder.make(), straighten: { _, _, _ in straightFile }, trim: { _, _ in trimmedFile })
        let straight = try? await corrections.straightened(page, text: noText)
        _ = try? await corrections.trimmed(straight ?? page)
        let restored = corrections.restoreOriginal(of: page.id)
        expect(
            restored == page && corrections.trimmedIDs.isEmpty,
            "restoring a page straightened and then trimmed gives back the scan with its region")
    }

    static func forgottenPageHasNoOriginal() async {
        let page = a4Page()
        let corrections = PageCorrections(folder: TemporaryFolder.make(), straighten: { _, _, _ in straightFile })
        _ = try? await corrections.straightened(page, text: noText)
        corrections.forget(page.id)
        expect(corrections.restoreOriginal(of: page.id) == nil, "a forgotten page has no original to restore")
    }

    private static func a4Page() -> ScannedPage {
        ScannedPage(file: scan, resolution: A4Sheet.resolution, region: TestImage.a4Region)
    }
}
