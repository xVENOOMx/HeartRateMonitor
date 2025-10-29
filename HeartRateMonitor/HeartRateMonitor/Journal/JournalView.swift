//
//  JournalView.swift
//  HeartRateMonitor
//
//  Created by Claude on 29/10/2025.
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var measurements: [HeartRateMeasurement]
    @Query private var activities: [DailyActivity]

    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showDayView = false

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    // Get dates that have measurements
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
        NavigationStack {
            VStack(spacing: 0) {
                // Month selector
                HStack {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    Text(dateFormatter.string(from: selectedMonth))
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
                .padding()

                // Calendar Grid
                ScrollView {
                    VStack(spacing: 15) {
                        // Weekday headers
                        HStack(spacing: 0) {
                            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                                Text(day)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)

                        // Calendar days
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                            ForEach(generateCalendarDays(), id: \.self) { date in
                                if let date = date {
                                    CalendarDayCell(
                                        date: date,
                                        hasData: datesWithData.contains(calendar.startOfDay(for: date)),
                                        isSelected: selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!),
                                        isCurrentMonth: calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month),
                                        isToday: calendar.isDateInToday(date)
                                    )
                                    .onTapGesture {
                                        if datesWithData.contains(calendar.startOfDay(for: date)) {
                                            selectedDate = date
                                            showDayView = true
                                        }
                                    }
                                } else {
                                    Color.clear
                                        .frame(height: 50)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Legend
                        HStack(spacing: 20) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("Has data")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 5) {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                                    .frame(width: 8, height: 8)
                                Text("Today")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showDayView) {
                if let date = selectedDate {
                    DayView(date: date)
                }
            }
        }
    }

    private func changeMonth(by months: Int) {
        if let newDate = calendar.date(byAdding: .month, value: months, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func generateCalendarDays() -> [Date?] {
        var days: [Date?] = []

        // Get the first day of the month
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return days
        }

        // Get the weekday of the first day (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: monthStart)

        // Add empty cells for days before the month starts
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Get the range of days in the month
        guard let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return days
        }

        // Add all days in the month
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }

        return days
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let date: Date
    let hasData: Bool
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isCurrentMonth ? .primary : .secondary.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.2))
                        }
                        if isToday {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 2)
                        }
                    }
                )

            if hasData {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
    }
}

#Preview {
    JournalView()
        .modelContainer(for: [HeartRateMeasurement.self, DailyActivity.self], inMemory: true)
}
