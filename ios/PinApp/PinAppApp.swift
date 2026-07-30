import SwiftUI

@main
struct PinAppApp: App {
    @StateObject private var locationManager: LocationManager
    @StateObject private var viewModel: IslandsViewModel

    init() {
        let locationManager = LocationManager()
        _locationManager = StateObject(wrappedValue: locationManager)
        _viewModel = StateObject(wrappedValue: IslandsViewModel(locationManager: locationManager))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(locationManager)
                .onAppear { locationManager.requestPermission() }
        }
    }
}
