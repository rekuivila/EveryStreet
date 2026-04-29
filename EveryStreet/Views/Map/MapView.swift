import SwiftUI
import MapKit
import SwiftData

@MainActor
struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = MapViewModel()
    @State private var locationService = LocationService()
    @State private var showPermissionAlert = false
    @State private var showZipSheet = false
    @State private var zipInput = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer

            // Completion pill — shown above the walk control panel when streets are loaded.
            if !viewModel.streets.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        completionPill
                        Spacer()
                    }
                    .padding(.leading, 16)
                    // Offset upward to clear the walk control panel (≈ 90 pt).
                    .padding(.bottom, 92)
                }
            }

            VStack(spacing: 0) {
                // Top banners
                VStack(spacing: 8) {
                    if viewModel.isLoadingStreets {
                        loadingBanner
                    }
                    if viewModel.streetLoadError != nil {
                        errorBanner
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)

                Spacer()

                walkControlPanel
            }
        }
        .task {
            let granted = await locationService.requestPermission()
            if !granted { showPermissionAlert = true }

            let zip = authViewModel.currentUser?.zipCode ?? ""
            if zip.isEmpty {
                showZipSheet = true
            } else {
                await viewModel.loadStreets(for: zip, modelContext: modelContext)
            }
        }
        .alert("Location Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every Street needs location access to track your walks. Enable it in Settings.")
        }
        .sheet(isPresented: $showZipSheet) {
            zipCodeSheet
        }
    }

    // MARK: - Map layer

    private var mapLayer: some View {
        Map(position: $viewModel.mapPosition) {
            // Unwalked streets — subtle dark overlay.
            ForEach(viewModel.unwalkedStreets, id: \.osmID) { street in
                MapPolyline(coordinates: street.coordinates)
                    .stroke(Color(hex: "444444"), lineWidth: 2)
            }

            // Walked streets — highlight in brand green; flash white for newly walked.
            ForEach(viewModel.walkedStreets, id: \.osmID) { street in
                MapPolyline(coordinates: street.coordinates)
                    .stroke(
                        viewModel.newlyWalkedIDs.contains(street.osmID)
                            ? Color.white
                            : Color(hex: "00E5A0"),
                        lineWidth: 4
                    )
            }

            // Active walk path.
            if viewModel.walkPath.count > 1 {
                MapPolyline(coordinates: viewModel.walkPath)
                    .stroke(AppConstants.accentColor, lineWidth: 5)
            }

            UserAnnotation()
        }
        .ignoresSafeArea(edges: .top)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Banners

    private var loadingBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
            Text("Loading streets…")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var errorBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(viewModel.streetLoadError ?? "Unknown error")
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                viewModel.streetLoadError = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.red.opacity(0.15), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Completion pill

    private var completionPill: some View {
        Text("\(Int(viewModel.completionPercent * 100))% complete")
            .font(.caption).fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppConstants.accentColor, in: Capsule())
    }

    // MARK: - Walk control panel

    private var walkControlPanel: some View {
        VStack(spacing: 0) {
            if viewModel.isRecording {
                liveStatsBar
            }

            Button {
                if viewModel.isRecording {
                    viewModel.endWalk(locationService: locationService, modelContext: modelContext)
                } else {
                    viewModel.startWalk(locationService: locationService)
                }
            } label: {
                Text(viewModel.isRecording ? "End Walk" : "Start Walk")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(viewModel.isRecording ? Color.red : AppConstants.accentColor)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
            }
            .background(.ultraThinMaterial)
        }
    }

    private var liveStatsBar: some View {
        HStack(spacing: 40) {
            statItem(value: viewModel.formattedElapsedTime, label: "Time", monospaced: true)
            statItem(value: viewModel.formattedDistance, label: "Distance")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    private func statItem(value: String, label: String, monospaced: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(monospaced
                    ? .system(size: 26, weight: .bold, design: .monospaced)
                    : .system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - ZIP code sheet

    private var zipCodeSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppConstants.accentColor)

                VStack(spacing: 8) {
                    Text("Your Neighborhood")
                        .font(.title2).fontWeight(.bold)
                    Text("Enter your ZIP code so we can load the streets in your area.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                TextField("ZIP Code", text: $zipInput)
                    .keyboardType(.numberPad)
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                Button {
                    authViewModel.currentUser?.zipCode = zipInput
                    showZipSheet = false
                    Task {
                        await viewModel.loadStreets(for: zipInput, modelContext: modelContext)
                    }
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(zipInput.count == 5 ? AppConstants.accentColor : Color.gray)
                        .cornerRadius(14)
                }
                .disabled(zipInput.count != 5)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
