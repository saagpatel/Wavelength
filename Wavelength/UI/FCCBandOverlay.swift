import SwiftUI

/// Semi-transparent colored rectangles showing FCC spectrum allocations.
struct FCCBandOverlay: View {
    let bands: [FrequencyBand]
    var displayRange: ClosedRange<Double> = 70.0...6000.0

    var body: some View {
        Canvas { context, size in
            guard size.height > 0, size.width > 0 else { return }
            for band in bands {
                let topY = size.height * (1.0 - band.logPosition(in: displayRange, edge: .high))
                let bottomY = size.height * (1.0 - band.logPosition(in: displayRange, edge: .low))
                let bandHeight = max(bottomY - topY, 1)

                let rect = CGRect(x: 0, y: topY, width: size.width, height: bandHeight)
                context.fill(
                    Path(rect),
                    with: .color(FCCDatabase.colorFor(band).opacity(0.08))
                )
            }
        }
        .allowsHitTesting(false)
    }
}
