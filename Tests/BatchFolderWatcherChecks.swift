import Foundation

enum BatchFolderWatcherChecks {
    static func run() {
        lonePartialPageIsNotFinished()
        partialPageAfterFinishedPageIsSkipped()
        pageIsFinishedOnceStableWithLaterFile()
        allPagesAtExitArriveInOrder()
        deliveredPageIsNotDeliveredAgain()
        emptyFirstPageHoldsBackLaterPages()
    }

    private static func watcher(over files: [String: Int]) -> BatchFolderWatcher {
        let folder = TemporaryFolder.make()
        for (name, size) in files {
            try! Data(count: size).write(to: folder.appending(path: name))
        }
        return BatchFolderWatcher(folder: folder)
    }

    private static func names(_ pages: [URL]) -> [String] {
        pages.map(\.lastPathComponent)
    }

    static func lonePartialPageIsNotFinished() {
        var watcher = watcher(over: ["page001.jpg.part": 4000])
        expect(watcher.finishedPages(processEnded: true).isEmpty, "a lone .part page is not finished when scanimage ends")
    }

    static func partialPageAfterFinishedPageIsSkipped() {
        var watcher = watcher(over: ["page001.jpg": 4000, "page002.jpg.part": 4000])
        let finished = names(watcher.finishedPages(processEnded: true))
        expect(finished == ["page001.jpg"], "a .part page left at exit is skipped and the finished page is kept")
    }

    static func pageIsFinishedOnceStableWithLaterFile() {
        var watcher = watcher(over: ["page001.jpg": 4000, "page002.jpg.part": 4000])
        let firstLook = names(watcher.finishedPages(processEnded: false))
        let secondLook = names(watcher.finishedPages(processEnded: false))
        expect(firstLook.isEmpty, "a page seen once while scanning is not finished yet")
        expect(secondLook == ["page001.jpg"], "a page with unchanged size and a later file is finished")
    }

    static func allPagesAtExitArriveInOrder() {
        var watcher = watcher(over: ["page002.jpg": 4000, "page001.jpg": 4000])
        let finished = names(watcher.finishedPages(processEnded: true))
        expect(finished == ["page001.jpg", "page002.jpg"], "all pages left at exit arrive in page order")
    }

    static func deliveredPageIsNotDeliveredAgain() {
        var watcher = watcher(over: ["page001.jpg": 4000])
        _ = watcher.finishedPages(processEnded: true)
        expect(watcher.finishedPages(processEnded: true).isEmpty, "a delivered page is not delivered again")
    }

    static func emptyFirstPageHoldsBackLaterPages() {
        var watcher = watcher(over: ["page001.jpg": 0, "page002.jpg": 4000, "page003.jpg.part": 4000])
        let firstLook = watcher.finishedPages(processEnded: false)
        let secondLook = watcher.finishedPages(processEnded: false)
        expect(firstLook.isEmpty && secondLook.isEmpty, "a later page never arrives before an empty first page")
    }
}
