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

    // Additional HRV metrics
    var meanRR: Double?        // Mean RR interval (ms)
    var rmssd: Double?         // Root Mean Square of Successive Differences (ms)
    var pnn50: Double?         // Percentage of NN intervals differing by >50ms (%)
    var mxdmn: Double?         // Max Delta Min - difference between max and min RR (ms)
    var mode: Double?          // Most common RR interval (ms)
    var amo50: Double?         // Amplitude of Mode 50 (%)
    var cv: Double?            // Coefficient of Variation (%)
    var coherence: Double?     // Heart rhythm coherence score (0-100)
    var focus: Double?         // Mental focus score (0-100)
    var health: Double?        // Overall health score (0-100)

    init(
        heartRate: Double = 0,
        hrv: Double = 0,
        sdnn: Double = 0,
        stress: Double = 0,
        energy: Double = 0,
        plus: Double = 0,
        signalQuality: Double = 0,
        confidence: String = "Good",
        meanRR: Double = 0,
        rmssd: Double = 0,
        pnn50: Double = 0,
        mxdmn: Double = 0,
        mode: Double = 0,
        amo50: Double = 0,
        cv: Double = 0,
        coherence: Double = 0,
        focus: Double = 0,
        health: Double = 0
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
        self.meanRR = meanRR
        self.rmssd = rmssd
        self.pnn50 = pnn50
        self.mxdmn = mxdmn
        self.mode = mode
        self.amo50 = amo50
        self.cv = cv
        self.coherence = coherence
        self.focus = focus
        self.health = health
    }
}
