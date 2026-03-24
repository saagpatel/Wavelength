import Foundation
import CoreLocation
import GRDB
import os

/// Coordinates all contextual data services. Observes location changes
/// and refreshes cell tower, satellite, FM, and probable signal data.
actor ContextualEngine {

    private let signalRegistry: SignalRegistry
    private let locationMonitor: LocationMonitor
    private let networkMonitor: NetworkMonitor
    private let databaseManager: DatabaseManager
    private let cellTowerService: CellTowerService?
    private let satelliteService: SatelliteService
    private let fmStationService: FMStationService
    private let fmDBQueue: DatabaseQueue?
    private let airports: [Airport]

    private var lastProcessedLocation: CLLocation?
    private var lastGeocodedLocality: String?
    private var locationPollTask: Task<Void, Never>?
    private var satelliteRefreshTask: Task<Void, Never>?

    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "ContextualEngine")

    private static let locationThreshold: Double = 500
    private static let locationPollInterval: Duration = .seconds(5)
    private static let satelliteRefreshInterval: Duration = .seconds(30)

    init(
        signalRegistry: SignalRegistry,
        locationMonitor: LocationMonitor,
        networkMonitor: NetworkMonitor,
        databaseManager: DatabaseManager,
        openCellIDKey: String?
    ) {
        self.signalRegistry = signalRegistry
        self.locationMonitor = locationMonitor
        self.networkMonitor = networkMonitor
        self.databaseManager = databaseManager

        if let key = openCellIDKey, !key.isEmpty {
            self.cellTowerService = CellTowerService(apiKey: key, dbQueue: databaseManager.dbQueue)
        } else {
            self.cellTowerService = nil
            Logger(subsystem: "com.yourname.wavelength", category: "ContextualEngine")
                .info("No OpenCellID API key — cell tower service disabled")
        }

        self.satelliteService = SatelliteService(dbQueue: databaseManager.dbQueue)
        self.fmStationService = FMStationService()
        self.fmDBQueue = try? DatabaseManager.openBundledFMDatabase()
        self.airports = AirportLoader.loadBundled()
    }

    func start() {
        locationPollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.checkForLocationUpdate()
                try? await Task.sleep(for: Self.locationPollInterval)
            }
        }

        satelliteRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshSatelliteVisibility()
                try? await Task.sleep(for: Self.satelliteRefreshInterval)
            }
        }
    }

    func stop() {
        locationPollTask?.cancel()
        locationPollTask = nil
        satelliteRefreshTask?.cancel()
        satelliteRefreshTask = nil
    }

    // MARK: - Location Observation

    private func checkForLocationUpdate() async {
        let currentLocation = await MainActor.run { locationMonitor.currentLocation }
        guard let location = currentLocation else { return }

        let shouldProcess: Bool
        if let last = lastProcessedLocation {
            shouldProcess = location.distance(from: last) >= Self.locationThreshold
        } else {
            shouldProcess = true
        }

        guard shouldProcess else { return }
        lastProcessedLocation = location
        logger.info("Location changed, refreshing contextual data")
        await refreshAllServices(for: location)
    }

    // MARK: - Service Orchestration

    private func refreshAllServices(for location: CLLocation) async {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        let online = await MainActor.run { networkMonitor.isOnline }

        if online {
            async let towersResult: Void = refreshCellTowers(lat: lat, lon: lon)
            async let fmResult: Void = refreshFMStations(lat: lat, lon: lon)
            async let satResult: Void = refreshSatelliteTLEs()
            async let probableResult: Void = refreshProbableSignals(lat: lat, lon: lon)

            _ = await (towersResult, fmResult, satResult, probableResult)
        } else {
            logger.info("Offline — loading cached data")
            await loadCachedData(lat: lat, lon: lon)
            await refreshProbableSignals(lat: lat, lon: lon)
        }
    }

    // MARK: - Online Refresh Methods

    private func refreshCellTowers(lat: Double, lon: Double) async {
        guard let service = cellTowerService else { return }
        do {
            let towers = try await service.fetchNearbyTowers(lat: lat, lon: lon)
            let signals = CellTowerService.toSignals(towers)
            await MainActor.run { signalRegistry.setNearbySignals(signals, forCategory: .cellular) }
            logger.info("Updated \(towers.count) cell towers")
        } catch {
            logger.error("Cell tower refresh failed: \(error.localizedDescription)")
        }
    }

    private func refreshFMStations(lat: Double, lon: Double) async {
        guard let fmDB = fmDBQueue else { return }
        do {
            let stations = try fmStationService.nearbyStations(lat: lat, lon: lon, dbQueue: fmDB)
            let signals = FMStationService.toSignals(stations)
            await MainActor.run { signalRegistry.setNearbySignals(signals, forCategory: .fm) }
            logger.info("Updated \(stations.count) FM stations")
        } catch {
            logger.error("FM station refresh failed: \(error.localizedDescription)")
        }
    }

    private func refreshSatelliteTLEs() async {
        do {
            try await satelliteService.refreshTLEs()
        } catch {
            logger.error("TLE refresh failed: \(error.localizedDescription)")
        }
    }

    private func refreshSatelliteVisibility() async {
        let currentLocation = await MainActor.run { locationMonitor.currentLocation }
        guard let location = currentLocation else { return }

        do {
            let signals = try await satelliteService.visibleSatelliteSignals(
                observerLat: location.coordinate.latitude,
                observerLon: location.coordinate.longitude
            )
            // Split GPS and other satellites into their categories
            let gpsSignals = signals.filter { $0.category == .gps }
            let otherSatSignals = signals.filter { $0.category == .satellite }
            await MainActor.run {
                signalRegistry.setNearbySignals(gpsSignals, forCategory: .gps)
                signalRegistry.setNearbySignals(otherSatSignals, forCategory: .satellite)
            }
            logger.debug("Visible satellites: \(signals.count) (\(gpsSignals.count) GPS, \(otherSatSignals.count) other)")
        } catch {
            logger.error("Satellite visibility failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Offline Cache Fallback

    private func loadCachedData(lat: Double, lon: Double) async {
        // Load cached cell towers within 10km (ignore TTL)
        do {
            let bbox = CellTowerService.computeBBOX(lat: lat, lon: lon, radiusKm: 10.0)
            let towers: [CellTowerRecord] = try await databaseManager.dbQueue.read { db in
                try CellTowerRecord.fetchAll(db, sql: """
                    SELECT * FROM cell_towers
                    WHERE latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?
                """, arguments: [bbox.latMin, bbox.latMax, bbox.lonMin, bbox.lonMax])
            }
            let signals = CellTowerService.toSignals(towers)
            await MainActor.run { signalRegistry.setNearbySignals(signals, forCategory: .cellular) }
            logger.info("Loaded \(towers.count) cached cell towers")
        } catch {
            logger.error("Cached tower load failed: \(error.localizedDescription)")
        }

        // Load cached FM stations (bundled DB — always available)
        if let fmDB = fmDBQueue {
            do {
                let stations = try fmStationService.nearbyStations(lat: lat, lon: lon, dbQueue: fmDB)
                let signals = FMStationService.toSignals(stations)
                await MainActor.run { signalRegistry.setNearbySignals(signals, forCategory: .fm) }
                logger.info("Loaded \(stations.count) cached FM stations")
            } catch {
                logger.error("Cached FM load failed: \(error.localizedDescription)")
            }
        }

        // Load cached satellite TLEs (all of them, since orbits are global)
        do {
            let tles: [SatelliteTLERecord] = try await databaseManager.dbQueue.read { db in
                try SatelliteTLERecord.fetchAll(db, sql: "SELECT * FROM satellite_tles")
            }
            // We can't compute current visibility without SatelliteKit propagation,
            // but we can at least show them as nearby signals
            var gpsSignals: [Signal] = []
            var otherSignals: [Signal] = []
            for tle in tles {
                let signal = Signal(
                    id: "sat-\(tle.noradId)",
                    category: tle.constellation == "GPS" ? .gps : .satellite,
                    provenance: .nearby,
                    frequencyMHz: tle.frequencyMhz,
                    bandwidthMHz: nil,
                    signalDBM: nil,
                    label: tle.name,
                    sublabel: "\(tle.constellation) (cached)",
                    lastUpdated: tle.fetchedAt,
                    isActive: true
                )
                if tle.constellation == "GPS" {
                    gpsSignals.append(signal)
                } else {
                    otherSignals.append(signal)
                }
            }
            await MainActor.run {
                signalRegistry.setNearbySignals(gpsSignals, forCategory: .gps)
                signalRegistry.setNearbySignals(otherSignals, forCategory: .satellite)
            }
            logger.info("Loaded \(tles.count) cached satellite TLEs")
        } catch {
            logger.error("Cached satellite load failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Probable Inference

    private func refreshProbableSignals(lat: Double, lon: Double) async {
        var broadcastSignals: [Signal] = []
        var cellularSignals: [Signal] = []

        // ADS-B near airports
        if let airport = AirportLoader.nearestAirport(lat: lat, lon: lon, airports: airports) {
            broadcastSignals.append(Signal(
                id: "probable-adsb-\(airport.ident)",
                category: .broadcast,
                provenance: .probable,
                frequencyMHz: 1090,
                bandwidthMHz: nil,
                signalDBM: nil,
                label: "ADS-B",
                sublabel: "Aircraft transponders near \(airport.name.prefix(20))",
                lastUpdated: .now,
                isActive: true
            ))
        }

        // Urban 5G inference via reverse geocoding (skip when offline)
        let online = await MainActor.run { networkMonitor.isOnline }
        if online {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: lat, longitude: lon)
            if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
               let locality = placemarks.first?.locality,
               Self.majorUSCities.contains(locality) {
                cellularSignals.append(Signal(
                    id: "probable-5g-\(locality)",
                    category: .cellular,
                    provenance: .probable,
                    frequencyMHz: 3700,
                    bandwidthMHz: 500,
                    signalDBM: nil,
                    label: "5G C-Band",
                    sublabel: "Probable coverage in \(locality)",
                    lastUpdated: .now,
                    isActive: true
                ))
            }
        }

        await MainActor.run {
            signalRegistry.setProbableSignals(broadcastSignals, forCategory: .broadcast)
            signalRegistry.setProbableSignals(cellularSignals, forCategory: .cellular)
        }
    }

    private static let majorUSCities: Set<String> = [
        "New York", "Los Angeles", "Chicago", "Houston", "Phoenix",
        "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose",
        "Austin", "Jacksonville", "San Francisco", "Columbus", "Charlotte",
        "Indianapolis", "Seattle", "Denver", "Washington", "Nashville",
        "Oklahoma City", "Boston", "Portland", "Las Vegas", "Memphis",
        "Louisville", "Baltimore", "Milwaukee", "Albuquerque", "Tucson",
        "Fresno", "Sacramento", "Mesa", "Kansas City", "Atlanta",
        "Omaha", "Colorado Springs", "Raleigh", "Long Beach", "Miami",
        "Oakland", "Minneapolis", "Tampa", "Arlington", "New Orleans",
        "Wichita", "Cleveland", "Honolulu", "Anchorage", "Detroit",
    ]
}
