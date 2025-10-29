//
//  MainTabView.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingCameraView = false

    var body: some View {
        ZStack {
            // Main content
            TabView(selection: $selectedTab) {
                TodayView()
                    .tag(0)
                    .tabItem {
                        Label("Today", systemImage: "calendar")
                    }

                Color.clear
                    .tag(1)
                    .tabItem {
                        Label("", systemImage: "")
                    }

                JournalView()
                    .tag(2)
                    .tabItem {
                        Label("Journal", systemImage: "book.fill")
                    }

                SettingsView()
                    .tag(3)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }

            // Center floating button
            VStack {
                Spacer()

                Button {
                    showingCameraView = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.red.gradient)
                            .frame(width: 70, height: 70)
                            .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 5)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 5)
            }
            .ignoresSafeArea(.keyboard)
        }
        .fullScreenCover(isPresented: $showingCameraView) {
            CameraView(isPresented: $showingCameraView)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [HeartRateMeasurement.self, DailyActivity.self], inMemory: true)
}
