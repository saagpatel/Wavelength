import SwiftUI

/// Half-height sheet showing detailed information about a tapped signal.
struct SignalDetailPanel: View {
    let signal: Signal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                provenanceIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.label)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    if let sublabel = signal.sublabel {
                        Text(sublabel)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                Spacer()
                provenanceBadge
            }

            Divider().background(Color.white.opacity(0.1))

            detailGrid

            Divider().background(Color.white.opacity(0.1))

            if let education = SignalEducation.blurbs[signal.category] {
                VStack(alignment: .leading, spacing: 4) {
                    Text(education.title)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(education.detail)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(4)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(Color.black.opacity(0.95))
    }

    // MARK: - Subviews

    private var provenanceIcon: some View {
        Circle()
            .fill(provenanceColor)
            .frame(width: 12, height: 12)
    }

    private var provenanceBadge: some View {
        Text(signal.provenance.rawValue.capitalized)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var detailGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            detailRow("Frequency", String(format: "%.1f MHz", signal.frequencyMHz))
            if let bw = signal.bandwidthMHz {
                detailRow("Bandwidth", String(format: "%.1f MHz", bw))
            }
            if let dbm = signal.signalDBM {
                detailRow("Signal", String(format: "%.0f dBm", dbm))
            }
            detailRow("Category", signal.category.rawValue.capitalized)
            detailRow("Provenance", provenanceExplanation)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var provenanceColor: Color {
        switch signal.provenance {
        case .live: .green
        case .nearby: .blue
        case .probable: .orange
        }
    }

    private var provenanceExplanation: String {
        switch signal.provenance {
        case .live: "Actively sensed by device hardware"
        case .nearby: "Confirmed present via database at this location"
        case .probable: "Inferred from location context"
        }
    }

    // MARK: - Tap-to-Frequency Mapping (pure, testable)

    /// Convert a tap Y coordinate to a frequency using inverse log mapping.
    nonisolated static func frequencyFromTapY(
        tapY: Double,
        viewHeight: Double,
        displayRange: ClosedRange<Double> = 70.0...6000.0
    ) -> Double {
        let normalizedPosition = 1.0 - (tapY / viewHeight)
        let logLow = log10(displayRange.lowerBound)
        let logHigh = log10(displayRange.upperBound)
        let logFreq = logLow + normalizedPosition * (logHigh - logLow)
        return pow(10, logFreq)
    }

    /// Find the nearest signal to a given frequency within a tolerance.
    nonisolated static func nearestSignal(
        to frequency: Double,
        in signals: [Signal],
        toleranceMHz: Double = 200.0
    ) -> Signal? {
        signals
            .filter { $0.isActive }
            .min { abs($0.frequencyMHz - frequency) < abs($1.frequencyMHz - frequency) }
            .flatMap { abs($0.frequencyMHz - frequency) <= toleranceMHz ? $0 : nil }
    }
}
