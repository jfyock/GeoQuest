//
//  ContentView.swift
//  GeoQuest
//
//  Created by Jacob Fyock on 2/25/26.
//

import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        Group {
            switch appState.authPhase {
            case .loading:
                LoadingScreenView()
            case .unauthenticated:
                AuthGateView()
            case .authenticated:
                MainTabView()
            }
        }
        .environment(appState)
        .task {
            appState.locationService.requestPermission()
            await appState.initialize()
        }
    }
}
