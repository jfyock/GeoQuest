import SwiftUI
import MapKit

struct MapContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: MapViewModel?

    var body: some View {
        ZStack {
            if let viewModel {
                mapContent(viewModel: viewModel)
            } else {
                GQLoadingIndicator(message: "Loading map...")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MapViewModel(
                    questService: appState.questService,
                    questGenerationService: appState.questGenerationService
                )
            }
        }
    }

    @ViewBuilder
    private func mapContent(viewModel: MapViewModel) -> some View {
        @Bindable var vm = viewModel

        ZStack {
            Map(position: $vm.cameraPosition) {
                // GPS accuracy radius — flat blue disc on the map ground plane
                if let location = appState.locationService.currentLocation,
                   appState.locationService.gpsAccuracy > 0 {
                    MapCircle(center: location, radius: appState.locationService.gpsAccuracy)
                        .foregroundStyle(GQTheme.primary.opacity(0.12))
                        .stroke(GQTheme.primary.opacity(0.3), lineWidth: 1.5)
                }

                // Player avatar with 3D model and movement-aware animation
                if let location = appState.locationService.currentLocation {
                    Annotation("Me", coordinate: location) {
                        AvatarMapAnnotationView(
                            config: appState.currentUser?.avatarConfig,
                            isMoving: appState.locationService.isMoving,
                            movementHeading: appState.locationService.movementHeading,
                            mapHeading: viewModel.cameraHeading
                        )
                    }
                }

                // Quest annotations
                ForEach(viewModel.visibleQuests) { quest in
                    Annotation(quest.title, coordinate: quest.coordinate) {
                        QuestAnnotationView(data: quest)
                            .onTapGesture {
                                withAnimation(GQTheme.bouncyQuick) {
                                    viewModel.selectedQuestId = quest.id
                                }
                            }
                    }
                }
            }
            .mapStyle(MapStyleConfiguration.cartoonStyle)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                viewModel.cameraHeading = context.camera.heading
                Task {
                    await viewModel.loadQuestsForRegion(center: context.camera.centerCoordinate)
                }
            }
            .onMapCameraChange(frequency: .continuous) { context in
                viewModel.cameraHeading = context.camera.heading
            }

            // Floating controls overlay
            VStack {
                HStack {
                    // Menu button
                    Button {
                        withAnimation(GQTheme.bouncy) {
                            viewModel.showMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                            .gqShadow()
                    }
                    .buttonStyle(BouncyButtonStyle())

                    Spacer()

                    // Loading indicator
                    if viewModel.isLoadingQuests {
                        ProgressView()
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, GQTheme.paddingMedium)

                Spacer()

                #if DEBUG
                DebugMovementOverlay(locationService: appState.locationService)
                #endif
            }
            .padding(.top, 8)
        }
        .sheet(item: $vm.selectedQuestId) { questId in
            QuestDetailView(questId: questId, mapViewModel: viewModel)
        }
        .sheet(isPresented: $vm.showMenu) {
            GameMenuView()
                .presentationDetents([.medium, .large])
        }
        .task {
            if let location = appState.locationService.currentLocation {
                await viewModel.loadQuestsForRegion(center: location)
                // Generate quests if the area is sparse (runs once per geohash per session)
                await viewModel.generateQuestsIfNeeded(near: location)
            }
        }
    }
}

// Make String conform to Identifiable for sheet binding
extension String: @retroactive Identifiable {
    public var id: String { self }
}
