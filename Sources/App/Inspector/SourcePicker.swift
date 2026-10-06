import SwiftUI

struct SourcePicker: View {
    let sources: [String]
    @Binding var source: String

    var body: some View {
        InspectorMenuRow(title: "Source", value: OptionLabels.label(forValue: source), selection: $source) {
            ForEach(sources, id: \.self) { source in
                Text(OptionLabels.label(forValue: source)).tag(source)
            }
        }
    }
}
