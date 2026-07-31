import Combine
import CoreLocation
import Foundation

enum AppTab: Hashable {
    case map, islands
}

@MainActor
final class IslandsViewModel: ObservableObject {
    static let checkInRadiusMeters: CLLocationDistance = 50

    @Published private(set) var displayIslands: [DisplayIsland] = []
    @Published private(set) var loading = true
    @Published private(set) var loadError: String?
    @Published var justCaught: Island?
    @Published var selectedTab: AppTab = .map
    /// Set to request the map jump to and center on a specific island; MapScreen
    /// consumes and clears this once it's handled the jump.
    @Published var mapFocusRequest: Island?

    /// The closest island that hasn't been checked off yet, if the user's location is known.
    var nearestUncaught: DisplayIsland? {
        displayIslands.first { !$0.checked && $0.distanceMeters != nil }
    }

    var checkedCount: Int { checkedIds.count }
    var totalCount: Int { islands.count }

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
            checkProximity(at: locationManager.coordinate)
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
            checkProximity(at: locationManager.coordinate)
        } catch {
            loadError = "Failed to load islands: \(error.localizedDescription)"
        }
        loading = false
    }

    func dismissCaught() {
        justCaught = nil
    }

    func focusOnMap(_ island: Island) {
        mapFocusRequest = island
        selectedTab = .map
    }

    func focusOnNearest() {
        guard let nearest = nearestUncaught else { return }
        focusOnMap(nearest.island)
    }

    private func handleLocationUpdate(_ coordinate: CLLocationCoordinate2D?) {
        checkProximity(at: coordinate)
    }

    /// Runs the 50m catch check against whatever's current. Called both when a new
    /// location fix arrives and when the island list finishes (re)loading — either
    /// one can be the "last piece" needed, e.g. a fix landing while islands are still
    /// mid-fetch would otherwise be checked against an empty list and silently wasted.
    private func checkProximity(at coordinate: CLLocationCoordinate2D?) {
        if let coordinate {
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
