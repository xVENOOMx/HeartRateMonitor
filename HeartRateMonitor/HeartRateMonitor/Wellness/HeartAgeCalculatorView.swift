//
//  HeartAgeCalculatorView.swift
//  HeartRateMonitor
//
//  Created by Claude on 29/10/2025.
//

import SwiftUI

struct HeartAgeCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var age = ""
    @State private var sex = "Male"
    @State private var systolicBP = ""
    @State private var totalCholesterol = "190"
    @State private var hdlCholesterol = "50"
    @State private var weight = ""
    @State private var height = ""
    @State private var isSmoker = false
    @State private var hasDiabetes = false
    @State private var calculatedHeartAge: Int?
    @State private var isLoadingData = true
    @State private var validationErrors: Set<Field> = []
    @State private var resultData: HeartAgeResultData?

    enum Field: Hashable {
        case age, systolicBP, totalCholesterol, hdlCholesterol, weight, height
    }

    struct HeartAgeResultData: Identifiable {
        let id = UUID()
        let heartAge: Int
        let actualAge: Int
        let sex: String
        let isSmoker: Bool
        let hasDiabetes: Bool
    }

    var bmi: Double {
        guard let w = Double(weight), let h = Double(height), h > 0 else { return 25 }
        return w / ((h / 100) * (h / 100))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 15) {
                        Group {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Age")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("Age", text: $age)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .age)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(validationErrors.contains(.age) ? Color.red : Color.clear, lineWidth: 2)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sex")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Picker("Sex", selection: $sex) {
                                    Text("Male").tag("Male")
                                    Text("Female").tag("Female")
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Systolic Blood Pressure (mmHg)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("120", text: $systolicBP)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .systolicBP)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(validationErrors.contains(.systolicBP) ? Color.red : Color.clear, lineWidth: 2)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Total Cholesterol (mg/dL)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("190", text: $totalCholesterol)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .totalCholesterol)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(validationErrors.contains(.totalCholesterol) ? Color.red : Color.clear, lineWidth: 2)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("HDL Cholesterol (mg/dL)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("50", text: $hdlCholesterol)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .hdlCholesterol)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(validationErrors.contains(.hdlCholesterol) ? Color.red : Color.clear, lineWidth: 2)
                                    )
                            }

                            HStack(spacing: 15) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Weight (kg)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    TextField("70", text: $weight)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .weight)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(validationErrors.contains(.weight) ? Color.red : Color.clear, lineWidth: 2)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Height (cm)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    TextField("170", text: $height)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .height)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(validationErrors.contains(.height) ? Color.red : Color.clear, lineWidth: 2)
                                        )
                                }
                            }

                            Text("BMI: \(String(format: "%.1f", bmi))")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Toggle("Smoker", isOn: $isSmoker)
                            Toggle("Diabetes", isOn: $hasDiabetes)
                        }
                    }
                    .padding()

                    Button {
                        focusedField = nil // Dismiss keyboard
                        validateAndCalculate()
                    } label: {
                        Text("Calculate Heart Age")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Heart Age Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                loadHealthKitData()
            }
            .sheet(item: $resultData) { data in
                HeartAgeResultView(
                    heartAge: data.heartAge,
                    actualAge: data.actualAge,
                    sex: data.sex,
                    isSmoker: data.isSmoker,
                    hasDiabetes: data.hasDiabetes
                )
            }
        }
    }

    private func loadHealthKitData() {
        Task {
            isLoadingData = true

            // Load age
            if let userAge = await HealthKitManager.shared.getUserAge() {
                age = String(userAge)
            }

            // Load sex
            if let userSex = await HealthKitManager.shared.getUserSex() {
                sex = userSex
            }

            // Load weight
            if let userWeight = await HealthKitManager.shared.getUserWeight() {
                weight = String(format: "%.1f", userWeight)
            }

            // Load height
            if let userHeight = await HealthKitManager.shared.getUserHeight() {
                height = String(format: "%.0f", userHeight)
            }

            // Load blood pressure
            let bp = await HealthKitManager.shared.getUserBloodPressure()
            if let systolic = bp.systolic {
                systolicBP = String(format: "%.0f", systolic)
            }

            isLoadingData = false
        }
    }

    private func validateAndCalculate() {
        // Clear previous validation errors
        validationErrors.removeAll()

        // Validate required fields
        if age.isEmpty || Int(age) == nil {
            validationErrors.insert(.age)
        }
        if systolicBP.isEmpty || Double(systolicBP) == nil {
            validationErrors.insert(.systolicBP)
        }
        if totalCholesterol.isEmpty || Double(totalCholesterol) == nil {
            validationErrors.insert(.totalCholesterol)
        }
        if hdlCholesterol.isEmpty || Double(hdlCholesterol) == nil {
            validationErrors.insert(.hdlCholesterol)
        }
        if weight.isEmpty || Double(weight) == nil {
            validationErrors.insert(.weight)
        }
        if height.isEmpty || Double(height) == nil {
            validationErrors.insert(.height)
        }

        // If there are validation errors, trigger haptic feedback and return
        if !validationErrors.isEmpty {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }

        // All fields valid, calculate heart age
        // Setting resultData will automatically present the sheet
        calculateHeartAge()
    }

    private func calculateHeartAge() -> Bool {
        guard let actualAge = Int(age),
              let sbp = Double(systolicBP),
              let tc = Double(totalCholesterol),
              let hdl = Double(hdlCholesterol),
              let w = Double(weight),
              let h = Double(height) else {
            return false
        }

        // Calculate BMI
        let calculatedBMI = w / ((h / 100) * (h / 100))

        // Formula based on Framingham Heart Study
        let smokingFactor = isSmoker ? (sex == "Male" ? 4.0 : 3.0) : 0.0
        let diabetesFactor = hasDiabetes ? (sex == "Male" ? 3.0 : 2.0) : 0.0
        let bpFactor = (sbp - 120.0) / 10.0
        let cholesterolFactor = (tc - 190.0) / 50.0
        let hdlFactor = -(hdl - 45.0) / 10.0
        let bmiFactor = (calculatedBMI - 25.0) / 5.0

        let heartAge = Double(actualAge) + bpFactor + cholesterolFactor + hdlFactor + smokingFactor + diabetesFactor + bmiFactor

        let calculatedAge = max(actualAge, Int(heartAge.rounded()))

        // Store result data
        resultData = HeartAgeResultData(
            heartAge: calculatedAge,
            actualAge: actualAge,
            sex: sex,
            isSmoker: isSmoker,
            hasDiabetes: hasDiabetes
        )

        calculatedHeartAge = calculatedAge
        return true
    }
}

