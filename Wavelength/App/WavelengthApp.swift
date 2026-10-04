import SwiftUI
import os
import CoreBluetooth

@main
struct WavelengthApp: App {
    private enum LaunchState: Equatable {
        case initializing
        case ready
        case failed(String)
    }

    @State private var signalRegistry = SignalRegistry()
    @State private var locationMonitor = LocationMonitor()
    @State private var networkMonitor = NetworkMonitor()
    @State private var renderer: SpectrogramRenderer?
    @State private var settingsManager: SettingsManager?
    @State private var bluetoothScanner: BluetoothScanner?
    @State private var contextualEngine: ContextualEngine?
    @State private var fccBands: [FrequencyBand] = []
    @State private var launchState: LaunchState = .initializing

    private let logger = Logger(subsystem: "com.waveylength.app", category: "App")

    var body: some Scene {
        WindowGroup {
            Group {
                if let settingsManager, let renderer {
                    if settingsManager.hasSeenOnboarding {
                        ContentView(
                            signalRegistry: signalRegistry,
                            renderer: renderer,
                            settingsManager: settingsManager,
                            networkMonitor: networkMonitor,
                            bluetoothScanner: bluetoothScanner!,
                            fccBands: fccBands
                        )
                    } else {
                        OnboardingView(
                            settingsManager: settingsManager,
                            locationMonitor: locationMonitor,
                            bluetoothScanner: bluetoothScanner!,
                            onComplete: startAuthorizedSensing
                        )
                    }
                } else if case .failed(let message) = launchState {
                    ContentUnavailableView {
                        Label("Wavelength couldn't start", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again") {
                            Task { await initialize() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .preferredColorScheme(.dark)
                } else {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        ProgressView("Preparing Wavelength…")
                            .tint(.white)
                            .foregroundStyle(.white)
                    }
                }
            }
            .task {
                await initialize()
            }
        }
    }

    @MainActor
    private func initialize() async {
        launchState = .initializing
        do {
            #if DEBUG
            if try AppStoreScreenshot.requested() != nil {
                try initializeAppStoreScreenshot()
                launchState = .ready
                return
            }
            #endif

            // Database + settings
            let db = try DatabaseManager.makeDefault()
            let settings = SettingsManager(dbQueue: db.dbQueue)
            settingsManager = settings

            // Wire settings to registry
            signalRegistry.showProbable = settings.showProbable

            // Metal renderer
            renderer = try SpectrogramRenderer(signalRegistry: signalRegistry, settingsManager: settings)

            // Network monitoring
            networkMonitor.startMonitoring()

            // FCC band overlay
            if let fccDB = try? DatabaseManager.openBundledFCCDatabase() {
                let fccDatabase = FCCDatabase()
                if let allocations = try? fccDatabase.allocations(dbQueue: fccDB) {
                    fccBands = FCCDatabase.toBands(allocations)
                }
            }

            // Bluetooth scanner
            let bleScanner = BluetoothScanner(signalRegistry: signalRegistry)
            bleScanner.privacyMode = settings.privacyMode
            bluetoothScanner = bleScanner

            // Contextual engine
            let engine = ContextualEngine(
                signalRegistry: signalRegistry,
                locationMonitor: locationMonitor,
                networkMonitor: networkMonitor,
                databaseManager: db
            )
            contextualEngine = engine
            await engine.start()

            if settings.hasSeenOnboarding {
                startAuthorizedSensing()
            }

            #if DEBUG
            MockSignalProvider.populateRegistry(signalRegistry)
            #endif

            launchState = .ready
            logger.info("Wavelength initialized")
        } catch {
            launchState = .failed(error.localizedDescription)
            logger.error("Initialization failed: \(error.localizedDescription)")
        }
    }

    #if DEBUG
    @MainActor
    private func initializeAppStoreScreenshot() throws {
        let settings = try AppStoreScreenshot.makeSettings()
        let registry = SignalRegistry()
        MockSignalProvider.populateRegistry(
            registry, date: AppStoreScreenshot.fixtureDate, privacyMode: true
        )
        guard let fccDB = try DatabaseManager.openBundledFCCDatabase() else {
            throw AppStoreScreenshot.ScreenshotError.missingAllocations
        }
        let allocations = try FCCDatabase().allocations(dbQueue: fccDB)
        guard !allocations.isEmpty else {
            throw AppStoreScreenshot.ScreenshotError.missingAllocations
        }
        let fixedRenderer = try SpectrogramRenderer(signalRegistry: registry, settingsManager: settings)
        try fixedRenderer.prepareAppStoreScreenshot()

        // No sensors, reachability updates, contextual timers, or reference downloads start here.
        signalRegistry = registry
        fccBands = FCCDatabase.toBands(allocations)
        bluetoothScanner = BluetoothScanner(signalRegistry: registry)
        settingsManager = settings
        renderer = fixedRenderer
    }
    #endif

    @MainActor
    private func startAuthorizedSensing() {
        let status = locationMonitor.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationMonitor.startMonitoring()
        }
        if CBManager.authorization == .allowedAlways {
            bluetoothScanner?.requestAuthorizationAndStartScanning()
        }
    }
}
