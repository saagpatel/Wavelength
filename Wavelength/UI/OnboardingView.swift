import SwiftUI
import CoreBluetooth
import CoreLocation

struct OnboardingView: View {
    let settingsManager: SettingsManager

    @State private var currentPage = 0
    @State private var locationGranted = false
    @State private var bluetoothGranted = false
    @State private var centralManager: CBCentralManager?

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            permissionsPage.tag(1)
            getStartedPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Wavelength")
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            Text("See the invisible\nelectromagnetic world")
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                provenanceRow(color: .green, opacity: 1.0, filled: true,
                              label: "Live", description: "Sensed by your device")
                provenanceRow(color: .blue, opacity: 0.5, filled: true,
                              label: "Nearby", description: "Confirmed present via GPS + data")
                provenanceRow(color: .orange, opacity: 0.3, filled: false,
                              label: "Probable", description: "Inferred from context")
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Spacer()

            Text("Swipe to continue")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Page 2: Permissions

    private var permissionsPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Permissions")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            Text("Wavelength needs access to your location\nand Bluetooth to detect nearby signals.")
                .font(.system(size: 14, weight: .light, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                permissionButton(
                    title: "Location",
                    icon: "location.fill",
                    granted: locationGranted
                ) {
                    let manager = CLLocationManager()
                    manager.requestWhenInUseAuthorization()
                    // Check after a brief delay for authorization response
                    Task {
                        try? await Task.sleep(for: .seconds(1))
                        let status = CLLocationManager().authorizationStatus
                        locationGranted = status == .authorizedWhenInUse || status == .authorizedAlways
                    }
                }

                permissionButton(
                    title: "Bluetooth",
                    icon: "antenna.radiowaves.left.and.right",
                    granted: bluetoothGranted
                ) {
                    // Initializing CBCentralManager triggers the system Bluetooth prompt
                    centralManager = CBCentralManager()
                    Task {
                        try? await Task.sleep(for: .seconds(1))
                        bluetoothGranted = centralManager?.state == .poweredOn
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Text("Swipe to continue")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Page 3: Get Started

    private var getStartedPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Ready to explore")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "waveform.path.ecg", text: "Real-time spectrogram visualization")
                featureRow(icon: "antenna.radiowaves.left.and.right", text: "Bluetooth, Wi-Fi, and cellular detection")
                featureRow(icon: "globe", text: "Cell tower and satellite tracking")
                featureRow(icon: "radio", text: "FM station identification")
                featureRow(icon: "hand.tap", text: "Tap any signal for details")
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Spacer()

            Button {
                settingsManager.hasSeenOnboarding = true
            } label: {
                Text("Get Started")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func provenanceRow(
        color: Color, opacity: Double, filled: Bool,
        label: String, description: String
    ) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(filled ? color.opacity(opacity) : .clear)
                .overlay(
                    Circle()
                        .stroke(color.opacity(opacity), lineWidth: filled ? 0 : 1.5)
                )
                .frame(width: 12, height: 12)

            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 70, alignment: .leading)

            Text(description)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func permissionButton(
        title: String, icon: String, granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                Spacer()
                if granted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .foregroundStyle(.white)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .disabled(granted)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 24)
            Text(text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
