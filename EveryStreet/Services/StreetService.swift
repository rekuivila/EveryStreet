import Foundation
import CoreLocation

// Fetches and matches street segments from OpenStreetMap's Overpass API.
struct StreetService {
    private let overpassURL = URL(string: "https://overpass-api.de/api/interpreter")!

    // TODO Phase 2: Implement — fetch all walkable streets within a zip code bounding box.
    func fetchStreets(in zipCode: String) async throws -> [Street] {
        throw ServiceError.notImplemented
    }

    // TODO Phase 2: Implement — snap GPS polyline to nearest street segments.
    // Uses haversine distance; returns set of OSM way IDs covered by this walk.
    func matchWalkToStreets(_ walk: Walk, streets: [Street]) -> Set<String> {
        return []
    }
}

enum ServiceError: LocalizedError {
    case notImplemented
    case networkError(underlying: Error)
    case decodingError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notImplemented:      return "This feature is coming in a future update."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .decodingError(let e): return "Data error: \(e.localizedDescription)"
        }
    }
}
