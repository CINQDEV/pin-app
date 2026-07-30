import Combine
import CoreLocation
import Foundation

@MainActor
final class IslandsViewModel: ObservableObject {
    static let checkInRadiusMeters: CLLocationDistance = 50

    @Published private(set) var displayIslands: [DisplayIsland] = []
    @Published private(set) var loading = true
    @Published private(set) var loadError: String?
    @Published var justCaught: Island?

    private let locationManager: LocationManager
    private var islands: [Island] = []
    private var checkedIds: Set<String>
    private var checkingInFlight: Set<String> = []
    private var cancellables: Set<AnyCancellable> = []

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        self.checkedIds = CheckedIslandsStore.loadCheckedIds()

        if let cached = CheckedIslandsStore.loadCachedIslands(), !cached.isEmpty {
            self.islands = cached
            self.loading = false
            recomputeDisplayIslands()
        }

        locationManager.$coordinate
            .sink { [weak self] coordinate in
                self?.handleLocationUpdate(coordinate)
            }
            .store(in: &cancellables)

        Task { await refresh() }
    }

    func refresh() async {
        loading = true
        loadError = nil
        do {
            let fetched = try await SearchIsleAPI.fetchAllIslands()
            islands = fetched
            CheckedIslandsStore.saveCachedIslands(fetched)
            recomputeDisplayIslands()
        } catch {
            loadError = "Failed to load islands: \(error.localizedDescription)"
        }
        loading = false
    }

    func dismissCaught() {
        justCaught = nil
    }

    private func handleLocationUpdate(_ coordinate: CLLocationCoordinate2D?) {
        guard let coordinate else { return }
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        for island in islands {
            guard !checkedIds.contains(island.id), !checkingInFlight.contains(island.id) else { continue }
            let islandLocation = CLLocation(latitude: island.lat, longitude: island.lng)
            let distance = userLocation.distance(from: islandLocation)
            if distance <= Self.checkInRadiusMeters {
                checkingInFlight.insert(island.id)
                checkedIds.insert(island.id)
                CheckedIslandsStore.saveCheckedIds(checkedIds)
                justCaught = island
                checkingInFlight.remove(island.id)
            }
        }

        recomputeDisplayIslands()
    }

    private func recomputeDisplayIslands() {
        let coordinate = locationManager.coordinate
        let userLocation = coordinate.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }

        displayIslands = islands
            .map { island -> DisplayIsland in
                let distance = userLocation?.distance(from: CLLocation(latitude: island.lat, longitude: island.lng))
                return DisplayIsland(island: island, checked: checkedIds.contains(island.id), distanceMeters: distance)
            }
            .sorted { ($0.distanceMeters ?? .greatestFiniteMagnitude) < ($1.distanceMeters ?? .greatestFiniteMagnitude) }
    }
}
