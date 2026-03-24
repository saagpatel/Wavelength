import Foundation

/// How a signal was detected. Determines visual treatment on spectrogram.
enum SignalProvenance: String, Codable, Sendable {
    case live       // Actively sensed by device hardware
    case nearby     // Confirmed present via database + GPS anchor
    case probable   // Inferred from location context heuristics
}

/// Broad category of a signal source.
enum SignalCategory: String, Codable, Sendable {
    case bluetooth, wifi, cellular, fm, gps, satellite, broadcast, emergency
}

/// A single electromagnetic signal for display on the spectrogram.
struct Signal: Identifiable, Sendable {
    let id: String
    let category: SignalCategory
    let provenance: SignalProvenance
    let frequencyMHz: Double
    let bandwidthMHz: Double?
    let signalDBM: Double?
    let label: String
    let sublabel: String?
    let lastUpdated: Date
    var isActive: Bool
}

extension Signal: Equatable {
    static func == (lhs: Signal, rhs: Signal) -> Bool { lhs.id == rhs.id }
}

extension Signal: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
