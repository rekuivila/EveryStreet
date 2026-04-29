import SwiftUI
import MapKit
import CoreLocation
import SwiftData

@MainActor
@Observable
final class MapViewModel {
    // MARK: - Walk tracking state

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

    // MARK: - Street overlay state

    var streets: [CachedStreet] = []
    var isLoadingStreets = false
    var streetLoadError: String?
    var completionPercent: Double = 0
    var newlyWalkedIDs: Set<String> = []
    var showZipCodePrompt = false

    // MARK: - Computed street views

    var walkedStreets: [CachedStreet] { streets.filter(\.isWalked) }
    var unwalkedStreets: [CachedStreet] { streets.filter { !$0.isWalked } }

    // MARK: - Private tasks

    private var recordingTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    // MARK: - Formatted accessors

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

    // MARK: - Street loading

    func loadStreets(for zipCode: String, modelContext: ModelContext) async {
        guard !zipCode.isEmpty else { return }
        guard streets.isEmpty else { return }

        // Check SwiftData cache first.
        let descriptor = FetchDescriptor<CachedStreet>(
            predicate: #Predicate { street in street.zipCode == zipCode }
        )
        if let cached = try? modelContext.fetch(descriptor), !cached.isEmpty {
            streets = cached
            updateCompletion()
            return
        }

        isLoadingStreets = true
        defer { isLoadingStreets = false }

        do {
            let dtos = try await StreetService().fetchStreets(zipCode: zipCode)
            let models = dtos.map { dto in
                CachedStreet(
                    osmID: dto.id,
                    name: dto.name,
                    zipCode: zipCode,
                    coordinatesData: dto.coordinatesData
                )
            }
            for model in models {
                modelContext.insert(model)
            }
            streets = models
            updateCompletion()
        } catch {
            streetLoadError = error.localizedDescription
        }
    }

    private func updateCompletion() {
        guard !streets.isEmpty else {
            completionPercent = 0
            return
        }
        completionPercent = Double(streets.filter(\.isWalked).count) / Double(streets.count)
    }

    // MARK: - Walk control

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
                guard let self else { break }
                self.elapsedSeconds += 1
            }
        }

        recordingTask = Task { [weak self] in
            for await location in locationService.locationStream {
                guard let self else { break }
                let coord = location.coordinate
                if let last = self.walkPath.last {
                    self.distanceMeters += last.distance(to: coord)
                }
                self.walkPath.append(coord)
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

        processStreetMatching(for: walkPath)
    }

    // MARK: - Street matching

    private func processStreetMatching(for coords: [CLLocationCoordinate2D]) {
        let matchedIDs = StreetService.matchWalkToStreets(
            walkCoordinates: coords,
            streets: streets
        )
        guard !matchedIDs.isEmpty else { return }

        var newlyWalked = Set<String>()
        for street in streets where matchedIDs.contains(street.osmID) && !street.isWalked {
            street.isWalked = true
            newlyWalked.insert(street.osmID)
        }

        guard !newlyWalked.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.8)) {
            newlyWalkedIDs = newlyWalked
            updateCompletion()
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                self.newlyWalkedIDs = []
            }
        }
    }
}
