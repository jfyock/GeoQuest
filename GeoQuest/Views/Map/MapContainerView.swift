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
                            compassHeading: appState.locationService.compassHeading,
                            mapHeading: viewModel.cameraHeading,
                            cameraPitch: viewModel.cameraPitch,
                            zoomScale: viewModel.playerAnnotationScale,
                            emote: viewModel.activeEmote
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

                // Atmospheric elements anchored to real map coordinates
                ForEach(viewModel.atmosphericElements) { element in
                    Annotation("", coordinate: element.coordinate, anchor: .center) {
                        AtmosphericAnnotationView(element: element)
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
                viewModel.cameraPitch = context.camera.pitch
                viewModel.cameraSpanLatitudeDelta = context.region.span.latitudeDelta
                viewModel.cameraCenterCoordinate = context.camera.centerCoordinate
                Task {
                    await viewModel.loadQuestsForRegion(center: context.camera.centerCoordinate)
                    await viewModel.regenerateAtmosphericElements(center: context.camera.centerCoordinate)
                }
            }
            .onMapCameraChange(frequency: .continuous) { context in
                viewModel.cameraHeading = context.camera.heading
                viewModel.cameraPitch = context.camera.pitch
                viewModel.cameraSpanLatitudeDelta = context.region.span.latitudeDelta
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

                    // Loading indicator or refresh button
                    if viewModel.isLoadingQuests {
                        ProgressView()
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    } else {
                        Button {
                            Task {
                                if let location = appState.locationService.currentLocation {
                                    await viewModel.forceRegenerate(near: location)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial, in: Circle())
                                .gqShadow()
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
                .padding(.horizontal, GQTheme.paddingMedium)

                Spacer()

                HStack {
                    Spacer()

                    // Emote button
                    Button {
                        withAnimation(GQTheme.bouncy) {
                            viewModel.showEmoteMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "face.smiling.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(GQTheme.accent)
                            .frame(width: 48, height: 48)
                            .background(.ultraThinMaterial, in: Circle())
                            .gqShadow()
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .padding(.trailing, GQTheme.paddingMedium)
                    .padding(.bottom, GQTheme.paddingSmall)
                }

                #if DEBUG
                DebugMovementOverlay(locationService: appState.locationService)
                #endif
            }
            .padding(.top, 8)
        }
        .overlay {
            if viewModel.showEmoteMenu {
                let equippedEmoteIds = appState.currentUser?.avatarConfig.equippedEmotes ?? []
                let availableEmotes = EmoteType.allCases.filter { emote in
                    // Show default emotes + equipped ones
                    let defaults: Set<String> = ["wave", "clap", "shrug"]
                    return defaults.contains(emote.rawValue) || equippedEmoteIds.contains(emote.rawValue)
                }
                EmoteMenuView(
                    availableEmotes: availableEmotes,
                    onSelectEmote: { emote in
                        viewModel.activeEmote = emote
                        // Clear emote after animation plays
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            viewModel.activeEmote = nil
                        }
                    },
                    onDismiss: {
                        withAnimation(GQTheme.bouncy) {
                            viewModel.showEmoteMenu = false
                        }
                    }
                )
            }
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
                // Populate atmospheric world elements around the player
                await viewModel.regenerateAtmosphericElements(center: location)
            }
        }
    }
}

// Make String conform to Identifiable for sheet binding
extension String: @retroactive Identifiable {
    public var id: String { self }
}
