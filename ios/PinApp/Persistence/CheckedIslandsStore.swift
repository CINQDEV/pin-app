import Foundation

/// On-device persistence for check-in state and a list cache — searchisle.com's
/// API is read-only and not ours, so there's nowhere server-side to record catches.
enum CheckedIslandsStore {
    private static let checkedIdsKey = "pinapp.checkedIslandIds"
    private static let islandsCacheKey = "pinapp.islandsCache"

    static func loadCheckedIds() -> Set<String> {
        let ids = UserDefaults.standard.stringArray(forKey: checkedIdsKey) ?? []
        return Set(ids)
    }

    static func saveCheckedIds(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: checkedIdsKey)
    }

    static func loadCachedIslands() -> [Island]? {
        guard let data = UserDefaults.standard.data(forKey: islandsCacheKey) else { return nil }
        return try? JSONDecoder().decode([Island].self, from: data)
    }

    static func saveCachedIslands(_ islands: [Island]) {
        guard let data = try? JSONEncoder().encode(islands) else { return }
        UserDefaults.standard.set(data, forKey: islandsCacheKey)
    }
}
