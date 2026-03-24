import SwiftUI
import os

@main
struct WavelengthApp: App {
    @State private var signalRegistry = SignalRegistry()
    @State private var locationMonitor = LocationMonitor()
    @State private var networkMonitor = NetworkMonitor()
    @State private var renderer: SpectrogramRenderer?
    @State private var settingsManager: SettingsManager?
    @State private var bluetoothScanner: BluetoothScanner?
    @State private var contextualEngine: ContextualEngine?
    @State private var fccBands: [FrequencyBand] = []

    private let logger = Logger(subsystem: "com.yourname.wavelength", category: "App")

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
                        OnboardingView(settingsManager: settingsManager)
                    }
                } else {
                    Color.black
                        .ignoresSafeArea()
                }
            }
            .task {
                await initialize()
            }
        }
    }

    @MainActor
    private func initialize() async {
        do {
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
                databaseManager: db,
                openCellIDKey: nil
            )
            contextualEngine = engine
            await engine.start()

            locationMonitor.requestAuthorization()
            locationMonitor.startMonitoring()

            #if DEBUG
            MockSignalProvider.populateRegistry(signalRegistry)
            #endif

            logger.info("Wavelength initialized")
        } catch {
            logger.error("Initialization failed: \(error.localizedDescription)")
        }
    }
}
