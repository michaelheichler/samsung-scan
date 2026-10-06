import SwiftUI

struct PreviewCanvas: View {
    let session: ScanSession

    @ViewState private var picture: PreviewPicture?

    var body: some View {
        Group {
            if let area = session.scanArea, let draft = session.draft {
                if session.usesFlatbed {
                    FlatbedStage(
                        area: area,
                        region: draft.region,
                        isCustom: session.selectedRegion != nil,
                        picture: picture,
                        isBusy: session.phase.isBusy,
                        commit: session.selectRegion,
                        clear: session.clearCustomRegion,
                        preview: session.preview)
                } else {
                    FeederStage(area: area, region: draft.region)
                }
            } else {
                // So that the detail column never empties, which collapses the split view.
                ContentUnavailableView(
                    "No Preview",
                    systemImage: "viewfinder",
                    description: Text("Select a scanner to see its glass."))
                    .opacity(session.phase.isBusy ? 0 : 1)
                    .accessibilityHidden(session.phase.isBusy)
            }
        }
        .task(id: session.previewImage) {
            await loadPicture()
        }
    }

    private func loadPicture() async {
        guard let file = session.previewImage else {
            picture = nil
            return
        }
        let loaded = await PreviewPicture.load(from: file)
        if !Task.isCancelled { picture = loaded }
    }
}
