//
//  HeartRateMeasurement.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import Foundation
import SwiftData

@Model
final class HeartRateMeasurement {
    var id: UUID?
    var timestamp: Date?
    var heartRate: Double?
    var hrv: Double?
    var sdnn: Double?
    var stress: Double?
    var energy: Double?
    var plus: Double?
    var signalQuality: Double?
    var confidence: String?
    
    init(
        heartRate: Double = 0,
        hrv: Double = 0,
        sdnn: Double = 0,
        stress: Double = 0,
        energy: Double = 0,
        plus: Double = 0,
        signalQuality: Double = 0,
        confidence: String = "Good"
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.heartRate = heartRate
        self.hrv = hrv
        self.sdnn = sdnn
        self.stress = stress
        self.energy = energy
        self.plus = plus
        self.signalQuality = signalQuality
        self.confidence = confidence
    }
}
