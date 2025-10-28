//
//  MetricRow.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 25)
            
            Text(label)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        MetricRow(icon: "heart.fill", label: "Heart Rate", value: "72", unit: "BPM", color: .red)
        MetricRow(icon: "waveform.path.ecg", label: "HRV", value: "55.3", unit: "ms", color: .blue)
        MetricRow(icon: "bolt.fill", label: "Energy", value: "75", unit: "%", color: .yellow)
    }
    .padding()
}
