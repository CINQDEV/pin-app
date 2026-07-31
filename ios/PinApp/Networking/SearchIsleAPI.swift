import Foundation

enum SearchIsleAPIError: Error {
    case badResponse(Int)
}

/// Raw shape of a WordPress `wp/v2/islands` record, trimmed to the fields
/// requested via `_fields=id,title,link,acf`.
private struct WPIslandRecord: Decodable {
    struct Title: Decodable {
        let rendered: String
    }
    struct ACF: Decodable {
        struct IslandMap: Decodable {
            let lat: Double
            let lng: Double
        }
        let island_map: IslandMap?
        let island_intro: String?
    }

    let id: Int
    let link: String
    let title: Title
    let acf: ACF?
    let featured_media: Int?
}

enum SearchIsleAPI {
    private static let baseURL = URL(string: "https://searchisle.com/wp-json/wp/v2/islands")!
    private static let perPage = 100
    private static let pageFetchConcurrency = 4

    /// Fetches every island from the public searchisle.com REST API, paginating as needed.
    static func fetchAllIslands() async throws -> [Island] {
        let first = try await fetchPage(1)
        var allRecords = first.records

        if first.totalPages > 1 {
            let remainingPages = Array(2...first.totalPages)
            var index = 0
            while index < remainingPages.count {
                let batch = remainingPages[index..<min(index + pageFetchConcurrency, remainingPages.count)]
                let results = try await withThrowingTaskGroup(of: [WPIslandRecord].self) { group in
                    for page in batch {
                        group.addTask { try await fetchPage(page).records }
                    }
                    var collected: [WPIslandRecord] = []
                    for try await records in group {
                        collected.append(contentsOf: records)
                    }
                    return collected
                }
                allRecords.append(contentsOf: results)
                index += pageFetchConcurrency
            }
        }

        return allRecords.compactMap(toIsland)
    }

    private static func fetchPage(_ page: Int) async throws -> (records: [WPIslandRecord], totalPages: Int) {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "_fields", value: "id,title,link,acf,featured_media"),
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw SearchIsleAPIError.badResponse(status)
        }
        let totalPages = Int(http.value(forHTTPHeaderField: "X-WP-TotalPages") ?? "1") ?? 1
        let records = try JSONDecoder().decode([WPIslandRecord].self, from: data)
        return (records, totalPages)
    }

    private static func toIsland(_ record: WPIslandRecord) -> Island? {
        guard let coords = record.acf?.island_map else { return nil }
        return Island(
            id: String(record.id),
            name: htmlToPlainText(record.title.rendered),
            description: htmlToPlainText(record.acf?.island_intro ?? ""),
            lat: coords.lat,
            lng: coords.lng,
            url: record.link,
            featuredMediaID: (record.featured_media ?? 0) == 0 ? nil : record.featured_media
        )
    }

    /// WordPress fields come back as HTML fragments with entity-encoded characters
    /// (e.g. "Thompson&#8217;s Holme", "<p>...</p>"). NSAttributedString's HTML
    /// importer could do this in one call but requires the main thread; this runs
    /// from background tasks, so tags/entities are stripped manually instead.
    private static func htmlToPlainText(_ html: String) -> String {
        guard !html.isEmpty else { return html }
        let withoutTags = html.replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression)
        return decodeHTMLEntities(withoutTags).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        if let regex = try? NSRegularExpression(pattern: "&#(\\d+);") {
            let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed()
            for match in matches {
                guard let range = Range(match.range, in: result),
                      let codeRange = Range(match.range(at: 1), in: result),
                      let code = UInt32(result[codeRange]),
                      let scalar = Unicode.Scalar(code)
                else { continue }
                result.replaceSubrange(range, with: String(Character(scalar)))
            }
        }
        return result
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#039;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }

    private struct MediaRecord: Decodable {
        struct Sizes: Decodable {
            struct Size: Decodable { let source_url: String }
            let large: Size?
            let medium: Size?
        }
        struct MediaDetails: Decodable { let sizes: Sizes? }
        let source_url: String?
        let media_details: MediaDetails?
    }

    /// Fetched lazily (not part of the bulk list fetch) — only called when a detail
    /// screen for a specific island with a `featuredMediaID` is actually shown.
    static func fetchImageURL(mediaID: Int) async throws -> URL? {
        var components = URLComponents(string: "https://searchisle.com/wp-json/wp/v2/media/\(mediaID)")!
        components.queryItems = [URLQueryItem(name: "_fields", value: "source_url,media_details")]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SearchIsleAPIError.badResponse((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        let media = try JSONDecoder().decode(MediaRecord.self, from: data)
        let urlString = media.media_details?.sizes?.large?.source_url
            ?? media.media_details?.sizes?.medium?.source_url
            ?? media.source_url
        return urlString.flatMap(URL.init(string:))
    }
}
