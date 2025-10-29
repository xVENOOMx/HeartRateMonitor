//
//  WellnessView.swift
//  HeartRateMonitor
//
//  Created by Claude on 29/10/2025.
//

import SwiftUI
import SwiftData
import HealthKit

struct WellnessView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allMeasurements: [HeartRateMeasurement]
    @Query private var allActivities: [DailyActivity]

    @State private var selectedDate = Date()
    @State private var showHeartAgeCalculator = false
    @State private var showHealthKitPermissions = false
    @State private var healthKitAuthorized = false

    private let calendar = Calendar.current

    // Get measurements for selected date
    var selectedDateMeasurements: [HeartRateMeasurement] {
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return allMeasurements.filter { measurement in
            guard let timestamp = measurement.timestamp else { return false }
            return timestamp >= dayStart && timestamp < dayEnd
        }
    }

    // Get activity for selected date
    var selectedDateActivity: DailyActivity? {
        let dayStart = calendar.startOfDay(for: selectedDate)

        return allActivities.first { activity in
            guard let date = activity.date else { return false }
            return calendar.isDate(date, inSameDayAs: dayStart)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Horizontal Scrollable Calendar
                    HorizontalCalendarView(selectedDate: $selectedDate)
                        .padding(.top, 10)

                    // Heart Age Calculator Card
                    HeartAgeCard {
                        showHeartAgeCalculator = true
                    }
                    .padding(.horizontal)

                    // Mood Tracker
                    MoodTrackerCard(selectedDate: selectedDate, activity: selectedDateActivity)
                        .padding(.horizontal)

                    // Step Counter
                    StepCounterCard(selectedDate: selectedDate)
                        .padding(.horizontal)

                    // HealthKit Connection
                    HealthKitConnectionCard(
                        isAuthorized: healthKitAuthorized,
                        onTap: {
                            showHealthKitPermissions = true
                        }
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 100)
            }
            .navigationTitle("Wellness")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showHeartAgeCalculator) {
                HeartAgeCalculatorView()
            }
            .sheet(isPresented: $showHealthKitPermissions) {
                HealthKitPermissionsView(isAuthorized: $healthKitAuthorized)
            }
            .onAppear {
                checkHealthKitAuthorization()
            }
        }
    }

    private func checkHealthKitAuthorization() {
        Task {
            healthKitAuthorized = await HealthKitManager.shared.isAuthorized()
        }
    }
}

// MARK: - Horizontal Calendar View
struct HorizontalCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth = Date()
    @Query private var measurements: [HeartRateMeasurement]

    private let calendar = Calendar.current

    var datesWithData: Set<Date> {
        var dates = Set<Date>()
        for measurement in measurements {
            if let timestamp = measurement.timestamp {
                let day = calendar.startOfDay(for: timestamp)
                dates.insert(day)
            }
        }
        return dates
    }

    var body: some View {
        VStack(spacing: 10) {
            // Month navigation
            HStack {
                Text(currentMonth, format: .dateTime.month(.wide).year())
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                HStack(spacing: 15) {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.blue)
                    }

                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.horizontal)

            // Horizontal scrolling days
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(generateDaysForMonth(), id: \.self) { date in
                        DayButton(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasData: datesWithData.contains(calendar.startOfDay(for: date)),
                            isToday: calendar.isDateInToday(date)
                        ) {
                            selectedDate = date
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }

    private func changeMonth(by months: Int) {
        if let newDate = calendar.date(byAdding: .month, value: months, to: currentMonth) {
            currentMonth = newDate
            // Auto-select first day of new month
            if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: newDate)) {
                selectedDate = monthStart
            }
        }
    }

    private func generateDaysForMonth() -> [Date] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        return monthRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }
}

struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let hasData: Bool
    let isToday: Bool
    let action: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(date, format: .dateTime.weekday(.narrow))
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .secondary)

                Text("\(calendar.component(.day, from: date))")
                    .font(.title3)
                    .fontWeight(isSelected || isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : .primary)

                Circle()
                    .fill(hasData ? (isSelected ? Color.white : Color.red) : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 50, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Heart Age Card
struct HeartAgeCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)

                        Text("What's your heart age?")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    Text("Calculate your cardiovascular age based on your health metrics")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mood Tracker Card
struct MoodTrackerCard: View {
    let selectedDate: Date
    let activity: DailyActivity?
    @Environment(\.modelContext) private var modelContext

    let moods: [(String, String, Color)] = [
        ("Happy", "face.smiling.fill", .yellow),
        ("Calm", "leaf.fill", .green),
        ("Okay", "face.dashed", .blue),
        ("Sad", "cloud.rain.fill", .gray),
        ("Tired", "bed.double.fill", .purple)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("How was your day?")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 15) {
                ForEach(moods, id: \.0) { mood in
                    MoodButton(
                        title: mood.0,
                        icon: mood.1,
                        color: mood.2,
                        isSelected: activity?.mood == mood.0
                    ) {
                        saveMood(mood.0)
                    }
                }
            }

            if let mood = activity?.mood {
                Text("Today's mood: \(mood)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }

    private func saveMood(_ mood: String) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)

        if let existingActivity = activity {
            existingActivity.mood = mood
        } else {
            let newActivity = DailyActivity()
            newActivity.date = dayStart
            newActivity.mood = mood
            modelContext.insert(newActivity)
        }

        try? modelContext.save()
    }
}

struct MoodButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : color)

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color : Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Step Counter Card
struct StepCounterCard: View {
    let selectedDate: Date
    @State private var steps = 0
    @State private var calories = 0
    @State private var distance = 0.0
    @State private var flights = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Activity")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 20) {
                // Steps (larger, on left)
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)

                    Text("\(steps)")
                        .font(.system(size: 32, weight: .bold))

                    Text("Steps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)

                // Other metrics (stacked on right)
                VStack(spacing: 12) {
                    ActivityMetricRow(icon: "flame.fill", value: "\(calories)", unit: "Cal", color: .orange)
                    ActivityMetricRow(icon: "map.fill", value: String(format: "%.2f", distance), unit: "km", color: .green)
                    ActivityMetricRow(icon: "figure.stairs", value: "\(flights)", unit: "Floors", color: .purple)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
        .onAppear {
            loadStepData()
        }
    }

    private func loadStepData() {
        Task {
            let healthKit = HealthKitManager.shared
            steps = await healthKit.getStepsForDate(selectedDate)
            calories = await healthKit.getCaloriesForDate(selectedDate)
            distance = await healthKit.getDistanceForDate(selectedDate)
            flights = await healthKit.getFlightsForDate(selectedDate)
        }
    }
}

struct ActivityMetricRow: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

// MARK: - HealthKit Connection Card
struct HealthKitConnectionCard: View {
    let isAuthorized: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isAuthorized ? "checkmark.circle.fill" : "heart.text.square.fill")
                    .font(.title2)
                    .foregroundStyle(isAuthorized ? .green : .red)

                VStack(alignment: .leading, spacing: 4) {
                    Text(isAuthorized ? "HealthKit Connected" : "Connect HealthKit")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(isAuthorized ? "Sync your health data" : "Enable health data syncing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WellnessView()
        .modelContainer(for: [HeartRateMeasurement.self, DailyActivity.self], inMemory: true)
}
