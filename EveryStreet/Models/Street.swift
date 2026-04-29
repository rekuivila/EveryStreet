import Foundation
import CoreLocation

// Represents one OSM way segment within a zip-code boundary.
struct Street: Identifiable, Codable {
    let id: String          // OSM way ID
    let name: String
    let coordinates: [[Double]]     // [[lat, lon], ...]
    var isWalked: Bool

    var polylineCoordinates: [CLLocationCoordinate2D] {
        coordinates.compactMap { pair in
            guard pair.count == 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
        }
    }
}

// TODO Phase 2: Fetch streets via Overpass API query:
//   [out:json];
//   area[postal_code="XXXXX"];
//   way[highway~"^(residential|tertiary|secondary|primary)$"](area);
//   out geom;
// Persist walked street IDs in Supabase per user.
