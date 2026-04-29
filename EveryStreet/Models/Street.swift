import Foundation

// Lightweight DTO representing one OSM way segment within a ZIP-code boundary.
// This is a transient value type — use CachedStreet for SwiftData persistence.
struct Street: Identifiable, Codable {
    let id: String          // OSM way ID
    let name: String
    let coordinatesData: Data   // JSON-encoded [[lat, lon]]
}

// TODO Phase 2: OSM Overpass API query used to fetch streets:
//   [out:json][timeout:30];
//   way["highway"~"^(residential|living_street|footway|path|pedestrian|service|unclassified|tertiary|secondary|primary)$"]
//     ({south},{west},{north},{east});
//   out geom;
// Bounding box is derived from Nominatim postal-code lookup.