// MARK: - Heart Age Result View
struct HeartAgeResultView: View {
    @Environment(\.dismiss) private var dismiss
    let heartAge: Int
    let actualAge: Int
    let sex: String
    let isSmoker: Bool
    let hasDiabetes: Bool

    var ageDifference: Int {
        heartAge - actualAge
    }

    var healthStatus: (title: String, color: Color, icon: String) {
        if ageDifference > 10 {
            return ("Needs Attention", .red, "exclamationmark.triangle.fill")
        } else if ageDifference > 5 {
            return ("Could Be Better", .orange, "exclamationmark.circle.fill")
        } else if ageDifference > 0 {
            return ("Good", .yellow, "checkmark.circle.fill")
        } else if ageDifference < 0 {
            return ("Excellent", .green, "star.circle.fill")
        } else {
            return ("Very Good", .green, "checkmark.circle.fill")
        }
    }

    var recommendations: [String] {
        var tips: [String] = []

        if isSmoker {
            tips.append("Quit smoking - This is the single most important change you can make")
        }

        if hasDiabetes {
            tips.append("Manage your diabetes with regular monitoring and medication")
        }

        if ageDifference > 0 {
            tips.append("Increase physical activity to at least 150 minutes per week")
            tips.append("Follow a heart-healthy diet rich in fruits, vegetables, and whole grains")
            tips.append("Reduce stress through meditation, yoga, or regular exercise")
        }

        if ageDifference > 5 {
            tips.append("Schedule a check-up with your doctor to discuss cardiovascular health")
            tips.append("Monitor your blood pressure regularly")
        }

        if tips.isEmpty {
            tips.append("Maintain your current healthy lifestyle")
            tips.append("Continue regular exercise and healthy eating habits")
            tips.append("Keep monitoring your cardiovascular health")
        }

        return tips
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Main Result Card
                    VStack(spacing: 20) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.red)

                        Text("Your Heart Age")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Text("\(heartAge)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundStyle(.blue)

                        Text("years")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Divider()
                            .padding(.horizontal, 40)

                        VStack(spacing: 8) {
                            Text("Your Actual Age: \(actualAge) years")
                                .font(.headline)

                            if ageDifference > 0 {
                                Text("\(abs(ageDifference)) years older than your actual age")
                                    .font(.subheadline)
                                    .foregroundStyle(.orange)
                            } else if ageDifference < 0 {
                                Text("\(abs(ageDifference)) years younger than your actual age")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Same as your actual age")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                        }

                        // Health Status Badge
                        HStack {
                            Image(systemName: healthStatus.icon)
                            Text(healthStatus.title)
                                .fontWeight(.semibold)
                        }
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(healthStatus.color)
                        .cornerRadius(25)
                    }
                    .padding(30)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Recommendations Card
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Recommendations")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding(.bottom, 5)

                        ForEach(Array(recommendations.enumerated()), id: \.offset) { index, tip in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                                    .frame(width: 25, alignment: .leading)

                                Text(tip)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(15)
                    .padding(.horizontal)

                    // Risk Factors
                    if isSmoker || hasDiabetes {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Current Risk Factors")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .padding(.bottom, 5)

                            if isSmoker {
                                HStack {
                                    Image(systemName: "smoke.fill")
                                        .foregroundStyle(.red)
                                    Text("Smoking")
                                        .font(.subheadline)
                                }
                            }

                            if hasDiabetes {
                                HStack {
                                    Image(systemName: "cross.circle.fill")
                                        .foregroundStyle(.orange)
                                    Text("Diabetes")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }

                    Text("This calculation is an estimate based on the Framingham Heart Study. Please consult with a healthcare professional for personalized advice.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Heart Age Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HeartAgeCalculatorView()
}
