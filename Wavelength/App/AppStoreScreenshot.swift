#if DEBUG
import Foundation
import GRDB

/// Numbering matches APPSTORE-METADATA.md. This entire fixture path is Debug-only.
enum AppStoreScreenshot: Int, CaseIterable {
    case frequencyView = 1
    case displayControls = 2
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
    static func makeSettings() throws -> SettingsManager {
        // A fresh in-memory database avoids changing user settings or reading stale caches.
        let queue = try DatabaseQueue()
        var migrator = DatabaseMigrator()
        migrator.registerMigration("001_schema", migrate: Migration001_Schema.migrate)
        migrator.registerMigration("002_onboarding", migrate: Migration002_Onboarding.migrate)
        try migrator.migrate(queue)
        let settings = SettingsManager(dbQueue: queue)
        settings.colormap = .viridis
        settings.frequencyPreset = .full
        settings.privacyMode = true
        settings.showProbable = true
        settings.hasSeenOnboarding = true
        return settings
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
