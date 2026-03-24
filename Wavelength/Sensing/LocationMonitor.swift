import CoreLocation
import os

/// Monitors device location and publishes updates when the user moves
/// more than a configurable distance threshold.
///
/// Uses iOS 17+ CLLocationUpdate.liveUpdates() for Swift concurrency
/// compatibility. Distance filtering is applied in-app.
@Observable
@MainActor
final class LocationMonitor {

    /// Most recent location that passed the distance threshold.
    private(set) var currentLocation: CLLocation?

    /// Current authorization status.
    private(set) var authorizationStatus: CLAuthorizationStatus

    /// Whether location monitoring is actively running.
    private(set) var isMonitoring = false

    /// Minimum distance (meters) between published updates.
    let distanceThreshold: Double

    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "LocationMonitor")
    private var monitoringTask: Task<Void, Never>?

    init(distanceThreshold: Double = 500.0) {
        self.distanceThreshold = distanceThreshold
        self.authorizationStatus = locationManager.authorizationStatus
    }

    /// Request when-in-use location authorization.
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        authorizationStatus = locationManager.authorizationStatus
    }

    /// Start monitoring location updates. Filters by distance threshold.
    func startMonitoring() {
        guard monitoringTask == nil else { return }
        isMonitoring = true

        monitoringTask = Task { [weak self] in
            guard let self else { return }

            let updates = CLLocationUpdate.liveUpdates()
            do {
                for try await update in updates {
                    guard !Task.isCancelled else { break }
                    guard let location = update.location else { continue }

                    if Self.shouldUpdate(
                        newLocation: location,
                        currentLocation: self.currentLocation,
                        threshold: self.distanceThreshold
                    ) {
                        self.currentLocation = location
                        self.logger.info(
                            "Location updated: \(location.coordinate.latitude, privacy: .private), \(location.coordinate.longitude, privacy: .private)"
                        )
                    }
                }
            } catch {
                self.logger.error("Location updates failed: \(error.localizedDescription)")
            }

            self.isMonitoring = false
        }
    }

    /// Stop monitoring location updates.
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
    }

    /// Pure function: determine whether a new location should replace the current one
    /// based on a minimum distance threshold.
    nonisolated static func shouldUpdate(
        newLocation: CLLocation,
        currentLocation: CLLocation?,
        threshold: Double
    ) -> Bool {
        guard let current = currentLocation else {
            return true
        }
        return newLocation.distance(from: current) >= threshold
    }
}
