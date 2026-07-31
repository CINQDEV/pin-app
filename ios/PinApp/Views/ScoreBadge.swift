import SwiftUI

struct ScoreBadge: View {
    let checked: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flag.checkered")
            Text(total > 0 ? "\(checked) / \(total) islands found" : "\(checked) islands found")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(.thinMaterial))
    }
}
