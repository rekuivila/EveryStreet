import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \Walk.date, order: .reverse) private var walks: [Walk]

    private var streakInfo: StreakInfo {
        StreakCalculator.compute(from: walks)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    streakCard
                    progressCard
                    recentWalksCard
                }
                .padding()
            }
            .navigationTitle("Stats")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var streakCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("Current Streak").font(.headline)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(streakInfo.current)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                Text("days")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Best: \(streakInfo.best)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "map.fill").foregroundStyle(AppConstants.accentColor)
                Text("Neighborhood Progress").font(.headline)
                Spacer()
            }
            // TODO Phase 2: Populate from OSM street-matching data
            ProgressView(value: 0.0)
                .tint(AppConstants.accentColor)
            HStack {
                Text("0% complete")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("0 / 0 streets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

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
