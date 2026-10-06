import SwiftUI

struct ScanSettingsInspector: View {
    @Bindable var session: ScanSession

    var body: some View {
        if let draft = session.draft, let capabilities = session.inspectorCapabilities {
            ScanSettingsForm(session: session, draft: binding(fallingBackTo: draft), capabilities: capabilities)
        } else {
            ContentUnavailableView(
                "No Settings",
                systemImage: "slider.horizontal.3",
                description: Text("Select a scanner to see its settings."))
        }
    }

    // So that a control read after a device change clears the draft cannot trap.
    private func binding(fallingBackTo fallback: ScanRequest) -> Binding<ScanRequest> {
        Binding(
            get: { session.draft ?? fallback },
            set: { next in
                if session.draft != nil { session.draft = next }
            })
    }
}
