//
//  RecordingStore.swift
//  BowlerTrax
//
//  State management for recording sessions. Bridges the CV pipeline
//  with SwiftUI views, providing observable state for real-time metrics.
//

import SwiftUI
import Combine
import AVFoundation

// MARK: - Camera Frame Handler

/// Wrapper class to handle camera frames and forward to RecordingStore
/// This is needed because RecordingStore is @MainActor but frame callbacks are on processing queue
final class CameraFrameHandler: CameraFrameDelegate {
    private weak var store: RecordingStore?
    // Use weak reference to avoid retain cycle: RecordingStore -> CameraFrameHandler -> FrameProcessor
    // RecordingStore already owns the FrameProcessor strongly via its frameProcessor property
    private weak var frameProcessor: FrameProcessor?

    init() {}

    func configure(store: RecordingStore, frameProcessor: FrameProcessor) {
        self.store = store
        self.frameProcessor = frameProcessor
    }

    nonisolated func didCaptureFrame(_ pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        frameProcessor?.processFrame(pixelBuffer, timestamp: timestamp)
    }

    nonisolated func didDropFrame(at timestamp: CMTime) {
        // Optional: track dropped frames
    }
}

// MARK: - Recording Store

/// Observable store managing recording session state and CV pipeline
@MainActor
final class RecordingStore: ObservableObject {
    // MARK: - Published State

    /// Whether CV processing is active
    @Published private(set) var isProcessing: Bool = false

    /// Current tracking state
    @Published private(set) var trackingState: TrackingState = .idle

    /// Number of shots recorded this session
    @Published private(set) var shotCount: Int = 0

    /// Session start time
    @Published private(set) var sessionStartTime: Date = Date()

    /// Current shot start time (for duration display)
    @Published private(set) var currentShotStartTime: Date?

    // MARK: - Real-Time Metrics

    /// Ball position in pixels
    @Published private(set) var ballPosition: CGPoint?

    /// Ball position on boards (1-39)
    @Published private(set) var boardNumber: Double?

    /// Distance from foul line in feet
    @Published private(set) var distanceFeet: Double?

    /// Current speed estimate (mph)
    @Published private(set) var currentSpeed: Double?

    /// Current entry angle estimate (degrees)
    @Published private(set) var currentEntryAngle: Double?

    /// Current rev rate estimate (rpm)
    @Published private(set) var currentRevRate: Double?

    /// Current strike probability (0-1)
    @Published private(set) var strikeProbability: Double?

    /// Current ball phase
    @Published private(set) var ballPhase: BallPhase?

    /// Arrow board position (at 15 feet)
    @Published private(set) var arrowBoard: Double?

    /// Breakpoint position and distance
    @Published private(set) var breakpoint: (board: Double, distance: Double)?

    // MARK: - Last Shot Data

    /// Last completed shot analysis
    @Published private(set) var lastShotAnalysis: ShotAnalysis?

    /// Last shot result
    @Published private(set) var lastShotResult: ShotResult?

    /// Last shot speed
    @Published private(set) var lastShotSpeed: Double?

    /// Last shot angle
    @Published private(set) var lastShotAngle: Double?

    // MARK: - Performance

    /// Current processing FPS
    @Published private(set) var processingFPS: Double = 0

    /// Whether meeting frame budget
    @Published private(set) var meetingFrameBudget: Bool = true

    // MARK: - Components

    /// Frame processor for CV pipeline
    private var frameProcessor: FrameProcessor?

    /// Camera frame handler
    private let frameHandler = CameraFrameHandler()

    /// Camera manager reference
    private weak var cameraManager: CameraSessionManager?

    /// Calibration profile
    private var calibration: CalibrationProfile?

    /// Hand preference
    private var handPreference: HandPreference = .right

    /// Target ball color
    private var ballColor: HSVColor = HSVColor(h: 220, s: 80, v: 80)

    /// Cancellables
    private var cancellables = Set<AnyCancellable>()

    /// Shots recorded this session
    private(set) var recordedShots: [ShotAnalysis] = []

    // MARK: - Initialization

    init() {}

    // MARK: - Configuration

    /// Configure the recording store with required dependencies
    func configure(
        cameraManager: CameraSessionManager,
        calibration: CalibrationProfile? = nil,
        ballColor: HSVColor = HSVColor(h: 220, s: 80, v: 80),
        handPreference: HandPreference = .right
    ) {
        self.cameraManager = cameraManager
        self.calibration = calibration
        self.ballColor = ballColor
        self.handPreference = handPreference

        // Create frame processor
        let processor = FrameProcessor(
            targetColor: ballColor,
            tolerance: .default
        )
        processor.setCalibration(calibration)
        processor.setHandPreference(handPreference)
        self.frameProcessor = processor

        // Configure frame handler
        frameHandler.configure(store: self, frameProcessor: processor)

        // Set camera delegate to our frame handler
        cameraManager.frameDelegate = frameHandler

        // Subscribe to frame processor publishers
        setupSubscriptions()
    }

