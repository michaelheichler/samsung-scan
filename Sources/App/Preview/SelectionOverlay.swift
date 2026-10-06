import SwiftUI

struct SelectionOverlay: View {
    private static let dimOpacity = (standard: 0.35, increased: 0.6)
    private static let lineWidth = (standard: 1.5, increased: 3.0)
    private static let handleDiameter = (standard: 9.0, increased: 12.0)
    private static let presetDash: [CGFloat] = [6, 4]

    let mapping: CanvasMapping
    let region: ScanRegion
    let isEditable: Bool
    let dimsOutside: Bool

    @Environment(\.colorSchemeContrast) private var contrast

    private var isIncreased: Bool { contrast == .increased }

    var body: some View {
        let frame = mapping.rect(for: region)
        let lineWidth = isIncreased ? Self.lineWidth.increased : Self.lineWidth.standard
        let handleDiameter = isIncreased ? Self.handleDiameter.increased : Self.handleDiameter.standard
        ZStack {
            OutsideDim(glass: mapping.glass, selection: frame)
                .fill(
                    Color(nsColor: .shadowColor).opacity(isIncreased ? Self.dimOpacity.increased : Self.dimOpacity.standard),
                    style: FillStyle(eoFill: true))
                .opacity(dimsOutside ? 1 : 0)
            PlacedRectangle(rect: frame)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: lineWidth, dash: isEditable ? [] : Self.presetDash))
            ForEach(RegionHandle.allCases, id: \.self) { handle in
                Circle()
                    .fill(.background)
                    .stroke(Color.accentColor, lineWidth: lineWidth)
                    .frame(width: handleDiameter, height: handleDiameter)
                    .position(mapping.handlePoint(handle, of: region))
            }
            .opacity(isEditable ? 1 : 0)
        }
        .allowsHitTesting(false)
    }
}
