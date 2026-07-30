import CoreLocation
import Foundation

struct Island: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let lat: Double
    let lng: Double
    let url: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

/// An island combined with derived, per-render state — whether it's been
/// checked off and how far away it currently is.
struct DisplayIsland: Identifiable, Equatable {
    let island: Island
    let checked: Bool
    let distanceMeters: Double?

    var id: String { island.id }
}
