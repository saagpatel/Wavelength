import Testing
import CoreTelephony
@testable import Wavelength

struct CellularMonitorTests {

    @Test func lookupLTE() {
        let (band, mhz) = CellularMonitor.lookupFrequency(radioTech: CTRadioAccessTechnologyLTE)
        #expect(band == "LTE")
        #expect(mhz == 1900)
    }

    @Test func lookup5GStandalone() {
        let (band, mhz) = CellularMonitor.lookupFrequency(radioTech: CTRadioAccessTechnologyNR)
        #expect(band == "5G SA")
        #expect(mhz >= 2500 && mhz <= 3800)
    }

    @Test func lookup5GNSA() {
        let (band, mhz) = CellularMonitor.lookupFrequency(radioTech: CTRadioAccessTechnologyNRNSA)
        #expect(band == "5G NSA")
        #expect(mhz == 2500)
    }

    @Test func lookupCDMA() {
        let (band, mhz) = CellularMonitor.lookupFrequency(radioTech: CTRadioAccessTechnologyCDMA1x)
        #expect(band == "CDMA")
        #expect(mhz == 850)
    }

    @Test func unknownTechReturnsDefault() {
        let (band, mhz) = CellularMonitor.lookupFrequency(radioTech: "SomeFutureTech")
        #expect(band == "Unknown")
        #expect(mhz == 1900)
    }
}
