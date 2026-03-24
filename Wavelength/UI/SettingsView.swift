import SwiftUI

struct SettingsView: View {
    @Bindable var settingsManager: SettingsManager
    let signalRegistry: SignalRegistry
    let bluetoothScanner: BluetoothScanner

    @State private var cacheStats: CacheStats?
    @State private var showClearConfirmation = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                displaySection
                privacySection
                signalsSection
                cacheSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                cacheStats = try? settingsManager.cacheStats()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var displaySection: some View {
        Section("Display") {
            Picker("Colormap", selection: Binding(
                get: { settingsManager.colormap },
                set: { settingsManager.colormap = $0 }
            )) {
                ForEach(Colormap.allCases) { colormap in
                    Text(colormap.displayName).tag(colormap)
                }
            }
            .pickerStyle(.segmented)

            Picker("Frequency Range", selection: Binding(
                get: { settingsManager.frequencyPreset },
                set: { settingsManager.frequencyPreset = $0 }
            )) {
                ForEach(FrequencyPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Toggle("Hide Bluetooth device names", isOn: Binding(
                get: { settingsManager.privacyMode },
                set: {
                    settingsManager.privacyMode = $0
                    bluetoothScanner.privacyMode = $0
                }
            ))
        }
    }

    private var signalsSection: some View {
        Section("Signals") {
            Toggle("Show probable signals", isOn: Binding(
                get: { settingsManager.showProbable },
                set: {
                    settingsManager.showProbable = $0
                    signalRegistry.showProbable = $0
                }
            ))
        }
    }

    private var cacheSection: some View {
        Section("Cache") {
            if let stats = cacheStats {
                Text("Cell towers: \(stats.towerCount)")
                    .font(.system(size: 13, design: .monospaced))
                Text("FM stations: \(stats.fmCount)")
                    .font(.system(size: 13, design: .monospaced))
                Text("Satellites: \(stats.satelliteCount)")
                    .font(.system(size: 13, design: .monospaced))
            } else {
                Text("Loading cache info...")
                    .foregroundStyle(.secondary)
            }

            Button("Clear Cache", role: .destructive) {
                showClearConfirmation = true
            }
            .confirmationDialog("Clear all cached data?", isPresented: $showClearConfirmation) {
                Button("Clear Cache", role: .destructive) {
                    try? settingsManager.clearCache()
                    cacheStats = try? settingsManager.cacheStats()
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
            Link("Source Code on GitHub",
                 destination: URL(string: "https://github.com/wavelength-app/wavelength")!)
        }
    }
}
