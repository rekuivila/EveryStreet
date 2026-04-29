import Foundation
import CoreLocation
import SwiftData

/// SwiftData model for persisting OSM street segments fetched for a given ZIP code.
@Model
final class CachedStreet {
    var osmID: String
    var name: String
    var zipCode: String
    var coordinatesData: Data        // JSON-encoded [[lat, lon]]
    var isWalked: Bool
    var fetchedAt: Date

    init(
        osmID: String,
        name: String,
        zipCode: String,
        coordinatesData: Data
    ) {
        self.osmID = osmID
        self.name = name
        self.zipCode = zipCode
        self.coordinatesData = coordinatesData
        self.isWalked = false
        self.fetchedAt = Date()
    }

    /// Decoded coordinates from the stored JSON [[lat, lon]] data.
    var coordinates: [CLLocationCoordinate2D] {
        guard let pairs = try? JSONDecoder().decode([[Double]].self, from: coordinatesData) else {
            return []
        }
        return pairs.compactMap { pair in
            guard pair.count == 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
        }
    }
}
