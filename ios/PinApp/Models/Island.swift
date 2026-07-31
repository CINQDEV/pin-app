import CoreLocation
import Foundation

struct Island: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let lat: Double
    let lng: Double
    let url: String
    /// WordPress media ID for the featured photo, if any (0/nil means no image).
    /// Fetched lazily via `SearchIsleAPI.fetchImageURL` — not embedded in the bulk list fetch.
    let featuredMediaID: Int?

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

func formatDistance(_ meters: Double?) -> String {
    guard let meters else { return "…" }
    if meters < 1000 { return "\(Int(meters.rounded())) m away" }
    return String(format: "%.1f km away", meters / 1000)
}
