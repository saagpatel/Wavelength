import Foundation
import Alamofire
import GRDB

// MARK: - OpenCellID Area Response Types

struct OpenCellIDAreaResponse: Decodable, Sendable {
    let count: Int
    let cells: [OpenCellIDCell]
}

struct OpenCellIDCell: Decodable, Sendable {
    let lat: Double
    let lon: Double
    let mcc: Int
    let mnc: Int
    let lac: Int
    let cellid: Int
    let radio: String?
    let range: Int?
    let samples: Int?
    let averageSignalStrength: Int?
}

/// Kept for backward compatibility with Phase 0 tests.
struct OpenCellIDResponse: Decodable, Sendable {
    let lat: Double
    let lon: Double
    let mcc: Int
    let mnc: Int
    let lac: Int
    let cellid: Int
    let averageSignalStrength: Int?
    let range: Int?
    let status: String
}

// MARK: - CellTowerService

/// Fetches nearby cell towers from OpenCellID and caches in GRDB.
actor CellTowerService {

    private let apiKey: String
    private let dbQueue: DatabaseQueue
    private let baseURL = "https://opencellid.org/cell/getInArea"
    private static let cacheTTL: TimeInterval = 7 * 24 * 3600
    private static let searchRadiusKm: Double = 5.0

    init(apiKey: String, dbQueue: DatabaseQueue) {
        self.apiKey = apiKey
        self.dbQueue = dbQueue
    }

    /// Fetch towers near a GPS coordinate, using cache when available.
    func fetchNearbyTowers(lat: Double, lon: Double) async throws -> [CellTowerRecord] {
        let cached = try await cachedTowers(lat: lat, lon: lon)
        if !cached.isEmpty { return cached }

        let bbox = Self.computeBBOX(lat: lat, lon: lon, radiusKm: Self.searchRadiusKm)
        let response = try await fetchFromAPI(bbox: bbox)

        try await upsertTowers(response.cells, lat: lat, lon: lon)

        return try await cachedTowers(lat: lat, lon: lon)
    }

    private func cachedTowers(lat: Double, lon: Double) async throws -> [CellTowerRecord] {
        let cutoff = Date().addingTimeInterval(-Self.cacheTTL)
        let bbox = Self.computeBBOX(lat: lat, lon: lon, radiusKm: Self.searchRadiusKm)

        return try await dbQueue.read { db in
            try CellTowerRecord
                .filter(Column("latitude") >= bbox.latMin)
                .filter(Column("latitude") <= bbox.latMax)
                .filter(Column("longitude") >= bbox.lonMin)
                .filter(Column("longitude") <= bbox.lonMax)
                .filter(Column("fetched_at") > cutoff)
                .fetchAll(db)
        }
    }

    private func fetchFromAPI(
        bbox: (latMin: Double, lonMin: Double, latMax: Double, lonMax: Double)
    ) async throws -> OpenCellIDAreaResponse {
        let parameters: Parameters = [
            "key": apiKey,
            "BBOX": "\(bbox.latMin),\(bbox.lonMin),\(bbox.latMax),\(bbox.lonMax)",
            "radio": "LTE",
            "limit": 50,
            "format": "json"
        ]
        return try await AF.request(baseURL, parameters: parameters)
            .validate()
            .serializingDecodable(OpenCellIDAreaResponse.self)
            .value
    }

    private func upsertTowers(_ cells: [OpenCellIDCell], lat: Double, lon: Double) async throws {
        try await dbQueue.write { db in
            for cell in cells {
                let (bandName, freqMhz) = Self.radioToFrequency(cell.radio)
                var record = CellTowerRecord(
                    mcc: cell.mcc, mnc: cell.mnc, lac: cell.lac, cellId: cell.cellid,
                    latitude: cell.lat, longitude: cell.lon,
                    frequencyMhz: freqMhz, bandName: bandName,
                    operatorName: nil, signalDbm: cell.averageSignalStrength,
                    fetchedAt: Date()
                )
                try record.upsert(db)
            }
        }
    }

    /// Compute a bounding box around a GPS coordinate.
    nonisolated static func computeBBOX(
        lat: Double, lon: Double, radiusKm: Double
    ) -> (latMin: Double, lonMin: Double, latMax: Double, lonMax: Double) {
        let latDelta = radiusKm / 111.0
        let lonDelta = radiusKm / (111.0 * cos(lat * .pi / 180))
        return (lat - latDelta, lon - lonDelta, lat + latDelta, lon + lonDelta)
    }

    /// Map radio access technology string to band name and frequency.
    nonisolated static func radioToFrequency(_ radio: String?) -> (band: String, mhz: Double) {
        switch radio?.uppercased() {
        case "LTE": return ("LTE", 1900)
        case "NR": return ("5G NR", 3500)
        case "UMTS": return ("WCDMA", 1900)
        case "GSM": return ("GSM", 900)
        case "CDMA": return ("CDMA", 850)
        default: return ("Unknown", 1900)
        }
    }

    /// Convert tower records to Signal array.
    nonisolated static func toSignals(_ towers: [CellTowerRecord]) -> [Signal] {
        towers.map { tower in
            Signal(
                id: "tower-\(tower.mcc)-\(tower.mnc)-\(tower.lac)-\(tower.cellId)",
                category: .cellular,
                provenance: .nearby,
                frequencyMHz: tower.frequencyMhz,
                bandwidthMHz: nil,
                signalDBM: tower.signalDbm.map(Double.init),
                label: tower.bandName,
                sublabel: "\(tower.mcc)/\(tower.mnc)",
                lastUpdated: tower.fetchedAt,
                isActive: true
            )
        }
    }
}
