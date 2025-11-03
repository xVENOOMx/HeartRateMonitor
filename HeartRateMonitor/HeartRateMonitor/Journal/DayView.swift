//
//  DayView.swift
//  HeartRateMonitor
//
//  Created by Claude on 29/10/2025.
//

import SwiftUI
import SwiftData

struct DayView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Query private var allMeasurements: [HeartRateMeasurement]
    @Query private var allActivities: [DailyActivity]

    private let calendar = Calendar.current

    // Measurements for this specific day
    var dayMeasurements: [HeartRateMeasurement] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return allMeasurements.filter { measurement in
            guard let timestamp = measurement.timestamp else { return false }
            return timestamp >= dayStart && timestamp < dayEnd
        }.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
    }

    // Activity for this day
    var dayActivity: DailyActivity? {
        let dayStart = calendar.startOfDay(for: date)

        return allActivities.first { activity in
            guard let activityDate = activity.date else { return false }
            return calendar.isDate(activityDate, inSameDayAs: dayStart)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date header
                VStack(spacing: 5) {
                    Text(date, style: .date)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(calendar.isDateInToday(date) ? "Today" : "")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                .padding(.top, 10)

                // Day summary
                if !dayMeasurements.isEmpty {
                    DaySummaryCard(measurements: dayMeasurements)
                }

                // Activity for the day
                if let activity = dayActivity {
                    DayActivityCard(activity: activity)
                }

                // All measurements for the day
                VStack(alignment: .leading, spacing: 15) {
                    Text("Measurements")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if dayMeasurements.isEmpty {
                        Text("No measurements recorded")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(dayMeasurements) { measurement in
                            NavigationLink {
                                MeasurementDetailedView(measurement: measurement)
                            } label: {
                                DayMeasurementCard(measurement: measurement)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Day Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Day Summary Card
struct DaySummaryCard: View {
    let measurements: [HeartRateMeasurement]

    var averageHeartRate: Double {
        let rates = measurements.compactMap { $0.heartRate }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }

    var minHeartRate: Double {
        measurements.compactMap { $0.heartRate }.min() ?? 0
    }

    var maxHeartRate: Double {
        measurements.compactMap { $0.heartRate }.max() ?? 0
    }

    var averageHRV: Double {
        let hrvs = measurements.compactMap { $0.hrv }
        guard !hrvs.isEmpty else { return 0 }
        return hrvs.reduce(0, +) / Double(hrvs.count)
    }

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("Day Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(measurements.count) reading\(measurements.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Heart Rate Stats
            VStack(alignment: .leading, spacing: 10) {
                Text("Heart Rate")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                HStack(spacing: 20) {
                    StatBox(title: "Avg", value: "\(Int(averageHeartRate))", unit: "BPM", color: .red)
                    StatBox(title: "Min", value: "\(Int(minHeartRate))", unit: "BPM", color: .blue)
                    StatBox(title: "Max", value: "\(Int(maxHeartRate))", unit: "BPM", color: .orange)
                }
            }

            Divider()

            // HRV
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Average HRV")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", averageHRV))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        Text("ms")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Day Activity Card
struct DayActivityCard: View {
    let activity: DailyActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "figure.walk.motion")
                    .foregroundStyle(.green)
                Text("Activity & Notes")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            VStack(spacing: 12) {
                if let sleep = activity.sleepHours, sleep > 0 {
                    ActivityRow(
                        icon: "bed.double.fill",
                        title: "Sleep",
                        value: String(format: "%.1f hrs", sleep),
                        color: .purple
                    )
                }

                if let mood = activity.mood {
                    ActivityRow(
                        icon: "face.smiling.fill",
                        title: "Mood",
                        value: mood,
                        color: .yellow
                    )
                }

                if let stress = activity.stressLevel {
                    ActivityRow(
                        icon: "brain.head.profile",
                        title: "Stress",
                        value: "\(stress)/10",
                        color: .orange
                    )
                }

                if let energy = activity.energyLevel {
                    ActivityRow(
                        icon: "bolt.fill",
                        title: "Energy",
                        value: "\(energy)/10",
                        color: .blue
                    )
                }

                if let notes = activity.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Notes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 5)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// MARK: - Day Measurement Card
struct DayMeasurementCard: View {
    let measurement: HeartRateMeasurement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Time
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text(measurement.timestamp ?? Date(), style: .time)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if let quality = measurement.signalQuality, let confidence = measurement.confidence {
                    HStack(spacing: 5) {
                        Image(systemName: qualityIcon(quality))
                            .foregroundStyle(qualityColor(quality))
                            .font(.caption)
                        Text(confidence)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Metrics in compact format
            HStack(spacing: 15) {
                CompactMetric(
                    icon: "heart.fill",
                    value: "\(Int(measurement.heartRate ?? 0))",
                    unit: "BPM",
                    color: .red
                )

                Divider()
                    .frame(height: 30)

                CompactMetric(
                    icon: "waveform.path.ecg",
                    value: String(format: "%.0f", measurement.hrv ?? 0),
                    unit: "HRV",
                    color: .blue
                )

                Divider()
                    .frame(height: 30)

                CompactMetric(
                    icon: "brain.head.profile",
                    value: "\(Int(measurement.stress ?? 0))%",
                    unit: "Stress",
                    color: .orange
                )
            }
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

struct CompactMetric: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        DayView(date: Date())
            .modelContainer(for: [HeartRateMeasurement.self, DailyActivity.self], inMemory: true)
    }
}
