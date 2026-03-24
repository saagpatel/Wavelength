#if DEBUG
import Foundation

@MainActor
enum MockSignalProvider {

    static func populateRegistry(_ registry: SignalRegistry) {
        // BLE device
        registry.addLiveSignal(Signal(
            id: "mock-ble-airpods", category: .bluetooth, provenance: .live,
            frequencyMHz: 2441, bandwidthMHz: 78, signalDBM: -55,
            label: "Headphones", sublabel: "AirPods Pro",
            lastUpdated: .now, isActive: true
        ))

        // Wi-Fi
        registry.addLiveSignal(Signal(
            id: "mock-wifi", category: .wifi, provenance: .live,
            frequencyMHz: 2437, bandwidthMHz: 83.5, signalDBM: -45,
            label: "HomeNetwork", sublabel: "Wi-Fi 2.4 GHz",
            lastUpdated: .now, isActive: true
        ))

        // Cellular LTE
        registry.addLiveSignal(Signal(
            id: "mock-lte", category: .cellular, provenance: .live,
            frequencyMHz: 1900, bandwidthMHz: nil, signalDBM: -75,
            label: "LTE", sublabel: "1900 MHz",
            lastUpdated: .now, isActive: true
        ))

        // GPS (nearby — from satellite data)
        registry.setNearbySignals([
            Signal(
                id: "mock-gps", category: .gps, provenance: .nearby,
                frequencyMHz: 1575.42, bandwidthMHz: nil, signalDBM: -130,
                label: "GPS L1", sublabel: "1575.42 MHz",
                lastUpdated: .now, isActive: true
            ),
            Signal(
                id: "mock-fm-981", category: .fm, provenance: .nearby,
                frequencyMHz: 98.1, bandwidthMHz: 0.2, signalDBM: -40,
                label: "KQED", sublabel: "98.1 MHz",
                lastUpdated: .now, isActive: true
            ),
            Signal(
                id: "mock-fm-1015", category: .fm, provenance: .nearby,
                frequencyMHz: 101.5, bandwidthMHz: 0.2, signalDBM: -45,
                label: "KFOG", sublabel: "101.5 MHz",
                lastUpdated: .now, isActive: true
            ),
            Signal(
                id: "mock-iridium", category: .satellite, provenance: .nearby,
                frequencyMHz: 1621, bandwidthMHz: 10.5, signalDBM: -120,
                label: "Iridium", sublabel: "1621 MHz",
                lastUpdated: .now, isActive: true
            ),
        ])

        // ADS-B (probable — near airport)
        registry.setProbableSignals([
            Signal(
                id: "mock-adsb", category: .broadcast, provenance: .probable,
                frequencyMHz: 1090, bandwidthMHz: nil, signalDBM: nil,
                label: "ADS-B", sublabel: "Aircraft transponders",
                lastUpdated: .now, isActive: true
            ),
        ])
    }
}
#endif
