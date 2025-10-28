//
//  HealthKitManager.swift
//  HeartRateMonitor
//
//  Created by nick on 18/10/2025.
//

import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let typesToShare: Set<HKSampleType> = [heartRateType, hrvType]
        let typesToRead: Set<HKObjectType> = [heartRateType, hrvType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            completion(success)
        }
    }
    
    func saveHeartRate(_ bpm: Double) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return
        }
        
        let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: bpm)
        let heartRateSample = HKQuantitySample(type: heartRateType, quantity: heartRateQuantity, start: Date(), end: Date())
        
        healthStore.save(heartRateSample) { success, error in
            if success {
                print("✅ Heart rate saved to HealthKit: \(bpm) BPM")
            } else if let error = error {
                print("❌ Error saving to HealthKit: \(error.localizedDescription)")
            }
        }
    }
    
    func saveHRV(_ hrv: Double) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return
        }
        
        let hrvQuantity = HKQuantity(unit: HKUnit.secondUnit(with: .milli), doubleValue: hrv)
        let hrvSample = HKQuantitySample(type: hrvType, quantity: hrvQuantity, start: Date(), end: Date())
        
        healthStore.save(hrvSample) { success, error in
            if success {
                print("✅ HRV saved to HealthKit: \(hrv) ms")
            }
        }
    }
}
