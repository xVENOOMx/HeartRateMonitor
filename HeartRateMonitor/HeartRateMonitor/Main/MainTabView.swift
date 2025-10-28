//
//  MainTabView.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            ResultsView()
                .tabItem {
                    Label("Home", systemImage: "heart.fill")
                }
            
            ChartsView()
                .tabItem {
                    Label("Charts", systemImage: "chart.xyaxis.line")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: HeartRateMeasurement.self, inMemory: true)
}
