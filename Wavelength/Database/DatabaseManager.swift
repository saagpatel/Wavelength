import GRDB
import Foundation

/// Manages the application's SQLite databases.
/// The runtime database stores caches and settings.
/// The bundled FCC and FM databases provide read-only reference data.
struct DatabaseManager: Sendable {

    /// The runtime database for caches, settings, and signal history.
    let dbQueue: DatabaseQueue

    /// Opens (or creates) the runtime database and runs all pending migrations.
    static func makeDefault() throws -> DatabaseManager {
        let url = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask,
                 appropriateFor: nil, create: true)
            .appendingPathComponent("wavelength.db")

        var configuration = Configuration()
        configuration.foreignKeysEnabled = true

        let dbQueue = try DatabaseQueue(path: url.path(), configuration: configuration)

        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("001_schema", migrate: Migration001_Schema.migrate)
        migrator.registerMigration("002_onboarding", migrate: Migration002_Onboarding.migrate)
        try migrator.migrate(dbQueue)

        return DatabaseManager(dbQueue: dbQueue)
    }

    /// Opens the bundled read-only FCC spectrum allocation database.
    static func openBundledFCCDatabase() throws -> DatabaseQueue? {
        guard let path = Bundle.main.path(forResource: "fcc_spectrum", ofType: "sqlite") else {
            return nil
        }
        var configuration = Configuration()
        configuration.readonly = true
        return try DatabaseQueue(path: path, configuration: configuration)
    }

    /// Opens the bundled read-only FM station database.
    static func openBundledFMDatabase() throws -> DatabaseQueue? {
        guard let path = Bundle.main.path(forResource: "fm_stations", ofType: "sqlite") else {
            return nil
        }
        var configuration = Configuration()
        configuration.readonly = true
        return try DatabaseQueue(path: path, configuration: configuration)
    }
}
