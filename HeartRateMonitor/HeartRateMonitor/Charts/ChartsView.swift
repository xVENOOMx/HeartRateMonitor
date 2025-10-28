//
//  ChartsView.swift
//  HeartRateMonitor
//
//  Created by nick on 18/10/2025.
//

import SwiftUI
import SwiftData
import Charts

struct ChartsView: View {
    @Query(sort: [SortDescriptor(\HeartRateMeasurement.timestamp, order: .forward)])
    private var measurements: [HeartRateMeasurement]
    @State private var selectedMetric: MetricType = .heartRate
    
    enum MetricType: String, CaseIterable {
        case heartRate = "Heart Rate"
        case hrv = "HRV"
        case sdnn = "SDNN"
        case stress = "Stress"
        case energy = "Energy"
        case plus = "Plus Score"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if measurements.isEmpty {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Measurements will appear here after you take your first reading")
                    )
                } else {
                    VStack(spacing: 20) {
                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(MetricType.allCases, id: \.self) { metric in
                                Text(metric.rawValue).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        Chart {
                            ForEach(measurements) { measurement in
                                if let timestamp = measurement.timestamp {
                                    LineMark(
                                        x: .value("Time", timestamp),
                                        y: .value("Value", getValue(for: measurement))
                                    )
                                    .foregroundStyle(getColor())
                                    .interpolationMethod(.catmullRom)
                                    
                                    PointMark(
                                        x: .value("Time", timestamp),
                                        y: .value("Value", getValue(for: measurement))
                                    )
                                    .foregroundStyle(getColor())
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 300)
                        .padding()
                        
                        StatisticsView(measurements: measurements, metric: selectedMetric)
                    }
                }
            }
            .navigationTitle("Trends")
        }
    }
    
    private func getValue(for measurement: HeartRateMeasurement) -> Double {
        switch selectedMetric {
        case .heartRate: return measurement.heartRate ?? 0
        case .hrv: return measurement.hrv ?? 0
        case .sdnn: return measurement.sdnn ?? 0
        case .stress: return measurement.stress ?? 0
        case .energy: return measurement.energy ?? 0
        case .plus: return measurement.plus ?? 0
        }
    }
    
    private func getColor() -> Color {
        switch selectedMetric {
        case .heartRate: return .red
        case .hrv: return .blue
        case .sdnn: return .green
        case .stress: return .orange
        case .energy: return .yellow
        case .plus: return .purple
        }
    }
}

struct StatisticsView: View {
    let measurements: [HeartRateMeasurement]
    let metric: ChartsView.MetricType
    
    var statistics: (average: Double, min: Double, max: Double) {
        let values = measurements.compactMap { measurement -> Double? in
            switch metric {
            case .heartRate: return measurement.heartRate
            case .hrv: return measurement.hrv
            case .sdnn: return measurement.sdnn
            case .stress: return measurement.stress
            case .energy: return measurement.energy
            case .plus: return measurement.plus
            }
        }
        
        guard !values.isEmpty else { return (0, 0, 0) }
        
        let avg = values.reduce(0, +) / Double(values.count)
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        
        return (avg, min, max)
    }
    
    var body: some View {
        HStack(spacing: 30) {
            StatCard(title: "Average", value: String(format: "%.1f", statistics.average))
            StatCard(title: "Min", value: String(format: "%.1f", statistics.min))
            StatCard(title: "Max", value: String(format: "%.1f", statistics.max))
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    ChartsView()
        .modelContainer(for: HeartRateMeasurement.self, inMemory: true)
}
