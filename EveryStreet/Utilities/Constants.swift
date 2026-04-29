import SwiftUI
import CoreLocation
import MapKit

enum AppConstants {
    static let appName = "Every Street"
    static let accentColor = Color(red: 0.18, green: 0.80, blue: 0.44)  // fresh green

    enum MapDefaults {
        static let defaultCenter = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        static let defaultSpan   = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    }

    enum WalkTracking {
        static let minimumDistanceFilter: CLLocationDistance = 5     // metres
        static let desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    }

    enum Supabase {
        // TODO Phase 2: Replace with your project credentials (load from .xcconfig, not hardcoded).
        static let projectURL = "https://your-project.supabase.co"
        static let anonKey    = "your-anon-key"
    }
}
