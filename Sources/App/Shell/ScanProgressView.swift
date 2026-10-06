import SwiftUI

struct ScanProgressView: View {
    private static let spacing = 12.0
    private static let padding = 24.0
    private static let minimumWidth = 240.0
    private static let cornerRadius = 16.0
    private static let barWidth = minimumWidth - 2 * padding

    let phase: ScanPhase
    let cancel: (() -> Void)?

    private var title: String {
        phase.progressTitle ?? ""
    }

    var body: some View {
        VStack(spacing: Self.spacing) {
            ScanProgressIndicator(phase: phase, barWidth: Self.barWidth)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            if let detail = phase.progressDetail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let cancel {
                Button("Cancel", action: cancel)
                    .controlSize(.large)
            }
        }
        .padding(Self.padding)
        .frame(minWidth: Self.minimumWidth)
        .background {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(.regularMaterial)
                .shadow(radius: Self.cornerRadius / 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}
