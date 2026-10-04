#if DEBUG
import Foundation
import GRDB

/// Numbering matches APPSTORE-METADATA.md. This entire fixture path is Debug-only.
enum AppStoreScreenshot: Int, CaseIterable {
    case frequencyView = 1
    case mobileView = 2
    case bluetoothDetails = 3

    static let fixtureDate = Date(timeIntervalSince1970: 1_704_067_200)

    static func requested(in arguments: [String] = ProcessInfo.processInfo.arguments) throws -> Self? {
        guard let index = arguments.firstIndex(of: "-AppStoreScreenshot") else { return nil }
        guard arguments.indices.contains(index + 1),
              let number = Int(arguments[index + 1]),
              let shot = Self(rawValue: number) else {
            throw ScreenshotError.invalidArgument
        }
        return shot
    }

    @MainActor
    func makeSettings() throws -> SettingsManager {
        // A fresh in-memory database avoids changing user settings or reading stale caches.
        let queue = try DatabaseQueue()
        var migrator = DatabaseMigrator()
        migrator.registerMigration("001_schema", migrate: Migration001_Schema.migrate)
        migrator.registerMigration("002_onboarding", migrate: Migration002_Onboarding.migrate)
        try migrator.migrate(queue)
        let settings = SettingsManager(dbQueue: queue)
        settings.colormap = self == .mobileView ? .magma : .viridis
        // Full is the only existing preset that includes both FM and Bluetooth.
        settings.frequencyPreset = self == .mobileView ? .mobile : .full
        settings.privacyMode = true
        settings.showProbable = true
        settings.hasSeenOnboarding = true
        return settings
    }

    @MainActor
    static func populateRegistry(_ registry: SignalRegistry, frequencyRange: ClosedRange<Double>) {
        registry.addLiveSignal(Signal(
            id: "screenshot-ble", category: .bluetooth, provenance: .live,
            frequencyMHz: 2441, bandwidthMHz: 78, signalDBM: -38,
            label: "Bluetooth", sublabel: "BLE 2.4 GHz",
            lastUpdated: fixtureDate, isActive: true
        ))

        // Reference entries have no measured power. The normal renderer supplies
        // its default reference amplitude, keeping GPS/Iridium visible without
        // inventing implausibly strong satellite reception or live cellular scans.
        registry.setNearbySignals([
            Signal(
                id: "screenshot-fm", category: .fm, provenance: .nearby,
                frequencyMHz: 98.1, bandwidthMHz: 0.2, signalDBM: nil,
                label: "FM 98.1", sublabel: "FM reference",
                lastUpdated: fixtureDate, isActive: true
            ),
            Signal(
                id: "screenshot-lte", category: .cellular, provenance: .nearby,
                frequencyMHz: 750, bandwidthMHz: 10, signalDBM: nil,
                label: "LTE ref", sublabel: "750 MHz reference",
                lastUpdated: fixtureDate, isActive: true
            ),
            Signal(
                id: "screenshot-gps", category: .gps, provenance: .nearby,
                frequencyMHz: 1575.42, bandwidthMHz: 2, signalDBM: nil,
                label: "GPS L1 ref", sublabel: "1575.42 MHz reference",
                lastUpdated: fixtureDate, isActive: true
            ),
            Signal(
                id: "screenshot-iridium", category: .satellite, provenance: .nearby,
                frequencyMHz: 1621, bandwidthMHz: 10.5, signalDBM: nil,
                label: "Iridium ref", sublabel: "1621 MHz reference",
                lastUpdated: fixtureDate, isActive: true
            ),
            Signal(
                id: "screenshot-5g", category: .cellular, provenance: .nearby,
                frequencyMHz: 3500, bandwidthMHz: 100, signalDBM: nil,
                label: "5G ref", sublabel: "3500 MHz reference",
                lastUpdated: fixtureDate, isActive: true
            ),
        ].filter { frequencyRange.contains($0.frequencyMHz) })
        registry.setProbableSignals([
            Signal(
                id: "screenshot-adsb", category: .broadcast, provenance: .probable,
                frequencyMHz: 1090, bandwidthMHz: nil, signalDBM: nil,
                label: "ADS-B", sublabel: "Aircraft transponders",
                lastUpdated: fixtureDate, isActive: true
            ),
        ])
    }

    enum ScreenshotError: LocalizedError {
        case invalidArgument
        case missingAllocations
        case renderingFailed

        var errorDescription: String? {
            switch self {
            case .invalidArgument: "-AppStoreScreenshot requires a number from 1 through 3."
            case .missingAllocations: "Screenshot fixtures require the bundled FCC allocations."
            case .renderingFailed: "Could not prepare the fixed screenshot spectrogram."
            }
        }
    }
}
#endif
