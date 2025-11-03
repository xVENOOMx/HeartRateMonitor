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

    enum Field: Hashable {
        case age, systolicBP, totalCholesterol, hdlCholesterol, weight, height
    }

    var bmi: Double {
        guard let w = Double(weight), let h = Double(height), h > 0 else { return 25 }
        return w / ((h / 100) * (h / 100))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let heartAge = calculatedHeartAge {
                        // Result Card
                        VStack(spacing: 15) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.red)

                            Text("Your Heart Age")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("\(heartAge) years")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(.blue)

                            if let actualAge = Int(age) {
                                let difference = heartAge - actualAge
                                Text(difference > 0 ? "\(abs(difference)) years older" : difference < 0 ? "\(abs(difference)) years younger" : "Same as your age")
                                    .font(.subheadline)
                                    .foregroundStyle(difference > 0 ? .orange : .green)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(15)
                        .padding()
                    }

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
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Total Cholesterol (mg/dL)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("190", text: $totalCholesterol)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .totalCholesterol)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("HDL Cholesterol (mg/dL)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("50", text: $hdlCholesterol)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .hdlCholesterol)
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
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Height (cm)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    TextField("170", text: $height)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .height)
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
                        calculateHeartAge()
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

    private func calculateHeartAge() {
        guard let actualAge = Int(age),
              let sbp = Double(systolicBP),
              let tc = Double(totalCholesterol),
              let hdl = Double(hdlCholesterol) else {
            return
        }

        // Formula based on Framingham Heart Study
        let smokingFactor = isSmoker ? (sex == "Male" ? 4.0 : 3.0) : 0.0
        let diabetesFactor = hasDiabetes ? (sex == "Male" ? 3.0 : 2.0) : 0.0
        let bpFactor = (sbp - 120.0) / 10.0
        let cholesterolFactor = (tc - 190.0) / 50.0
        let hdlFactor = -(hdl - 45.0) / 10.0
        let bmiFactor = (bmi - 25.0) / 5.0

        let heartAge = Double(actualAge) + bpFactor + cholesterolFactor + hdlFactor + smokingFactor + diabetesFactor + bmiFactor

        calculatedHeartAge = max(actualAge, Int(heartAge.rounded()))
    }
}

#Preview {
    HeartAgeCalculatorView()
}
