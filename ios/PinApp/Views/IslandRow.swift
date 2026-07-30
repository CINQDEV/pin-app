import SwiftUI

struct IslandRow: View {
    let display: DisplayIsland

    private var distanceText: String {
        guard let meters = display.distanceMeters else { return "…" }
        if meters < 1000 { return "\(Int(meters.rounded())) m away" }
        return String(format: "%.1f km away", meters / 1000)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .strokeBorder(Color.green, lineWidth: 2)
                .background(Circle().fill(display.checked ? Color.green.opacity(0.15) : .clear))
                .frame(width: 28, height: 28)
                .overlay {
                    if display.checked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.green)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(display.island.name)
                    .font(.headline)
                    .foregroundStyle(display.checked ? Color.green : Color.primary)
                if !display.island.description.isEmpty {
                    Text(display.island.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(distanceText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
