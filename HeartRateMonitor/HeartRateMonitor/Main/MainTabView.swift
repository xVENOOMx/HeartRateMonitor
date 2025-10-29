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
    @State private var showDetailedView = false
    @State private var completedMeasurement: HeartRateMeasurement?

    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                TabView(selection: $selectedTab) {
                    TodayView()
                        .tag(0)
                        .tabItem {
                            Label("Today", systemImage: "calendar")
                        }

                    JournalView()
                        .tag(1)
                        .tabItem {
                            Label("Journal", systemImage: "book.fill")
                        }

                    WellnessView()
                        .tag(2)
                        .tabItem {
                            Label("Wellness", systemImage: "heart.text.square")
                        }

                    SettingsView()
                        .tag(3)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }

                // Center floating button (smaller)
                VStack {
                    Spacer()

                    Button {
                        showingCameraView = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.red.gradient)
                                .frame(width: 60, height: 60)
                                .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 5)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.bottom, 5)
                }
                .ignoresSafeArea(.keyboard)
            }
            .fullScreenCover(isPresented: $showingCameraView) {
                CameraView(isPresented: $showingCameraView) { measurement in
                    completedMeasurement = measurement
                    showDetailedView = true
                }
            }
            .navigationDestination(isPresented: $showDetailedView) {
                if let measurement = completedMeasurement {
                    MeasurementDetailedView(measurement: measurement)
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [HeartRateMeasurement.self, DailyActivity.self], inMemory: true)
}
