import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: IslandsViewModel

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $viewModel.selectedTab) {
                MapScreen()
                    .tabItem { Label("Map", systemImage: "map") }
                    .tag(AppTab.map)
                IslandsListScreen()
                    .tabItem { Label("Islands", systemImage: "list.bullet") }
                    .tag(AppTab.islands)
            }
            CatchBanner(island: viewModel.justCaught, onDismiss: viewModel.dismissCaught)
        }
    }
}
