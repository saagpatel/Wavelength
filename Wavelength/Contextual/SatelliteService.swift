import Foundation
import Alamofire
import GRDB
import SatelliteKit
import os

/// Fetches satellite TLEs, caches in GRDB, and computes visibility from observer location.
actor SatelliteService {

    private let dbQueue: DatabaseQueue
    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "SatelliteService")

    private static let cacheTTL: TimeInterval = 24 * 3600
    private static let elevationThreshold: Double = 10.0

    private let constellations: [(url: String, name: String, freqMHz: Double)] = [
        ("https://celestrak.org/NORAD/elements/gp.php?GROUP=gps-ops&FORMAT=TLE", "GPS", 1575.42),
        ("https://celestrak.org/NORAD/elements/gp.php?GROUP=iridium-NEXT&FORMAT=TLE", "IRIDIUM", 1621.0),
    ]

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Fetch TLEs from CelesTrak if cache is stale (>24h). Stores in GRDB.
    func refreshTLEs() async throws {
        let cutoff = Date().addingTimeInterval(-Self.cacheTTL)
        let needsRefresh = try await dbQueue.read { db in
            let count = try SatelliteTLERecord
                .filter(Column("fetched_at") > cutoff)
                .fetchCount(db)
            return count == 0
        }

        guard needsRefresh else {
            logger.debug("TLE cache is fresh, skipping refresh")
            return
        }

        for constellation in constellations {
            do {
                try await fetchAndStore(
                    url: constellation.url,
                    constellationName: constellation.name,
                    frequencyMHz: constellation.freqMHz
                )
            } catch {
                logger.error("Failed to fetch \(constellation.name) TLEs: \(error.localizedDescription)")
            }
        }
    }

    /// Compute which satellites are visible (elevation >10°) from the observer.
    func visibleSatelliteSignals(
        observerLat: Double,
        observerLon: Double
    ) async throws -> [Signal] {
        let records = try await dbQueue.read { db in
            try SatelliteTLERecord.fetchAll(db)
        }

        let observer = LatLonAlt(observerLat, observerLon, 0)
        let now = Date()

        return records.compactMap { record -> Signal? in
            do {
                let elevation = try Self.computeElevation(
                    name: record.name, line1: record.line1, line2: record.line2,
                    observer: observer, at: now
                )
                guard elevation >= Self.elevationThreshold else { return nil }

                return Signal(
                    id: "sat-\(record.noradId)",
                    category: record.constellation == "GPS" ? .gps : .satellite,
                    provenance: .nearby,
                    frequencyMHz: record.frequencyMhz,
                    bandwidthMHz: record.constellation == "IRIDIUM" ? 10.5 : nil,
                    signalDBM: record.constellation == "GPS" ? -130 : -120,
                    label: "\(record.constellation) \(record.name.prefix(12))",
                    sublabel: String(format: "%.1f MHz, elev %.0f\u{00B0}", record.frequencyMhz, elevation),
                    lastUpdated: now,
                    isActive: true
                )
            } catch {
                return nil
            }
        }
    }

    // MARK: - Private

    private func fetchAndStore(url: String, constellationName: String, frequencyMHz: Double) async throws {
        let tleText = try await AF.request(url)
            .validate()
            .serializingString()
            .value

        let triplets = Self.parseTLETriplets(from: tleText)
        logger.info("Fetched \(triplets.count) \(constellationName) TLEs")

        try await dbQueue.write { db in
            for triplet in triplets {
                let noradId = Self.extractNoradId(from: triplet.line1)
                var record = SatelliteTLERecord(
                    name: triplet.name, noradId: noradId,
                    line1: triplet.line1, line2: triplet.line2,
                    frequencyMhz: frequencyMHz,
                    constellation: constellationName,
                    fetchedAt: Date()
                )
                try record.upsert(db)
            }
        }
    }

    // MARK: - Pure Static Functions (testable)

    /// Compute satellite elevation from observer location.
    nonisolated static func computeElevation(
        name: String, line1: String, line2: String,
        observer: LatLonAlt, at date: Date = Date()
    ) throws -> Double {
        let satellite = try Satellite(name, line1, line2)
        let topo = try satellite.topPosition(
            minsAfterEpoch: satellite.minsAfterEpoch,
            observer: observer
        )
        return topo.elev
    }

    /// Parse TLE text into triplets.
    nonisolated static func parseTLETriplets(
        from text: String
    ) -> [(name: String, line1: String, line2: String)] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var triplets: [(String, String, String)] = []
        var i = 0
        while i + 2 < lines.count {
            let name = lines[i]
            let line1 = lines[i + 1]
            let line2 = lines[i + 2]
            if line1.hasPrefix("1 ") && line2.hasPrefix("2 ") {
                triplets.append((name, line1, line2))
                i += 3
            } else {
                i += 1
            }
        }
        return triplets
    }

    /// Extract NORAD catalog number from TLE line 1 (chars 2-6).
    nonisolated static func extractNoradId(from line1: String) -> Int {
        let start = line1.index(line1.startIndex, offsetBy: 2)
        let end = line1.index(line1.startIndex, offsetBy: 7)
        return Int(line1[start..<end].trimmingCharacters(in: .whitespaces)) ?? 0
    }
}
