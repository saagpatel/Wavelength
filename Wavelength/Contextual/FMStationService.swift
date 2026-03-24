import GRDB
import Foundation

/// Queries the bundled FM station database for nearby stations.
struct FMStationService: Sendable {

    private static let searchRadiusKm: Double = 80.0

    /// Query bundled fm_stations.sqlite for stations near the given location.
    func nearbyStations(
        lat: Double,
        lon: Double,
        dbQueue: DatabaseQueue
    ) throws -> [FMStationRecord] {
        let bbox = Self.computeBBOX(lat: lat, lon: lon, radiusKm: Self.searchRadiusKm)

        return try dbQueue.read { db in
            try FMStationRecord
                .filter(Column("latitude") >= bbox.latMin)
                .filter(Column("latitude") <= bbox.latMax)
                .filter(Column("longitude") >= bbox.lonMin)
                .filter(Column("longitude") <= bbox.lonMax)
                .order(Column("frequency_mhz"))
                .fetchAll(db)
        }
    }

    /// Convert FM station records to Signal array.
    nonisolated static func toSignals(_ stations: [FMStationRecord]) -> [Signal] {
        stations.map { station in
            Signal(
                id: "fm-\(station.callSign)-\(station.frequencyMhz)",
                category: .fm,
                provenance: .nearby,
                frequencyMHz: station.frequencyMhz,
                bandwidthMHz: 0.2,
                signalDBM: estimateSignalStrength(erpWatts: station.erpWatts),
                label: station.callSign,
                sublabel: String(format: "%.1f MHz", station.frequencyMhz)
                    + (station.city.map { " (\($0))" } ?? ""),
                lastUpdated: station.fetchedAt,
                isActive: true
            )
        }
    }

    /// Estimate received signal strength from transmitter ERP.
    nonisolated static func estimateSignalStrength(erpWatts: Int?) -> Double {
        guard let erp = erpWatts else { return -60 }
        switch erp {
        case 50_000...: return -35
        case 10_000..<50_000: return -45
        case 1_000..<10_000: return -55
        default: return -65
        }
    }

    nonisolated static func computeBBOX(
        lat: Double, lon: Double, radiusKm: Double
    ) -> (latMin: Double, lonMin: Double, latMax: Double, lonMax: Double) {
        let latDelta = radiusKm / 111.0
        let lonDelta = radiusKm / (111.0 * cos(lat * .pi / 180))
        return (lat - latDelta, lon - lonDelta, lat + latDelta, lon + lonDelta)
    }
}
