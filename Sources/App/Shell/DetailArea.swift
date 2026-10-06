import SwiftUI

struct DetailArea: View {
    let session: ScanSession

    private var cancelAction: (() -> Void)? {
        guard session.phase.isCancellable else { return nil }
        return { session.cancel() }
    }

    var body: some View {
        Group {
            if session.showsPageGrid {
                PageGrid(session: session)
            } else {
                PreviewCanvas(session: session)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if session.phase.progressTitle != nil {
                ScanProgressView(phase: session.phase, cancel: cancelAction)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: session.phase.progressTitle != nil)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StatusBar(text: session.statusText, isProblem: session.statusIsProblem)
        }
    }
}
