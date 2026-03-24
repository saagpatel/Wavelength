import Testing
import CoreBluetooth
@testable import Wavelength

struct BluetoothScannerTests {

    @Test func classifyHeadphones() {
        let uuids = [CBUUID(string: "1108")]
        #expect(BluetoothScanner.classifyDevice(serviceUUIDs: uuids) == "Headphones")
    }

    @Test func classifyWatch() {
        let uuids = [CBUUID(string: "1805")]
        #expect(BluetoothScanner.classifyDevice(serviceUUIDs: uuids) == "Watch")
    }

    @Test func classifyBeacon() {
        let uuids = [CBUUID(string: "FEAA")]
        #expect(BluetoothScanner.classifyDevice(serviceUUIDs: uuids) == "Beacon")
    }

    @Test func classifyNilReturnsUnknown() {
        #expect(BluetoothScanner.classifyDevice(serviceUUIDs: nil) == "Unknown")
    }

    @Test func classifyEmptyReturnsUnknown() {
        #expect(BluetoothScanner.classifyDevice(serviceUUIDs: []) == "Unknown")
    }

    @Test func classifyFirstMatchWins() {
        // Speaker UUID comes before Watch UUID in the switch
        let uuids = [CBUUID(string: "110B"), CBUUID(string: "1805")]
        #expect(BluetoothScanner.classifyDevice(serviceUUIDs: uuids) == "Speaker")
    }
}
