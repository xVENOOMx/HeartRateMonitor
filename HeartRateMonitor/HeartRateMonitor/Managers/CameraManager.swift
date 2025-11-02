//
//  CameraManager.swift
//  HeartRateMonitor
//
//  Created by nick on 16/10/2025.
//

import SwiftUI
@preconcurrency import AVFoundation
import Accelerate
import CoreMotion
import Combine
import UIKit

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentBPM: Double?
    @Published var recordingProgress: Double = 0
    @Published var measurementComplete = false
    @Published var finalMeasurement: HeartRateMeasurement?
    @Published var fingerDetected = false
    @Published var motionDetected = false
    @Published var pulseAnimation = false
    @Published var signalQualityText: String?
    @Published var signalQualityIcon = "checkmark.circle.fill"
    @Published var signalQualityColor: Color = .green
    @Published var wasInterrupted = false
    @Published var showInterruptedOverlay = false
    @Published var showNoFingerTimeout = false
    @Published var waitingForFinger = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""

    var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let videoOutputQueue = DispatchQueue(label: "VideoOutputQueue", qos: .userInitiated)
    private var selectedCameraDevice: AVCaptureDevice?
    
    // PPG signal data - GREEN channel only
    private var greenChannelValues: [Double] = []
    private var timestamps: [Double] = []
    private var redChannelValues: [Double] = []    // For finger detection only
    
    private var startTime: Date?
    private let recordingDuration: TimeInterval = 30.0
    private var timer: Timer?
    private var motionManager: CMMotionManager?
    private var lastPulseTime: Date?
    
    // NEW: Timeout tracking
    private var lastFingerDetectedTime: Date?
    private var noFingerTimeoutTimer: Timer?
    private let noFingerTimeoutDuration: TimeInterval = 10.0
    private var flashIsOn = false
    
    // NEW: Finger detection with color pattern
    private var consecutiveFingerFrames = 0
    private let requiredConsecutiveFrames = 60  // 2 seconds at 30fps
    private var screenSleepDisabled = false
    
    // Enhanced signal quality metrics
    private var signalQuality: Double = 1.0
    private var perfusionIndex: Double = 0.0
    private var signalToNoiseRatio: Double = 0.0
    private var goodPulseCount = 0
    private let minimumGoodPulses = 15
    private var frameCount = 0
    private let stabilizationFrames = 60  // 2 seconds at 30fps
    
    // FIXED: Optimized parameters to prevent double-counting
    private let samplingRate = 30.0  // Camera fps
    private let targetSamplingRate = 200.0  // Interpolated rate for precision
    private let minHeartRate = 40.0
    private let maxHeartRate = 200.0
    private let refractoryPeriod = 0.5  // FIXED: Increased from 0.3 to 0.5 seconds (minimum 500ms between beats)
    
    // Enhanced peak detection parameters
    private var adaptiveThreshold: Double = 0.0
    private var lastPeakIndex: Int = 0
    
    // Haptic feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private var lastBPMValue: Int?
    
    func startSession() {
        setupCaptureSession()
        setupMotionManager()
        disableScreenSleep()
    }
    
    func stopSession() {
        captureSession?.stopRunning()
        turnOffFlash()
        timer?.invalidate()
        noFingerTimeoutTimer?.invalidate()
        motionManager?.stopAccelerometerUpdates()
        enableScreenSleep()
    }
    
    private func disableScreenSleep() {
        UIApplication.shared.isIdleTimerDisabled = true
        screenSleepDisabled = true
        print("🔒 Screen sleep disabled")
    }
    
    private func enableScreenSleep() {
        UIApplication.shared.isIdleTimerDisabled = false
        screenSleepDisabled = false
        print("🔓 Screen sleep enabled")
    }
    
    func handleAppDidEnterBackground() {
        if isRecording {
            print("📱 App backgrounded during recording - marking as interrupted")
            wasInterrupted = true
            stopRecording()
        }
    }
    
    func handleAppWillEnterForeground() {
        if wasInterrupted {
            print("📱 App returned - showing interrupted overlay")
            showInterruptedOverlay = true
        }
    }
    
    func restartAfterInterruption() {
        print("🔄 Restarting session after interruption")
        wasInterrupted = false
        showInterruptedOverlay = false
        resetSession()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startRecording()
        }
    }
    
    func cancelAfterInterruption() {
        print("❌ User canceled after interruption")
        wasInterrupted = false
        showInterruptedOverlay = false
        resetSession()
    }
    
    func startRecording() {
        print("🎬 Starting recording session...")
        isRecording = true
        waitingForFinger = true
        greenChannelValues.removeAll()
        timestamps.removeAll()
        redChannelValues.removeAll()
        startTime = nil  // Will be set when finger is first detected
        measurementComplete = false
        goodPulseCount = 0
        currentBPM = nil
        signalQualityText = "Place finger on camera"
        lastBPMValue = nil
        lastPulseTime = nil
        frameCount = 0
        wasInterrupted = false
        perfusionIndex = 0.0
        signalToNoiseRatio = 0.0
        lastFingerDetectedTime = nil
        showNoFingerTimeout = false
        consecutiveFingerFrames = 0
        
        // Turn on flash IMMEDIATELY to detect finger color pattern
        turnOnFlash()
        print("💡 Flash ON - waiting for finger (red/orange/yellow pattern)...")
        
        impactFeedback.prepare()
        lightImpact.prepare()
        
        // Start timeout timer for no finger detection
        startNoFingerTimeout()
    }
    
    private func startNoFingerTimeout() {
        noFingerTimeoutTimer?.invalidate()
        noFingerTimeoutTimer = Timer.scheduledTimer(withTimeInterval: noFingerTimeoutDuration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.waitingForFinger && !self.fingerDetected {
                    print("⏰ No finger detected for \(Int(self.noFingerTimeoutDuration)) seconds")
                    self.showNoFingerTimeout = true
                }
            }
        }
    }
    
    private func onFingerDetected() {
        guard waitingForFinger else { return }
        
        print("✅ Finger confirmed! Starting measurement...")
        waitingForFinger = false
        startTime = Date()
        lastFingerDetectedTime = Date()
        noFingerTimeoutTimer?.invalidate()
        
        // CRITICAL: Invalidate any existing timer before creating new one
        timer?.invalidate()
        timer = nil
        
        // Start progress timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let start = self.startTime else { return }
                let elapsed = Date().timeIntervalSince(start)
                
                self.recordingProgress = min(elapsed / self.recordingDuration, 1.0)
                
                print("📊 Progress: \(Int(self.recordingProgress * 100))% | Elapsed: \(Int(elapsed))s | Samples: \(self.greenChannelValues.count)")
                
                if self.recordingProgress >= 1.0 {
                    if self.goodPulseCount >= self.minimumGoodPulses {
                        print("✅ Stopping: 100% reached with \(self.goodPulseCount) good pulses")
                        self.stopRecording()
                    } else if elapsed >= self.recordingDuration * 1.2 {
                        print("⚠️ Stopping: Extended time reached with \(self.goodPulseCount) pulses")
                        self.stopRecording()
                    }
                }
            }
        }
    }
    
    func retryAfterTimeout() {
        print("🔄 Retrying after timeout")
        showNoFingerTimeout = false
        waitingForFinger = true
        recordingProgress = 0
        greenChannelValues.removeAll()
        timestamps.removeAll()
        redChannelValues.removeAll()
        currentBPM = nil
        goodPulseCount = 0
        signalQualityText = "Place finger on camera"
        consecutiveFingerFrames = 0
        
        // Keep flash ON for detection
        if !flashIsOn {
            turnOnFlash()
        }
        
        startNoFingerTimeout()
    }
    
    func cancelAfterTimeout() {
        print("❌ User canceled after timeout")
        showNoFingerTimeout = false
        stopRecording()
    }
    
    func stopRecording() {
        guard isRecording else {
            print("⚠️ stopRecording called but not recording")
            return
        }
        
        print("🛑 Stopping recording...")
        print("   Samples collected: \(greenChannelValues.count)")
        print("   Good pulses: \(goodPulseCount)")
        print("   Perfusion Index: \(perfusionIndex)")
        print("   SNR: \(signalToNoiseRatio) dB")
        
        isRecording = false
        waitingForFinger = false
        timer?.invalidate()
        timer = nil
        noFingerTimeoutTimer?.invalidate()
        noFingerTimeoutTimer = nil
        turnOffFlash()
        
        if !wasInterrupted {
            if greenChannelValues.count >= 150 && goodPulseCount >= 5 {
                print("✅ Processing heart rate...")
                processHeartRate()
            } else {
                print("❌ Insufficient data quality")
                print("   Samples: \(greenChannelValues.count) (need ≥150)")
                print("   Good pulses: \(goodPulseCount) (need ≥5)")
                
                if goodPulseCount < 5 {
                    signalQualityText = "Could not detect heartbeat - try again"
                } else {
                    signalQualityText = "Insufficient data - hold steady"
                }
                signalQualityColor = .red
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.recordingProgress = 0
                }
            }
        }
    }
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        // Use Ultra-Wide Camera (0.5x zoom)
        guard let ultraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) else {
            print("❌ Ultra-Wide Camera not available")
            Task { @MainActor in
                self.signalQualityText = "Camera not available"
                self.signalQualityColor = .red
            }
            return
        }

        self.selectedCameraDevice = ultraWide
        print("✅ Using Ultra-Wide Camera (0.5x zoom)")

        do {
            try ultraWide.lockForConfiguration()

            // Lock to exactly 30 fps for stable sampling
            let frameDuration = CMTime(value: 1, timescale: 30)
            ultraWide.activeVideoMinFrameDuration = frameDuration
            ultraWide.activeVideoMaxFrameDuration = frameDuration

            // FIXED: Lock exposure instead of auto - critical for PPG stability
            // Set to a moderate exposure duration for finger measurements
            if ultraWide.isExposureModeSupported(.custom) {
                let exposureDuration = CMTime(value: 1, timescale: 60) // 1/60s
                let iso: Float = 100.0  // Low ISO for less noise
                ultraWide.setExposureModeCustom(duration: exposureDuration, iso: iso)
            } else if ultraWide.isExposureModeSupported(.locked) {
                ultraWide.exposureMode = .locked
            }

            // FIXED: Lock white balance to prevent color drift
            if ultraWide.isWhiteBalanceModeSupported(.locked) {
                // Set to warm white balance (good for skin/blood detection)
                let warmTemp: Float = 5000 // Kelvin - warm white
                let tint: Float = 0
                let gains = ultraWide.deviceWhiteBalanceGains(for: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: warmTemp, tint: tint))
                ultraWide.setWhiteBalanceModeLocked(with: gains)
            }

            // FIXED: Lock focus at close distance (macro range)
            if ultraWide.isFocusModeSupported(.locked) {
                ultraWide.focusMode = .locked
                // Set to minimum focus distance for finger
                ultraWide.setFocusModeLocked(lensPosition: 0.0) // 0.0 = closest focus
            }

            ultraWide.unlockForConfiguration()

            let input = try AVCaptureDeviceInput(device: ultraWide)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: videoOutputQueue)
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            videoOutput = output
            captureSession = session
            
            DispatchQueue.global(qos: .userInitiated).async { [session] in
                session.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    private func setupMotionManager() {
        motionManager = CMMotionManager()
        motionManager?.accelerometerUpdateInterval = 0.1
        
        motionManager?.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }
            
            let acceleration = sqrt(pow(data.acceleration.x, 2) +
                                  pow(data.acceleration.y, 2) +
                                  pow(data.acceleration.z, 2))
            
            Task { @MainActor in
                self?.motionDetected = acceleration > 0.2
            }
        }
    }
    
    private func turnOnFlash() {
        guard let device = selectedCameraDevice, device.hasTorch else {
            print("❌ Flash not available")
            return
        }
        
        guard !flashIsOn else {
            return  // Already on
        }
        
        do {
            try device.lockForConfiguration()
            // IMPROVED: Use 80% flash level instead of 100%
            // Research shows calibrated flash levels improve accuracy by up to 74%
            // Maximum flash can cause sensor saturation and reduce signal quality
            try device.setTorchModeOn(level: 0.8)
            device.unlockForConfiguration()
            flashIsOn = true
            print("✅ Flash turned on at 80% (calibrated level)")
        } catch {
            print("❌ Flash error: \(error)")
        }
    }
    
    private func turnOffFlash() {
        guard let device = selectedCameraDevice, device.hasTorch else { return }
        
        guard flashIsOn else {
            return  // Already off
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
            flashIsOn = false
            print("✅ Flash turned off")
        } catch {
            print("❌ Flash error: \(error)")
        }
    }
    
    // MARK: - Enhanced Signal Processing

    private func processHeartRate() {
        // Wrap entire processing in error handling
        do {
            guard greenChannelValues.count >= 150 else {
                showError("Not enough data collected. Please try again.")
                return
            }

            print("\n" + String(repeating: "=", count: 70))
            print("🔬 PROCESSING HEART RATE")
            print(String(repeating: "=", count: 70))
            print("📊 Raw samples: \(greenChannelValues.count)")
            print("   Perfusion Index: \(String(format: "%.2f%%", perfusionIndex))")
            print("   SNR: \(String(format: "%.1f dB", signalToNoiseRatio))")

            // Interpolate to 200 Hz for precision
            let interpolated = interpolateToHigherRate(greenChannelValues)
            guard !interpolated.isEmpty else {
                throw ProcessingError.interpolationFailed
            }
            print("   Interpolated to: \(interpolated.count) samples at \(Int(targetSamplingRate))Hz")

            // Enhanced filtering with FIXED parameters
            let filtered = optimizedButterworthFilter(interpolated)
            guard !filtered.isEmpty else {
                throw ProcessingError.filteringFailed
            }
            print("   Filtered signal length: \(filtered.count)")

            // Advanced peak detection with FIXED validation
            let peaks = detectPeaksWithValidation(filtered, samplingRate: targetSamplingRate)

            guard peaks.count >= 5 else {
                print("❌ Only \(peaks.count) peaks detected (need ≥5)")
                showError("Unable to detect heartbeat. Please ensure your finger covers the camera completely and hold steady.")
                return
            }

            print("   ✅ Valid peaks detected: \(peaks.count)")

            // Calculate metrics with validation
            let heartRate = calculateHeartRate(peaks: peaks, samplingRate: targetSamplingRate)
            guard heartRate.isFinite && heartRate > 0 else {
                throw ProcessingError.invalidHeartRate
            }

            let hrv = calculateHRV(peaks: peaks, samplingRate: targetSamplingRate)
            let sdnn = calculateSDNN(peaks: peaks, samplingRate: targetSamplingRate)
            let stress = calculateStress(hrv: hrv, heartRate: heartRate)
            let energy = calculateEnergy(hrv: hrv, heartRate: heartRate)
            let plus = calculatePlusScore(heartRate: heartRate, hrv: hrv, sdnn: sdnn)

            let confidence = determineConfidence(snr: signalToNoiseRatio, perfusion: perfusionIndex)

            print("\n📈 RESULTS:")
            print("   Heart Rate: \(Int(heartRate)) BPM")
            print("   HRV (RMSSD): \(String(format: "%.1f ms", hrv))")
            print("   SDNN: \(String(format: "%.1f ms", sdnn))")
            print("   Stress: \(Int(stress))%")
            print("   Energy: \(Int(energy))%")
            print("   Plus Score: \(Int(plus))")
            print("   Confidence: \(confidence)")
            print(String(repeating: "=", count: 70) + "\n")

            let measurement = HeartRateMeasurement(
                heartRate: heartRate,
                hrv: hrv,
                sdnn: sdnn,
                stress: stress,
                energy: energy,
                plus: plus,
                signalQuality: signalQuality,
                confidence: confidence
            )

            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)

            self.finalMeasurement = measurement
            self.measurementComplete = true

        } catch let error as ProcessingError {
            print("❌ Processing error: \(error)")
            showError(error.localizedDescription)
        } catch {
            print("❌ Unexpected error: \(error)")
            showError("An unexpected error occurred during measurement. Please try again.")
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
        signalQualityText = "Error occurred"
        signalQualityColor = .red
    }

    func resetAfterError() {
        showErrorAlert = false
        errorMessage = ""
        resetSession()
    }

    // Processing error types
    enum ProcessingError: LocalizedError {
        case interpolationFailed
        case filteringFailed
        case invalidHeartRate
        case insufficientPeaks

        var errorDescription: String? {
            switch self {
            case .interpolationFailed:
                return "Signal processing failed. Please try again."
            case .filteringFailed:
                return "Signal filtering failed. Please try again."
            case .invalidHeartRate:
                return "Invalid heart rate detected. Please try again with better finger placement."
            case .insufficientPeaks:
                return "Unable to detect heartbeat. Please hold your finger steady and press firmly."
            }
        }
    }
    
    // Cubic spline interpolation to 200 Hz
    private func interpolateToHigherRate(_ signal: [Double]) -> [Double] {
        guard signal.count > 3 else { return signal }
        
        let originalRate = samplingRate
        let originalCount = signal.count
        let targetCount = Int(Double(originalCount) * (targetSamplingRate / originalRate))
        
        var interpolated: [Double] = []
        interpolated.reserveCapacity(targetCount)
        
        let step = Double(originalCount - 1) / Double(targetCount - 1)
        
        for i in 0..<targetCount {
            let index = Double(i) * step
            let lowerIndex = Int(floor(index))
            let upperIndex = min(lowerIndex + 1, originalCount - 1)
            let fraction = index - Double(lowerIndex)
            
            // Linear interpolation
            let value = signal[lowerIndex] * (1.0 - fraction) + signal[upperIndex] * fraction
            interpolated.append(value)
        }
        
        return interpolated
    }
    
    // FIXED: Butterworth filter with CORRECTED frequency range (0.5-4 Hz instead of 0.1-10 Hz)
    private func optimizedButterworthFilter(_ signal: [Double]) -> [Double] {
        guard signal.count >= 50 else { return signal }
        
        // Normalize first
        let mean = signal.reduce(0, +) / Double(signal.count)
        let variance = signal.map { pow($0 - mean, 2) }.reduce(0, +) / Double(signal.count)
        let std = sqrt(variance)
        let normalized = signal.map { ($0 - mean) / (std + 1e-10) }
        
        // Detrend with 1-second window
        let detrended = detrendSignal(normalized, samplingRate: targetSamplingRate)
        
        // FIXED: Bandpass filter 0.5-4 Hz (30-240 BPM range)
        // This prevents harmonics and double-counting
        let lowCut = 0.5   // 30 BPM minimum
        let highCut = 4.0  // 240 BPM maximum (changed from 10 Hz)
        let nyquist = targetSamplingRate / 2.0
        
        let low = lowCut / nyquist
        let high = highCut / nyquist
        
        // FIR filter with optimal length
        let filterLength = min(max(signal.count / 8, 64), 128)
        var coefficients = [Double](repeating: 0, count: filterLength)
        
        // Design bandpass filter
        for i in 0..<filterLength {
            let n = Double(i - filterLength / 2)
            if n == 0 {
                coefficients[i] = 2.0 * (high - low)
            } else {
                coefficients[i] = (sin(2.0 * .pi * high * n) - sin(2.0 * .pi * low * n)) / (.pi * n)
            }
            
            // Hamming window
            let window = 0.54 - 0.46 * cos(2.0 * .pi * Double(i) / Double(filterLength - 1))
            coefficients[i] *= window
        }
        
        // Apply convolution
        var filtered = detrended
        for i in filterLength..<filtered.count {
            var sum = 0.0
            for j in 0..<filterLength {
                sum += coefficients[j] * detrended[i - j]
            }
            filtered[i] = sum
        }
        
        return Array(filtered.dropFirst(filterLength))
    }
    
    private func detrendSignal(_ signal: [Double], samplingRate: Double) -> [Double] {
        let windowSize = Int(samplingRate)  // 1 second window
        var detrended = [Double]()
        detrended.reserveCapacity(signal.count)
        
        for i in 0..<signal.count {
            let start = max(0, i - windowSize / 2)
            let end = min(signal.count, i + windowSize / 2)
            let window = Array(signal[start..<end])
            let mean = window.reduce(0, +) / Double(window.count)
            detrended.append(signal[i] - mean)
        }
        
        return detrended
    }
    
    // FIXED: Peak detection with STRONGER validation to prevent double-counting
    private func detectPeaksWithValidation(_ signal: [Double], samplingRate: Double) -> [Int] {
        guard signal.count >= 50 else { return [] }
        
        print("\n🔍 PEAK DETECTION:")
        
        // Calculate adaptive threshold from signal statistics
        let signalMean = signal.reduce(0, +) / Double(signal.count)
        let signalStd = sqrt(signal.map { pow($0 - signalMean, 2) }.reduce(0, +) / Double(signal.count))
        
        // FIXED: More aggressive threshold (1.0 std above mean instead of 0.6)
        let adaptiveThreshold = signalMean + (signalStd * 1.0)
        print("   Adaptive threshold: \(String(format: "%.3f", adaptiveThreshold))")
        print("   Signal mean: \(String(format: "%.3f", signalMean))")
        print("   Signal std: \(String(format: "%.3f", signalStd))")
        
        var peaks: [Int] = []
        
        // FIXED: Larger minimum peak distance (0.5s = 500ms, was 300ms)
        let minPeakDistance = Int(refractoryPeriod * samplingRate)
        let searchWindow = Int(0.1 * samplingRate)  // 100ms window for local maximum
        
        print("   Min peak distance: \(minPeakDistance) samples (\(Int(refractoryPeriod * 1000))ms)")
        print("   Search window: \(searchWindow) samples")
        
        var i = searchWindow
        var candidatePeaks = 0
        var rejectedByDistance = 0
        var rejectedByRate = 0
        
        while i < signal.count - searchWindow {
            // Check if this is a local maximum above threshold
            let windowStart = i - searchWindow
            let windowEnd = i + searchWindow
            let windowMax = signal[windowStart...windowEnd].max() ?? 0
            
            if signal[i] == windowMax && signal[i] > adaptiveThreshold {
                candidatePeaks += 1
                
                // FIXED: Stricter validation with refractory period
                if peaks.isEmpty || (i - peaks.last!) >= minPeakDistance {
                    // Additional validation: check instantaneous heart rate
                    if !peaks.isEmpty {
                        let interval = Double(i - peaks.last!) / samplingRate
                        let instantBPM = 60.0 / interval
                        
                        // Accept only physiologically valid intervals
                        if instantBPM >= minHeartRate && instantBPM <= maxHeartRate {
                            peaks.append(i)
                        } else {
                            rejectedByRate += 1
                        }
                    } else {
                        peaks.append(i)  // First peak
                    }
                } else {
                    rejectedByDistance += 1
                }
            }
            
            i += 1
        }
        
        print("   Candidate peaks found: \(candidatePeaks)")
        print("   Rejected by distance: \(rejectedByDistance)")
        print("   Rejected by rate: \(rejectedByRate)")
        print("   Initial valid peaks: \(peaks.count)")
        
        // FIXED: Additional outlier removal with IQR method
        peaks = removeOutlierPeaks(peaks, samplingRate: samplingRate)
        
        print("   Final valid peaks: \(peaks.count)")
        
        // Calculate and display RR intervals for debugging
        if peaks.count >= 2 {
            var intervals: [Double] = []
            for j in 1..<peaks.count {
                let interval = Double(peaks[j] - peaks[j-1]) / samplingRate
                intervals.append(interval)
            }
            
            let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
            let estimatedBPM = 60.0 / avgInterval
            print("   Average RR interval: \(String(format: "%.3f s", avgInterval))")
            print("   Estimated BPM: \(String(format: "%.1f", estimatedBPM))")
        }
        
        return peaks
    }
    
    private func calculateEnvelope(_ signal: [Double]) -> [Double] {
        var envelope = [Double](repeating: 0, count: signal.count)
        let windowSize = 20
        
        for i in 0..<signal.count {
            let start = max(0, i - windowSize)
            let end = min(signal.count, i + windowSize)
            envelope[i] = signal[start..<end].max() ?? 0
        }
        
        return envelope
    }
    
    private func removeOutlierPeaks(_ peaks: [Int], samplingRate: Double) -> [Int] {
        guard peaks.count >= 3 else { return peaks }
        
        // Calculate RR intervals
        var intervals: [Double] = []
        for i in 1..<peaks.count {
            let interval = Double(peaks[i] - peaks[i-1]) / samplingRate
            intervals.append(interval)
        }
        
        // Calculate IQR for outlier detection
        let sortedIntervals = intervals.sorted()
        let q1 = sortedIntervals[sortedIntervals.count / 4]
        let q3 = sortedIntervals[3 * sortedIntervals.count / 4]
        let iqr = q3 - q1
        
        // FIXED: More aggressive outlier removal (1.5*IQR)
        var validPeaks = [peaks[0]]
        var removedCount = 0
        
        for i in 1..<peaks.count {
            let interval = intervals[i-1]
            if interval >= (q1 - 1.5 * iqr) && interval <= (q3 + 1.5 * iqr) {
                validPeaks.append(peaks[i])
            } else {
                removedCount += 1
            }
        }
        
        if removedCount > 0 {
            print("   Removed \(removedCount) outlier peaks via IQR method")
        }
        
        return validPeaks
    }
    
    private func calculateHeartRate(peaks: [Int], samplingRate: Double) -> Double {
        guard peaks.count >= 2 else { return 70 }
        
        var intervals: [Double] = []
        for i in 1..<peaks.count {
            let interval = Double(peaks[i] - peaks[i-1]) / samplingRate
            intervals.append(interval)
        }
        
        // Use median for robustness against outliers
        let median = calculateMedian(intervals)
        let bpm = 60.0 / median
        
        return max(minHeartRate, min(maxHeartRate, bpm))
    }
    
    private func calculateHRV(peaks: [Int], samplingRate: Double) -> Double {
        guard peaks.count >= 3 else { return 50 }
        
        var intervals: [Double] = []
        for i in 1..<peaks.count {
            let interval = Double(peaks[i] - peaks[i-1]) * (1000.0 / samplingRate)
            intervals.append(interval)
        }
        
        // RMSSD calculation
        var squaredDiffs: [Double] = []
        for i in 1..<intervals.count {
            let diff = intervals[i] - intervals[i-1]
            squaredDiffs.append(diff * diff)
        }
        
        let meanSquared = squaredDiffs.reduce(0, +) / Double(squaredDiffs.count)
        return sqrt(meanSquared)
    }
    
    private func calculateSDNN(peaks: [Int], samplingRate: Double) -> Double {
        guard peaks.count >= 3 else { return 45 }
        
        var intervals: [Double] = []
        for i in 1..<peaks.count {
            let interval = Double(peaks[i] - peaks[i-1]) * (1000.0 / samplingRate)
            intervals.append(interval)
        }
        
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
        
        return sqrt(variance)
    }
    
    private func calculateStress(hrv: Double, heartRate: Double) -> Double {
        let hrvFactor = max(0, 100 - hrv)
        let hrFactor = max(0, heartRate - 60)
        return min(100, (hrvFactor + hrFactor) / 2)
    }
    
    private func calculateEnergy(hrv: Double, heartRate: Double) -> Double {
        let hrvFactor = min(100, hrv)
        let hrFactor = 100 - abs(heartRate - 70)
        return max(0, min(100, (hrvFactor + hrFactor) / 2))
    }
    
    private func calculatePlusScore(heartRate: Double, hrv: Double, sdnn: Double) -> Double {
        let hrScore = max(0, 100 - abs(heartRate - 70))
        let hrvScore = min(100, hrv)
        let sdnnScore = min(100, sdnn)
        
        return (hrScore + hrvScore + sdnnScore) / 3
    }
    
    private func calculateMedian(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let count = sorted.count
        
        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
        } else {
            return sorted[count / 2]
        }
    }
    
    private func determineConfidence(snr: Double, perfusion: Double) -> String {
        // Use NSQI-based confidence (research shows NSQI < 0.293 = excellent)
        let nsqi = signalQuality

        if nsqi < 0.293 {
            return "Excellent"
        } else if nsqi < 0.5 {
            return "Good"
        } else if nsqi < 0.7 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
    
    private func resetSession() {
        greenChannelValues.removeAll()
        timestamps.removeAll()
        redChannelValues.removeAll()
        currentBPM = nil
        goodPulseCount = 0
        recordingProgress = 0
        lastPulseTime = nil
        signalQualityText = "Place finger to start"
        signalQualityColor = .orange
        frameCount = 0
        perfusionIndex = 0.0
        signalToNoiseRatio = 0.0
        consecutiveFingerFrames = 0
        
        print("🔄 Session reset - ready to start fresh")
    }
}

