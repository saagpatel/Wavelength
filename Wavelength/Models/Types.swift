import Foundation

/// A discovered Bluetooth LE peripheral.
struct BLEDevice: Sendable {
    let uuid: UUID
    let rssi: Int
    let deviceType: String
    let advertisedName: String?
}

/// A detected Wi-Fi network.
struct WiFiNetwork: Sendable {
    let ssid: String
    let bssid: String
    let rssi: Int
    let channel: Int
    let band: WiFiBand
    let channelMHz: Double
}

/// Wi-Fi frequency band.
enum WiFiBand: Sendable {
    case band24, band5, band6
}

/// Current cellular radio information.
struct CellularInfo: Sendable {
    let carrier: String
    let radioTech: String
    let bandName: String?
    let frequencyMHz: Double?
}
