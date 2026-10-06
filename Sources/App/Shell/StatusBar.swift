import SwiftUI

struct StatusBar: View {
    private static let horizontalPadding = 12.0
    private static let verticalPadding = 6.0
    private static let lineLimit = 2

    let text: String
    let isProblem: Bool

    var body: some View {
        HStack {
            if isProblem {
                Label {
                    Text(text)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            } else {
                Text(text)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .font(.callout)
        .lineLimit(Self.lineLimit)
        .help(text)
        .padding(.horizontal, Self.horizontalPadding)
        .padding(.vertical, Self.verticalPadding)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
