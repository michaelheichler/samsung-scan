import SwiftUI

struct OptionSlider: View {
    let title: String
    let unit: ScannerOptionUnit?
    let bounds: ClosedRange<Double>
    let step: Double?
    @Binding var value: Double

    var body: some View {
        LabeledContent {
            Group {
                if let step, step > 0 {
                    Slider(value: $value, in: bounds, step: step) { Text(title) }
                } else {
                    Slider(value: $value, in: bounds) { Text(title) }
                }
            }
            .labelsHidden()
            .accessibilityValue(valueText)
        } label: {
            Text(title)
            Text(valueText)
        }
    }

    private var valueText: String {
        InspectorFormat.optionValue(value, unit: unit)
    }
}
