//
//  HealthKitPermissionsView.swift
//  HeartRateMonitor
//
//  Created by Claude on 29/10/2025.
//

import SwiftUI

struct HealthKitPermissionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isAuthorized: Bool

    let permissions = [
        ("Heart Rate", "heart.fill", "Track your heart rate measurements"),
        ("Steps", "figure.walk", "Monitor your daily step count"),
        ("Distance", "map.fill", "Track distance walked/run"),
        ("Calories", "flame.fill", "Monitor calories burned"),
        ("Flights Climbed", "figure.stairs", "Track stairs climbed"),
        ("Blood Pressure", "waveform.path.ecg", "For heart age calculation"),
        ("Cholesterol", "drop.fill", "For heart age calculation"),
        ("Weight", "scalemass.fill", "For BMI and heart age"),
        ("Height", "ruler.fill", "For BMI calculation"),
        ("Blood Glucose", "cross.vial", "Diabetes monitoring")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)

                        Text("Connect to HealthKit")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Enable these permissions to get the most out of the app")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    // Permissions List
                    VStack(spacing: 15) {
                        ForEach(permissions, id: \.0) { permission in
                            PermissionRow(
                                title: permission.0,
                                icon: permission.1,
                                description: permission.2
                            )
                        }
                    }
                    .padding()

                    // Connect Button
                    Button {
                        requestPermissions()
                    } label: {
                        Text("Connect HealthKit")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Text("You can change these permissions anytime in the Health app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("HealthKit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func requestPermissions() {
        Task {
            let success = await HealthKitManager.shared.requestAllPermissions()
            if success {
                isAuthorized = true
                dismiss()
            }
        }
    }
}

struct PermissionRow: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    HealthKitPermissionsView(isAuthorized: .constant(false))
}
