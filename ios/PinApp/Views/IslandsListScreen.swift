import SwiftUI

enum PinFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pinned = "Pinned"
    case unpinned = "Unpinned"

    var id: String { rawValue }
}

struct IslandsListScreen: View {
    @EnvironmentObject private var viewModel: IslandsViewModel
    @EnvironmentObject private var locationManager: LocationManager
    @State private var searchText = ""
    @State private var filter: PinFilter = .all

    private var accuracyWarning: String? {
        switch locationManager.accuracyAuthorization {
        case .reducedAccuracy:
            return "Precise location is off — 50 m check-ins may be unreliable."
        default:
            return nil
        }
    }

    private var isSearching: Bool { !searchText.isEmpty }
    private var isFiltered: Bool { isSearching || filter != .all }

    private var filteredIslands: [DisplayIsland] {
        var result = viewModel.displayIslands
        switch filter {
        case .all: break
        case .pinned: result = result.filter { $0.checked }
        case .unpinned: result = result.filter { !$0.checked }
        }
        if isSearching {
            result = result.filter { $0.island.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                if let message = locationManager.errorMessage ?? accuracyWarning {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
                if let loadError = viewModel.loadError {
                    Section {
                        Text(loadError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                if !isFiltered, let nearest = viewModel.nearestUncaught {
                    Section {
                        NearestIslandCard(display: nearest) {
                            viewModel.focusOnNearest()
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(8)
                    }
                }
                ForEach(filteredIslands) { display in
                    IslandRow(display: display) {
                        viewModel.focusOnMap(display.island)
                    }
                }
            }
            .navigationTitle("Islands")
            .searchable(text: $searchText, prompt: "Search islands")
            .safeAreaInset(edge: .top) {
                ScoreBadge(checked: viewModel.checkedCount, total: viewModel.totalCount)
                    .padding(.top, 8)
            }
            .refreshable { await viewModel.refresh() }
            .overlay {
                if viewModel.loading && viewModel.displayIslands.isEmpty {
                    ProgressView("Loading islands…")
                } else if isFiltered && filteredIslands.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if viewModel.displayIslands.isEmpty {
                    ContentUnavailableView("No islands loaded yet", systemImage: "water.waves")
                }
            }
            .navigationDestination(for: Island.self) { island in
                IslandDetailScreen(island: island)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(PinFilter.allCases) { option in
                            Button {
                                filter = option
                            } label: {
                                if filter == option {
                                    Label(option.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(option.rawValue)
                                }
                            }
                        }
                    } label: {
                        Label(
                            "Filter",
                            systemImage: filter == .all
                                ? "line.3.horizontal.decrease.circle"
                                : "line.3.horizontal.decrease.circle.fill"
                        )
                    }
                    .accessibilityIdentifier("islandFilterMenu")
                }
            }
        }
    }
}
