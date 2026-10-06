import SwiftUI

struct BlankPageBadge: View {
    static let symbol = "square.dashed"
    private static let horizontalPadding = 8.0
    private static let verticalPadding = 3.0
    private static let edgeInset = 6.0

    var body: some View {
        Label("Blank", systemImage: Self.symbol)
            .font(.caption)
            .bold()
            .foregroundStyle(.black)
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.vertical, Self.verticalPadding)
            .background(.yellow, in: .capsule)
            .padding(Self.edgeInset)
    }
}
