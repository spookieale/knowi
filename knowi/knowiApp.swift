//
//  knowiApp.swift
//  knowi
//
//  Created by Alumno on 29/03/25.
//

import SwiftUI

@main
struct knowiApp: App {
    // App state to control flow
    @State private var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                Group {
                    // Check if user has completed onboarding
                    if UserDefaults.standard.data(forKey: "userProfile") != nil {
                        // User has profile, show HomeView
                        HomeView()
                    } else {
                        // User needs onboarding
                        LandingView()
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .preferredColorScheme(.light) // Force light mode for consistent appearance
        }
    }
}
