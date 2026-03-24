import CoreTelephony
import os

@Observable
@MainActor
final class CellularMonitor {

    private(set) var currentInfo: CellularInfo?

    private let signalRegistry: SignalRegistry
    private let networkInfo = CTTelephonyNetworkInfo()
    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "CellularMonitor")

    init(signalRegistry: SignalRegistry) {
        self.signalRegistry = signalRegistry
    }

    func startMonitoring() {
        pollRadioTech()

        networkInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollRadioTech()
            }
        }
    }

    private func pollRadioTech() {
        guard let techDict = networkInfo.serviceCurrentRadioAccessTechnology,
              let (_, tech) = techDict.first else {
            logger.info("No radio access technology available")
            currentInfo = nil
            signalRegistry.removeLiveSignal(id: "cellular-primary")
            return
        }

        let (bandName, frequencyMHz) = Self.lookupFrequency(radioTech: tech)

        let info = CellularInfo(
            carrier: "Carrier",
            radioTech: bandName,
            bandName: bandName,
            frequencyMHz: frequencyMHz
        )
        currentInfo = info

        let signal = Signal(
            id: "cellular-primary",
            category: .cellular,
            provenance: .live,
            frequencyMHz: frequencyMHz,
            bandwidthMHz: nil,
            signalDBM: nil,
            label: bandName,
            sublabel: "\(Int(frequencyMHz)) MHz",
            lastUpdated: .now,
            isActive: true
        )
        signalRegistry.addLiveSignal(signal)
        logger.info("Cellular: \(bandName) at \(Int(frequencyMHz)) MHz")
    }

    /// Map radio access technology string to band name and estimated frequency.
    nonisolated static func lookupFrequency(radioTech: String) -> (band: String, mhz: Double) {
        switch radioTech {
        case CTRadioAccessTechnologyLTE:
            return ("LTE", 1900)
        case CTRadioAccessTechnologyNRNSA:
            return ("5G NSA", 2500)
        case CTRadioAccessTechnologyNR:
            return ("5G SA", 3500)
        case CTRadioAccessTechnologyHSDPA:
            return ("HSPA+", 1900)
        case CTRadioAccessTechnologyHSUPA:
            return ("HSPA+", 1900)
        case CTRadioAccessTechnologyWCDMA:
            return ("WCDMA", 1900)
        case CTRadioAccessTechnologyCDMA1x:
            return ("CDMA", 850)
        case CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB:
            return ("EVDO", 1900)
        case CTRadioAccessTechnologyEdge:
            return ("EDGE", 1900)
        case CTRadioAccessTechnologyGPRS:
            return ("GPRS", 1900)
        default:
            return ("Unknown", 1900)
        }
    }
}