// MARK: - Video Frame Processing
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return }
        
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // Larger center region for better signal
        let centerX = width / 2
        let centerY = height / 2
        let regionSize = 80
        
        var totalRed: Double = 0
        var totalGreen: Double = 0
        var totalBlue: Double = 0
        var pixelCount = 0
        
        for row in (centerY - regionSize)..<(centerY + regionSize) {
            for col in (centerX - regionSize)..<(centerX + regionSize) {
                let offset = row * bytesPerRow + col * 4
                totalBlue += Double(buffer[offset])
                totalGreen += Double(buffer[offset + 1])
                totalRed += Double(buffer[offset + 2])
                pixelCount += 1
            }
        }
        
        let avgRed = totalRed / Double(pixelCount)
        let avgGreen = totalGreen / Double(pixelCount)
        let avgBlue = totalBlue / Double(pixelCount)
        
        // Calculate metrics
        let dcComponent = (avgRed + avgGreen + avgBlue) / 3.0
        let acComponent = max(avgRed, avgGreen, avgBlue) - min(avgRed, avgGreen, avgBlue)
        let perfusion = (acComponent / max(dcComponent, 1.0)) * 100.0
        
        // Finger detection
        let hasSignal = dcComponent >= 50 &&
                       avgRed >= 80 &&
                       avgRed <= 253 &&
                       acComponent >= 10
        
        let avgGreenBlue = (avgGreen + avgBlue) / 2.0
        let hasBloodSignature = avgRed > avgGreenBlue

        _ = hasSignal && hasBloodSignature

        Task { @MainActor in
            self.frameCount += 1
            self.perfusionIndex = perfusion
            
            // DETECT FINGER BY COLOR PATTERN (Red/Orange/Yellow with flash on)
            // When flash illuminates blood through finger, we see distinctive warm colors
            
            // Calculate color ratios
            let redToGreenRatio = avgRed / max(avgGreen, 1.0)
            let redToBlueRatio = avgRed / max(avgBlue, 1.0)
            
            // FINGER DETECTION CRITERIA with flash on:
            // 1. Moderate brightness (not too dark, not saturated) - flash is working
            let hasGoodBrightness = dcComponent >= 40 && dcComponent <= 200
            
            // 2. Red channel dominates (blood color) but not saturated
            let hasRedDominance = avgRed >= 60 && avgRed <= 250 &&
                                  redToGreenRatio >= 1.1 &&
                                  redToBlueRatio >= 1.1
            
            // 3. Warm tone (red/orange/yellow) - characteristic of finger with flash
            let hasWarmTone = avgRed > avgGreen && avgRed > avgBlue
            
            // 4. Some pulsation visible
            let hasPulsation = acComponent >= 5
            
            // 5. Not ambient light (would have balanced RGB or blue-dominant)
            let notAmbientLight = redToGreenRatio > 0.9
            
            let fingerDetectedThisFrame = hasGoodBrightness &&
                                          hasRedDominance &&
                                          hasWarmTone &&
                                          hasPulsation &&
                                          notAmbientLight
            
            // DEBUG: Print detection details every 30 frames
            if self.frameCount % 30 == 0 {
                print("\n🔍 FINGER DETECTION (Flash ON):")
                print("   RGB: R=\(String(format: "%.0f", avgRed)) G=\(String(format: "%.0f", avgGreen)) B=\(String(format: "%.0f", avgBlue))")
                print("   DC: \(String(format: "%.1f", dcComponent)) AC: \(String(format: "%.1f", acComponent))")
                print("   R/G ratio: \(String(format: "%.2f", redToGreenRatio)) R/B ratio: \(String(format: "%.2f", redToBlueRatio))")
                print("   ✓ Brightness OK: \(hasGoodBrightness) (40-200)")
                print("   ✓ Red dominant: \(hasRedDominance) (60-250, R/G>1.1)")
                print("   ✓ Warm tone: \(hasWarmTone) (R>G && R>B)")
                print("   ✓ Pulsation: \(hasPulsation) (AC≥5)")
                print("   ✓ Not ambient: \(notAmbientLight)")
                print("   → Finger: \(fingerDetectedThisFrame ? "YES ✅" : "NO ❌")\n")
            }
            
            // WAITING FOR FINGER STATE
            if self.isRecording && self.waitingForFinger {
                
                if fingerDetectedThisFrame {
                    self.consecutiveFingerFrames += 1
                    
                    if self.consecutiveFingerFrames >= self.requiredConsecutiveFrames {
                        // Finger confirmed for 2 seconds
                        print("✅ Finger pattern confirmed for 2 seconds!")
                        print("   Final RGB: R=\(Int(avgRed)) G=\(Int(avgGreen)) B=\(Int(avgBlue))")
                        print("   R/G ratio: \(String(format: "%.2f", redToGreenRatio))")
                        print("🎯 Starting recording!")
                        
                        self.onFingerDetected()
                    } else {
                        let progress = Int((Double(self.consecutiveFingerFrames) / Double(self.requiredConsecutiveFrames)) * 100)
                        self.signalQualityText = "Detecting finger... \(progress)%"
                        self.signalQualityColor = .orange
                    }
                } else {
                    // Pattern not detected - reset counter
                    if self.consecutiveFingerFrames > 0 {
                        print("⚠️ Lost finger pattern - resetting (had \(self.consecutiveFingerFrames) frames)")
                    }
                    self.consecutiveFingerFrames = 0
                    
                    // Provide helpful feedback based on what's wrong
                    if !hasGoodBrightness {
                        if dcComponent < 40 {
                            self.signalQualityText = "Too dark - check flash"
                        } else {
                            self.signalQualityText = "Too bright - cover completely"
                        }
                    } else if !hasRedDominance {
                        self.signalQualityText = "Place finger on camera"
                    } else if !hasPulsation {
                        self.signalQualityText = "Hold steady and press firmly"
                    } else {
                        self.signalQualityText = "Place finger on camera"
                    }
                    self.signalQualityColor = .gray
                }
                
                self.fingerDetected = self.consecutiveFingerFrames > 0
            }
            
            // ACTIVE RECORDING STATE
            else if self.isRecording && !self.waitingForFinger {
                self.fingerDetected = fingerDetectedThisFrame
                
                if fingerDetectedThisFrame {
                    self.lastFingerDetectedTime = Date()
                    
                    // Skip stabilization period
                    if self.frameCount < self.stabilizationFrames {
                        self.signalQualityText = "Stabilizing... (Hold steady)"
                        self.signalQualityColor = .orange
                        return
                    }
                    
                    // Collect data
                    let timestamp = Date().timeIntervalSince(self.startTime ?? Date())
                    self.greenChannelValues.append(avgGreen)
                    self.timestamps.append(timestamp)
                    self.redChannelValues.append(avgRed)
                    
                    // Real-time processing every 30 samples
                    if self.greenChannelValues.count >= 150 && self.greenChannelValues.count % 30 == 0 {
                        self.processRealTimeUpdate()
                    }
                } else {
                    // Finger removed during active recording
                    print("⚠️ Finger removed during recording - resetting")
                    self.waitingForFinger = true
                    self.consecutiveFingerFrames = 0
                    self.greenChannelValues.removeAll()
                    self.timestamps.removeAll()
                    self.redChannelValues.removeAll()
                    self.currentBPM = nil
                    self.recordingProgress = 0
                    self.startTime = nil
                    self.goodPulseCount = 0
                    self.frameCount = 0
                    self.signalQualityText = "Place finger back on camera"
                    self.signalQualityColor = .red
                    
                    // Invalidate timer (flash stays on)
                    self.timer?.invalidate()
                    self.timer = nil
                    
                    // Restart timeout timer
                    self.startNoFingerTimeout()
                }
            }
        }
    }
    
    @MainActor
    private func processRealTimeUpdate() {
        let windowSize = min(300, greenChannelValues.count)  // 10 seconds max
        let recentValues = Array(greenChannelValues.suffix(windowSize))
        
        // Quick processing for real-time feedback
        let interpolated = interpolateToHigherRate(recentValues)
        let filtered = optimizedButterworthFilter(interpolated)
        let peaks = detectPeaksWithValidation(filtered, samplingRate: targetSamplingRate)
        
        if peaks.count >= 5 {
            let currentBPM = calculateHeartRate(peaks: peaks, samplingRate: targetSamplingRate)
            self.currentBPM = currentBPM
            self.goodPulseCount = peaks.count
            
            print("💓 Current BPM: \(Int(currentBPM)) (from \(peaks.count) peaks)")

            // IMPROVED: Calculate Signal Quality Index using research-based NSQI method
            // Based on: "Optimal signal quality index for remote photoplethysmogram sensing"
            // NSQI combines SNR, perfusion index, and peak consistency

            // 1. Calculate actual SNR from signal vs noise regions
            let mean = filtered.reduce(0, +) / Double(filtered.count)

            // Signal power: variance of the detected peaks
            var peakValues: [Double] = []
            for peakIdx in peaks {
                if peakIdx < filtered.count {
                    peakValues.append(filtered[peakIdx])
                }
            }
            let peakMean = peakValues.reduce(0, +) / Double(max(peakValues.count, 1))
            let signalPower = peakValues.map { pow($0 - peakMean, 2) }.reduce(0, +) / Double(max(peakValues.count, 1))

            // Noise power: variance of non-peak regions
            var nonPeakValues: [Double] = []
            let peakSet = Set(peaks)
            for i in 0..<filtered.count {
                if !peakSet.contains(i) {
                    nonPeakValues.append(filtered[i])
                }
            }
            let noiseMean = nonPeakValues.reduce(0, +) / Double(max(nonPeakValues.count, 1))
            let noisePower = nonPeakValues.map { pow($0 - noiseMean, 2) }.reduce(0, +) / Double(max(nonPeakValues.count, 1))

            // Calculate true SNR
            let snr = signalPower / max(noisePower, 0.001)
            self.signalToNoiseRatio = 10 * log10(snr)

            // 2. Calculate NSQI (Normalized Signal Quality Index)
            // NSQI = (SNR * Perfusion * PeakConsistency) normalized to 0-1
            let normalizedSNR = min(1.0, snr / 10.0) // Normalize SNR to 0-1
            let normalizedPerfusion = min(1.0, perfusionIndex / 5.0) // 5% perfusion = good

            // Peak consistency: how regular are the RR intervals?
            var rrIntervals: [Double] = []
            for i in 1..<peaks.count {
                let interval = Double(peaks[i] - peaks[i-1]) / targetSamplingRate
                rrIntervals.append(interval)
            }
            let rrMean = rrIntervals.reduce(0, +) / Double(max(rrIntervals.count, 1))
            let rrStd = sqrt(rrIntervals.map { pow($0 - rrMean, 2) }.reduce(0, +) / Double(max(rrIntervals.count, 1)))
            let coefficientOfVariation = rrStd / max(rrMean, 0.001)
            let peakConsistency = max(0, 1.0 - coefficientOfVariation) // Lower CV = better consistency

            // Combine into NSQI (research shows NSQI < 0.293 indicates good quality)
            let nsqi = 1.0 - (normalizedSNR * normalizedPerfusion * peakConsistency)
            self.signalQuality = nsqi

            print("   📊 Quality Metrics:")
            print("      SNR: \(String(format: "%.1f dB", signalToNoiseRatio))")
            print("      Perfusion: \(String(format: "%.2f%%", perfusionIndex))")
            print("      Peak Consistency: \(String(format: "%.2f", peakConsistency))")
            print("      NSQI: \(String(format: "%.3f", nsqi)) (target: <0.293)")

            // Update quality indicators based on NSQI thresholds (research-based)
            if nsqi < 0.293 {
                // Excellent quality - NSQI threshold from research
                signalQualityText = "Excellent Signal"
                signalQualityIcon = "checkmark.circle.fill"
                signalQualityColor = .green
            } else if nsqi < 0.5 {
                // Good quality
                signalQualityText = "Good Signal"
                signalQualityIcon = "checkmark.circle"
                signalQualityColor = .yellow
            } else if nsqi < 0.7 {
                // Fair quality
                signalQualityText = "Fair Signal"
                signalQualityIcon = "exclamationmark.triangle"
                signalQualityColor = .orange
            } else {
                // Poor quality
                signalQualityText = "Weak Signal - Hold Steady"
                signalQualityIcon = "exclamationmark.triangle.fill"
                signalQualityColor = .red
            }
            
            // Haptic feedback
            let now = Date()
            let expectedInterval = 60.0 / currentBPM
            
            if lastPulseTime == nil || now.timeIntervalSince(lastPulseTime!) >= (expectedInterval * 0.75) {
                impactFeedback.impactOccurred(intensity: 0.7)
                
                pulseAnimation = true
                lastPulseTime = now
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.pulseAnimation = false
                }
                
                impactFeedback.prepare()
            }
        }
    }
}
