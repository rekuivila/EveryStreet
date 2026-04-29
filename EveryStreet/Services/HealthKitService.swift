import Foundation
import HealthKit

// TODO Phase 2: Enable the HealthKit capability in Signing & Capabilities,
// then call requestAuthorization() at app launch before importing workouts.
// Also add NSHealthShareUsageDescription + NSHealthUpdateUsageDescription to Info.plist.

final class HealthKitService {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        guard isAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    // TODO Phase 2: Import recent walking/hiking workouts and convert to Walk objects.
    func fetchRecentWalkingWorkouts(since date: Date) async throws -> [HKWorkout] {
        guard isAvailable else { return [] }

        let walkPredicate = HKQuery.predicateForWorkouts(with: .walking)
        let hikePredicate = HKQuery.predicateForWorkouts(with: .hiking)
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [walkPredicate, hikePredicate])

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: 100,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
                }
            }
            store.execute(query)
        }
    }
}
