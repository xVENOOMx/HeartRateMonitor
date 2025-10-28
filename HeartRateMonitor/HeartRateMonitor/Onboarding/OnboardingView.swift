//
//  OnboardingView.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingPage1View()
                .tag(0)
            
            OnboardingPage2View()
                .tag(1)
            
            OnboardingPage3View(hasCompletedOnboarding: $hasCompletedOnboarding)
                .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
