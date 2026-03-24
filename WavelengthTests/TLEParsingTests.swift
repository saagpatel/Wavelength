import Testing
import SatelliteKit
@testable import Wavelength

struct TLEParsingTests {

    // Known GPS satellite TLE (GPS BIIR-2, PRN 13)
    private let sampleName = "GPS BIIR-2  (PRN 13)"
    private let sampleLine1 = "1 24876U 97035A   26079.45443328  .00000053  00000+0  00000+0 0  9994"
    private let sampleLine2 = "2 24876  55.9450 102.0429 0098423  56.1606 304.8379  2.00563909210174"

    @Test func parseSingleTLETriplet() {
        let text = "\(sampleName)\n\(sampleLine1)\n\(sampleLine2)\n"
        let triplets = SatelliteService.parseTLETriplets(from: text)
        #expect(triplets.count == 1)
        #expect(triplets[0].name == sampleName)
        #expect(triplets[0].line1.hasPrefix("1 "))
        #expect(triplets[0].line2.hasPrefix("2 "))
    }

    @Test func parseMultipleTLETriplets() {
        let text = """
        \(sampleName)
        \(sampleLine1)
        \(sampleLine2)
        GPS BIIF-1  (PRN 25)
        1 36585U 10022A   26079.12345678  .00000012  00000+0  00000+0 0  9991
        2 36585  55.0123 200.1234 0056789 123.4567 234.5678  2.00563123456789
        """
        let triplets = SatelliteService.parseTLETriplets(from: text)
        #expect(triplets.count == 2)
    }

    @Test func satelliteKitConstructsFromTLE() throws {
        let sat = try Satellite(sampleName, sampleLine1, sampleLine2)
        #expect(sat.commonName.contains("GPS"))
        #expect(sat.noradIdent == "24876")
    }

    @Test func gpsAltitudeInExpectedRange() throws {
        let sat = try Satellite(sampleName, sampleLine1, sampleLine2)
        let geo = try sat.geoPosition(minsAfterEpoch: 0)
        let altitude = geo.alt
        // GPS orbital altitude: ~20,200 km (19,000 - 21,000 km range)
        #expect(altitude > 19_000, "GPS altitude \(altitude) km below 19,000 km")
        #expect(altitude < 21_000, "GPS altitude \(altitude) km above 21,000 km")
    }

    @Test func emptyInputReturnsNoTriplets() {
        let triplets = SatelliteService.parseTLETriplets(from: "")
        #expect(triplets.isEmpty)
    }

    @Test func malformedTLESkippedGracefully() {
        let text = """
        SATELLITE NAME
        This is not a TLE line
        Also not a TLE line
        """
        let triplets = SatelliteService.parseTLETriplets(from: text)
        #expect(triplets.isEmpty)
    }
}
