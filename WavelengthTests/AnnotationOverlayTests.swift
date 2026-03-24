import Testing
import Foundation
@testable import Wavelength

struct AnnotationOverlayTests {

    private func makeSignal(
        id: String = UUID().uuidString,
        category: SignalCategory = .fm,
        provenance: SignalProvenance = .nearby,
        frequencyMHz: Double = 98.1,
        signalDBM: Double? = -60
    ) -> Signal {
        Signal(
            id: id, category: category, provenance: provenance,
            frequencyMHz: frequencyMHz, bandwidthMHz: nil, signalDBM: signalDBM,
            label: "Test \(id.prefix(4))", sublabel: nil, lastUpdated: .now, isActive: true
        )
    }

    @Test func emptySignalsProducesNoLabels() {
        let result = AnnotationOverlay.resolveCollisions(signals: [], viewHeight: 800)
        #expect(result.isEmpty)
    }

    @Test func singleSignalProducesOneLabel() {
        let signals = [makeSignal(frequencyMHz: 98.1)]
        let result = AnnotationOverlay.resolveCollisions(signals: signals, viewHeight: 800)
        #expect(result.count == 1)
    }

    @Test func overlappingLabelsAreSeparated() {
        // Two signals at the same frequency should be pushed apart
        let signals = [
            makeSignal(id: "a", frequencyMHz: 98.1),
            makeSignal(id: "b", frequencyMHz: 98.2),
        ]
        let result = AnnotationOverlay.resolveCollisions(signals: signals, viewHeight: 800)
        #expect(result.count == 2)
        let gap = abs(result[1].y - result[0].y)
        #expect(gap >= 18, "Labels should be at least 18pt apart, got \(gap)")
    }

    @Test func maxLabelsCapped() {
        let signals = (0..<30).map { i in
            makeSignal(id: "sig-\(i)", frequencyMHz: 88.0 + Double(i) * 0.5)
        }
        let result = AnnotationOverlay.resolveCollisions(signals: signals, viewHeight: 800)
        #expect(result.count <= 15)
    }
}
