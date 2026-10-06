import SwiftUI

struct DocumentCommands: Commands {
    let session: ScanSession

    var body: some Commands {
        CommandMenu("Document") {
            DocumentCommandItems(session: session)
        }
    }
}
