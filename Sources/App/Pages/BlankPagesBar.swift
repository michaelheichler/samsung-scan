import SwiftUI

struct BlankPagesBar: View {
    static let height = 40.0
    private static let spacing = 12.0
    private static let horizontalPadding = 16.0
    private static let shadowRadius = 6.0

    let count: Int
    let canRemove: Bool
    let remove: () -> Void

    var body: some View {
        HStack(spacing: Self.spacing) {
            Label("^[\(count) blank page](inflect: true)", systemImage: BlankPageBadge.symbol)
            Button("Remove", action: remove)
                .accessibilityLabel("Remove blank pages")
                .disabled(!canRemove)
        }
        .font(.callout)
        .padding(.horizontal, Self.horizontalPadding)
        .frame(height: Self.height)
        .background {
            Capsule()
                .fill(.regularMaterial)
                .shadow(radius: Self.shadowRadius)
        }
        .accessibilityElement(children: .contain)
    }
}
