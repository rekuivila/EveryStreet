import Foundation
import CoreLocation
import SwiftUI

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

// MARK: - Point-to-segment distance

extension CLLocationCoordinate2D {
    /// Minimum distance in metres from this point to the line segment [a, b].
    ///
    /// Uses a flat-earth approximation accurate to within ~0.1 % for segments
    /// under 500 m (typical city block), which is sufficient for street matching.
    func distanceToSegment(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let cosLat = cos(a.latitude * .pi / 180)
        let mPerLat: Double = 111_320
        let mPerLon: Double = 111_320 * cosLat

        // Convert all coordinates to local metres relative to segment start A.
        let px = (longitude - a.longitude) * mPerLon
        let py = (latitude  - a.latitude)  * mPerLat
        let bx = (b.longitude - a.longitude) * mPerLon
        let by = (b.latitude  - a.latitude)  * mPerLat

        let segLenSq = bx * bx + by * by

        if segLenSq == 0 {
            // Degenerate segment — distance to the single point A.
            return sqrt(px * px + py * py)
        }

        // Project p onto the segment; clamp t to [0, 1].
        let t = max(0, min(1, (px * bx + py * by) / segLenSq))

        let closestX = t * bx
        let closestY = t * by

        let dx = px - closestX
        let dy = py - closestY
        return sqrt(dx * dx + dy * dy)
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

// MARK: - Hex color

extension Color {
    /// Creates a color from a 6-character hex string, e.g. "FF3B30" or "#00E5A0".
    /// Falls back to `.clear` if the string cannot be parsed.
    init(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleaned.count == 6,
              let value = UInt64(cleaned, radix: 16) else {
            self = .clear
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >>  8) & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
