//
//  HeartRateMonitorApp.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI
import SwiftData

@main
struct HeartRateMonitorApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasActiveSubscription") private var hasActiveSubscription = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            HeartRateMeasurement.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            print("❌ ModelContainer creation failed: \(error)")
            
            do {
                let inMemoryConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                let container = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                print("⚠️ Using in-memory storage as fallback")
                return container
            } catch {
                fatalError("Could not create ModelContainer even with in-memory storage: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else if !hasActiveSubscription {
                SubscriptionStoreView(hasActiveSubscription: $hasActiveSubscription)
            } else {
                MainTabView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
