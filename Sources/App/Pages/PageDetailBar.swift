import SwiftUI

struct PageDetailBar: View {
    let title: String
    let hasPrevious: Bool
    let hasNext: Bool
    let previous: () -> Void
    let next: () -> Void
    let close: () -> Void

    var body: some View {
        HStack {
            Button("Previous Page", systemImage: "chevron.left", action: previous)
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(!hasPrevious)
            Button("Next Page", systemImage: "chevron.right", action: next)
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(!hasNext)
            Spacer()
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button("Close", action: close)
                .keyboardShortcut(.cancelAction)
        }
        .labelStyle(.iconOnly)
    }
}
