import SwiftUI

struct IslandRow: View {
    let display: DisplayIsland
    let onShowOnMap: () -> Void

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

            NavigationLink(value: display.island) {
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("islandTitleLink_\(display.island.id)")

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatDistance(display.distanceMeters))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(action: onShowOnMap) {
                    Image(systemName: "map")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.green)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.green.opacity(0.12)))
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("islandMapButton_\(display.island.id)")
            }
        }
        .padding(.vertical, 6)
    }
}
