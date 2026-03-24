import Testing
import Foundation
import GRDB
@testable import Wavelength

struct SettingsManagerTests {

    private func makeTestDB() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue()
        var migrator = DatabaseMigrator()
        migrator.registerMigration("001_schema", migrate: Migration001_Schema.migrate)
        migrator.registerMigration("002_onboarding", migrate: Migration002_Onboarding.migrate)
        try migrator.migrate(dbQueue)
        return dbQueue
    }

    @MainActor @Test func defaultSettings() throws {
        let db = try makeTestDB()
        let manager = SettingsManager(dbQueue: db)
        #expect(manager.colormap == .viridis)
        #expect(manager.frequencyRange == 70.0...6000.0)
        #expect(manager.showProbable == true)
        #expect(manager.privacyMode == true)
        #expect(manager.hasSeenOnboarding == false)
    }

    @MainActor @Test func colormapPersistence() throws {
        let db = try makeTestDB()
        let manager = SettingsManager(dbQueue: db)
        manager.colormap = .magma

        let manager2 = SettingsManager(dbQueue: db)
        #expect(manager2.colormap == .magma)
    }

    @MainActor @Test func frequencyRangePersistence() throws {
        let db = try makeTestDB()
        let manager = SettingsManager(dbQueue: db)
        manager.frequencyPreset = .broadcast

        let manager2 = SettingsManager(dbQueue: db)
        #expect(manager2.frequencyRange == 70.0...1000.0)
    }

    @MainActor @Test func showProbablePersistence() throws {
        let db = try makeTestDB()
        let manager = SettingsManager(dbQueue: db)
        manager.showProbable = false

        let manager2 = SettingsManager(dbQueue: db)
        #expect(manager2.showProbable == false)
    }

    @MainActor @Test func privacyModePersistence() throws {
        let db = try makeTestDB()
        let manager = SettingsManager(dbQueue: db)
        manager.privacyMode = false

        let manager2 = SettingsManager(dbQueue: db)
        #expect(manager2.privacyMode == false)
    }

    @MainActor @Test func hasSeenOnboardingPersistence() throws {
        let db = try makeTestDB()
        let manager = SettingsManager(dbQueue: db)
        manager.hasSeenOnboarding = true

        let manager2 = SettingsManager(dbQueue: db)
        #expect(manager2.hasSeenOnboarding == true)
    }

    @MainActor @Test func clearCacheEmptiesTables() throws {
        let db = try makeTestDB()

        // Insert test data
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO cell_towers (mcc, mnc, lac, cell_id, latitude, longitude, frequency_mhz, band_name)
                VALUES (310, 260, 1, 1, 37.0, -122.0, 700.0, 'Band 12')
            """)
            try db.execute(sql: """
                INSERT INTO satellite_tles (name, norad_id, line1, line2, frequency_mhz, constellation)
                VALUES ('GPS-01', 25933, '1 25933U', '2 25933', 1575.42, 'GPS')
            """)
        }

        let manager = SettingsManager(dbQueue: db)
        try manager.clearCache()

        let stats = try manager.cacheStats()
        #expect(stats.towerCount == 0)
        #expect(stats.fmCount == 0)
        #expect(stats.satelliteCount == 0)
    }

    @MainActor @Test func cacheStatsReturnsAccurateCounts() throws {
        let db = try makeTestDB()

        try db.write { db in
            try db.execute(sql: """
                INSERT INTO cell_towers (mcc, mnc, lac, cell_id, latitude, longitude, frequency_mhz, band_name)
                VALUES (310, 260, 1, 1, 37.0, -122.0, 700.0, 'Band 12')
            """)
            try db.execute(sql: """
                INSERT INTO cell_towers (mcc, mnc, lac, cell_id, latitude, longitude, frequency_mhz, band_name)
                VALUES (310, 260, 1, 2, 37.1, -122.1, 1900.0, 'Band 2')
            """)
        }

        let manager = SettingsManager(dbQueue: db)
        let stats = try manager.cacheStats()
        #expect(stats.towerCount == 2)
        #expect(stats.fmCount == 0)
        #expect(stats.satelliteCount == 0)
    }
}
