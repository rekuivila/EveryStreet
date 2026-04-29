import Foundation
import CoreLocation

// Fetches walkable street segments from OpenStreetMap via Nominatim + Overpass API,
// and matches a recorded GPS walk to those segments.
struct StreetService {

    // MARK: - Public API

    /// Fetches all walkable streets within the bounding box of the given US ZIP code.
    func fetchStreets(zipCode: String) async throws -> [Street] {
        let trimmed = zipCode.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw ServiceError.invalidZipCode }

        let bbox = try await fetchBoundingBox(for: trimmed)
        let elements = try await fetchOverpassElements(bbox: bbox)

        return elements.compactMap { element -> Street? in
            guard let geometry = element.geometry, !geometry.isEmpty else { return nil }
            let pairs = geometry.map { [$0.lat, $0.lon] }
            guard let data = try? JSONEncoder().encode(pairs) else { return nil }
            let name = element.tags?["name"] ?? element.tags?["highway"] ?? "Unnamed"
            return Street(id: String(element.id), name: name, coordinatesData: data)
        }
    }

    /// Matches GPS coordinates from a walk to the given cached streets.
    /// Returns the set of osmIDs that the walk covered.
    static func matchWalkToStreets(
        walkCoordinates: [CLLocationCoordinate2D],
        streets: [CachedStreet]
    ) -> Set<String> {
        let threshold = 15.0  // metres
        var matched = Set<String>()

        for street in streets where !street.isWalked {
            let streetCoords = street.coordinates
            guard streetCoords.count >= 2 else { continue }

            streetLoop: for point in walkCoordinates {
                for i in 0 ..< streetCoords.count - 1 {
                    let dist = point.distanceToSegment(from: streetCoords[i], to: streetCoords[i + 1])
                    if dist <= threshold {
                        matched.insert(street.osmID)
                        break streetLoop
                    }
                }
            }
        }

        return matched
    }

    // MARK: - Private helpers

    private func fetchBoundingBox(for zipCode: String) async throws -> BoundingBox {
        var components = URLComponents(string: "https://nominatim.openstreetmap.org/search")
        components?.queryItems = [
            URLQueryItem(name: "postalcode", value: zipCode),
            URLQueryItem(name: "country", value: "us"),
            URLQueryItem(name: "format", value: "json"),
        ]

        guard let url = components?.url else { throw ServiceError.invalidZipCode }

        var request = URLRequest(url: url)
        request.setValue("EveryStreet/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw ServiceError.networkError(underlying: URLError(.badServerResponse))
        }

        let places: [NominatimPlace]
        do {
            places = try JSONDecoder().decode([NominatimPlace].self, from: data)
        } catch {
            throw ServiceError.decodingError(underlying: error)
        }

        guard let place = places.first, place.boundingbox.count == 4 else {
            throw ServiceError.invalidZipCode
        }

        guard
            let south = Double(place.boundingbox[0]),
            let north = Double(place.boundingbox[1]),
            let west  = Double(place.boundingbox[2]),
            let east  = Double(place.boundingbox[3])
        else {
            throw ServiceError.invalidZipCode
        }

        return BoundingBox(south: south, west: west, north: north, east: east)
    }

    private func fetchOverpassElements(bbox: BoundingBox) async throws -> [OverpassElement] {
        guard let url = URL(string: "https://overpass-api.de/api/interpreter") else {
            throw ServiceError.networkError(underlying: URLError(.badURL))
        }

        let query = """
            [out:json][timeout:30];
            way["highway"~"^(residential|living_street|footway|path|pedestrian|service|unclassified|tertiary|secondary|primary)$"](\(bbox.south),\(bbox.west),\(bbox.north),\(bbox.east));
            out geom;
            """

        // URL-encode the "data" parameter using URLComponents
        var formComponents = URLComponents()
        formComponents.queryItems = [URLQueryItem(name: "data", value: query)]
        guard let bodyString = formComponents.percentEncodedQuery else {
            throw ServiceError.networkError(underlying: URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("EveryStreet/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ServiceError.networkError(underlying: error)
        }

        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw ServiceError.networkError(underlying: URLError(.badServerResponse))
        }

        do {
            let overpass = try JSONDecoder().decode(OverpassResponse.self, from: data)
            return overpass.elements
        } catch {
            throw ServiceError.decodingError(underlying: error)
        }
    }
}

// MARK: - Private types

private struct BoundingBox {
    let south: Double
    let west: Double
    let north: Double
    let east: Double
}

private struct NominatimPlace: Decodable {
    let boundingbox: [String]   // [south, north, west, east]
}

private struct OverpassResponse: Decodable {
    let elements: [OverpassElement]
}

private struct OverpassElement: Decodable {
    let id: Int64
    let tags: [String: String]?
    let geometry: [OverpassNode]?
}

private struct OverpassNode: Decodable {
    let lat: Double
    let lon: Double
}

// MARK: - ServiceError

enum ServiceError: LocalizedError {
    case invalidZipCode
    case notImplemented
    case networkError(underlying: Error)
    case decodingError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidZipCode:
            return "The ZIP code could not be found. Please check and try again."
        case .notImplemented:
            return "This feature is coming in a future update."
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .decodingError(let e):
            return "Data error: \(e.localizedDescription)"
        }
    }
}
