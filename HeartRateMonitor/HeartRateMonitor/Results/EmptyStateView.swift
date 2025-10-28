//
//  EmptyStateView.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            Text("No Measurements Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the button below to measure your heart rate using clinical-grade PPG technology")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView()
}
