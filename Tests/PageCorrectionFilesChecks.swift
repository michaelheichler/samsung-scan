import Foundation

@MainActor
enum PageCorrectionFilesChecks {
    nonisolated static let noText = PageText(transcript: "", lines: [])

    static func run() async {
        await trimAfterStraighteningDeletesTheStraightenedFile()
        await restoringDeletesTheCorrectedFileAndKeepsTheScan()
        await forgettingAPageDeletesItsCorrectedFile()
        await forgettingAllPagesDeletesEveryCorrectedFile()
    }

    static func trimAfterStraighteningDeletesTheStraightenedFile() async {
        let page = scannedPage()
        let corrections = writingCorrections()
        let straight = try? await corrections.straightened(page, text: noText)
        let trimmed = try? await corrections.trimmed(straight ?? page)
        expect(
            straight.map { !exists($0.file) } == true && trimmed.map { exists($0.file) } == true && exists(page.file),
            "trimming a straightened page deletes the straightened file and keeps the trimmed file and the scan")
    }

    static func restoringDeletesTheCorrectedFileAndKeepsTheScan() async {
        let page = scannedPage()
        let corrections = writingCorrections()
        let straight = try? await corrections.straightened(page, text: noText)
        let restored = corrections.restoreOriginal(of: page.id)
        expect(
            straight.map { !exists($0.file) } == true && restored.map { exists($0.file) } == true,
            "restoring the original deletes the corrected file and keeps the scan it gives back")
    }

    static func forgettingAPageDeletesItsCorrectedFile() async {
        let page = scannedPage()
        let corrections = writingCorrections()
        let trimmed = try? await corrections.trimmed(page)
        corrections.forget(page.id)
        expect(
            trimmed.map { !exists($0.file) } == true && exists(page.file),
            "forgetting a corrected page deletes its corrected file and keeps the scan")
    }

    static func forgettingAllPagesDeletesEveryCorrectedFile() async {
        let first = scannedPage()
        let second = scannedPage()
        let corrections = writingCorrections()
        let straight = try? await corrections.straightened(first, text: noText)
        let trimmed = try? await corrections.trimmed(second)
        corrections.forgetAll()
        let correctedFiles = [straight, trimmed].compactMap { $0?.file }
        expect(
            correctedFiles.count == 2 && !correctedFiles.contains(where: exists),
            "forgetting all pages deletes the corrected file of every page")
    }

    private static func writingCorrections() -> PageCorrections {
        PageCorrections(
            folder: TemporaryFolder.make(),
            straighten: { _, _, folder in try writtenFile(named: "straight", in: folder) },
            trim: { _, folder in try writtenFile(named: "trimmed", in: folder) })
    }

    private static func scannedPage() -> ScannedPage {
        let scan = try! writtenFile(named: "scan", in: TemporaryFolder.make())
        return ScannedPage(file: scan, resolution: A4Sheet.resolution, region: TestImage.a4Region)
    }

    nonisolated private static func writtenFile(named name: String, in folder: URL) throws -> URL {
        let file = folder.appending(path: "\(name)-\(UUID().uuidString).jpg")
        try Data([0xFF, 0xD8]).write(to: file)
        return file
    }

    nonisolated private static func exists(_ file: URL) -> Bool {
        FileManager.default.fileExists(atPath: file.path(percentEncoded: false))
    }
}
