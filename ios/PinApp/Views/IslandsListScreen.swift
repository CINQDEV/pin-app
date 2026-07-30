import SwiftUI

struct IslandsListScreen: View {
    @EnvironmentObject private var viewModel: IslandsViewModel
    @EnvironmentObject private var locationManager: LocationManager

    private var accuracyWarning: String? {
        switch locationManager.accuracyAuthorization {
        case .reducedAccuracy:
            return "Precise location is off — 50 m check-ins may be unreliable."
        default:
            return nil
        }
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
                ForEach(viewModel.displayIslands) { display in
                    IslandRow(display: display)
                }
            }
            .navigationTitle("Islands")
            .refreshable { await viewModel.refresh() }
            .overlay {
                if viewModel.loading && viewModel.displayIslands.isEmpty {
                    ProgressView("Loading islands…")
                } else if viewModel.displayIslands.isEmpty {
                    ContentUnavailableView("No islands loaded yet", systemImage: "water.waves")
                }
            }
        }
    }
}
