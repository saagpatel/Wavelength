import Testing
import Foundation
@testable import Wavelength

struct SignalRegistryTests {

    private func makeSignal(
        id: String = UUID().uuidString,
        category: SignalCategory = .bluetooth,
        provenance: SignalProvenance = .live,
        frequencyMHz: Double = 2441,
        lastUpdated: Date = .now
    ) -> Signal {
        Signal(
            id: id, category: category, provenance: provenance,
            frequencyMHz: frequencyMHz, bandwidthMHz: nil, signalDBM: -60,
            label: "Test", sublabel: nil, lastUpdated: lastUpdated, isActive: true
        )
    }

    @Test func mergeAndSortCombinesAllTiersAndSortsByFrequency() {
        let live = [
            makeSignal(provenance: .live, frequencyMHz: 2441),
            makeSignal(provenance: .live, frequencyMHz: 700),
            makeSignal(provenance: .live, frequencyMHz: 5000),
        ]
        let nearby = [
            makeSignal(provenance: .nearby, frequencyMHz: 98.1),
            makeSignal(provenance: .nearby, frequencyMHz: 1575),
            makeSignal(provenance: .nearby, frequencyMHz: 850),
        ]
        let probable = [
            makeSignal(provenance: .probable, frequencyMHz: 1090),
            makeSignal(provenance: .probable, frequencyMHz: 3500),
            makeSignal(provenance: .probable, frequencyMHz: 433),
        ]

        let merged = SignalRegistry.mergeAndSort(live: live, nearby: nearby, probable: probable)

        #expect(merged.count == 9)
        for i in 0..<merged.count - 1 {
            #expect(merged[i].frequencyMHz <= merged[i + 1].frequencyMHz)
        }
        #expect(merged.first?.frequencyMHz == 98.1)
        #expect(merged.last?.frequencyMHz == 5000)
    }

    @Test func mergeAndSortWithEmptyArrays() {
        let result = SignalRegistry.mergeAndSort(live: [], nearby: [], probable: [])
        #expect(result.isEmpty)
    }

    @Test @MainActor func addDuplicateIdUpdatesExisting() {
        let registry = SignalRegistry()
        let signal1 = makeSignal(id: "ble-1", frequencyMHz: 2441)
        let signal2 = Signal(
            id: "ble-1", category: .bluetooth, provenance: .live,
            frequencyMHz: 2441, bandwidthMHz: nil, signalDBM: -40,
            label: "Updated", sublabel: nil, lastUpdated: .now, isActive: true
        )

        registry.addLiveSignal(signal1)
        registry.addLiveSignal(signal2)

        #expect(registry.liveSignals.count == 1)
        #expect(registry.liveSignals[0].label == "Updated")
    }

    @Test @MainActor func removeByIdWorks() {
        let registry = SignalRegistry()
        registry.addLiveSignal(makeSignal(id: "remove-me"))
        registry.addLiveSignal(makeSignal(id: "keep-me"))

        registry.removeLiveSignal(id: "remove-me")

        #expect(registry.liveSignals.count == 1)
        #expect(registry.liveSignals[0].id == "keep-me")
    }

    @Test @MainActor func expireStaleSignalsRemovesOldKeepsNew() {
        let registry = SignalRegistry()
        let old = makeSignal(id: "old", lastUpdated: Date().addingTimeInterval(-60))
        let fresh = makeSignal(id: "fresh", lastUpdated: .now)

        registry.addLiveSignal(old)
        registry.addLiveSignal(fresh)
        registry.expireStaleSignals(olderThan: 30)

        #expect(registry.liveSignals.count == 1)
        #expect(registry.liveSignals[0].id == "fresh")
    }

    @Test @MainActor func allSignalsIncludesAllTiers() {
        let registry = SignalRegistry()
        registry.addLiveSignal(makeSignal(provenance: .live, frequencyMHz: 2441))
        registry.setNearbySignals([makeSignal(provenance: .nearby, frequencyMHz: 98.1)])
        registry.setProbableSignals([makeSignal(provenance: .probable, frequencyMHz: 1090)])

        #expect(registry.allSignals.count == 3)
        #expect(registry.allSignals[0].frequencyMHz == 98.1)
        #expect(registry.allSignals[2].frequencyMHz == 2441)
    }

    @Test @MainActor func visibleSignalsFiltersProbableWhenDisabled() {
        let registry = SignalRegistry()
        registry.addLiveSignal(makeSignal(provenance: .live, frequencyMHz: 2441))
        registry.setNearbySignals([makeSignal(provenance: .nearby, frequencyMHz: 98.1)])
        registry.setProbableSignals([makeSignal(provenance: .probable, frequencyMHz: 1090)])

        // With probable enabled (default)
        #expect(registry.visibleSignals.count == 3)

        // Disable probable
        registry.showProbable = false
        #expect(registry.visibleSignals.count == 2)
        #expect(registry.visibleSignals.allSatisfy { $0.provenance != .probable })
    }
}
