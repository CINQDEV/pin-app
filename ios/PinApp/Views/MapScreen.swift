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
    @State private var selectedIsland: Island?

    private var visibleIslands: [DisplayIsland] {
        viewModel.displayIslands.filter { isInRegion($0.island.coordinate, visibleRegion) }
    }

    private var selectedDisplay: DisplayIsland? {
        guard let selectedIsland else { return nil }
        return viewModel.displayIslands.first { $0.id == selectedIsland.id }
    }

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $selectedIsland) {
                UserAnnotation()
                if let coordinate = locationManager.coordinate {
                    MapCircle(center: coordinate, radius: IslandsViewModel.checkInRadiusMeters)
                        .foregroundStyle(.green.opacity(0.15))
                        .stroke(.green.opacity(0.6), lineWidth: 1)
                        .mapOverlayLevel(level: .aboveRoads)
                }
                ForEach(visibleIslands) { display in
                    Annotation(display.island.name, coordinate: display.island.coordinate, anchor: .bottom) {
                        IslandMapPin(checked: display.checked)
                    }
                    .tag(display.island)
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleRegion = context.region
            }
            .mapControls {
                MapUserLocationButton()
                MapPitchToggle()
                MapCompass()
            }
            .onChange(of: locationManager.coordinate == nil) { _, _ in
                guard !hasCenteredOnUser, let newCoordinate = locationManager.coordinate else { return }
                hasCenteredOnUser = true
                focus(on: newCoordinate, spanDegrees: 0.05)
            }
            .onChange(of: viewModel.mapFocusRequest) { _, requested in
                guard let requested else { return }
                focus(on: requested.coordinate, spanDegrees: 0.01)
                selectedIsland = requested
                viewModel.mapFocusRequest = nil
            }
            .overlay(alignment: .bottomLeading) {
                if let nearest = viewModel.nearestUncaught {
                    Button {
                        focus(on: nearest.island.coordinate, spanDegrees: 0.01)
                        selectedIsland = nearest.island
                    } label: {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.green))
                    }
                    .padding(16)
                }
            }
            .overlay(alignment: .topLeading) {
                ScoreBadge(checked: viewModel.checkedCount, total: viewModel.totalCount)
                    .padding(16)
            }
            .overlay(alignment: .trailing) {
                VStack(spacing: 0) {
                    Button {
                        zoom(by: 0.5)
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 44, height: 44)
                    }
                    Divider().frame(width: 30)
                    Button {
                        zoom(by: 2)
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 44, height: 44)
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.trailing, 16)
            }
            .safeAreaInset(edge: .bottom) {
                if let selectedDisplay {
                    NavigationLink(value: selectedDisplay.island) {
                        MapSelectionCallout(display: selectedDisplay)
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityIdentifier("mapSelectionCallout")
                }
            }
            .animation(.spring(duration: 0.3), value: selectedIsland)
            .navigationDestination(for: Island.self) { island in
                IslandDetailScreen(island: island)
            }
        }
    }

    private func focus(on coordinate: CLLocationCoordinate2D, spanDegrees: Double) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: spanDegrees, longitudeDelta: spanDegrees)
        )
        withAnimation {
            cameraPosition = .region(region)
        }
        visibleRegion = region
    }

    /// Zooms in (factor < 1) or out (factor > 1) around the current center by
    /// scaling the visible region's span — mirrors a standard map zoom stepper.
    private func zoom(by factor: Double) {
        let clampedLat = min(max(visibleRegion.span.latitudeDelta * factor, 0.002), 90)
        let clampedLng = min(max(visibleRegion.span.longitudeDelta * factor, 0.002), 90)
        let region = MKCoordinateRegion(
            center: visibleRegion.center,
            span: MKCoordinateSpan(latitudeDelta: clampedLat, longitudeDelta: clampedLng)
        )
        withAnimation {
            cameraPosition = .region(region)
        }
        visibleRegion = region
    }
}
