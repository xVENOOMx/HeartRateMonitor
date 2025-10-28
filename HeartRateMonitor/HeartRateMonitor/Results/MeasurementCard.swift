//
//  MeasurementCard.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI

struct MeasurementCard: View {
    let measurement: HeartRateMeasurement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(measurement.timestamp ?? Date(), style: .date)
                    .font(.headline)
                Spacer()
                Text(measurement.timestamp ?? Date(), style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let quality = measurement.signalQuality, let confidence = measurement.confidence {
                HStack {
                    Image(systemName: qualityIcon(quality))
                        .foregroundStyle(qualityColor(quality))
                    Text(confidence)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            
            Divider()
            
            MetricRow(
                icon: "heart.fill",
                label: "Heart Rate",
                value: "\(Int(measurement.heartRate ?? 0))",
                unit: "BPM",
                color: .red
            )
            
            MetricRow(
                icon: "waveform.path.ecg",
                label: "HRV",
                value: String(format: "%.1f", measurement.hrv ?? 0),
                unit: "ms",
                color: .blue
            )
            
            MetricRow(
                icon: "chart.line.uptrend.xyaxis",
                label: "SDNN",
                value: String(format: "%.1f", measurement.sdnn ?? 0),
                unit: "ms",
                color: .green
            )
            
            MetricRow(
                icon: "brain.head.profile",
                label: "Stress",
                value: String(format: "%.0f", measurement.stress ?? 0),
                unit: "%",
                color: .orange
            )
            
            MetricRow(
                icon: "bolt.fill",
                label: "Energy",
                value: String(format: "%.0f", measurement.energy ?? 0),
                unit: "%",
                color: .yellow
            )
            
            MetricRow(
                icon: "star.fill",
                label: "Plus Score",
                value: String(format: "%.0f", measurement.plus ?? 0),
                unit: "",
                color: .purple
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private func qualityIcon(_ quality: Double) -> String {
        if quality < 0.293 {
            return "checkmark.circle.fill"
        } else if quality < 0.5 {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private func qualityColor(_ quality: Double) -> Color {
        if quality < 0.293 {
            return .green
        } else if quality < 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    MeasurementCard(measurement: HeartRateMeasurement(
        heartRate: 72,
        hrv: 55,
        sdnn: 48,
        stress: 35,
        energy: 75,
        plus: 82,
        signalQuality: 0.25,
        confidence: "Excellent"
    ))
    .padding()
}
