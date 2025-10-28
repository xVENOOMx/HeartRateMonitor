//
//  SubscriptionFeatureRow.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI

struct SubscriptionFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 30)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

#Preview {
    SubscriptionFeatureRow(icon: "infinity", text: "Unlimited Measurements")
        .padding()
}
