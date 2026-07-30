import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: IslandsViewModel

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                MapScreen()
                    .tabItem { Label("Map", systemImage: "map") }
                IslandsListScreen()
                    .tabItem { Label("Islands", systemImage: "list.bullet") }
            }
            CatchBanner(island: viewModel.justCaught, onDismiss: viewModel.dismissCaught)
        }
    }
}
