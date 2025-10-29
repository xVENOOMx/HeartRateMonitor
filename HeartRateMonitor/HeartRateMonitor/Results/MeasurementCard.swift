//
//  MeasurementCard.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI

struct MeasurementCard: View {
    let measurement: HeartRateMeasurement
    let isMinimal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with timestamp
            HStack {
                Text(measurement.timestamp ?? Date(), style: .date)
                    .font(.headline)
                Spacer()
                Text(measurement.timestamp ?? Date(), style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Quality indicator
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

            // Always show minimal view
            minimalView
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }

    // MARK: - Minimal View
    private var minimalView: some View {
        VStack(spacing: 12) {
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
        }
    }

    // MARK: - Detailed View
    private var detailedView: some View {
        VStack(spacing: 12) {
            // Heart Rate with interpretation
            DetailedMetricRow(
                icon: "heart.fill",
                label: "Heart Rate",
                value: "\(Int(measurement.heartRate ?? 0))",
                unit: "BPM",
                status: heartRateStatus(measurement.heartRate ?? 0),
                color: .red
            )

            // HRV with interpretation
            DetailedMetricRow(
                icon: "waveform.path.ecg",
                label: "HRV (RMSSD)",
                value: String(format: "%.1f", measurement.hrv ?? 0),
                unit: "ms",
                status: hrvStatus(measurement.hrv ?? 0),
                color: .blue
            )

            // SDNN with interpretation
            DetailedMetricRow(
                icon: "chart.line.uptrend.xyaxis",
                label: "SDNN",
                value: String(format: "%.1f", measurement.sdnn ?? 0),
                unit: "ms",
                status: sdnnStatus(measurement.sdnn ?? 0),
                color: .green
            )

            // Stress with interpretation
            DetailedMetricRow(
                icon: "brain.head.profile",
                label: "Stress Index",
                value: String(format: "%.0f", measurement.stress ?? 0),
                unit: "%",
                status: stressStatus(measurement.stress ?? 0),
                color: .orange
            )

            // Energy with interpretation
            DetailedMetricRow(
                icon: "bolt.fill",
                label: "Energy Level",
                value: String(format: "%.0f", measurement.energy ?? 0),
                unit: "%",
                status: energyStatus(measurement.energy ?? 0),
                color: .yellow
            )

            // Plus Score
            DetailedMetricRow(
                icon: "star.fill",
                label: "Plus Score",
                value: String(format: "%.0f", measurement.plus ?? 0),
                unit: "",
                status: plusStatus(measurement.plus ?? 0),
                color: .purple
            )
        }
    }

    // MARK: - Status Interpretation Functions
    private func heartRateStatus(_ hr: Double) -> String {
        if hr < 60 {
            return "Low (Athlete/Resting)"
        } else if hr <= 100 {
            return "Normal Range"
        } else if hr <= 120 {
            return "Elevated"
        } else {
            return "High - Consult Doctor"
        }
    }

    private func hrvStatus(_ hrv: Double) -> String {
        // Based on RMSSD ranges (19-48ms for adults 38-42 years)
        if hrv >= 50 {
            return "Excellent Recovery"
        } else if hrv >= 35 {
            return "Good - Well Recovered"
        } else if hrv >= 20 {
            return "Fair - Moderate Stress"
        } else {
            return "Low - High Stress"
        }
    }

    private func sdnnStatus(_ sdnn: Double) -> String {
        // SDNN < 50ms indicates increased mortality risk
        // Normal 24h SDNN: 141 ± 39 ms
        if sdnn >= 100 {
            return "Excellent Variability"
        } else if sdnn >= 50 {
            return "Good - Healthy Range"
        } else if sdnn >= 30 {
            return "Fair - Consider Rest"
        } else {
            return "Low - Seek Medical Advice"
        }
    }

    private func stressStatus(_ stress: Double) -> String {
        if stress < 25 {
            return "Low - Relaxed State"
        } else if stress < 50 {
            return "Moderate - Normal"
        } else if stress < 75 {
            return "High - Consider Rest"
        } else {
            return "Very High - Recovery Needed"
        }
    }

    private func energyStatus(_ energy: Double) -> String {
        if energy >= 75 {
            return "High - Ready for Activity"
        } else if energy >= 50 {
            return "Good - Moderate Activity"
        } else if energy >= 25 {
            return "Low - Rest Recommended"
        } else {
            return "Very Low - Recovery Mode"
        }
    }

    private func plusStatus(_ plus: Double) -> String {
        if plus >= 85 {
            return "Excellent Overall Score"
        } else if plus >= 70 {
            return "Good - Above Average"
        } else if plus >= 50 {
            return "Fair - Average Range"
        } else {
            return "Below Average"
        }
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

// MARK: - Detailed Metric Row Component
struct DetailedMetricRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let status: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                HStack(spacing: 4) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 28)
        }
        .padding(.vertical, 4)
    }
}

#Preview("Minimal View") {
    MeasurementCard(
        measurement: HeartRateMeasurement(
            heartRate: 72,
            hrv: 55,
            sdnn: 48,
            stress: 35,
            energy: 75,
            plus: 82,
            signalQuality: 0.25,
            confidence: "Excellent"
        ),
        isMinimal: true
    )
    .padding()
}
