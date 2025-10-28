//
//  SettingsView.swift
//  HeartRateMonitor
//
//  Created by nick on 20/10/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var measurements: [HeartRateMeasurement]
    
    @State private var showingDeleteAlert = false
    @State private var showingDeleteSuccess = false
    
    var body: some View {
        NavigationStack {
            List {
                // Data Section
                Section {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .foregroundStyle(.blue)
                            .frame(width: 30)
                        
                        Text("Total Measurements")
                        
                        Spacer()
                        
                        Text("\(measurements.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Data")
                }
                
                // Danger Zone Section
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .frame(width: 30)
                            
                            Text("Delete All Measurements")
                        }
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will permanently delete all heart rate measurements from this device and iCloud. This action cannot be undone.")
                }
                
                // App Info Section
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                            .frame(width: 30)
                        
                        Text("Version")
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "heart.circle")
                            .foregroundStyle(.red)
                            .frame(width: 30)
                        
                        Text("PPG Technology")
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .alert("Delete All Measurements?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                
                Button("Delete All", role: .destructive) {
                    deleteAllMeasurements()
                }
            } message: {
                Text("Are you sure you want to delete all \(measurements.count) measurements? This will remove them from both this device and iCloud permanently.")
            }
            .alert("Success", isPresented: $showingDeleteSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All measurements have been deleted successfully.")
            }
        }
    }
    
    private func deleteAllMeasurements() {
        print("🗑️ Deleting all \(measurements.count) measurements...")
        
        // Delete all measurements from SwiftData
        for measurement in measurements {
            modelContext.delete(measurement)
        }
        
        // Save changes (this will sync to iCloud if enabled)
        do {
            try modelContext.save()
            print("✅ Successfully deleted all measurements")
            showingDeleteSuccess = true
        } catch {
            print("❌ Error deleting measurements: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: HeartRateMeasurement.self, inMemory: true)
}
