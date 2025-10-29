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

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if measurements.isEmpty {
                            EmptyStateView()
                        } else {
                            ForEach(measurements) { measurement in
                                NavigationLink {
                                    MeasurementDetailedView(measurement: measurement)
                                } label: {
                                    MeasurementCard(measurement: measurement, isMinimal: true)
                                }
                                .buttonStyle(PlainButtonStyle())
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
