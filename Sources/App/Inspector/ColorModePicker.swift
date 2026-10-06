import SwiftUI

struct ColorModePicker: View {
    let modes: [String]
    @Binding var mode: String

    var body: some View {
        InspectorMenuRow(title: "Color", value: OptionLabels.label(forValue: mode), selection: $mode) {
            ForEach(modes, id: \.self) { mode in
                Text(OptionLabels.label(forValue: mode)).tag(mode)
            }
        }
    }
}
