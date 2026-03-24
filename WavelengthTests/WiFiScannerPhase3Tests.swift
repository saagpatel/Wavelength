import Testing
import Foundation
@testable import Wavelength

struct WiFiScannerPhase3Tests {

    @Test func channelToFrequency_24GHz() {
        #expect(WiFiScanner.channelToFrequency(channel: 1) == 2412.0)
        #expect(WiFiScanner.channelToFrequency(channel: 6) == 2437.0)
        #expect(WiFiScanner.channelToFrequency(channel: 11) == 2462.0)
        #expect(WiFiScanner.channelToFrequency(channel: 14) == 2484.0)
    }

    @Test func channelToFrequency_5GHz() {
        #expect(WiFiScanner.channelToFrequency(channel: 36) == 5180.0)
        #expect(WiFiScanner.channelToFrequency(channel: 44) == 5220.0)
    }

    @Test func networkToSignalProducesValidSignal() {
        let signal = WiFiScanner.networkToSignal(
            ssid: "TestNetwork",
            bssid: "AA:BB:CC:DD:EE:FF",
            signalStrength: 0.5
        )
        #expect(signal.category == .wifi)
        #expect(signal.provenance == .live)
        #expect(signal.label == "TestNetwork")
        #expect(signal.id == "wifi-AA:BB:CC:DD:EE:FF")
        // 0.5 → -90 + 30 = -60 dBm
        #expect(signal.signalDBM == -60.0)
    }

    @Test func multipleNetworksHaveUniqueIDs() {
        let s1 = WiFiScanner.networkToSignal(ssid: "Net1", bssid: "AA:BB:CC:00:00:01", signalStrength: 0.8)
        let s2 = WiFiScanner.networkToSignal(ssid: "Net2", bssid: "AA:BB:CC:00:00:02", signalStrength: 0.3)
        #expect(s1.id != s2.id)
    }
}
