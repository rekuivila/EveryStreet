import Foundation
import CoreLocation

// MARK: - Haversine distance

extension CLLocationCoordinate2D {
    /// Great-circle distance in metres using the Haversine formula.
    func distance(to other: CLLocationCoordinate2D) -> Double {
        let R = 6_371_000.0
        let φ1 = latitude  * .pi / 180
        let φ2 = other.latitude  * .pi / 180
        let Δφ = (other.latitude  - latitude)  * .pi / 180
        let Δλ = (other.longitude - longitude) * .pi / 180
        let a = sin(Δφ / 2) * sin(Δφ / 2)
              + cos(φ1) * cos(φ2) * sin(Δλ / 2) * sin(Δλ / 2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

// MARK: - Coordinate serialisation

extension Array where Element == CLLocationCoordinate2D {
    /// Encodes coordinates as JSON [[lat, lon]] for SwiftData storage.
    func encoded() -> Data {
        let pairs = map { [$0.latitude, $0.longitude] }
        return (try? JSONEncoder().encode(pairs)) ?? Data()
    }
}

// MARK: - Walk preview helper

extension Walk {
    static func previewSample() -> Walk {
        let coords = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7755, longitude: -122.4180),
            CLLocationCoordinate2D(latitude: 37.7762, longitude: -122.4165)
        ]
        return Walk(duration: 1_800, distanceMeters: 2_400, coordinatesData: coords.encoded())
    }
}
