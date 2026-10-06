import SwiftUI

struct EmptyGlassPrompt: View {
    let preview: @MainActor () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Preview", systemImage: "viewfinder")
        } description: {
            Text("Place a page face down on the glass, then preview it to choose the area to scan.")
        } actions: {
            Button("Preview", action: preview)
                .buttonStyle(.borderedProminent)
                .help("Scan the whole glass at low resolution")
        }
    }
}
