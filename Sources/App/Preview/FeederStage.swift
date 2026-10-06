import SwiftUI

struct FeederStage: View {
    let area: ScanArea
    let region: ScanRegion

    @Environment(\.locale) private var locale

    var body: some View {
        GeometryReader { proxy in
            let bounds = CGRect(origin: .zero, size: proxy.size)
                .insetBy(dx: FlatbedStage.padding, dy: FlatbedStage.padding)
            let mapping = CanvasMapping(area: area, bounds: bounds)
            ZStack {
                GlassSurface(mapping: mapping, picture: nil)
                SelectionOverlay(mapping: mapping, region: region, isEditable: false, dimsOutside: false)
                    .accessibilityElement()
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel("Paper size outline")
                    .accessibilityValue(RegionSizeText.string(for: region, locale: locale))
                ContentUnavailableView(
                    "Document Feeder",
                    systemImage: "doc.on.doc",
                    description: Text("The feeder scans every page at the chosen paper size. Preview and area selection work on the glass."))
                    .frame(maxWidth: mapping.glass.width)
                    .position(x: mapping.glass.midX, y: mapping.glass.midY)
            }
        }
    }
}
