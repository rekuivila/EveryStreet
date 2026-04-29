import Foundation
import CoreLocation
import SwiftData

@Model
final class Walk {
    var id: UUID
    var date: Date
    var duration: TimeInterval      // seconds
    var distanceMeters: Double
    var coordinatesData: Data       // JSON-encoded [[lat, lon]]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval,
        distanceMeters: Double,
        coordinatesData: Data
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.distanceMeters = distanceMeters
        self.coordinatesData = coordinatesData
    }

    var coordinates: [CLLocationCoordinate2D] {
        guard let pairs = try? JSONDecoder().decode([[Double]].self, from: coordinatesData) else {
            return []
        }
        return pairs.compactMap { pair in
            guard pair.count == 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
        }
    }

    var formattedDistance: String {
        distanceMeters >= 1000
            ? String(format: "%.2f km", distanceMeters / 1000)
            : String(format: "%.0f m", distanceMeters)
    }

    var formattedDuration: String {
        let total = Int(duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%dh %02dm", h, m)
            : String(format: "%dm %02ds", m, s)
    }
}
