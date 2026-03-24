import SwiftUI

struct ContentView: View {
    let signalRegistry: SignalRegistry
    let renderer: SpectrogramRenderer
    let settingsManager: SettingsManager
    let networkMonitor: NetworkMonitor
    let bluetoothScanner: BluetoothScanner
    var fccBands: [FrequencyBand] = []

    @State private var selectedSignal: Signal?
    @State private var isReady = false
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .leading) {
            SpectrogramView(renderer: renderer)

            if isReady {
                FCCBandOverlay(
                    bands: fccBands,
                    displayRange: settingsManager.frequencyRange
                )

                AnnotationOverlay(
                    signals: signalRegistry.visibleSignals,
                    displayRange: settingsManager.frequencyRange
                )
            }

            FrequencyAxisView(displayRange: settingsManager.frequencyRange)

            VStack {
                // Settings gear button (top-right)
                HStack {
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 8)
                }

                Spacer()

                // Legend + offline banner
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        LegendView()

                        if !networkMonitor.isOnline {
                            Text("Offline — using cached data")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.9), in: Capsule())
                        }
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .task {
            try? await Task.sleep(for: .seconds(1))
            isReady = true
        }
        .gesture(
            SpatialTapGesture()
                .onEnded { value in
                    handleTap(at: value.location)
                }
        )
        .sheet(item: $selectedSignal) { signal in
            SignalDetailPanel(signal: signal)
                .presentationDetents([.fraction(0.45)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                settingsManager: settingsManager,
                signalRegistry: signalRegistry,
                bluetoothScanner: bluetoothScanner
            )
        }
    }

    private func handleTap(at point: CGPoint) {
        let screenHeight = UIScreen.main.bounds.height
        let frequency = SignalDetailPanel.frequencyFromTapY(
            tapY: point.y,
            viewHeight: screenHeight,
            displayRange: settingsManager.frequencyRange
        )
        selectedSignal = SignalDetailPanel.nearestSignal(
            to: frequency,
            in: signalRegistry.visibleSignals
        )
    }
}
