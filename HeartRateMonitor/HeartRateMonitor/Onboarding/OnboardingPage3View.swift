//
//  OnboardingPage3View.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI
import UserNotifications

struct OnboardingPage3View: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var notificationsAuthorized = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 100))
                .foregroundStyle(.orange.gradient)
            
            Text("Stay Informed")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get reminders to check your heart rate and insights about your cardiovascular health")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                requestNotificationPermission()
            } label: {
                Text(notificationsAuthorized ? "Authorized ✓" : "Enable Notifications")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(notificationsAuthorized ? Color.green : Color.orange)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
            .disabled(notificationsAuthorized)
            
            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                notificationsAuthorized = granted
            }
        }
    }
}

#Preview {
    OnboardingPage3View(hasCompletedOnboarding: .constant(false))
}
