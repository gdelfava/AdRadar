//
//  AdRadarWatchApp.swift
//  AdRadarWatch Watch App
//
//  Created by Guilio Del Fava on 2025/06/24.
//

import SwiftUI
import WatchConnectivity

@main
struct AdRadarWatch_Watch_AppApp: App {
    @StateObject private var connectivityService = WatchConnectivityService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityService)
                .onAppear {
                    // Initialize connectivity when app launches
                    print("⌚ [Watch] App launched, connectivity service initialized")
                }
        }
    }
}
