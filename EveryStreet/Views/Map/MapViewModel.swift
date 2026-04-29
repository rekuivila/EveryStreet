import SwiftUI
import MapKit
import CoreLocation
import SwiftData

@Observable
final class MapViewModel {
    var walkPath: [CLLocationCoordinate2D] = []
    var isRecording = false
    var elapsedSeconds: Int = 0
    var distanceMeters: Double = 0
    var mapPosition: MapCameraPosition = .userLocation(
        followsHeading: false,
        fallback: .region(MKCoordinateRegion(
            center: AppConstants.MapDefaults.defaultCenter,
            span: AppConstants.MapDefaults.defaultSpan
        ))
    )

    // TODO Phase 2: walkedSegments: [Street] for rendering previously walked streets as overlays

    private var recordingTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    var formattedElapsedTime: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    var formattedDistance: String {
        distanceMeters >= 1000
            ? String(format: "%.2f km", distanceMeters / 1000)
            : String(format: "%.0f m", distanceMeters)
    }

    func startWalk(locationService: LocationService) {
        walkPath = []
        elapsedSeconds = 0
        distanceMeters = 0
        isRecording = true

        locationService.startTracking()

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                await MainActor.run { self?.elapsedSeconds += 1 }
            }
        }

        recordingTask = Task { [weak self] in
            for await location in locationService.locationStream {
                guard let self else { break }
                let coord = location.coordinate
                await MainActor.run {
                    if let last = self.walkPath.last {
                        self.distanceMeters += last.distance(to: coord)
                    }
                    self.walkPath.append(coord)
                }
            }
        }
    }

    func endWalk(locationService: LocationService, modelContext: ModelContext) {
        isRecording = false
        locationService.stopTracking()
        recordingTask?.cancel()
        timerTask?.cancel()
        recordingTask = nil
        timerTask = nil

        guard !walkPath.isEmpty else { return }

        let walk = Walk(
            duration: TimeInterval(elapsedSeconds),
            distanceMeters: distanceMeters,
            coordinatesData: walkPath.encoded()
        )
        modelContext.insert(walk)

        // TODO Phase 2: Upload walk to Supabase, run OSM street-matching, update leaderboard
    }
}
