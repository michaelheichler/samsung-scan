import SwiftUI

struct ScannerRow: View {
    private static let lineSpacing = 2.0

    let device: ScannerDevice

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Self.lineSpacing) {
                Text(device.model)
                    .lineLimit(2)
                Text(device.name)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        } icon: {
            Image(systemName: "scanner")
        }
        .help(device.name)
        .accessibilityElement(children: .combine)
    }
}
