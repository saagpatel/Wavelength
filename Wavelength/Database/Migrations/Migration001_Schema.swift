import GRDB

enum Migration001_Schema {
    static func migrate(_ db: Database) throws {
        // 1. Cell towers cache (OpenCellID)
        try db.create(table: "cell_towers") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("mcc", .integer).notNull()
            t.column("mnc", .integer).notNull()
            t.column("lac", .integer).notNull()
            t.column("cell_id", .integer).notNull()
            t.column("latitude", .double).notNull()
            t.column("longitude", .double).notNull()
            t.column("frequency_mhz", .double).notNull()
            t.column("band_name", .text).notNull()
            t.column("operator_name", .text)
            t.column("signal_dbm", .integer)
            t.column("fetched_at", .datetime)
                .notNull()
                .defaults(sql: "CURRENT_TIMESTAMP")
            t.uniqueKey(["mcc", "mnc", "lac", "cell_id"])
        }
        try db.create(index: "idx_towers_location",
                      on: "cell_towers", columns: ["latitude", "longitude"])
        try db.create(index: "idx_towers_fetched",
                      on: "cell_towers", columns: ["fetched_at"])

        // 2. Satellite TLEs cache (CelesTrak)
        try db.create(table: "satellite_tles") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("name", .text).notNull()
            t.column("norad_id", .integer).notNull().unique()
            t.column("line1", .text).notNull()
            t.column("line2", .text).notNull()
            t.column("frequency_mhz", .double).notNull()
            t.column("constellation", .text).notNull()
            t.column("fetched_at", .datetime)
                .notNull()
                .defaults(sql: "CURRENT_TIMESTAMP")
        }

        // 3. FM stations cache (FCC FM Query)
        try db.create(table: "fm_stations") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("call_sign", .text).notNull()
            t.column("frequency_mhz", .double).notNull()
            t.column("latitude", .double).notNull()
            t.column("longitude", .double).notNull()
            t.column("erp_watts", .integer)
            t.column("city", .text)
            t.column("fetched_at", .datetime)
                .notNull()
                .defaults(sql: "CURRENT_TIMESTAMP")
        }
        try db.create(index: "idx_fm_location",
                      on: "fm_stations", columns: ["latitude", "longitude"])

        // 4. FCC allocations (schema marker — actual data in bundled fcc_spectrum.sqlite)
        try db.create(table: "fcc_allocations") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("freq_low_mhz", .double).notNull()
            t.column("freq_high_mhz", .double).notNull()
            t.column("service_name", .text).notNull()
            t.column("allocation_type", .text).notNull()
            t.column("itu_region", .text)
            t.column("notes", .text)
        }
        try db.create(index: "idx_alloc_freq",
                      on: "fcc_allocations", columns: ["freq_low_mhz", "freq_high_mhz"])

        // 5. Settings (single-row enforced by CHECK constraint)
        try db.execute(sql: """
            CREATE TABLE settings (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                colormap TEXT NOT NULL DEFAULT 'viridis',
                freq_low_mhz REAL NOT NULL DEFAULT 70.0,
                freq_high_mhz REAL NOT NULL DEFAULT 6000.0,
                show_probable INTEGER NOT NULL DEFAULT 1,
                privacy_mode INTEGER NOT NULL DEFAULT 1,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
        try db.execute(sql: "INSERT INTO settings (id) VALUES (1)")

        // 6. Signal history (rolling 24h log, v2 feature)
        try db.create(table: "signal_history") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("signal_id", .text).notNull()
            t.column("provenance", .text).notNull()
            t.column("frequency_mhz", .double).notNull()
            t.column("signal_dbm", .double)
            t.column("latitude", .double)
            t.column("longitude", .double)
            t.column("recorded_at", .datetime)
                .notNull()
                .defaults(sql: "CURRENT_TIMESTAMP")
        }
        try db.create(index: "idx_history_time",
                      on: "signal_history", columns: ["recorded_at"])
        try db.create(index: "idx_history_signal",
                      on: "signal_history", columns: ["signal_id", "recorded_at"])
    }
}
