import SwiftUI

struct DocumentFactsLine: View {
    let facts: DocumentFacts

    // So that the page image keeps its size when the facts arrive.
    var body: some View {
        let summary = facts.summary()
        Text(summary.isEmpty ? " " : summary)
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .help(summary)
            .accessibilityLabel("Document: \(summary)")
            .accessibilityHidden(summary.isEmpty)
    }
}
