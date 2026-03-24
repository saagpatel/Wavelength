import SwiftUI

/// Signal label overlay rendered at 1fps via TimelineView.
/// Uses greedy collision avoidance to prevent text overlap.
struct AnnotationOverlay: View {
    let signals: [Signal]
    var displayRange: ClosedRange<Double> = 70.0...6000.0

    private nonisolated static let maxLabels = 15
    private nonisolated static let minVerticalSpacing: CGFloat = 18

    var body: some View {
        GeometryReader { geometry in
            let labels = Self.resolveCollisions(
                signals: signals,
                viewHeight: geometry.size.height,
                displayRange: displayRange
            )
            ForEach(Array(labels.enumerated()), id: \.element.text) { _, label in
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 1)
                    Text(label.text)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .position(x: geometry.size.width - 40, y: label.y)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Collision Resolution (pure, testable)

    struct ResolvedLabel: Sendable {
        let text: String
        let y: CGFloat
    }

    /// Place labels at their ideal Y position, then push apart overlapping labels.
    nonisolated static func resolveCollisions(
        signals: [Signal],
        viewHeight: CGFloat,
        displayRange: ClosedRange<Double> = 70.0...6000.0
    ) -> [ResolvedLabel] {
        guard viewHeight > 0 else { return [] }

        let active = signals.filter { $0.isActive }
        guard !active.isEmpty else { return [] }

        // Priority: live > nearby > probable, then by signal strength
        let prioritized = Array(active
            .sorted { provenanceRank($0) > provenanceRank($1) }
            .prefix(maxLabels))

        var labels: [(text: String, y: CGFloat)] = prioritized.map { signal in
            let band = FrequencyBand(
                lowMHz: signal.frequencyMHz, highMHz: signal.frequencyMHz,
                name: "", allocationSource: ""
            )
            let position = band.logPosition(in: displayRange)
            let y = viewHeight * CGFloat(1.0 - position)
            return (String(signal.label.prefix(14)), y)
        }

        labels.sort { $0.y < $1.y }

        // Push apart overlapping labels
        if labels.count > 1 {
            for i in 1..<labels.count {
                let gap = labels[i].y - labels[i - 1].y
                if gap < minVerticalSpacing {
                    labels[i].y = labels[i - 1].y + minVerticalSpacing
                }
            }
        }

        return labels.map { ResolvedLabel(text: $0.text, y: min($0.y, viewHeight - 8)) }
    }

    private nonisolated static func provenanceRank(_ signal: Signal) -> Int {
        switch signal.provenance {
        case .live: 3
        case .nearby: 2
        case .probable: 1
        }
    }
}
