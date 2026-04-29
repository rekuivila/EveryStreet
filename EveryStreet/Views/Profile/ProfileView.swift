import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Query(sort: \Walk.date, order: .reverse) private var walks: [Walk]
    @Query private var cachedStreets: [CachedStreet]

    @State private var editingZip = false
    @State private var zipInput = ""

    private var totalDistanceMeters: Double { walks.reduce(0) { $0 + $1.distanceMeters } }
    private var formattedTotalDistance: String {
        totalDistanceMeters >= 1000
            ? String(format: "%.1f km", totalDistanceMeters / 1000)
            : String(format: "%.0f m", totalDistanceMeters)
    }

    private var walkedCount: Int { cachedStreets.filter(\.isWalked).count }
    private var completionPercent: Double {
        cachedStreets.isEmpty ? 0 : Double(walkedCount) / Double(cachedStreets.count)
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
        .sheet(isPresented: $editingZip) {
            zipEditSheet
        }
    }

    // MARK: - Profile header

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
                HStack(spacing: 4) {
                    Label(zip, systemImage: "mappin.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        zipInput = zip
                        editingZip = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.subheadline)
                            .foregroundStyle(AppConstants.accentColor)
                    }
                }
            } else {
                Button {
                    zipInput = ""
                    editingZip = true
                } label: {
                    Label("Set ZIP Code", systemImage: "mappin.circle")
                        .font(.subheadline)
                        .foregroundStyle(AppConstants.accentColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCell(value: "\(walks.count)", label: "Total Walks", icon: "figure.walk")
            StatCell(value: formattedTotalDistance, label: "Total Distance", icon: "ruler")
            StatCell(value: "\(walkedCount)", label: "Streets Walked", icon: "road.lanes")
            StatCell(value: "\(Int(completionPercent * 100))%", label: "Completion", icon: "percent")
        }
    }

    // MARK: - Connected apps

    private var connectedAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected Apps")
                .font(.headline)
                .padding(.horizontal, 4)

            // TODO Phase 3: OAuth flows for Strava, Garmin; Apple HealthKit authorization
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

    // MARK: - ZIP edit sheet

    private var zipEditSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("ZIP Code", text: $zipInput)
                    .keyboardType(.numberPad)
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("ZIP Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingZip = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        authViewModel.currentUser?.zipCode = zipInput
                        editingZip = false
                    }
                    .disabled(zipInput.count != 5)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Stat cell

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
