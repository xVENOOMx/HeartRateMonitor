//
//  DetailResultView.swift
//  HeartRateMonitor
//
//  Created by Claude on 28/10/2025.
//

import SwiftUI

struct DetailResultView: View {
    let measurement: HeartRateMeasurement

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red.gradient)

                    Text("Detailed Health Analysis")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(formatDate(measurement.timestamp ?? Date()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ConfidenceBadge(confidence: measurement.confidence ?? "Good")
                }
                .padding(.top)

                // Overall Health Status Section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Overall Health Status", icon: "heart.text.square.fill", color: .pink)

                    HealthStatusCard(
                        title: "Health Score",
                        value: measurement.health ?? 0,
                        unit: "",
                        interpretation: getHealthInterpretation(measurement.health ?? 0),
                        color: .pink
                    )

                    MetricDetailCard(
                        title: "Focus",
                        value: measurement.focus ?? 0,
                        unit: "",
                        normalRange: "60-100",
                        interpretation: getFocusInterpretation(measurement.focus ?? 0),
                        color: .purple
                    )

                    MetricDetailCard(
                        title: "Energy",
                        value: measurement.energy ?? 0,
                        unit: "%",
                        normalRange: "50-100",
                        interpretation: getEnergyInterpretation(measurement.energy ?? 0),
                        color: .yellow
                    )

                    MetricDetailCard(
                        title: "Stress Level",
                        value: measurement.stress ?? 0,
                        unit: "%",
                        normalRange: "0-40",
                        interpretation: getStressInterpretation(measurement.stress ?? 0),
                        color: .orange
                    )
                }
                .padding(.horizontal)

                Divider()
                    .padding(.vertical, 8)

                // Heart Rate Metrics Section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Heart Rate Metrics", icon: "waveform.path.ecg", color: .red)

                    MetricDetailCard(
                        title: "Heart Rate",
                        value: measurement.heartRate ?? 0,
                        unit: "BPM",
                        normalRange: "60-100",
                        interpretation: getHeartRateInterpretation(measurement.heartRate ?? 0),
                        color: .red
                    )

                    MetricDetailCard(
                        title: "Mean RR Interval",
                        value: measurement.meanRR ?? 0,
                        unit: "ms",
                        normalRange: "600-1000",
                        interpretation: getMeanRRInterpretation(measurement.meanRR ?? 0),
                        color: .blue
                    )
                }
                .padding(.horizontal)

                Divider()
                    .padding(.vertical, 8)

                // HRV Time Domain Section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "HRV Time Domain", icon: "chart.line.uptrend.xyaxis", color: .blue)

                    MetricDetailCard(
                        title: "HRV Score",
                        value: measurement.hrv ?? 0,
                        unit: "ms",
                        normalRange: "20-100",
                        interpretation: getHRVInterpretation(measurement.hrv ?? 0),
                        color: .blue
                    )

                    MetricDetailCard(
                        title: "RMSSD",
                        value: measurement.rmssd ?? 0,
                        unit: "ms",
                        normalRange: "20-100",
                        interpretation: getRMSSDInterpretation(measurement.rmssd ?? 0),
                        color: .cyan
                    )

                    MetricDetailCard(
                        title: "SDNN",
                        value: measurement.sdnn ?? 0,
                        unit: "ms",
                        normalRange: "30-100",
                        interpretation: getSDNNInterpretation(measurement.sdnn ?? 0),
                        color: .green
                    )

                    MetricDetailCard(
                        title: "pNN50",
                        value: measurement.pnn50 ?? 0,
                        unit: "%",
                        normalRange: "5-30",
                        interpretation: getPNN50Interpretation(measurement.pnn50 ?? 0),
                        color: .teal
                    )

                    MetricDetailCard(
                        title: "Coefficient of Variation (CV)",
                        value: measurement.cv ?? 0,
                        unit: "%",
                        normalRange: "3-8",
                        interpretation: getCVInterpretation(measurement.cv ?? 0),
                        color: .mint
                    )
                }
                .padding(.horizontal)

                Divider()
                    .padding(.vertical, 8)

                // HRV Geometric Methods Section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "HRV Geometric Methods", icon: "chart.bar.fill", color: .green)

                    MetricDetailCard(
                        title: "MxDMn",
                        value: measurement.mxdmn ?? 0,
                        unit: "ms",
                        normalRange: "200-500",
                        interpretation: getMxDMnInterpretation(measurement.mxdmn ?? 0),
                        color: .indigo
                    )

                    MetricDetailCard(
                        title: "Mode",
                        value: measurement.mode ?? 0,
                        unit: "ms",
                        normalRange: "600-1000",
                        interpretation: getModeInterpretation(measurement.mode ?? 0),
                        color: .purple
                    )

                    MetricDetailCard(
                        title: "AMo50",
                        value: measurement.amo50 ?? 0,
                        unit: "%",
                        normalRange: "30-60",
                        interpretation: getAMo50Interpretation(measurement.amo50 ?? 0),
                        color: .brown)
                }
                .padding(.horizontal)

                Divider()
                    .padding(.vertical, 8)

                // Advanced Metrics Section
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Advanced Metrics", icon: "brain.head.profile", color: .purple)

                    MetricDetailCard(
                        title: "Heart Rate Variability",
                        value: measurement.hrv ?? 0,
                        unit: "ms",
                        normalRange: "20-100",
                        interpretation: getHRVVariabilityInterpretation(measurement.hrv ?? 0),
                        color: .blue
                    )

                    MetricDetailCard(
                        title: "Coherence Score",
                        value: measurement.coherence ?? 0,
                        unit: "",
                        normalRange: "50-100",
                        interpretation: getCoherenceInterpretation(measurement.coherence ?? 0),
                        color: .purple
                    )

                    MetricDetailCard(
                        title: "Plus Score",
                        value: measurement.plus ?? 0,
                        unit: "",
                        normalRange: "60-100",
                        interpretation: getPlusScoreInterpretation(measurement.plus ?? 0),
                        color: .purple
                    )
                }
                .padding(.horizontal)

                // Info Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("About These Metrics")
                            .font(.headline)
                    }

                    Text("These metrics provide comprehensive insights into your cardiovascular health and autonomic nervous system function. Higher HRV values generally indicate better cardiovascular fitness and stress resilience.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Detailed Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color.gradient)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            Spacer()
        }
        .padding(.top, 8)
    }
}

