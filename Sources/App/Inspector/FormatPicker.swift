import SwiftUI

struct FormatPicker: View {
    static let customTitle = "Custom"

    @Bindable var session: ScanSession
    let region: ScanRegion

    private var selectedName: String {
        session.availablePapers.first { $0.id == session.selectedPaperID }?.name ?? Self.customTitle
    }

    var body: some View {
        InspectorMenuRow(
            title: "Format",
            detail: InspectorFormat.dimensions(of: region),
            value: selectedName,
            selection: $session.selectedPaperID
        ) {
            ForEach(session.availablePapers) { paper in
                Text(paper.name).tag(Optional(paper.id))
            }
            if session.selectedPaperID == nil {
                Divider()
                Text(Self.customTitle).tag(String?.none)
            }
        }
    }
}
