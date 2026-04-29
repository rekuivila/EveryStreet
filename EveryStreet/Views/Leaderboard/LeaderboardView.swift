import SwiftUI

struct LeaderboardView: View {
    @State private var selectedScope = LeaderboardScope.global

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Scope", selection: $selectedScope) {
                    Text("Global").tag(LeaderboardScope.global)
                    Text("Friends").tag(LeaderboardScope.friends)
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    LazyVStack(spacing: 8) {
                        // TODO Phase 2: Replace placeholders with live Supabase data
                        ForEach(LeaderboardEntry.placeholders(for: selectedScope)) { entry in
                            LeaderboardRowView(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Leaderboard")
            .background(Color(.systemGroupedBackground))
        }
    }
}

private struct LeaderboardRowView: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 14) {
            rankBadge
            avatarCircle
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.displayName)
                    .font(.subheadline).fontWeight(.medium)
                Text("\(entry.streetsWalked) streets walked")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(entry.completionPercent)%")
                .font(.subheadline).fontWeight(.bold)
                .foregroundStyle(AppConstants.accentColor)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var rankBadge: some View {
        Group {
            switch entry.rank {
            case 1: Image(systemName: "medal.fill").foregroundStyle(.yellow).font(.title2)
            case 2: Image(systemName: "medal.fill").foregroundStyle(Color(white: 0.7)).font(.title2)
            case 3: Image(systemName: "medal.fill").foregroundStyle(.brown).font(.title2)
            default:
                Text("#\(entry.rank)")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
            }
        }
    }

    private var avatarCircle: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: 40, height: 40)
            .overlay(
                Text(entry.displayName.prefix(1).uppercased())
                    .font(.headline).foregroundStyle(.secondary)
            )
    }
}

enum LeaderboardScope {
    case global, friends
}

struct LeaderboardEntry: Identifiable {
    let id: UUID
    let displayName: String
    let streetsWalked: Int
    let completionPercent: Int
    let rank: Int

    static func placeholders(for scope: LeaderboardScope) -> [LeaderboardEntry] {
        // TODO Phase 2: Remove placeholders — fetch from Supabase with RLS per scope
        let names: [String]
        switch scope {
        case .global:
            names = ["explorer_4f2a", "wanderer_9b1c", "pathfinder_7e3d", "walker_2a8f", "roamer_5c1b"]
        case .friends:
            names = ["You", "friend_alpha", "friend_beta"]
        }
        return names.enumerated().map { index, name in
            LeaderboardEntry(
                id: UUID(),
                displayName: name,
                streetsWalked: max(1, 130 - index * 22),
                completionPercent: max(1, 88 - index * 14),
                rank: index + 1
            )
        }
    }
}
