import SwiftUI

struct NearestIslandCard: View {
    let display: DisplayIsland
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.green))

                VStack(alignment: .leading, spacing: 2) {
                    Text("NEAREST")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
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
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }
}
