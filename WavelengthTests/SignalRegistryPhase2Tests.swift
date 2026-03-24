import Testing
import Foundation
@testable import Wavelength

struct SignalRegistryPhase2Tests {

    private func makeSignal(
        id: String = UUID().uuidString,
        category: SignalCategory = .fm,
        provenance: SignalProvenance = .nearby,
        frequencyMHz: Double = 98.1
    ) -> Signal {
        Signal(
            id: id, category: category, provenance: provenance,
            frequencyMHz: frequencyMHz, bandwidthMHz: nil, signalDBM: -60,
            label: "Test", sublabel: nil, lastUpdated: .now, isActive: true
        )
    }

    @Test @MainActor func perCategoryDoesNotClobberOtherCategory() {
        let registry = SignalRegistry()
        let fmSignals = [makeSignal(id: "fm-1", category: .fm, frequencyMHz: 98.1)]
        let satSignals = [makeSignal(id: "sat-1", category: .gps, frequencyMHz: 1575.42)]

        registry.setNearbySignals(fmSignals, forCategory: .fm)
        registry.setNearbySignals(satSignals, forCategory: .gps)

        #expect(registry.nearbySignals.count == 2)
        #expect(registry.nearbySignals.contains { $0.id == "fm-1" })
        #expect(registry.nearbySignals.contains { $0.id == "sat-1" })
    }

    @Test @MainActor func perCategoryReplacesOwnCategory() {
        let registry = SignalRegistry()
        let batch1 = [makeSignal(id: "fm-old", category: .fm)]
        let batch2 = [makeSignal(id: "fm-new", category: .fm)]

        registry.setNearbySignals(batch1, forCategory: .fm)
        registry.setNearbySignals(batch2, forCategory: .fm)

        #expect(registry.nearbySignals.count == 1)
        #expect(registry.nearbySignals[0].id == "fm-new")
    }

    @Test @MainActor func bulkSetNearbyPreservesBackwardCompat() {
        let registry = SignalRegistry()
        let mixed = [
            makeSignal(id: "fm-1", category: .fm),
            makeSignal(id: "gps-1", category: .gps),
        ]

        registry.setNearbySignals(mixed)

        #expect(registry.nearbySignals.count == 2)
    }

    @Test @MainActor func clearCategoryRemovesOnlyThatCategory() {
        let registry = SignalRegistry()
        registry.setNearbySignals([makeSignal(id: "fm-1", category: .fm)], forCategory: .fm)
        registry.setNearbySignals([makeSignal(id: "gps-1", category: .gps)], forCategory: .gps)

        registry.clearCategory(.fm)

        #expect(registry.nearbySignals.count == 1)
        #expect(registry.nearbySignals[0].id == "gps-1")
    }

    @Test @MainActor func allSignalsIncludesPerCategorySignals() {
        let registry = SignalRegistry()
        registry.addLiveSignal(makeSignal(id: "live-1", category: .bluetooth, provenance: .live, frequencyMHz: 2441))
        registry.setNearbySignals([makeSignal(id: "fm-1", category: .fm, frequencyMHz: 98.1)], forCategory: .fm)
        registry.setProbableSignals([makeSignal(id: "adsb", category: .broadcast, provenance: .probable, frequencyMHz: 1090)], forCategory: .broadcast)

        let all = registry.allSignals
        #expect(all.count == 3)
        #expect(all[0].frequencyMHz == 98.1)
        #expect(all[1].frequencyMHz == 1090)
        #expect(all[2].frequencyMHz == 2441)
    }
}
