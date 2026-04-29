import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \Walk.date, order: .reverse) private var walks: [Walk]
    @Query private var cachedStreets: [CachedStreet]

    // MARK: - Computed properties

    private var walkedCount: Int { cachedStreets.filter(\.isWalked).count }
    private var totalStreets: Int { cachedStreets.count }
    private var completionPercent: Double {
        totalStreets > 0 ? Double(walkedCount) / Double(totalStreets) : 0
    }

    private var totalDistance: Double { walks.reduce(0) { $0 + $1.distanceMeters } }
    private var formattedTotalDistance: String {
        totalDistance >= 1000
            ? String(format: "%.1f km", totalDistance / 1000)
            : String(format: "%.0f m", totalDistance)
    }

    private var streakInfo: StreakInfo { StreakCalculator.compute(from: walks) }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    completionCard
                    statsGrid
                    recentWalksCard
                }
                .padding()
            }
            .navigationTitle("Stats")
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Completion card

    private var completionCard: some View {
        VStack(spacing: 16) {
            ZStack {
                CircularProgressRing(progress: completionPercent, size: 160)
                VStack(spacing: 4) {
                    Text("\(Int(completionPercent * 100))%")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(walkedCount) of \(totalStreets) streets walked")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                value: "\(streakInfo.current)",
                label: "Current Streak",
                icon: "flame.fill",
                iconColor: .orange
            )
            StatCard(
                value: formattedTotalDistance,
                label: "Total Distance",
                icon: "ruler",
                iconColor: AppConstants.accentColor
            )
            StatCard(
                value: "\(walks.count)",
                label: "Total Walks",
                icon: "figure.walk",
                iconColor: .blue
            )
            StatCard(
                value: "\(streakInfo.best)",
                label: "Best Streak",
                icon: "trophy.fill",
                iconColor: .yellow
            )
        }
    }

    // MARK: - Recent walks card

    private var recentWalksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Walks").font(.headline)

            if walks.isEmpty {
                Text("No walks yet — tap Start Walk on the map to begin!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(walks.prefix(10)) { walk in
                    WalkRowView(walk: walk)
                    if walk.id != walks.prefix(10).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Circular progress ring

private struct CircularProgressRing: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: size * 0.1)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppConstants.accentColor,
                    style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Stat card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.title2).fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Walk row

private struct WalkRowView: View {
    let walk: Walk

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(walk.date, style: .date)
                    .font(.subheadline).fontWeight(.medium)
                Text(walk.date, style: .time)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(walk.formattedDistance)
                    .font(.subheadline).fontWeight(.medium)
                Text(walk.formattedDuration)
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
