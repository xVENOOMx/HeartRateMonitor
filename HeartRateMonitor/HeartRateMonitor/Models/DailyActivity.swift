//
//  DailyActivity.swift
//  HeartRateMonitor
//
//  Created by Claude on 29/10/2025.
//

import Foundation
import SwiftData

@Model
final class DailyActivity {
    var id: UUID?
    var date: Date?

    // Sleep tracking
    var sleepHours: Double?
    var sleepQuality: String? // "Poor", "Fair", "Good", "Excellent"
    var bedTime: Date?
    var wakeTime: Date?

    // Feeling/Mood
    var mood: String? // "Great", "Good", "Okay", "Poor", "Bad"
    var stressLevel: Int? // 1-10
    var energyLevel: Int? // 1-10

    // Activity states
    var lyingDownMinutes: Double? // Time spent lying down
    var sittingMinutes: Double? // Time spent sitting
    var activeMinutes: Double? // Time spent active/moving

    // Notes
    var notes: String?

    init(
        sleepHours: Double = 0,
        sleepQuality: String = "Good",
        mood: String = "Good",
        stressLevel: Int = 5,
        energyLevel: Int = 5,
        lyingDownMinutes: Double = 0,
        sittingMinutes: Double = 0,
        activeMinutes: Double = 0,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = Date()
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.mood = mood
        self.stressLevel = stressLevel
        self.energyLevel = energyLevel
        self.lyingDownMinutes = lyingDownMinutes
        self.sittingMinutes = sittingMinutes
        self.activeMinutes = activeMinutes
        self.notes = notes
    }
}
