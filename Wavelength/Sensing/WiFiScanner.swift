import NetworkExtension
import os

@Observable
@MainActor
final class WiFiScanner {

    private(set) var currentNetwork: WiFiNetwork?
    private(set) var visibleNetworkCount: Int = 0

    private let signalRegistry: SignalRegistry
    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "WiFiScanner")
    private var pollTask: Task<Void, Never>?
    private var useHotspotHelper = false

    init(signalRegistry: SignalRegistry) {
        self.signalRegistry = signalRegistry
        useHotspotHelper = registerHotspotHelper()
        if useHotspotHelper {
            logger.info("NEHotspotHelper registered — full Wi-Fi scanning active")
        } else {
            logger.info("NEHotspotHelper unavailable — using fallback (connected AP only)")
        }
    }

    func startMonitoring() {
        guard pollTask == nil else { return }
        // Fallback polling: always runs for connected network info
        // NEHotspotHelper events are push-based (handled in handleHotspotCommand)
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.fetchCurrentNetwork()
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    func stopMonitoring() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - NEHotspotHelper Registration

    private func registerHotspotHelper() -> Bool {
        let options: [String: NSObject] = [
            kNEHotspotHelperOptionDisplayName: "Wavelength" as NSObject
        ]
        return NEHotspotHelper.register(
            options: options,
            queue: DispatchQueue(label: "com.wavelength.hotspot")
        ) { [weak self] command in
            self?.handleHotspotCommand(command)
        }
    }

    private nonisolated func handleHotspotCommand(_ command: NEHotspotHelperCommand) {
        switch command.commandType {
        case .filterScanList:
            guard let networks = command.networkList else {
                command.createResponse(.success).deliver()
                return
            }
            let signals = networks.map { network in
                Self.networkToSignal(
                    ssid: network.ssid,
                    bssid: network.bssid,
                    signalStrength: network.signalStrength
                )
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.visibleNetworkCount = signals.count
                for signal in signals {
                    self.signalRegistry.addLiveSignal(signal)
                }
                self.logger.info("NEHotspotHelper: \(signals.count) visible networks")
            }
            command.createResponse(.success).deliver()

        case .evaluate, .maintain:
            command.createResponse(.success).deliver()

        default:
            command.createResponse(.success).deliver()
        }
    }

    // MARK: - Fallback: Connected Network Only

    private func fetchCurrentNetwork() async {
        let network = await NEHotspotNetwork.fetchCurrent()
        guard let network else {
            if currentNetwork != nil {
                currentNetwork = nil
                signalRegistry.removeLiveSignal(id: "wifi-connected")
                logger.info("Wi-Fi disconnected or unavailable")
            }
            return
        }

        // NEHotspotNetwork only provides SSID, BSSID, securityType
        // No channel info available — default to 2.4 GHz center (2437 MHz)
        let wifiNetwork = WiFiNetwork(
            ssid: network.ssid,
            bssid: network.bssid,
            rssi: -50,
            channel: 6,
            band: .band24,
            channelMHz: 2437
        )
        currentNetwork = wifiNetwork

        let signal = Signal(
            id: "wifi-connected",
            category: .wifi,
            provenance: .live,
            frequencyMHz: 2437,
            bandwidthMHz: 83.5,
            signalDBM: -50,
            label: network.ssid,
            sublabel: "Wi-Fi (estimated frequency)",
            lastUpdated: .now,
            isActive: true
        )
        signalRegistry.addLiveSignal(signal)
    }

    // MARK: - Signal Conversion

    /// Convert a discovered network into a Signal.
    nonisolated static func networkToSignal(
        ssid: String,
        bssid: String,
        signalStrength: Double
    ) -> Signal {
        // NEHotspotNetwork signalStrength is 0.0–1.0; convert to dBm estimate
        let dbm = -90.0 + (signalStrength * 60.0) // 0.0 → -90 dBm, 1.0 → -30 dBm

        return Signal(
            id: "wifi-\(bssid)",
            category: .wifi,
            provenance: .live,
            frequencyMHz: 2437, // Default to 2.4 GHz — no channel info from API
            bandwidthMHz: 20,
            signalDBM: dbm,
            label: ssid.isEmpty ? "Hidden Network" : ssid,
            sublabel: "Wi-Fi (estimated frequency)",
            lastUpdated: .now,
            isActive: true
        )
    }

    /// Map 802.11 channel number to center frequency in MHz.
    nonisolated static func channelToFrequency(channel: Int) -> Double {
        switch channel {
        // 2.4 GHz (channels 1–14)
        case 1...13:
            return 2412.0 + Double(channel - 1) * 5.0
        case 14:
            return 2484.0

        // 5 GHz (UNII-1, UNII-2, UNII-2E, UNII-3)
        case 32...68:
            return 5160.0 + Double(channel - 32) * 5.0
        case 96...177:
            return 5480.0 + Double(channel - 96) * 5.0

        // 6 GHz (Wi-Fi 6E)
        case 1...233 where channel > 177:
            return 5955.0 + Double(channel) * 5.0

        default:
            return 2437.0 // Fallback to channel 6
        }
    }
}
