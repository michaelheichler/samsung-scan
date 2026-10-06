import Foundation

extension ScanSession {
    var blankPages: [ScannedPage] {
        blankCheck.blankPages(among: pages, text: textRecognition)
    }

    func isBlank(_ page: ScannedPage) -> Bool {
        blankCheck.isBlank(page.id, text: textRecognition)
    }

    // So that text recognition stops too, removal goes through remove(_:).
    func removeBlankPages() {
        guard canEditPages else { return }
        for page in blankPages {
            remove(page)
        }
    }
}