struct ConfidenceBadge: View {
    let confidence: String

    var badgeColor: Color {
        switch confidence {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidence == "Excellent" || confidence == "Good" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            Text("Signal Quality: \(confidence)")
        }
        .font(.caption)
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(badgeColor.opacity(0.1))
        .cornerRadius(20)
    }
}

struct HealthStatusCard: View {
    let title: String
    let value: Double
    let unit: String
    let interpretation: (status: String, description: String, color: Color)
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f", value))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(color.gradient)
                        if !unit.isEmpty {
                            Text(unit)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Status Indicator
                VStack {
                    Image(systemName: getStatusIcon(interpretation.status))
                        .font(.system(size: 32))
                        .foregroundStyle(interpretation.color)
                }
            }

            // Status Badge
            HStack {
                Circle()
                    .fill(interpretation.color)
                    .frame(width: 8, height: 8)
                Text(interpretation.status)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(interpretation.color)
                Spacer()
            }

            // Description
            Text(interpretation.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func getStatusIcon(_ status: String) -> String {
        switch status {
        case "Excellent", "Optimal", "Great": return "checkmark.circle.fill"
        case "Good", "Normal": return "checkmark.circle"
        case "Fair", "Moderate": return "exclamationmark.circle"
        default: return "xmark.circle"
        }
    }
}

struct MetricDetailCard: View {
    let title: String
    let value: Double
    let unit: String
    let normalRange: String
    let interpretation: (status: String, description: String, color: Color)
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formatValue(value))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(color.gradient)
                        Text(unit)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(interpretation.color)
                            .frame(width: 8, height: 8)
                        Text(interpretation.status)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(interpretation.color)
                    }

                    Text("Normal: \(normalRange)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(interpretation.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 100 || value == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Interpretation Functions

extension DetailResultView {
    func getHealthInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 80...:
            return ("Excellent", "Your overall cardiovascular health is excellent. Maintain your healthy lifestyle.", .green)
        case 60..<80:
            return ("Good", "Your cardiovascular health is good. Consider small improvements in exercise and stress management.", .blue)
        case 40..<60:
            return ("Fair", "Your cardiovascular health is fair. Focus on regular exercise and stress reduction.", .orange)
        default:
            return ("Needs Attention", "Consider consulting a healthcare professional and improving lifestyle habits.", .red)
        }
    }

    func getFocusInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 70...:
            return ("Excellent", "High mental focus and clarity. Great cognitive performance.", .green)
        case 50..<70:
            return ("Good", "Good focus levels. Adequate for most tasks.", .blue)
        case 30..<50:
            return ("Moderate", "Moderate focus. Consider breaks and stress management techniques.", .orange)
        default:
            return ("Low", "Low focus detected. Rest and relaxation may be needed.", .red)
        }
    }

    func getEnergyInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 70...:
            return ("High", "Excellent energy levels. Your body is well-recovered and ready for activity.", .green)
        case 50..<70:
            return ("Moderate", "Good energy levels. Suitable for most activities.", .blue)
        case 30..<50:
            return ("Low", "Energy levels are lower. Consider rest and proper nutrition.", .orange)
        default:
            return ("Very Low", "Very low energy. Rest and recovery are recommended.", .red)
        }
    }

    func getStressInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case ...30:
            return ("Low", "Low stress levels. Your body is relaxed and recovered.", .green)
        case 30..<50:
            return ("Moderate", "Moderate stress levels. Consider relaxation techniques.", .blue)
        case 50..<70:
            return ("High", "Elevated stress levels. Stress management is recommended.", .orange)
        default:
            return ("Very High", "Very high stress detected. Prioritize rest and stress reduction.", .red)
        }
    }

    func getHeartRateInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 60...100:
            return ("Normal", "Your resting heart rate is within the normal range.", .green)
        case 50..<60:
            return ("Athletic", "Lower heart rate, often seen in well-trained athletes.", .blue)
        case 100..<120:
            return ("Elevated", "Slightly elevated. May indicate stress, caffeine, or recent activity.", .orange)
        default:
            return ("Abnormal", "Outside normal range. Consider consulting a healthcare professional if persistent.", .red)
        }
    }

    func getMeanRRInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 600...1000:
            return ("Normal", "Average time between heartbeats is within healthy range.", .green)
        case 500..<600:
            return ("Slightly Fast", "Shorter intervals indicate a faster heart rate.", .blue)
        case 1000...:
            return ("Slow", "Longer intervals indicate a slower heart rate, common in athletes.", .blue)
        default:
            return ("Abnormal", "RR interval outside expected range.", .orange)
        }
    }

    func getHRVInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 50...:
            return ("Excellent", "High HRV indicates excellent cardiovascular fitness and stress resilience.", .green)
        case 30..<50:
            return ("Good", "Good HRV. Your autonomic nervous system is functioning well.", .blue)
        case 20..<30:
            return ("Fair", "Fair HRV. Consider improving sleep quality and reducing stress.", .orange)
        default:
            return ("Low", "Low HRV may indicate fatigue, stress, or need for recovery.", .red)
        }
    }

    func getRMSSDInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 40...:
            return ("Excellent", "High RMSSD indicates excellent parasympathetic (rest & digest) activity.", .green)
        case 25..<40:
            return ("Good", "Good RMSSD values. Healthy short-term heart rate variability.", .blue)
        case 15..<25:
            return ("Fair", "Moderate RMSSD. May benefit from stress reduction and better sleep.", .orange)
        default:
            return ("Low", "Low RMSSD suggests reduced parasympathetic activity. Rest is recommended.", .red)
        }
    }

    func getSDNNInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 50...:
            return ("Excellent", "High SDNN reflects excellent overall HRV and autonomic balance.", .green)
        case 35..<50:
            return ("Good", "Good SDNN values indicate healthy autonomic nervous system function.", .blue)
        case 20..<35:
            return ("Fair", "Fair SDNN. Consider lifestyle improvements for better heart health.", .orange)
        default:
            return ("Low", "Low SDNN may indicate autonomic imbalance or high stress.", .red)
        }
    }

    func getPNN50Interpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 15...:
            return ("Excellent", "High pNN50 indicates strong parasympathetic activity and good fitness.", .green)
        case 8..<15:
            return ("Good", "Healthy pNN50 levels showing good autonomic function.", .blue)
        case 3..<8:
            return ("Fair", "Moderate pNN50. May improve with regular exercise and stress management.", .orange)
        default:
            return ("Low", "Low pNN50 suggests limited heart rate variability between beats.", .red)
        }
    }

    func getCVInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 5...:
            return ("Good", "Healthy coefficient of variation indicating good autonomic balance.", .green)
        case 3..<5:
            return ("Normal", "Normal CV values for resting measurements.", .blue)
        case 2..<3:
            return ("Low", "Lower CV may indicate reduced heart rate variability.", .orange)
        default:
            return ("Very Low", "Very low CV suggests limited variability in heart rhythm.", .red)
        }
    }

    func getMxDMnInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 300...:
            return ("Excellent", "Large range between max and min RR intervals shows excellent adaptability.", .green)
        case 200..<300:
            return ("Good", "Good range of RR intervals indicating healthy heart rhythm variability.", .blue)
        case 100..<200:
            return ("Fair", "Moderate range. Heart rhythm shows some variability.", .orange)
        default:
            return ("Low", "Limited range between RR intervals suggests reduced heart rate adaptability.", .red)
        }
    }

    func getModeInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 700...1000:
            return ("Normal", "Most common RR interval is within healthy range.", .green)
        case 600..<700:
            return ("Slightly Fast", "Mode indicates slightly faster average heart rate.", .blue)
        case 1000...:
            return ("Slow", "Mode indicates slower heart rate, common in trained athletes.", .blue)
        default:
            return ("Abnormal", "Mode outside typical range.", .orange)
        }
    }

    func getAMo50Interpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case ...40:
            return ("Good", "Lower AMo50 indicates better heart rate variability and autonomic balance.", .green)
        case 40..<55:
            return ("Normal", "Normal amplitude of mode for resting measurements.", .blue)
        case 55..<70:
            return ("Elevated", "Higher AMo50 may indicate sympathetic dominance or stress.", .orange)
        default:
            return ("High", "High AMo50 suggests reduced variability and possible stress state.", .red)
        }
    }

    func getHRVVariabilityInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 60...:
            return ("Excellent", "Exceptional heart rate variability indicating superior cardiovascular health.", .green)
        case 40..<60:
            return ("Very Good", "Very good HRV showing excellent fitness and recovery capacity.", .blue)
        case 25..<40:
            return ("Good", "Good heart rate variability. Continue healthy habits.", .blue)
        default:
            return ("Fair", "Fair variability. Focus on recovery and stress management.", .orange)
        }
    }

    func getCoherenceInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 70...:
            return ("High", "High coherence indicates excellent heart rhythm synchronization and emotional balance.", .green)
        case 50..<70:
            return ("Moderate", "Moderate coherence. Your heart rhythm shows good organization.", .blue)
        case 30..<50:
            return ("Low", "Lower coherence suggests heart rhythm desynchronization. Practice breathing exercises.", .orange)
        default:
            return ("Very Low", "Very low coherence. Consider stress management and mindfulness techniques.", .red)
        }
    }

    func getPlusScoreInterpretation(_ value: Double) -> (String, String, Color) {
        switch value {
        case 75...:
            return ("Excellent", "Outstanding composite score indicating excellent cardiovascular health.", .green)
        case 60..<75:
            return ("Good", "Good overall score combining heart rate, HRV, and SDNN metrics.", .blue)
        case 45..<60:
            return ("Fair", "Fair composite score. Room for improvement through lifestyle changes.", .orange)
        default:
            return ("Needs Improvement", "Lower composite score suggests need for health improvements.", .red)
        }
    }
}

#Preview {
    NavigationStack {
        DetailResultView(measurement: HeartRateMeasurement(
            heartRate: 72,
            hrv: 65,
            sdnn: 58,
            stress: 35,
            energy: 75,
            plus: 82,
            signalQuality: 92,
            confidence: "Excellent",
            meanRR: 833,
            rmssd: 62,
            pnn50: 18,
            mxdmn: 285,
            mode: 820,
            amo50: 42,
            cv: 6.8,
            coherence: 78,
            focus: 82,
            health: 85
        ))
    }
}
