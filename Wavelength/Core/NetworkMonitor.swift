import Foundation
import Network
import Observation
import os

/// Monitors network reachability for offline mode.
@Observable
@MainActor
final class NetworkMonitor {

    private(set) var isOnline: Bool = true
    private(set) var lastOnlineDate: Date = .now

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.wavelength.network-monitor")
    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "NetworkMonitor")

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasOnline = self.isOnline
                self.isOnline = path.status == .satisfied
                if self.isOnline {
                    self.lastOnlineDate = .now
                }
                if wasOnline && !self.isOnline {
                    self.logger.info("Network went offline")
                } else if !wasOnline && self.isOnline {
                    self.logger.info("Network came back online")
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
