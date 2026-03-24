import SwiftUI

struct LegendView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            legendRow(
                color: .green,
                opacity: 1.0,
                filled: true,
                label: "Live",
                description: "Sensed by device"
            )
            legendRow(
                color: .blue,
                opacity: 0.5,
                filled: true,
                label: "Nearby",
                description: "Confirmed nearby"
            )
            legendRow(
                color: .orange,
                opacity: 0.3,
                filled: false,
                label: "Probable",
                description: "Inferred from context"
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func legendRow(
        color: Color,
        opacity: Double,
        filled: Bool,
        label: String,
        description: String
    ) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(filled ? color.opacity(opacity) : .clear)
                .overlay(
                    Circle()
                        .stroke(color.opacity(opacity), lineWidth: filled ? 0 : 1.5)
                )
                .frame(width: 10, height: 10)

            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))

            Text(description)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
