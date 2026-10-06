import SwiftUI

struct AdvancedOptionRow: View {
    let option: ScannerOption
    @Binding var draft: ScanRequest

    private var title: String { OptionLabels.title(forOption: option.name) }

    var body: some View {
        control
            .help(option.description)
            .accessibilityHint(option.description)
    }

    @ViewBuilder private var control: some View {
        switch option.value {
        case .boolean:
            Toggle(title, isOn: $draft[flag: option])
        case .range(let lower, let upper, let step):
            OptionSlider(
                title: title,
                unit: option.unit,
                bounds: lower...upper,
                step: step,
                value: $draft[number: option])
        case .strings(let values):
            choiceMenu(values, label: OptionLabels.label(forValue:))
        case .numbers(let values):
            choiceMenu(values.map(ScanRequest.optionText)) { InspectorFormat.optionValue($0, unit: option.unit) }
        case .unconstrained:
            EmptyView()
        }
    }

    private func choiceMenu(_ values: [String], label: @escaping (String) -> String) -> some View {
        InspectorMenuRow(
            title: title,
            value: label(draft[choice: option]),
            selection: $draft[choice: option]
        ) {
            ForEach(values, id: \.self) { value in
                Text(label(value)).tag(value)
            }
        }
    }
}
