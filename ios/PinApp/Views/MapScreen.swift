import MapKit
import SwiftUI

// With 1,100+ islands worldwide, rendering every marker at once would tank map
// performance — only render pins inside (a little more than) the visible viewport.
private let viewportPaddingFactor = 1.3

private let defaultRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 56.4907, longitude: -4.2026),
    span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
)

private func isInRegion(_ coordinate: CLLocationCoordinate2D, _ region: MKCoordinateRegion) -> Bool {
    let latPad = region.span.latitudeDelta * viewportPaddingFactor / 2
    let lngPad = region.span.longitudeDelta * viewportPaddingFactor / 2
    return abs(coordinate.latitude - region.center.latitude) <= latPad
        && abs(coordinate.longitude - region.center.longitude) <= lngPad
}

struct MapScreen: View {
    @EnvironmentObject private var viewModel: IslandsViewModel
    @EnvironmentObject private var locationManager: LocationManager

    @State private var cameraPosition: MapCameraPosition = .region(defaultRegion)
    @State private var visibleRegion: MKCoordinateRegion = defaultRegion
    @State private var hasCenteredOnUser = false

    private var visibleIslands: [DisplayIsland] {
        viewModel.displayIslands.filter { isInRegion($0.island.coordinate, visibleRegion) }
    }

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            if let coordinate = locationManager.coordinate {
                MapCircle(center: coordinate, radius: IslandsViewModel.checkInRadiusMeters)
                    .foregroundStyle(.green.opacity(0.15))
                    .stroke(.green.opacity(0.6), lineWidth: 1)
                    .mapOverlayLevel(level: .aboveRoads)
            }
            ForEach(visibleIslands) { display in
                Marker(display.island.name, coordinate: display.island.coordinate)
                    .tint(display.checked ? .green : .red)
            }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleRegion = context.region
        }
        .mapControls {
            MapUserLocationButton()
        }
        .onChange(of: locationManager.coordinate == nil) { _, _ in
            guard !hasCenteredOnUser, let newCoordinate = locationManager.coordinate else { return }
            hasCenteredOnUser = true
            let region = MKCoordinateRegion(
                center: newCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            cameraPosition = .region(region)
            visibleRegion = region
        }
    }
}
