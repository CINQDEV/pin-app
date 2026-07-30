import SwiftUI

struct CatchBanner: View {
    let island: Island?
    let onDismiss: () -> Void

    private static let visibleDuration: Duration = .seconds(2.2)

    var body: some View {
        Group {
            if let island {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ISLAND DISCOVERED")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(island.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.green))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: island.id) {
                    try? await Task.sleep(for: Self.visibleDuration)
                    onDismiss()
                }
            }
        }
        .animation(.spring(duration: 0.35), value: island?.id)
    }
}
