//
//  MeasurementDetailedView.swift
//  HeartRateMonitor
//
//  Created by Claude on 29/10/2025.
//

import SwiftUI
import Charts

struct MeasurementDetailedView: View {
    let measurement: HeartRateMeasurement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header Section
                VStack(spacing: 10) {
                    Text(measurement.timestamp ?? Date(), style: .date)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(measurement.timestamp ?? Date(), style: .time)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let quality = measurement.signalQuality, let confidence = measurement.confidence {
                        HStack(spacing: 8) {
                            Image(systemName: qualityIcon(quality))
                                .foregroundStyle(qualityColor(quality))
                            Text(confidence)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 5)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)

                Divider()

                // Heart Rate Section
                MetricDetailCard(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    value: "\(Int(measurement.heartRate ?? 0))",
                    unit: "BPM",
                    status: heartRateStatus(measurement.heartRate ?? 0),
                    color: .red,
                    description: "Your heart rate indicates how many times your heart beats per minute. A normal resting heart rate for adults ranges from 60-100 BPM.",
                    gaugeValue: measurement.heartRate ?? 0,
                    gaugeRange: 40...200
                )

                // HRV Section
                MetricDetailCard(
                    icon: "waveform.path.ecg",
                    title: "HRV (RMSSD)",
                    value: String(format: "%.1f", measurement.hrv ?? 0),
                    unit: "ms",
                    status: hrvStatus(measurement.hrv ?? 0),
                    color: .blue,
                    description: "Heart Rate Variability (RMSSD) reflects the beat-to-beat variance in heart rate. Higher HRV typically indicates better cardiovascular fitness and stress resilience. Normal ranges: 19-48ms.",
                    gaugeValue: measurement.hrv ?? 0,
                    gaugeRange: 0...100
                )

                // SDNN Section
                MetricDetailCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "SDNN",
                    value: String(format: "%.1f", measurement.sdnn ?? 0),
                    unit: "ms",
                    status: sdnnStatus(measurement.sdnn ?? 0),
                    color: .green,
                    description: "SDNN is the standard deviation of normal-to-normal intervals. It reflects overall HRV and is a strong predictor of cardiovascular health. Values >50ms are considered healthy.",
                    gaugeValue: measurement.sdnn ?? 0,
                    gaugeRange: 0...150
                )

                // Stress Section
                MetricDetailCard(
                    icon: "brain.head.profile",
                    title: "Stress Index",
                    value: String(format: "%.0f", measurement.stress ?? 0),
                    unit: "%",
                    status: stressStatus(measurement.stress ?? 0),
                    color: .orange,
                    description: "Stress index is calculated from HRV and heart rate patterns. Lower values indicate a more relaxed state, while higher values suggest increased physiological stress.",
                    gaugeValue: measurement.stress ?? 0,
                    gaugeRange: 0...100
                )

                // Energy Section
                MetricDetailCard(
                    icon: "bolt.fill",
                    title: "Energy Level",
                    value: String(format: "%.0f", measurement.energy ?? 0),
                    unit: "%",
                    status: energyStatus(measurement.energy ?? 0),
                    color: .yellow,
                    description: "Energy level indicates your body's readiness for physical and mental activities. Higher values suggest better recovery and readiness for exertion.",
                    gaugeValue: measurement.energy ?? 0,
                    gaugeRange: 0...100
                )

                // Plus Score Section
                MetricDetailCard(
                    icon: "star.fill",
                    title: "Plus Score",
                    value: String(format: "%.0f", measurement.plus ?? 0),
                    unit: "",
                    status: plusStatus(measurement.plus ?? 0),
                    color: .purple,
                    description: "Plus Score is a composite metric combining heart rate, HRV, and SDNN. It provides an overall assessment of your cardiovascular health and readiness.",
                    gaugeValue: measurement.plus ?? 0,
                    gaugeRange: 0...100
                )
            }
            .padding()
        }
        .navigationTitle("Measurement Details")
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Metric Detail Card
struct MetricDetailCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let status: String
    let color: Color
    let description: String
    let gaugeValue: Double
    let gaugeRange: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(value)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(color)

                        if !unit.isEmpty {
                            Text(unit)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }

            // Status Badge
            HStack {
                Text(status)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.15))
                    .cornerRadius(8)

                Spacer()
            }

            // Gauge
            Gauge(value: min(max(gaugeValue, gaugeRange.lowerBound), gaugeRange.upperBound), in: gaugeRange) {
                EmptyView()
            }
            .gaugeStyle(.accessoryLinear)
            .tint(.white)

            Divider()

            // Description
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }
}

#Preview {
    NavigationStack {
        MeasurementDetailedView(
            measurement: HeartRateMeasurement(
                heartRate: 72,
                hrv: 55,
                sdnn: 48,
                stress: 35,
                energy: 75,
                plus: 82,
                signalQuality: 0.25,
                confidence: "Excellent"
            )
        )
    }
}
