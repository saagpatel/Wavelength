import GRDB
import SwiftUI

/// Queries the bundled FCC spectrum allocation database.
struct FCCDatabase: Sendable {

    /// Query allocations that overlap the given frequency range.
    func allocations(
        freqMin: Double = 70.0,
        freqMax: Double = 6000.0,
        dbQueue: DatabaseQueue
    ) throws -> [FCCAllocationRecord] {
        try dbQueue.read { db in
            try FCCAllocationRecord.fetchAll(db, sql: """
                SELECT * FROM fcc_allocations
                WHERE freq_low_mhz <= ? AND freq_high_mhz >= ?
                ORDER BY freq_low_mhz
            """, arguments: [freqMax, freqMin])
        }
    }

    /// Convert allocations to FrequencyBand array, filtering out point frequencies.
    nonisolated static func toBands(_ allocations: [FCCAllocationRecord]) -> [FrequencyBand] {
        allocations
            .filter { $0.freqLowMhz != $0.freqHighMhz }
            .map { alloc in
                FrequencyBand(
                    lowMHz: alloc.freqLowMhz,
                    highMHz: alloc.freqHighMhz,
                    name: alloc.serviceName,
                    allocationSource: "FCC"
                )
            }
    }

    /// Map an allocation's service name to a display color.
    nonisolated static func colorFor(_ band: FrequencyBand) -> Color {
        let name = band.name.lowercased()
        if name.contains("fm") || (name.contains("broadcast") && name.contains("radio")) {
            return .blue
        } else if name.contains("cellular") || name.contains("lte") || name.contains("5g")
                    || name.contains("pcs") || name.contains("band") {
            return .green
        } else if name.contains("tv") || name.contains("broadcast") {
            return .orange
        } else if name.contains("wi-fi") || name.contains("unii") || name.contains("ism") {
            return .cyan
        } else if name.contains("gps") || name.contains("satellite") || name.contains("iridium") {
            return .purple
        } else if name.contains("aviation") || name.contains("noaa") || name.contains("emergency") {
            return .yellow
        }
        return .gray
    }
}
