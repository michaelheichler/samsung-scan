import SwiftUI

struct InspectorMenuRow<Selection: Hashable, Choices: View>: View {
    let title: String
    var detail: String?
    let value: String
    @Binding var selection: Selection
    @ViewBuilder let choices: () -> Choices

    @ViewState private var rowWidth = CGFloat.infinity
    @ViewState private var neededWidth = CGFloat.zero

    var body: some View {
        // Because AppKit menus report no usable ideal width, ViewThatFits cannot decide.
        Group {
            if neededWidth <= rowWidth {
                picker
            } else {
                VStack(alignment: .leading) {
                    LabeledContent(title, value: detail ?? "")
                    picker
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { rowWidth = $0 }
        .background {
            widthProbe
                .fixedSize()
                .hidden()
                .onGeometryChange(for: CGFloat.self, of: \.size.width) { neededWidth = $0 }
        }
    }

    private var picker: some View {
        Picker(selection: $selection, content: choices) {
            Text(title)
            if let detail {
                Text(detail)
            }
        }
        .pickerStyle(.menu)
    }

    private var widthProbe: some View {
        HStack(spacing: InspectorLayout.labelGap) {
            VStack(alignment: .leading) {
                Text(title)
                if let detail {
                    Text(detail)
                }
            }
            Text(value)
        }
        .padding(.trailing, InspectorLayout.menuChrome)
    }
}
