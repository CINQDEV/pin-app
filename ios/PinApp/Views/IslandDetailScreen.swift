import SwiftUI

struct IslandDetailScreen: View {
    @EnvironmentObject private var viewModel: IslandsViewModel
    let island: Island

    @State private var imageURL: URL?

    private var display: DisplayIsland? {
        viewModel.displayIslands.first { $0.id == island.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            EmptyView()
                        default:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                HStack {
                    if display?.checked == true {
                        Label("Checked in", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.green)
                    }
                    Spacer()
                    Text(formatDistance(display?.distanceMeters))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !island.description.isEmpty {
                    Text(island.description)
                        .font(.body)
                }

                VStack(spacing: 10) {
                    Button {
                        viewModel.focusOnMap(island)
                    } label: {
                        Label("Show on Map", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if let url = URL(string: island.url) {
                        Link(destination: url) {
                            Label("View on Search Isle", systemImage: "safari")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle(island.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: island.id) {
            guard let mediaID = island.featuredMediaID else { return }
            imageURL = try? await SearchIsleAPI.fetchImageURL(mediaID: mediaID)
        }
    }
}
