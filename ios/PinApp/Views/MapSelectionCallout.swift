import SwiftUI

struct MapSelectionCallout: View {
    let display: DisplayIsland

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(Color.green, lineWidth: 2)
                .background(Circle().fill(display.checked ? Color.green.opacity(0.15) : .clear))
                .frame(width: 32, height: 32)
                .overlay {
                    if display.checked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.green)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(display.island.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(formatDistance(display.distanceMeters))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(.regularMaterial))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
    }
}
