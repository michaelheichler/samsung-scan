import Foundation

extension ScanSession {
    var pageTexts: [ScannedPage.ID: PageText] {
        textRecognition.texts
    }

    func textState(of page: ScannedPage) -> PageTextState? {
        textRecognition.states[page.id]
    }

    func warmUpTextRecognition() {
        textRecognition.warmUp()
    }
}
