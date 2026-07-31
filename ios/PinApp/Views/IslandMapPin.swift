import SwiftUI

/// A custom map marker: a circular badge with an icon, sitting on a small
/// pointed tail — built from scratch rather than MapKit's default teardrop pin.
struct IslandMapPin: View {
    let checked: Bool

    private var color: Color { checked ? .green : .red }

    var body: some View {
        VStack(spacing: -3) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                Image(systemName: checked ? "checkmark" : "flag.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            PinTailShape()
                .fill(color)
                .frame(width: 14, height: 9)
        }
        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
    }
}

private struct PinTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
