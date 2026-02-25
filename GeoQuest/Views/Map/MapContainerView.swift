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
                viewModel = MapViewModel(questService: appState.questService)
            }
        }
    }

    @ViewBuilder
    private func mapContent(viewModel: MapViewModel) -> some View {
        @Bindable var vm = viewModel

        ZStack {
            Map(position: $vm.cameraPosition) {
                // Player avatar
                if let location = appState.locationService.currentLocation {
                    Annotation("Me", coordinate: location) {
                        AvatarMapAnnotationView(config: appState.currentUser?.avatarConfig)
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
                Task {
                    await viewModel.loadQuestsForRegion(center: context.camera.centerCoordinate)
                }
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
            }
        }
    }
}

// Make String conform to Identifiable for sheet binding
extension String: @retroactive Identifiable {
    public var id: String { self }
}
