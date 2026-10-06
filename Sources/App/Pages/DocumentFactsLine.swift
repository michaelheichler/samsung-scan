import SwiftUI

struct DocumentFactsLine: View {
    let facts: DocumentFacts

    var body: some View {
        let summary = facts.summary()
        if !summary.isEmpty {
            Text(summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .help(summary)
                .accessibilityLabel("Document: \(summary)")
        }
    }
}