    /// Update ball color for detection
    func updateBallColor(_ color: HSVColor) {
        ballColor = color
        frameProcessor?.updateBallColor(color)
    }

    /// Update calibration
    func updateCalibration(_ calibration: CalibrationProfile?) {
        self.calibration = calibration
        frameProcessor?.setCalibration(calibration)
    }

    /// Update hand preference
    func updateHandPreference(_ hand: HandPreference) {
        handPreference = hand
        frameProcessor?.setHandPreference(hand)
    }

    // MARK: - Session Control

    /// Start recording session
    func startSession() {
        sessionStartTime = Date()
        shotCount = 0
        recordedShots.removeAll()

        clearCurrentMetrics()
        clearLastShotData()

        frameProcessor?.startProcessing()
        isProcessing = true
    }

    /// Stop recording session
    func stopSession() {
        frameProcessor?.stopProcessing()
        isProcessing = false
        trackingState = .idle
    }

    /// Pause recording
    func pauseSession() {
        frameProcessor?.stopProcessing()
        isProcessing = false
    }

    /// Resume recording
    func resumeSession() {
        frameProcessor?.startProcessing()
        isProcessing = true
    }

    /// Reset for next shot
    func resetForNextShot() {
        clearCurrentMetrics()
        frameProcessor?.resetForNewShot()
    }

    // MARK: - Private Methods

    /// Setup Combine subscriptions
    private func setupSubscriptions() {
        guard let processor = frameProcessor else { return }

        processor.metricsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.updateFromMetrics(metrics)
            }
            .store(in: &cancellables)

        processor.shotCompletedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] analysis in
                self?.handleShotCompleted(analysis)
            }
            .store(in: &cancellables)

        processor.trackingStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.trackingState = state
            }
            .store(in: &cancellables)
    }

    /// Update from real-time metrics
    private func updateFromMetrics(_ metrics: RealTimeMetrics) {
        ballPosition = metrics.position
        boardNumber = metrics.boardNumber
        distanceFeet = metrics.distanceFeet
        currentSpeed = metrics.speedMPH
        currentEntryAngle = metrics.entryAngleDegrees
        currentRevRate = metrics.revRatePM
        strikeProbability = metrics.strikeProbability
        ballPhase = metrics.ballPhase

        // Update performance metrics
        if let processor = frameProcessor {
            processingFPS = processor.currentFPS
            meetingFrameBudget = processor.isMeetingFrameBudget
        }
    }

    /// Handle shot completion
    private func handleShotCompleted(_ analysis: ShotAnalysis) {
        shotCount += 1
        recordedShots.append(analysis)
        lastShotAnalysis = analysis

        // Update last shot display data
        lastShotSpeed = analysis.impactSpeed ?? analysis.launchSpeed
        lastShotAngle = analysis.entryAngle?.angleDegrees

        // Determine shot result from probability
        if let prob = analysis.strikeProbability {
            if prob.probability > 0.8 {
                lastShotResult = .strike
            } else if prob.predictedLeave == .strike {
                lastShotResult = .strike
            } else if prob.predictedLeave == .split {
                lastShotResult = .split
            } else {
                lastShotResult = .spare
            }
        }

        // Update arrow board and breakpoint from analysis
        arrowBoard = analysis.arrowBoard
        breakpoint = analysis.breakpoint

        // Clear current metrics for next shot
        clearCurrentMetrics()

        // Auto-reset for next shot using Task with proper actor isolation
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await MainActor.run {
                self?.frameProcessor?.resetForNewShot()
            }
        }
    }

    /// Clear current metrics
    private func clearCurrentMetrics() {
        ballPosition = nil
        boardNumber = nil
        distanceFeet = nil
        currentSpeed = nil
        currentEntryAngle = nil
        currentRevRate = nil
        strikeProbability = nil
        ballPhase = nil
    }

    /// Clear last shot data
    private func clearLastShotData() {
        lastShotAnalysis = nil
        lastShotResult = nil
        lastShotSpeed = nil
        lastShotAngle = nil
        arrowBoard = nil
        breakpoint = nil
    }

    // MARK: - Shot Conversion

    /// Convert all recorded shots to Shot models
    func createShots(for sessionId: UUID) -> [Shot] {
        recordedShots.enumerated().map { index, analysis in
            analysis.toShot(sessionId: sessionId, shotNumber: index + 1)
        }
    }
}

// MARK: - Tracking State Extensions

extension TrackingState {
    /// Display string for UI
    var displayString: String {
        switch self {
        case .idle:
            return "Ready"
        case .searching:
            return "Looking for ball..."
        case .tracking:
            return "Tracking"
        case .occluded(let frames):
            return "Lost (\(frames) frames)"
        case .shotComplete:
            return "Shot Complete"
        case .lost:
            return "Lost"
        }
    }

    /// Color for UI indicator
    var indicatorColor: Color {
        switch self {
        case .idle:
            return .btTextMuted
        case .searching:
            return .orange
        case .tracking:
            return .green
        case .occluded:
            return .orange
        case .shotComplete:
            return .btPrimary
        case .lost:
            return .red
        }
    }
}
