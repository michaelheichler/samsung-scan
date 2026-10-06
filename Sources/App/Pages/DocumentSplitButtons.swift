import SwiftUI

struct DocumentSplitButtons: View {
    private static let startShortcut = KeyboardShortcut("d", modifiers: [.command, .shift])
    private static let joinShortcut = KeyboardShortcut("j", modifiers: [.command, .shift])

    let page: ScannedPage?
    let session: ScanSession

    private var canSplit: Bool {
        page.map(session.canSplit(at:)) ?? false
    }

    private var state: DocumentSplitState {
        page.map(session.splitState(of:)) ?? .none
    }

    var body: some View {
        if !canSplit || state == .none {
            Button("Start New Document Here", systemImage: "scissors", action: confirm)
                .keyboardShortcut(Self.startShortcut)
                .disabled(!canSplit)
        } else {
            if case .suggested = state {
                Button("Accept Suggested Split", systemImage: "checkmark", action: confirm)
                    .keyboardShortcut(Self.startShortcut)
            }
            Button("Join with Previous Document", systemImage: "arrow.merge", action: join)
                .keyboardShortcut(Self.joinShortcut)
        }
    }

    private func confirm() {
        guard let page else { return }
        session.confirmSplit(at: page)
    }

    private func join() {
        guard let page else { return }
        session.removeSplit(at: page)
    }
}
