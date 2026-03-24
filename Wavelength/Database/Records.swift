import GRDB
import Foundation

// MARK: - CellTowerRecord

struct CellTowerRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "cell_towers"

    var id: Int64?
    var mcc: Int
    var mnc: Int
    var lac: Int
    var cellId: Int
    var latitude: Double
    var longitude: Double
    var frequencyMhz: Double
    var bandName: String
    var operatorName: String?
    var signalDbm: Int?
    var fetchedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, mcc, mnc, lac
        case cellId = "cell_id"
        case latitude, longitude
        case frequencyMhz = "frequency_mhz"
        case bandName = "band_name"
        case operatorName = "operator_name"
        case signalDbm = "signal_dbm"
        case fetchedAt = "fetched_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - SatelliteTLERecord

struct SatelliteTLERecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "satellite_tles"

    var id: Int64?
    var name: String
    var noradId: Int
    var line1: String
    var line2: String
    var frequencyMhz: Double
    var constellation: String
    var fetchedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case noradId = "norad_id"
        case line1, line2
        case frequencyMhz = "frequency_mhz"
        case constellation
        case fetchedAt = "fetched_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - FMStationRecord

struct FMStationRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "fm_stations"

    var id: Int64?
    var callSign: String
    var frequencyMhz: Double
    var latitude: Double
    var longitude: Double
    var erpWatts: Int?
    var city: String?
    var fetchedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case callSign = "call_sign"
        case frequencyMhz = "frequency_mhz"
        case latitude, longitude
        case erpWatts = "erp_watts"
        case city
        case fetchedAt = "fetched_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - FCCAllocationRecord (read-only from bundled DB)

struct FCCAllocationRecord: Codable, FetchableRecord, TableRecord, Sendable {
    static let databaseTableName = "fcc_allocations"

    let id: Int64
    let freqLowMhz: Double
    let freqHighMhz: Double
    let serviceName: String
    let allocationType: String
    let ituRegion: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case freqLowMhz = "freq_low_mhz"
        case freqHighMhz = "freq_high_mhz"
        case serviceName = "service_name"
        case allocationType = "allocation_type"
        case ituRegion = "itu_region"
        case notes
    }
}
