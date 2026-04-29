import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MapViewModel()
    @State private var locationService = LocationService()
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $viewModel.mapPosition) {
                UserAnnotation()

                if viewModel.walkPath.count > 1 {
                    MapPolyline(coordinates: viewModel.walkPath)
                        .stroke(AppConstants.accentColor, lineWidth: 4)
                }

                // TODO Phase 2: Render previously walked street segments from OSM data
            }
            .ignoresSafeArea(edges: .top)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }

            walkControlPanel
        }
        .task {
            let granted = await locationService.requestPermission()
            if !granted { showPermissionAlert = true }
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
    }

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
}
