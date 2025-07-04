// Main content view for AdRadar
//
//  ContentView.swift
//  AdRadar
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import SwiftUI
import GoogleSignIn
import UIKit

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var showWhyGoogle = false
    @State private var showOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding") == false
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    
    init() {
        let authVM = AuthViewModel()
        _authViewModel = StateObject(wrappedValue: authVM)
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(authViewModel: authVM))
    }
    
    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .environmentObject(settingsViewModel)
                    .onDisappear {
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    }
            } else if authViewModel.isSignedIn {
                SummaryTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(settingsViewModel)
            } else {
                ModernSignInView(
                    authViewModel: authViewModel,
                    showWhyGoogle: $showWhyGoogle
                )
            }
        }
        .sheet(isPresented: $showWhyGoogle) {
            WhyGoogleModal(isPresented: $showWhyGoogle)
        }
        .sheet(isPresented: $networkMonitor.showNetworkErrorModal) {
            NetworkErrorModalView(
                message: "The Internet connection appears to be offline. Please check your Wi-Fi or Cellular settings.",
                onClose: { networkMonitor.showNetworkErrorModal = false },
                onSettings: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }
        .onAppear {
            // Ensure settingsViewModel has the correct authViewModel reference
            settingsViewModel.authViewModel = authViewModel
        }
    }
}

#Preview {
    ContentView()
}
