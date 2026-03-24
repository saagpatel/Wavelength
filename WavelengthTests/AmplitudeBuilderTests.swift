import Testing
import Foundation
@testable import Wavelength

struct AmplitudeBuilderTests {

    private func makeSignal(
        frequencyMHz: Double,
        bandwidthMHz: Double? = nil,
        signalDBM: Double? = -60,
        provenance: SignalProvenance = .live
    ) -> Signal {
        Signal(
            id: UUID().uuidString, category: .bluetooth, provenance: provenance,
            frequencyMHz: frequencyMHz, bandwidthMHz: bandwidthMHz, signalDBM: signalDBM,
            label: "Test", sublabel: nil, lastUpdated: .now, isActive: true
        )
    }

    @Test func emptySignalsProducesAllZeros() {
        let result = SpectrogramRenderer.buildAmplitudeArray(from: [])
        #expect(result.count == 1024)
        #expect(result.allSatisfy { $0 == 0.0 })
    }

    @Test func singleBLESignalAtCorrectBin() {
        let signal = makeSignal(frequencyMHz: 2441, signalDBM: -60)
        let result = SpectrogramRenderer.buildAmplitudeArray(from: [signal])

        // log10(2441) ≈ 3.3876, logLow=1.8451, logSpan=1.9331
        // normalized ≈ (3.3876 - 1.8451) / 1.9331 ≈ 0.7977
        // bin ≈ 0.7977 * 1023 ≈ 816
        let expectedBin = 816
        #expect(result[expectedBin] > 0)
        // Neighbors should also be nonzero (point source spreads ±1)
        #expect(result[expectedBin - 1] > 0)
        #expect(result[expectedBin + 1] > 0)
    }

    @Test func bandwidthSignalSpreadsAcrossBins() {
        // BLE: 2441 MHz, bandwidth 78 MHz → 2402–2480 MHz
        let signal = makeSignal(frequencyMHz: 2441, bandwidthMHz: 78, signalDBM: -50)
        let result = SpectrogramRenderer.buildAmplitudeArray(from: [signal])

        // Count nonzero bins in the BLE range
        let nonzeroBins = result.enumerated().filter { $0.element > 0 }.count
        #expect(nonzeroBins > 3, "Bandwidth signal should spread across multiple bins, got \(nonzeroBins)")
    }

    @Test func gpsPointSourceFillsThreeBins() {
        let signal = makeSignal(frequencyMHz: 1575.42, signalDBM: -60)
        let result = SpectrogramRenderer.buildAmplitudeArray(from: [signal])

        // Count nonzero bins — should be exactly 3 (center + 1 each side)
        let nonzeroBins = result.filter { $0 > 0 }.count
        #expect(nonzeroBins == 3)
    }

    @Test func dbmNormalizationBoundaries() {
        let weakSignal = makeSignal(frequencyMHz: 1000, signalDBM: -100)
        let strongSignal = makeSignal(frequencyMHz: 2000, signalDBM: -30)

        let weak = SpectrogramRenderer.buildAmplitudeArray(from: [weakSignal])
        let strong = SpectrogramRenderer.buildAmplitudeArray(from: [strongSignal])

        let weakMax = weak.max() ?? 0
        let strongMax = strong.max() ?? 0

        #expect(weakMax < 0.01, "dBm -100 should map to ~0.0")
        #expect(strongMax > 0.95, "dBm -30 should map to ~1.0")
    }

    @Test func provenanceAttenuationFactors() {
        let live = makeSignal(frequencyMHz: 1000, signalDBM: -30, provenance: .live)
        let nearby = makeSignal(frequencyMHz: 1000, signalDBM: -30, provenance: .nearby)
        let probable = makeSignal(frequencyMHz: 1000, signalDBM: -30, provenance: .probable)

        let liveAmp = SpectrogramRenderer.buildAmplitudeArray(from: [live]).max() ?? 0
        let nearbyAmp = SpectrogramRenderer.buildAmplitudeArray(from: [nearby]).max() ?? 0
        let probableAmp = SpectrogramRenderer.buildAmplitudeArray(from: [probable]).max() ?? 0

        #expect(liveAmp > nearbyAmp, "Live should be brighter than nearby")
        #expect(nearbyAmp > probableAmp, "Nearby should be brighter than probable")
        // Check approximate ratios
        #expect(abs(nearbyAmp / liveAmp - 0.5) < 0.05, "Nearby should be ~50% of live")
        #expect(abs(probableAmp / liveAmp - 0.25) < 0.05, "Probable should be ~25% of live")
    }

    @Test func overlappingSignalsUseMaxNotSum() {
        let sig1 = makeSignal(frequencyMHz: 2441, signalDBM: -50)
        let sig2 = makeSignal(frequencyMHz: 2441, signalDBM: -40)

        let combined = SpectrogramRenderer.buildAmplitudeArray(from: [sig1, sig2])
        let single = SpectrogramRenderer.buildAmplitudeArray(from: [sig2])

        let combinedMax = combined.max() ?? 0
        let singleMax = single.max() ?? 0

        // Max behavior: combined should equal the stronger signal, not sum
        #expect(abs(combinedMax - singleMax) < 0.01)
    }

    @Test func outOfRangeSignalIgnored() {
        let tooHigh = makeSignal(frequencyMHz: 10000, signalDBM: -30)
        let result = SpectrogramRenderer.buildAmplitudeArray(from: [tooHigh])
        #expect(result.allSatisfy { $0 == 0.0 })
    }
}
