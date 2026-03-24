import Testing
@testable import Wavelength

struct FrequencyBandTests {

    private let displayRange: ClosedRange<Double> = 70.0...6000.0

    @Test func fmBandPositionIsInLowerRegion() {
        let fm = FrequencyBand(lowMHz: 88.0, highMHz: 108.0,
                               name: "FM Broadcast", allocationSource: "FCC")
        let pos = fm.logPosition(in: displayRange)
        // log10(98) ≈ 1.991, expected ≈ 0.076
        #expect(pos > 0.05 && pos < 0.15)
    }

    @Test func gpsL1PositionIsInUpperHalf() {
        let gps = FrequencyBand(lowMHz: 1575.42, highMHz: 1575.42,
                                name: "GPS L1", allocationSource: "FCC")
        let pos = gps.logPosition(in: displayRange)
        // log10(1575.42) ≈ 3.197, expected ≈ 0.699
        #expect(pos > 0.65 && pos < 0.75)
    }

    @Test func wifi24PositionIsInUpperRange() {
        let wifi = FrequencyBand(lowMHz: 2400.0, highMHz: 2483.5,
                                 name: "Wi-Fi 2.4 GHz", allocationSource: "FCC")
        let pos = wifi.logPosition(in: displayRange)
        // log10(2441.75) ≈ 3.388, expected ≈ 0.798
        #expect(pos > 0.75 && pos < 0.85)
    }

    @Test func wifi5GHzPositionNearTop() {
        let wifi5 = FrequencyBand(lowMHz: 5150.0, highMHz: 5850.0,
                                  name: "Wi-Fi 5 GHz", allocationSource: "FCC")
        let pos = wifi5.logPosition(in: displayRange)
        // log10(5500) ≈ 3.740, expected ≈ 0.980
        #expect(pos > 0.95 && pos < 1.0)
    }

    @Test func invalidRangeReturnsZero() {
        let band = FrequencyBand(lowMHz: 100, highMHz: 200,
                                 name: "Test", allocationSource: "Test")
        #expect(band.logPosition(in: 0.0...100.0) == 0)
        #expect(band.logPosition(in: 100.0...100.0) == 0)
    }

    @Test func centerFrequencyIsCorrect() {
        let band = FrequencyBand(lowMHz: 88.0, highMHz: 108.0,
                                 name: "FM", allocationSource: "FCC")
        #expect(band.centerMHz == 98.0)
    }
}
