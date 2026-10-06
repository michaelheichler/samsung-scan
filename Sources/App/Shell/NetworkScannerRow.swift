import SwiftUI

struct NetworkScannerRow: View {
    private static let lineSpacing = 2.0

    let scanner: DiscoveredScanner

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Self.lineSpacing) {
                Text(scanner.name)
                    .lineLimit(2)
                Text("Found on the network, but it does not open")
                    .font(.callout)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: "exclamationmark.triangle")
        }
        .foregroundStyle(.secondary)
        .help("Samsung Scan found this scanner at \(scanner.host) through Bonjour, but scanimage does not list it. "
            + "Check that the scanner is on and awake. SANE may not support this model.")
        .accessibilityElement(children: .combine)
    }
}
