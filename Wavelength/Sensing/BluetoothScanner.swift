import CoreBluetooth
import os

@Observable
@MainActor
final class BluetoothScanner: NSObject, CBCentralManagerDelegate {

    private(set) var isScanning = false
    private(set) var discoveredDevices: [String: BLEDevice] = [:]

    /// When true, hides advertised device names from display.
    var privacyMode: Bool = true

    private var centralManager: CBCentralManager!
    private let signalRegistry: SignalRegistry
    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "BluetoothScanner")

    init(signalRegistry: SignalRegistry) {
        self.signalRegistry = signalRegistry
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            logger.info("BT not powered on, deferring scan")
            return
        }
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        isScanning = true
        logger.info("BLE scanning started")
    }

    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }

    // MARK: - CBCentralManagerDelegate

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        MainActor.assumeIsolated {
            handleStateUpdate(state)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let uuid = peripheral.identifier
        let rssi = RSSI.intValue
        let name = peripheral.name
        let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        // Classify outside MainActor — pure function with Sendable result
        let deviceType = Self.classifyDevice(serviceUUIDs: serviceUUIDs)

        MainActor.assumeIsolated {
            handleDiscovery(uuid: uuid, rssi: rssi, name: name, deviceType: deviceType)
        }
    }

    // MARK: - Private

    private func handleStateUpdate(_ state: CBManagerState) {
        switch state {
        case .poweredOn:
            logger.info("BT powered on")
            startScanning()
        case .poweredOff:
            logger.info("BT powered off")
            isScanning = false
        case .unauthorized:
            logger.warning("BT unauthorized")
        default:
            break
        }
    }

    private func handleDiscovery(uuid: UUID, rssi: Int, name: String?, deviceType: String) {
        guard rssi > -100 && rssi < 0 else { return }

        let storedName = privacyMode ? nil : name
        let device = BLEDevice(uuid: uuid, rssi: rssi, deviceType: deviceType, advertisedName: storedName)
        discoveredDevices[uuid.uuidString] = device

        let sublabel = privacyMode ? "BLE 2.4 GHz" : (name ?? "BLE 2.4 GHz")
        let signal = Signal(
            id: "ble-\(uuid.uuidString)",
            category: .bluetooth,
            provenance: .live,
            frequencyMHz: 2441,
            bandwidthMHz: 78,
            signalDBM: Double(rssi),
            label: deviceType,
            sublabel: sublabel,
            lastUpdated: .now,
            isActive: true
        )
        signalRegistry.addLiveSignal(signal)
    }

    /// Classify a BLE device by its advertised service UUIDs.
    nonisolated static func classifyDevice(serviceUUIDs: [CBUUID]?) -> String {
        guard let uuids = serviceUUIDs, !uuids.isEmpty else { return "Unknown" }
        for uuid in uuids {
            switch uuid.uuidString.uppercased() {
            case "110B": return "Speaker"
            case "1108": return "Headphones"
            case "1812": return "HID"
            case "180D": return "Heart Rate"
            case "1805": return "Watch"
            case "FEAA": return "Beacon"
            case "180F": return "BLE Device"
            default: continue
            }
        }
        return "Unknown"
    }
}
