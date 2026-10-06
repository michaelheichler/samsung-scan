import SwiftUI

struct ScanProgressIndicator: View {
    let phase: ScanPhase
    let barWidth: Double

    var body: some View {
        if phase.isStalled {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
        } else if let fraction = phase.progressFraction {
            ProgressView(value: fraction)
                .frame(width: barWidth)
                .accessibilityLabel("Scan progress")
                .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
        } else {
            ProgressView()
                .controlSize(.large)
        }
    }
}
