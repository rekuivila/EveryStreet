import Foundation
import CoreLocation

final class LocationService: NSObject {
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var lastLocation: CLLocation?

    private let manager = CLLocationManager()
    private var locationContinuation: AsyncStream<CLLocation>.Continuation?
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    // A fresh stream is vended for each recording session via startTracking().
    private(set) var locationStream: AsyncStream<CLLocation> = AsyncStream { _ in }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = AppConstants.WalkTracking.desiredAccuracy
        manager.distanceFilter = AppConstants.WalkTracking.minimumDistanceFilter
        authorizationStatus = manager.authorizationStatus
    }

    // Returns true if permission is granted (or already was).
    func requestPermission() async -> Bool {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            let status = await withCheckedContinuation { continuation in
                authContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
            return status == .authorizedWhenInUse || status == .authorizedAlways
        @unknown default:
            return false
        }
    }

    func startTracking() {
        // Create a fresh stream so each walk session gets isolated location events.
        locationStream = AsyncStream { [weak self] continuation in
            self?.locationContinuation = continuation
        }
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        locationContinuation?.finish()
        locationContinuation = nil
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        locationContinuation?.yield(location)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        guard manager.authorizationStatus != .notDetermined else { return }
        authContinuation?.resume(returning: manager.authorizationStatus)
        authContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO Phase 2: Surface persistent errors to the user via an observable error state
        print("[LocationService] error: \(error.localizedDescription)")
    }
}
