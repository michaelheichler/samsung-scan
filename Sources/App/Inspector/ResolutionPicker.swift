import SwiftUI

struct ResolutionPicker: View {
    let choices: [Int]
    @Binding var resolution: Int

    var body: some View {
        InspectorMenuRow(
            title: "Resolution",
            detail: ResolutionHint(dpi: resolution).title,
            value: InspectorFormat.dpi(resolution),
            selection: $resolution
        ) {
            ForEach(ResolutionHint.allCases, id: \.self) { hint in
                let values = hint.choices(in: choices)
                if !values.isEmpty {
                    Section(hint.title) {
                        ForEach(values, id: \.self) { value in
                            Text(InspectorFormat.dpi(value)).tag(value)
                        }
                    }
                }
            }
        }
    }
}
