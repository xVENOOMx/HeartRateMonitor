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

    // MARK: - Authorization

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

    func requestAllPermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        // Define all types we want to access
        var typesToRead: Set<HKObjectType> = []
        var typesToShare: Set<HKSampleType> = []

        // Heart metrics
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            typesToRead.insert(heartRate)
            typesToShare.insert(heartRate)
        }
        if let hrv = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            typesToRead.insert(hrv)
            typesToShare.insert(hrv)
        }

        // Activity metrics
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            typesToRead.insert(steps)
        }
        if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            typesToRead.insert(distance)
        }
        if let calories = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            typesToRead.insert(calories)
        }
        if let flights = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
            typesToRead.insert(flights)
        }

        // Health metrics for heart age
        if let bloodPressureSystolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic) {
            typesToRead.insert(bloodPressureSystolic)
        }
        if let bloodPressureDiastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            typesToRead.insert(bloodPressureDiastolic)
        }
        if let totalCholesterol = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) {
            typesToRead.insert(totalCholesterol)
        }
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            typesToRead.insert(weight)
        }
        if let height = HKQuantityType.quantityType(forIdentifier: .height) {
            typesToRead.insert(height)
        }

        // Biological sex and date of birth
        typesToRead.insert(HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex)!)
        typesToRead.insert(HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!)

        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                continuation.resume(returning: success)
            }
        }
    }

    func isAuthorized() async -> Bool {
        guard let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return false
        }

        let status = healthStore.authorizationStatus(for: heartRate)
        return status == .sharingAuthorized
    }

    // MARK: - Save Data

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

    // MARK: - Read Activity Data

    func getStepsForDate(_ date: Date) async -> Int {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        return await getQuantityForDate(date, type: stepsType, unit: .count())
    }

    func getCaloriesForDate(_ date: Date) async -> Int {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }

        return await getQuantityForDate(date, type: caloriesType, unit: .kilocalorie())
    }

    func getDistanceForDate(_ date: Date) async -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return 0.0
        }

        let meters = await getQuantityForDate(date, type: distanceType, unit: .meter())
        return Double(meters) / 1000.0 // Convert to kilometers
    }

    func getFlightsForDate(_ date: Date) async -> Int {
        guard let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else {
            return 0
        }

        return await getQuantityForDate(date, type: flightsType, unit: .count())
    }

    private func getQuantityForDate(_ date: Date, type: HKQuantityType, unit: HKUnit) async -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }

                let value = sum.doubleValue(for: unit)
                continuation.resume(returning: Int(value))
            }

            healthStore.execute(query)
        }
    }

    // MARK: - User Health Data for Heart Age

    func getUserAge() async -> Int? {
        do {
            let dateOfBirth = try healthStore.dateOfBirthComponents()
            let calendar = Calendar.current
            let now = Date()
            let ageComponents = calendar.dateComponents([.year], from: dateOfBirth.date ?? now, to: now)
            return ageComponents.year
        } catch {
            return nil
        }
    }

    func getUserSex() async -> String? {
        do {
            let biologicalSex = try healthStore.biologicalSex()
            switch biologicalSex.biologicalSex {
            case .male:
                return "Male"
            case .female:
                return "Female"
            default:
                return nil
            }
        } catch {
            return nil
        }
    }

    func getUserWeight() async -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }
        return await getMostRecentQuantity(type: weightType, unit: .gramUnit(with: .kilo))
    }

    func getUserHeight() async -> Double? {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            return nil
        }
        let meters = await getMostRecentQuantity(type: heightType, unit: .meter())
        return meters.map { $0 * 100 } // Convert to centimeters
    }

    func getUserBloodPressure() async -> (systolic: Double?, diastolic: Double?) {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            return (nil, nil)
        }

        async let systolic = getMostRecentQuantity(type: systolicType, unit: .millimeterOfMercury())
        async let diastolic = getMostRecentQuantity(type: diastolicType, unit: .millimeterOfMercury())

        return await (systolic, diastolic)
    }

    private func getMostRecentQuantity(type: HKQuantityType, unit: HKUnit) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }
}
