import Foundation
import os

@Observable
@MainActor
final class SignalRegistry {

    private(set) var liveSignals: [Signal] = []

    // Per-category storage prevents cross-source clobber
    // (e.g., satellite 30s timer won't wipe FM or tower data)
    private var nearbyByCategory: [SignalCategory: [Signal]] = [:]
    private var probableByCategory: [SignalCategory: [Signal]] = [:]

    var nearbySignals: [Signal] {
        nearbyByCategory.values.flatMap { $0 }
    }

    var probableSignals: [Signal] {
        probableByCategory.values.flatMap { $0 }
    }

    /// Whether to include probable signals in visible output.
    var showProbable: Bool = true

    var allSignals: [Signal] {
        Self.mergeAndSort(live: liveSignals, nearby: nearbySignals, probable: probableSignals)
    }

    /// Signals filtered by user settings (hides probable when toggled off).
    var visibleSignals: [Signal] {
        if showProbable {
            return allSignals
        }
        return Self.mergeAndSort(live: liveSignals, nearby: nearbySignals, probable: [])
    }

    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "SignalRegistry")

    func addLiveSignal(_ signal: Signal) {
        if let idx = liveSignals.firstIndex(where: { $0.id == signal.id }) {
            liveSignals[idx] = signal
        } else {
            liveSignals.append(signal)
        }
    }

    func removeLiveSignal(id: String) {
        liveSignals.removeAll { $0.id == id }
    }

    func expireStaleSignals(olderThan interval: TimeInterval = 30) {
        let cutoff = Date().addingTimeInterval(-interval)
        let expired = liveSignals.filter { $0.lastUpdated < cutoff }
        for signal in expired {
            logger.debug("Expiring stale signal: \(signal.id)")
        }
        liveSignals.removeAll { $0.lastUpdated < cutoff }
    }

    /// Replace nearby signals for a specific category without affecting other categories.
    func setNearbySignals(_ signals: [Signal], forCategory category: SignalCategory) {
        nearbyByCategory[category] = signals
    }

    /// Replace probable signals for a specific category without affecting other categories.
    func setProbableSignals(_ signals: [Signal], forCategory category: SignalCategory) {
        probableByCategory[category] = signals
    }

    /// Bulk replace all nearby signals (backward compat).
    func setNearbySignals(_ signals: [Signal]) {
        nearbyByCategory.removeAll()
        for signal in signals {
            nearbyByCategory[signal.category, default: []].append(signal)
        }
    }

    /// Bulk replace all probable signals (backward compat).
    func setProbableSignals(_ signals: [Signal]) {
        probableByCategory.removeAll()
        for signal in signals {
            probableByCategory[signal.category, default: []].append(signal)
        }
    }

    /// Clear all signals for a given category across all provenance tiers.
    func clearCategory(_ category: SignalCategory) {
        liveSignals.removeAll { $0.category == category }
        nearbyByCategory[category] = nil
        probableByCategory[category] = nil
    }

    nonisolated static func mergeAndSort(
        live: [Signal], nearby: [Signal], probable: [Signal]
    ) -> [Signal] {
        (live + nearby + probable).sorted { $0.frequencyMHz < $1.frequencyMHz }
    }
}
