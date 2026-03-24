import Foundation

enum BandEdge: Sendable {
    case low, high, center
}

/// A named range of the electromagnetic spectrum.
struct FrequencyBand: Sendable {
    let lowMHz: Double
    let highMHz: Double
    let name: String
    let allocationSource: String

    /// Center frequency of this band in MHz.
    var centerMHz: Double { (lowMHz + highMHz) / 2.0 }

    /// Convert a frequency to log-scale Y position [0.0, 1.0]
    /// within the given frequency range.
    func logPosition(in range: ClosedRange<Double>, edge: BandEdge = .center) -> Double {
        guard range.lowerBound > 0, range.upperBound > range.lowerBound else { return 0 }
        let freq: Double = switch edge {
        case .low: lowMHz
        case .high: highMHz
        case .center: centerMHz
        }
        let logLow = log10(range.lowerBound)
        let logHigh = log10(range.upperBound)
        return (log10(max(freq, range.lowerBound)) - logLow) / (logHigh - logLow)
    }
}
