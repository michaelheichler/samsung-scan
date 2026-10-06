import Foundation
import Observation

@MainActor
@Observable
public final class PageCorrections {
    public typealias Straighten = @concurrent @Sendable (ScannedPage, PageText, URL) async throws -> URL?
    public typealias Trim = @concurrent @Sendable (ScannedPage, URL) async throws -> URL?

    public private(set) var originals: [ScannedPage.ID: ScannedPage] = [:]
    public private(set) var trimmedIDs: Set<ScannedPage.ID> = []
    public private(set) var runningIDs: Set<ScannedPage.ID> = []
    @ObservationIgnored private let folder: URL
    @ObservationIgnored private let straighten: Straighten
    @ObservationIgnored private let trim: Trim

    public init(
        folder: URL,
        straighten: @escaping Straighten = PageStraightener.straighten(_:text:into:),
        trim: @escaping Trim = ContentTrimmer.trim(_:into:)
    ) {
        self.folder = folder
        self.straighten = straighten
        self.trim = trim
    }

    // Because nil means the page needs no change, a failure throws instead.
    public func straightened(_ page: ScannedPage, text: PageText) async throws -> ScannedPage? {
        let file = try await run(page) { [straighten, folder] in try await straighten(page, text, folder) }
        return file.map { page.replacingFile(with: $0, region: page.region) }
    }

    // So that the PDF page follows the cropped image, the region goes.
    public func trimmed(_ page: ScannedPage) async throws -> ScannedPage? {
        guard let file = try await run(page, work: { [trim, folder] in try await trim(page, folder) }) else {
            return nil
        }
        trimmedIDs.insert(page.id)
        return page.replacingFile(with: file, region: nil)
    }

    public func restoreOriginal(of id: ScannedPage.ID) -> ScannedPage? {
        trimmedIDs.remove(id)
        return originals.removeValue(forKey: id)
    }

    public func forget(_ id: ScannedPage.ID) {
        trimmedIDs.remove(id)
        originals[id] = nil
    }

    public func forgetAll() {
        trimmedIDs = []
        originals = [:]
    }

    private func run(_ page: ScannedPage, work: @Sendable () async throws -> URL?) async throws -> URL? {
        runningIDs.insert(page.id)
        defer { runningIDs.remove(page.id) }
        guard let file = try await work() else { return nil }
        if originals[page.id] == nil {
            originals[page.id] = page
        }
        return file
    }
}
