//
//  OnboardingPage1View.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI

struct OnboardingPage1View: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(.red.gradient)
            
            Text("Welcome to Heart Rate Monitor")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Monitor your heart health with clinical-grade accuracy using advanced PPG technology")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingPage1View()
}
