import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Query(sort: \Walk.date, order: .reverse) private var walks: [Walk]

    private var totalDistanceMeters: Double { walks.reduce(0) { $0 + $1.distanceMeters } }
    private var formattedTotalDistance: String {
        totalDistanceMeters >= 1000
            ? String(format: "%.1f km", totalDistanceMeters / 1000)
            : String(format: "%.0f m", totalDistanceMeters)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    statsGrid
                    connectedAppsSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out", role: .destructive) {
                        authViewModel.signOut()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(AppConstants.accentColor.opacity(0.15))
                .frame(width: 84, height: 84)
                .overlay(
                    Image(systemName: "figure.walk")
                        .font(.system(size: 38))
                        .foregroundStyle(AppConstants.accentColor)
                )

            Text(authViewModel.currentUser?.username ?? "Explorer")
                .font(.title2).fontWeight(.bold)

            if let zip = authViewModel.currentUser?.zipCode, !zip.isEmpty {
                Label(zip, systemImage: "mappin.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCell(value: "\(walks.count)", label: "Total Walks", icon: "figure.walk")
            StatCell(value: formattedTotalDistance, label: "Total Distance", icon: "ruler")
            // TODO Phase 2: Populate from OSM street-matching data
            StatCell(value: "0", label: "Streets Walked", icon: "road.lanes")
            StatCell(value: "0%", label: "Completion", icon: "percent")
        }
    }

    private var connectedAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected Apps")
                .font(.headline)
                .padding(.horizontal, 4)

            // TODO Phase 2: OAuth flows for Strava, Garmin; Apple HealthKit authorization
            connectedAppRow(icon: "figure.run", iconColor: .orange, name: "Strava")
            connectedAppRow(icon: "applewatch", iconColor: .green, name: "Apple Health")
            connectedAppRow(icon: "waveform.path.ecg", iconColor: .blue, name: "Garmin Connect")
        }
    }

    private func connectedAppRow(icon: String, iconColor: Color, name: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(iconColor).frame(width: 24)
            Text(name).font(.subheadline)
            Spacer()
            Text("Coming Soon")
                .font(.caption).foregroundStyle(.secondary)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct StatCell: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppConstants.accentColor)
            Text(value)
                .font(.title2).fontWeight(.bold)
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
