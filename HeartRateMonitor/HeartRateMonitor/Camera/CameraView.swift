//
//  CameraView.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI
import SwiftData
import AVFoundation

struct CameraView: View {
    @Binding var isPresented: Bool
    @StateObject private var cameraManager = CameraManager()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    var onMeasurementComplete: ((HeartRateMeasurement) -> Void)?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Live camera preview with green filter overlay for user feedback
            CameraPreviewView(session: cameraManager.captureSession)
                .ignoresSafeArea()
                .overlay(
                    // Green filter ONLY for visual feedback
                    Color.green.opacity(cameraManager.fingerDetected ? 0.25 : 0.05)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.3), value: cameraManager.fingerDetected)
                )
            
            VStack {
                // Top section - Close button and BPM display
                VStack(spacing: 10) {
                    HStack {
                        Button {
                            cameraManager.stopSession()
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Large BPM Display at top
                    if cameraManager.isRecording && !cameraManager.waitingForFinger {
                        if let currentBPM = cameraManager.currentBPM {
                            HStack(spacing: 15) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.red)
                                    .scaleEffect(cameraManager.pulseAnimation ? 1.3 : 1.0)
                                    .animation(.easeInOut(duration: 0.15), value: cameraManager.pulseAnimation)
                                
                                Text("\(Int(currentBPM)) bpm")
                                    .font(.system(size: 60, weight: .bold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 10)
                            }
                            .padding(.top, 20)
                        } else {
                            HStack(spacing: 15) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                Text("-- bpm")
                                    .font(.system(size: 60, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .padding(.top, 20)
                        }
                    }
                }
                
                Spacer()
                
                // Middle section - Instructions or Finish
                if cameraManager.measurementComplete {
                    // Finish State
                    VStack(spacing: 30) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)
                        
                        Text("Measurement Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        if let bpm = cameraManager.finalMeasurement?.heartRate {
                            VStack(spacing: 10) {
                                Text("\(Int(bpm)) BPM")
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                if let confidence = cameraManager.finalMeasurement?.confidence {
                                    Text(confidence + " Quality")
                                        .font(.title3)
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding()
                        }
                        
                        Button {
                            if let measurement = cameraManager.finalMeasurement {
                                saveMeasurement(measurement)

                                if let heartRate = measurement.heartRate {
                                    HealthKitManager.shared.saveHeartRate(heartRate)
                                }

                                // Dismiss camera view first
                                isPresented = false

                                // Then notify parent to show detailed view
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onMeasurementComplete?(measurement)
                                }
                            }
                        } label: {
                            Text("See Results")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 200, height: 55)
                                .background(Color.blue)
                                .cornerRadius(27.5)
                        }
                    }
                    .padding()
                } else if cameraManager.waitingForFinger {
                    // Waiting for finger state
                    VStack(spacing: 40) {
                        Text("Place Your Finger")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        VStack(spacing: 20) {
                            Image(systemName: "hand.point.up.left.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.white.opacity(0.8))
                                .symbolEffect(.pulse, options: .repeating)
                            
                            VStack(spacing: 15) {
                                Text("Position your finger over")
                                    .font(.body)
                                    .foregroundStyle(.white)
                                Text("the camera and flash")
                                    .font(.body)
                                    .foregroundStyle(.white)
                                Text("Cover completely and hold steady")
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                } else if cameraManager.isRecording {
                    // Status indicators during recording
                    VStack(spacing: 15) {
                        if !cameraManager.fingerDetected {
                            Text("Keep finger on camera and flash")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(10)
                        }
                        
                        if cameraManager.motionDetected {
                            Text("⚠️ Please hold steady")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.orange.opacity(0.8))
                                .cornerRadius(10)
                        }
                        
                        if let signalQuality = cameraManager.signalQualityText {
                            HStack {
                                Image(systemName: cameraManager.signalQualityIcon)
                                    .foregroundStyle(cameraManager.signalQualityColor)
                                Text(signalQuality)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(15)
                        }
                    }
                }
                
                Spacer()
                
                // Bottom section - Progress
                if cameraManager.isRecording && !cameraManager.measurementComplete && !cameraManager.waitingForFinger {
                    VStack(spacing: 8) {
                        ProgressView(value: cameraManager.recordingProgress)
                            .progressViewStyle(.linear)
                            .tint(.red)
                            .frame(width: 250)
                        
                        Text("\(Int(cameraManager.recordingProgress * 100))%")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 50)
                }
            }
            
            // Session Interrupted Overlay
            if cameraManager.showInterruptedOverlay {
                SessionInterruptedOverlay(
                    onTryAgain: {
                        cameraManager.restartAfterInterruption()
                    },
                    onCancel: {
                        cameraManager.cancelAfterInterruption()
                        isPresented = false
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
            
            // NEW: No Finger Timeout Overlay
            if cameraManager.showNoFingerTimeout {
                NoFingerTimeoutOverlay(
                    onTryAgain: {
                        cameraManager.retryAfterTimeout()
                    },
                    onCancel: {
                        cameraManager.cancelAfterTimeout()
                        isPresented = false
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .onAppear {
            cameraManager.startSession()
            // Start recording immediately (will wait for finger)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                cameraManager.startRecording()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        // Monitor app lifecycle
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                print("📱 App entered background")
                cameraManager.handleAppDidEnterBackground()
            case .active:
                print("📱 App became active")
                cameraManager.handleAppWillEnterForeground()
            case .inactive:
                print("📱 App became inactive")
            @unknown default:
                break
            }
        }
    }
    
    private func saveMeasurement(_ measurement: HeartRateMeasurement) {
        modelContext.insert(measurement)
        try? modelContext.save()
    }
}

// Session Interrupted Overlay
struct SessionInterruptedOverlay: View {
    let onTryAgain: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("⚠️")
                    .font(.system(size: 80))
                
                Text("Session Canceled")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("The measurement was interrupted when the app went to the background.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 15) {
                    Button(action: onTryAgain) {
                        Text("Try Again")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(.gray)
                    }
                    .frame(height: 44)
                }
                .padding(.top, 10)
            }
        }
    }
}

// NEW: No Finger Timeout Overlay
struct NoFingerTimeoutOverlay: View {
    let onTryAgain: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                
                Text("No Finger Detected")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Please place your finger on the camera and flash to start the measurement.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 15) {
                    Button(action: onTryAgain) {
                        Text("Try Again")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(.gray)
                    }
                    .frame(height: 44)
                }
                .padding(.top, 10)
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession?
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        if let session = session {
            view.setupPreview(with: session)
        }
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if let session = session, uiView.previewLayer?.session !== session {
            uiView.setupPreview(with: session)
        }
    }
}

class CameraPreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupPreview(with session: AVCaptureSession) {
        previewLayer?.removeFromSuperlayer()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoRotationAngle = 90
        
        layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
        previewLayer.frame = bounds
        
        print("✅ Preview layer setup complete")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

#Preview {
    CameraView(isPresented: .constant(true))
        .modelContainer(for: HeartRateMeasurement.self, inMemory: true)
}
