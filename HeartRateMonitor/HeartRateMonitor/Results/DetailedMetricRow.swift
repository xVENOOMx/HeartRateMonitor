//
//  DetailedMetricRow.swift
//  HeartRateMonitor
//
//  Created by nick on 28/10/2025.
//

import SwiftUI
import Charts

struct DetailedMetricRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    let numericValue: Double
    let maxValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon, label, and value
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

            // Chart visualization
            Chart {
                BarMark(
                    x: .value("Value", numericValue)
                )
                .foregroundStyle(color.gradient)
                .cornerRadius(4)
            }
            .chartXScale(domain: 0...maxValue)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 20)
            .padding(.leading, 25)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        DetailedMetricRow(
            icon: "heart.fill",
            label: "Heart Rate",
            value: "72",
            unit: "BPM",
            color: .red,
            numericValue: 72,
            maxValue: 200
        )
        DetailedMetricRow(
            icon: "waveform.path.ecg",
            label: "HRV",
            value: "55.3",
            unit: "ms",
            color: .blue,
            numericValue: 55.3,
            maxValue: 100
        )
        DetailedMetricRow(
            icon: "bolt.fill",
            label: "Energy",
            value: "75",
            unit: "%",
            color: .yellow,
            numericValue: 75,
            maxValue: 100
        )
    }
    .padding()
}
