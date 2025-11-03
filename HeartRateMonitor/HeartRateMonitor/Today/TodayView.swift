//
//  TodayView.swift
//  HeartRateMonitor
//
//  Created by Claude on 29/10/2025.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allMeasurements: [HeartRateMeasurement]
    @Query private var allActivities: [DailyActivity]

    @State private var showingCameraView = false

    // Today's measurements
    var todayMeasurements: [HeartRateMeasurement] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return allMeasurements.filter { measurement in
            guard let timestamp = measurement.timestamp else { return false }
            return timestamp >= today && timestamp < tomorrow
        }.sorted { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) }
    }

    // Today's activity
    var todayActivity: DailyActivity? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return allActivities.first { activity in
            guard let date = activity.date else { return false }
            return calendar.isDate(date, inSameDayAs: today)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 5) {
                        Text("Today")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(Date(), style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 10)

                    // Today's Summary Card
                    if !todayMeasurements.isEmpty {
                        TodaySummaryCard(measurements: todayMeasurements)
                    }

                    // Health Suggestions
                    HealthSuggestionsCard(
                        measurements: todayMeasurements,
                        activity: todayActivity
                    )

                    // Activity Tracking
                    ActivityTrackingCard(activity: todayActivity)

                    // Recent Measurements
                    if !todayMeasurements.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Today's Measurements")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ForEach(todayMeasurements) { measurement in
                                NavigationLink {
                                    MeasurementDetailedView(measurement: measurement)
                                } label: {
                                    MeasurementCard(measurement: measurement, isMinimal: true)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        EmptyTodayState()
                    }
                }
                .padding(.bottom, 100)
            }
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingCameraView) {
                CameraView(isPresented: $showingCameraView)
            }
        }
    }
}

// MARK: - Today Summary Card
struct TodaySummaryCard: View {
    let measurements: [HeartRateMeasurement]

    var averageHeartRate: Double {
        let rates = measurements.compactMap { $0.heartRate }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }

    var averageHRV: Double {
        let hrvs = measurements.compactMap { $0.hrv }
        guard !hrvs.isEmpty else { return 0 }
        return hrvs.reduce(0, +) / Double(hrvs.count)
    }

    var averageStress: Double {
        let stress = measurements.compactMap { $0.stress }
        guard !stress.isEmpty else { return 0 }
        return stress.reduce(0, +) / Double(stress.count)
    }

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.blue)
                Text("Today's Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
                Text("\(measurements.count) reading\(measurements.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Divider()

            HStack(spacing: 20) {
                VStack(spacing: 5) {
                    Text("\(Int(averageHeartRate))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                    Text("Avg BPM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 5) {
                    Text(String(format: "%.1f", averageHRV))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                    Text("Avg HRV")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 5) {
                    Text("\(Int(averageStress))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                    Text("Avg Stress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// MARK: - Health Suggestions Card
struct HealthSuggestionsCard: View {
    let measurements: [HeartRateMeasurement]
    let activity: DailyActivity?

    var suggestions: [HealthSuggestion] {
        var result: [HealthSuggestion] = []

        // Analyze heart rate
        if let latestMeasurement = measurements.first {
            if let hr = latestMeasurement.heartRate {
                if hr > 100 {
                    result.append(HealthSuggestion(
                        icon: "heart.fill",
                        title: "Elevated Heart Rate",
                        message: "Your heart rate is elevated. Consider resting and practicing deep breathing.",
                        color: .red
                    ))
                } else if hr < 60 {
                    result.append(HealthSuggestion(
                        icon: "heart.fill",
                        title: "Low Resting Heart Rate",
                        message: "Great! Low resting heart rate often indicates good cardiovascular fitness.",
                        color: .green
                    ))
                }
            }

            if let hrv = latestMeasurement.hrv {
                if hrv < 20 {
                    result.append(HealthSuggestion(
                        icon: "waveform.path.ecg",
                        title: "Low HRV Detected",
                        message: "Your HRV is low, indicating stress. Prioritize rest and relaxation today.",
                        color: .orange
                    ))
                } else if hrv > 50 {
                    result.append(HealthSuggestion(
                        icon: "waveform.path.ecg",
                        title: "Excellent Recovery",
                        message: "High HRV indicates great recovery. You're ready for physical activity!",
                        color: .green
                    ))
                }
            }

            if let stress = latestMeasurement.stress {
                if stress > 70 {
                    result.append(HealthSuggestion(
                        icon: "brain.head.profile",
                        title: "High Stress Levels",
                        message: "Consider meditation, yoga, or a short walk to reduce stress.",
                        color: .orange
                    ))
                }
            }
        }

        // Analyze activity
        if let activity = activity {
            if let sleep = activity.sleepHours, sleep < 7 {
                result.append(HealthSuggestion(
                    icon: "bed.double.fill",
                    title: "Insufficient Sleep",
                    message: "Try to get 7-9 hours of sleep tonight for better recovery.",
                    color: .purple
                ))
            }

            if let lyingDown = activity.lyingDownMinutes, lyingDown > 180 {
                result.append(HealthSuggestion(
                    icon: "figure.walk",
                    title: "Low Activity",
                    message: "You've been lying down for a while. A short walk can boost energy.",
                    color: .blue
                ))
            }
        }

        // Default suggestion if no specific issues
        if result.isEmpty {
            result.append(HealthSuggestion(
                icon: "checkmark.circle.fill",
                title: "Looking Good!",
                message: "Your vital signs are in healthy ranges. Keep up the good work!",
                color: .green
            ))
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Health Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            ForEach(suggestions) { suggestion in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: suggestion.icon)
                        .font(.title3)
                        .foregroundStyle(suggestion.color)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(suggestion.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct HealthSuggestion: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let color: Color
}

// MARK: - Activity Tracking Card
struct ActivityTrackingCard: View {
    let activity: DailyActivity?

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "figure.walk.motion")
                    .foregroundStyle(.green)
                Text("Today's Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            if let activity = activity {
                VStack(spacing: 12) {
                    // Sleep
                    if let sleep = activity.sleepHours, sleep > 0 {
                        ActivityRow(
                            icon: "bed.double.fill",
                            title: "Sleep",
                            value: String(format: "%.1f hrs", sleep),
                            color: .purple
                        )
                    }

                    // Mood
                    if let mood = activity.mood {
                        ActivityRow(
                            icon: "face.smiling.fill",
                            title: "Mood",
                            value: mood,
                            color: .yellow
                        )
                    }

                    // Activity time
                    if let lying = activity.lyingDownMinutes, lying > 0 {
                        ActivityRow(
                            icon: "figure.walk",
                            title: "Lying Down",
                            value: "\(Int(lying)) min",
                            color: .blue
                        )
                    }
                }
            } else {
                Text("No activity logged today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Empty State
struct EmptyTodayState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("No Measurements Today")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Tap the measure button to record your first reading of the day")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [HeartRateMeasurement.self, DailyActivity.self], inMemory: true)
}
