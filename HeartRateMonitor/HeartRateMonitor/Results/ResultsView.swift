//
//  ResultsView.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI
import SwiftData

struct ResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\HeartRateMeasurement.timestamp, order: .reverse)])
    private var measurements: [HeartRateMeasurement]
    @State private var showingCameraView = false
    @State private var viewMode: ViewMode = .minimal

    enum ViewMode: String, CaseIterable {
        case minimal = "Minimal"
        case detailed = "Detailed"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if measurements.isEmpty {
                            EmptyStateView()
                        } else {
                            ForEach(measurements) { measurement in
                                MeasurementCard(measurement: measurement, viewMode: viewMode)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }

                VStack {
                    Spacer()

                    Button {
                        showingCameraView = true
                    } label: {
                        HStack {
                            Image(systemName: "heart.circle.fill")
                                .font(.title2)
                            Text("Measure Heart Rate")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.red.gradient)
                        .cornerRadius(25)
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Heart Rate")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("View Mode", selection: $viewMode) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode == .minimal ? "list.bullet" : "list.bullet.rectangle")
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Label(viewMode.rawValue, systemImage: viewMode == .minimal ? "list.bullet" : "list.bullet.rectangle")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCameraView) {
                CameraView(isPresented: $showingCameraView)
            }
        }
    }
}

#Preview("Empty State") {
    ResultsView()
        .modelContainer(for: HeartRateMeasurement.self, inMemory: true)
}

#Preview("With Data") {
    @Previewable @State var previewContainer: ModelContainer = {
        let container = try! ModelContainer(
            for: HeartRateMeasurement.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        let measurement1 = HeartRateMeasurement(
            heartRate: 72,
            hrv: 55,
            sdnn: 48,
            stress: 35,
            energy: 75,
            plus: 82,
            signalQuality: 0.25
        )
        let measurement2 = HeartRateMeasurement(
            heartRate: 68,
            hrv: 62,
            sdnn: 54,
            stress: 28,
            energy: 82,
            plus: 88,
            signalQuality: 0.22
        )
        
        container.mainContext.insert(measurement1)
        container.mainContext.insert(measurement2)
        
        return container
    }()
    
    ResultsView()
        .modelContainer(previewContainer)
}
