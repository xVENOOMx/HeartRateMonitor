//
//  OnboardingPage2View.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI
import HealthKit

struct OnboardingPage2View: View {
    @State private var healthKitAuthorized = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 100))
                .foregroundStyle(.pink.gradient)

            Text("HealthKit Integration")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Access comprehensive health data including heart rate, activity metrics, blood pressure, and more for complete wellness tracking")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                requestHealthKitAuthorization()
            } label: {
                Text(healthKitAuthorized ? "Authorized ✓" : "Grant HealthKit Access")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(healthKitAuthorized ? Color.green : Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
            .disabled(healthKitAuthorized)

            Spacer()
        }
        .padding()
    }

    private func requestHealthKitAuthorization() {
        Task {
            let success = await HealthKitManager.shared.requestAllPermissions()
            await MainActor.run {
                healthKitAuthorized = success
            }
        }
    }
}

#Preview {
    OnboardingPage2View()
}
