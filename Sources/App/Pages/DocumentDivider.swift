import SwiftUI

struct DocumentDivider: View {
    // So that a suggested and a confirmed divider take the same height.
    private static let height = 28.0
    private static let spacing = 8.0
    private static let lineWidth = 1.0
    private static let dash: [CGFloat] = [5, 4]

    let section: DocumentSection
    let count: Int
    let session: ScanSession

    private var reason: DocumentSplitReason? {
        guard case .suggested(let reason) = section.split else { return nil }
        return reason
    }

    private var isSuggested: Bool {
        reason != nil
    }

    private var startsWithSplit: Bool {
        section.split != .none
    }

    private var lineStyle: AnyShapeStyle {
        switch section.split {
        case .none: AnyShapeStyle(.separator)
        case .suggested: AnyShapeStyle(.secondary)
        case .confirmed: AnyShapeStyle(.tint)
        }
    }

    private var accessibilityText: String {
        let state = switch section.split {
        case .none: ""
        case .suggested: ", suggested split"
        case .confirmed: ", confirmed split"
        }
        return "Document \(section.number) of \(count), \(section.name.stem)\(state)"
    }

    var body: some View {
        HStack(spacing: Self.spacing) {
            Text(section.name.stem)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(section.name.stem)
            if let reason {
                Text("Suggested")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .help(reason.summary)
            }
            DocumentDividerLine()
                .stroke(lineStyle, style: StrokeStyle(lineWidth: Self.lineWidth, dash: isSuggested ? Self.dash : []))
                .frame(height: Self.lineWidth)
            if startsWithSplit {
                Button("Accept", action: accept)
                    .accessibilityLabel("Accept split")
                    .help("Keep this split")
                    .opacity(isSuggested ? 1 : 0)
                    .disabled(!isSuggested)
                    .accessibilityHidden(!isSuggested)
                Button("Remove", action: remove)
                    .accessibilityLabel("Remove split")
                    .help("Join this document with the one before it")
            }
        }
        .controlSize(.small)
        .frame(minHeight: Self.height)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isHeader)
    }

    private func accept() {
        session.confirmSplit(at: section.firstPage)
    }

    private func remove() {
        session.removeSplit(at: section.firstPage)
    }
}
