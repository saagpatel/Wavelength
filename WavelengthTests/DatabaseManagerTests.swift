import Testing
import GRDB
@testable import Wavelength

struct DatabaseManagerTests {

    private func makeTestDatabase() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue()
        var migrator = DatabaseMigrator()
        migrator.registerMigration("001_schema", migrate: Migration001_Schema.migrate)
        try migrator.migrate(dbQueue)
        return dbQueue
    }

    @Test func migrationCreatesAllSixTables() throws {
        let db = try makeTestDatabase()
        let tables = try db.read { db in
            try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name != 'grdb_migrations'
                ORDER BY name
            """)
        }
        #expect(tables == [
            "cell_towers", "fcc_allocations", "fm_stations",
            "settings", "signal_history", "satellite_tles"
        ].sorted())
    }

    @Test func cellTowersUniqueConstraintRejectsDuplicate() throws {
        let db = try makeTestDatabase()
        let insertSQL = """
            INSERT INTO cell_towers (mcc, mnc, lac, cell_id, latitude, longitude, frequency_mhz, band_name)
            VALUES (310, 260, 7001, 7241401, 37.7749, -122.4194, 700.0, 'Band 12')
        """
        try db.write { db in
            try db.execute(sql: insertSQL)
        }
        do {
            try db.write { db in
                try db.execute(sql: insertSQL)
            }
            Issue.record("Expected UNIQUE constraint violation")
        } catch {
            // Expected
        }
    }

    @Test func settingsSingleRowConstraintRejectsSecondRow() throws {
        let db = try makeTestDatabase()
        let count = try db.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM settings")
        }
        #expect(count == 1)

        do {
            try db.write { db in
                try db.execute(sql: "INSERT INTO settings (id) VALUES (2)")
            }
            Issue.record("Expected CHECK constraint violation")
        } catch {
            // Expected
        }
    }

    @Test func settingsDefaultValuesAreCorrect() throws {
        let db = try makeTestDatabase()
        let row = try db.read { db in
            try Row.fetchOne(db, sql: "SELECT * FROM settings WHERE id = 1")
        }
        #expect(row != nil)
        #expect(row?["colormap"] as String? == "viridis")
        #expect(row?["freq_low_mhz"] as Double? == 70.0)
        #expect(row?["freq_high_mhz"] as Double? == 6000.0)
        #expect(row?["show_probable"] as Int? == 1)
        #expect(row?["privacy_mode"] as Int? == 1)
    }

    @Test func fccAllocationsFrequencyRangeQuery() throws {
        let db = try makeTestDatabase()
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO fcc_allocations (freq_low_mhz, freq_high_mhz, service_name, allocation_type)
                VALUES (88.0, 108.0, 'FM Broadcasting', 'PRIMARY')
            """)
        }
        let rows = try db.read { db in
            try Row.fetchAll(db, sql: """
                SELECT * FROM fcc_allocations
                WHERE freq_low_mhz <= 98.1 AND freq_high_mhz >= 98.1
            """)
        }
        #expect(rows.count == 1)
        #expect(rows[0]["service_name"] as String? == "FM Broadcasting")
    }

    @Test func signalHistoryIndexesExist() throws {
        let db = try makeTestDatabase()
        let indexes = try db.read { db in
            try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'signal_history'
            """)
        }
        #expect(indexes.contains("idx_history_time"))
        #expect(indexes.contains("idx_history_signal"))
    }
}
