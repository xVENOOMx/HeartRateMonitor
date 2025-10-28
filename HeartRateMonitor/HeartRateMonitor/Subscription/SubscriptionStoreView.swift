//
//  SubscriptionStoreView.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI

struct SubscriptionStoreView: View {
    @Binding var hasActiveSubscription: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "crown.fill")
                .font(.system(size: 100))
                .foregroundStyle(.yellow.gradient)
            
            Text("Unlock Premium Features")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get unlimited measurements and advanced analytics")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                SubscriptionFeatureRow(icon: "infinity", text: "Unlimited Measurements")
                SubscriptionFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced Analytics & Trends")
                SubscriptionFeatureRow(icon: "cloud.fill", text: "iCloud Sync Across Devices")
                SubscriptionFeatureRow(icon: "bell.fill", text: "Smart Health Reminders")
                SubscriptionFeatureRow(icon: "star.fill", text: "Export Data to CSV")
            }
            .padding()
            
            Button {
                hasActiveSubscription = true
            } label: {
                Text("Start Free Trial")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
            
            Button {
                hasActiveSubscription = true
            } label: {
                Text("Skip for now")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    SubscriptionStoreView(hasActiveSubscription: .constant(false))
}
