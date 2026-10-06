import SwiftUI

struct ExportOptionsForm: View {
    private static let qualityRange = 0.5...1.0
    private static let qualityStep = 0.05
    private static let qualityFormat = FloatingPointFormatStyle<Double>.Percent().precision(.fractionLength(0))

    @Binding var format: ExportFormat
    @Binding var scope: ExportScope
    @Binding var jpegQuality: Double
    let pageCount: Int
    let selectedCount: Int

    var body: some View {
        Form {
            Picker("Format", selection: $format) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.name).tag(format)
                }
            }
            .pickerStyle(.segmented)
            if selectedCount > 0 {
                Picker("Pages", selection: $scope) {
                    Text("All (\(pageCount))").tag(ExportScope.all)
                    Text("Selected (\(selectedCount))").tag(ExportScope.selected)
                }
                .pickerStyle(.radioGroup)
            }
            if format == .jpeg {
                LabeledContent("Quality") {
                    HStack {
                        Slider(value: $jpegQuality, in: Self.qualityRange, step: Self.qualityStep)
                            .accessibilityValue(jpegQuality.formatted(Self.qualityFormat))
                        Text(jpegQuality, format: Self.qualityFormat)
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}
