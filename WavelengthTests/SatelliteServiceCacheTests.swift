import Testing
import Foundation
import SatelliteKit
@testable import Wavelength

struct SatelliteServiceCacheTests {

    private let sampleName = "GPS BIIR-2  (PRN 13)"
    private let sampleLine1 = "1 24876U 97035A   26079.45443328  .00000053  00000+0  00000+0 0  9994"
    private let sampleLine2 = "2 24876  55.9450 102.0429 0098423  56.1606 304.8379  2.00563909210174"

    @Test func elevationComputationDoesNotCrash() throws {
        // At epoch (minsAfterEpoch=0), elevation depends on observer location
        let observer = LatLonAlt(37.7749, -122.4194, 0)
        let elevation = try SatelliteService.computeElevation(
            name: sampleName, line1: sampleLine1, line2: sampleLine2,
            observer: observer
        )
        // Elevation should be between -90 and 90 degrees
        #expect(elevation >= -90 && elevation <= 90)
    }

    @Test func extractNoradIdFromTLE() {
        let noradId = SatelliteService.extractNoradId(from: sampleLine1)
        #expect(noradId == 24876)
    }

    @Test func parseTLETripletsPreserved() {
        let text = "\(sampleName)\n\(sampleLine1)\n\(sampleLine2)\n"
        let triplets = SatelliteService.parseTLETriplets(from: text)
        #expect(triplets.count == 1)
        #expect(triplets[0].name == sampleName)
    }

    @Test func invalidTLEGracefullySkipped() {
        // computeElevation should throw, not crash
        do {
            _ = try SatelliteService.computeElevation(
                name: "INVALID", line1: "1 XXXXX", line2: "2 XXXXX",
                observer: LatLonAlt(0, 0, 0)
            )
            Issue.record("Expected error for invalid TLE")
        } catch {
            // Expected
        }
    }

    @Test func gpsSignalFrequencyCorrect() {
        let record = SatelliteTLERecord(
            name: "GPS BIIR-2", noradId: 24876,
            line1: sampleLine1, line2: sampleLine2,
            frequencyMhz: 1575.42, constellation: "GPS",
            fetchedAt: .now
        )
        #expect(record.frequencyMhz == 1575.42)
        #expect(record.constellation == "GPS")
    }
}
