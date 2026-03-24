import SwiftUI

struct FrequencyAxisView: View {

    var displayRange: ClosedRange<Double> = 70.0...6000.0

    private static let landmarks: [(mhz: Double, label: String)] = [
        (88, "FM"),
        (433, "ISM"),
        (700, "Cell"),
        (1575, "GPS"),
        (2441, "BT/WiFi"),
        (5000, "WiFi 5"),
    ]

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let visibleLandmarks = Self.landmarks.filter {
                $0.mhz >= displayRange.lowerBound && $0.mhz <= displayRange.upperBound
            }
            ForEach(visibleLandmarks, id: \.label) { landmark in
                let band = FrequencyBand(
                    lowMHz: landmark.mhz, highMHz: landmark.mhz,
                    name: landmark.label, allocationSource: "UI"
                )
                let position = band.logPosition(in: displayRange)
                // Position from bottom (low freq) to top (high freq)
                let y = height * (1.0 - position)

                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 12, height: 1)
                    Text(landmark.label)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .position(x: 36, y: y)
            }
        }
        .allowsHitTesting(false)
    }
}
