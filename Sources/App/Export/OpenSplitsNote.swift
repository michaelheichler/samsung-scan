import SwiftUI

struct OpenSplitsNote: View {
    let count: Int
    let acceptAll: () -> Void

    private var message: String {
        count == 1
            ? "1 suggested split is not accepted yet."
            : "\(count) suggested splits are not accepted yet."
    }

    var body: some View {
        HStack {
            Text(message)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Accept All", action: acceptAll)
                .help("Split the export at every suggested split")
        }
    }
}
