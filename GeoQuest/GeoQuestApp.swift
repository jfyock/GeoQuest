//
//  GeoQuestApp.swift
//  GeoQuest
//
//  Created by Jacob Fyock on 2/25/26.
//

import SwiftUI

@main
struct GeoQuestApp: App {
    init() {
        FirebaseConfig.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
