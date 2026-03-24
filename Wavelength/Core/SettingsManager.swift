import Foundation
import GRDB
import simd
import os

/// Which colormap to use for the spectrogram.
enum Colormap: String, Sendable, CaseIterable, Identifiable {
    case viridis
    case magma

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .viridis: "Viridis"
        case .magma: "Magma"
        }
    }

    var lutData: [SIMD4<Float>] {
        switch self {
        case .viridis: ColormapData.viridisLUT
        case .magma: ColormapData.magmaLUT
        }
    }
}

/// Predefined frequency range presets.
enum FrequencyPreset: String, Sendable, CaseIterable, Identifiable {
    case full
    case broadcast
    case mobile

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .full: "Full (70–6000 MHz)"
        case .broadcast: "Broadcast (70–1000 MHz)"
        case .mobile: "Mobile (700–6000 MHz)"
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .full: 70.0...6000.0
        case .broadcast: 70.0...1000.0
        case .mobile: 700.0...6000.0
        }
    }

    static func from(low: Double, high: Double) -> FrequencyPreset {
        for preset in allCases {
            if abs(preset.range.lowerBound - low) < 1 && abs(preset.range.upperBound - high) < 1 {
                return preset
            }
        }
        return .full
    }
}

/// Cache statistics for display in settings.
struct CacheStats: Sendable {
    let towerCount: Int
    let fmCount: Int
    let satelliteCount: Int
    let oldestFetchedAt: Date?
}

/// Central settings store. Reads from GRDB on init, writes back on property change.
@Observable
@MainActor
final class SettingsManager {

    private let dbQueue: DatabaseQueue
    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "Settings")

    // Suppress observation tracking for didSet-triggered DB writes
    private var _colormap: Colormap = .viridis
    var colormap: Colormap {
        get { _colormap }
        set {
            _colormap = newValue
            persistString("colormap", value: newValue.rawValue)
        }
    }

    private var _frequencyRange: ClosedRange<Double> = 70.0...6000.0
    var frequencyRange: ClosedRange<Double> {
        get { _frequencyRange }
        set {
            _frequencyRange = newValue
            persistRange(newValue)
        }
    }

    private var _showProbable: Bool = true
    var showProbable: Bool {
        get { _showProbable }
        set {
            _showProbable = newValue
            persistInt("show_probable", value: newValue ? 1 : 0)
        }
    }

    private var _privacyMode: Bool = true
    var privacyMode: Bool {
        get { _privacyMode }
        set {
            _privacyMode = newValue
            persistInt("privacy_mode", value: newValue ? 1 : 0)
        }
    }

    private var _hasSeenOnboarding: Bool = false
    var hasSeenOnboarding: Bool {
        get { _hasSeenOnboarding }
        set {
            _hasSeenOnboarding = newValue
            persistInt("has_seen_onboarding", value: newValue ? 1 : 0)
        }
    }

    var frequencyPreset: FrequencyPreset {
        get { FrequencyPreset.from(low: frequencyRange.lowerBound, high: frequencyRange.upperBound) }
        set { frequencyRange = newValue.range }
    }

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
        loadFromDB()
    }

    // MARK: - Cache Management

    func cacheStats() throws -> CacheStats {
        try dbQueue.read { db in
            let towerCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM cell_towers") ?? 0
            let fmCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM fm_stations") ?? 0
            let satelliteCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM satellite_tles") ?? 0
            let oldest = try Date.fetchOne(db, sql: """
                SELECT MIN(fetched_at) FROM (
                    SELECT fetched_at FROM cell_towers
                    UNION ALL SELECT fetched_at FROM fm_stations
                    UNION ALL SELECT fetched_at FROM satellite_tles
                )
            """)
            return CacheStats(
                towerCount: towerCount,
                fmCount: fmCount,
                satelliteCount: satelliteCount,
                oldestFetchedAt: oldest
            )
        }
    }

    func clearCache() throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM cell_towers")
            try db.execute(sql: "DELETE FROM fm_stations")
            try db.execute(sql: "DELETE FROM satellite_tles")
        }
        logger.info("Cache cleared")
    }

    // MARK: - Private

    private func loadFromDB() {
        do {
            try dbQueue.read { [self] db in
                guard let row = try Row.fetchOne(db, sql: "SELECT * FROM settings WHERE id = 1") else {
                    return
                }
                let colormapStr: String = row["colormap"]
                _colormap = Colormap(rawValue: colormapStr) ?? .viridis
                let low: Double = row["freq_low_mhz"]
                let high: Double = row["freq_high_mhz"]
                _frequencyRange = low...high
                let showProbableInt: Int = row["show_probable"]
                _showProbable = showProbableInt != 0
                let privacyInt: Int = row["privacy_mode"]
                _privacyMode = privacyInt != 0
                let onboardingInt: Int = row["has_seen_onboarding"]
                _hasSeenOnboarding = onboardingInt != 0
            }
        } catch {
            logger.error("Failed to load settings: \(error.localizedDescription)")
        }
    }

    private func persistString(_ column: String, value: String) {
        do {
            try dbQueue.write { db in
                try db.execute(
                    sql: "UPDATE settings SET \(column) = ?, updated_at = CURRENT_TIMESTAMP WHERE id = 1",
                    arguments: [value]
                )
            }
        } catch {
            logger.error("Failed to persist \(column): \(error.localizedDescription)")
        }
    }

    private func persistInt(_ column: String, value: Int) {
        do {
            try dbQueue.write { db in
                try db.execute(
                    sql: "UPDATE settings SET \(column) = ?, updated_at = CURRENT_TIMESTAMP WHERE id = 1",
                    arguments: [value]
                )
            }
        } catch {
            logger.error("Failed to persist \(column): \(error.localizedDescription)")
        }
    }

    private func persistRange(_ range: ClosedRange<Double>) {
        do {
            try dbQueue.write { db in
                try db.execute(
                    sql: "UPDATE settings SET freq_low_mhz = ?, freq_high_mhz = ?, updated_at = CURRENT_TIMESTAMP WHERE id = 1",
                    arguments: [range.lowerBound, range.upperBound]
                )
            }
        } catch {
            logger.error("Failed to persist freq range: \(error.localizedDescription)")
        }
    }
}
