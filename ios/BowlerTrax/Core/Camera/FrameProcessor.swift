//
//  FrameProcessor.swift
//  BowlerTrax
//
//  Orchestrates the complete CV pipeline: ball detection, trajectory tracking,
//  and physics calculations. Processes camera frames and publishes results.
//

@preconcurrency import AVFoundation
@preconcurrency import CoreVideo
import Combine
import UIKit

// MARK: - Processing Result

/// Complete result from processing a frame
struct FrameProcessingResult: Sendable {
    /// Frame number
    let frameNumber: Int

    /// Frame timestamp
    let timestamp: TimeInterval

    /// Ball detection result
    let detection: BallDetectionResult

    /// Current tracking state
    let trackingState: TrackingState

    /// Real-time metrics (updated continuously)
    let metrics: RealTimeMetrics

    /// Whether this frame was processed successfully
    let processed: Bool

    /// Processing time in milliseconds
    let processingTimeMs: Double
}

/// Real-time metrics updated during recording
struct RealTimeMetrics: Sendable {
    /// Ball position in pixels
    var position: CGPoint?

    /// Ball position on boards (1-39)
    var boardNumber: Double?

    /// Distance from foul line in feet
    var distanceFeet: Double?

    /// Current speed estimate (mph)
    var speedMPH: Double?

    /// Current entry angle estimate (degrees)
    var entryAngleDegrees: Double?

    /// Current rev rate estimate (rpm)
    var revRatePM: Double?

    /// Current strike probability (0-1)
    var strikeProbability: Double?

    /// Ball phase (skid/hook/roll)
    var ballPhase: BallPhase?

    static let empty = RealTimeMetrics()
}

/// Complete shot analysis after shot completion
struct ShotAnalysis: Sendable {
    /// Unique shot ID
    let id: UUID

    /// Full trajectory
    let trajectory: [TrajectoryPoint]

    /// Speed calculations
    let launchSpeed: Double?
    let impactSpeed: Double?

    /// Entry angle result
    let entryAngle: EntryAngleResult?

    /// Rev rate result
    let revRate: RevRateResult?

    /// Strike probability
    let strikeProbability: StrikeProbabilityResult?

    /// Position at arrows (15ft)
    let arrowBoard: Double?

    /// Breakpoint position and distance
    let breakpoint: (board: Double, distance: Double)?

    /// Pocket position
    let pocketBoard: Double?

    /// Shot duration
    let duration: TimeInterval

    /// Total frames processed
    let frameCount: Int
}

// MARK: - Frame Processor Delegate

protocol FrameProcessorDelegate: AnyObject {
    /// Called after each frame is processed
    func frameProcessor(_ processor: FrameProcessor, didProcessFrame result: FrameProcessingResult)

    /// Called when a shot is completed
    func frameProcessor(_ processor: FrameProcessor, didCompleteShot analysis: ShotAnalysis)

    /// Called when tracking state changes
    func frameProcessor(_ processor: FrameProcessor, trackingStateDidChange state: TrackingState)

    /// Called when an error occurs
    func frameProcessor(_ processor: FrameProcessor, didEncounterError error: Error)
}

// MARK: - Frame Processor

/// Main class orchestrating the CV pipeline
final class FrameProcessor: @unchecked Sendable {
    // MARK: - Properties

    /// Delegate for callbacks
    weak var delegate: FrameProcessorDelegate?

    /// Current processing state
    private(set) var isProcessing: Bool = false

    /// Current tracking state
    private(set) var trackingState: TrackingState = .idle

    /// Ball detector
    private let ballDetector: BallDetector

    /// Trajectory tracker
    private let trajectoryTracker: TrajectoryTracker

    /// Rev rate calculator
    private let revRateCalculator: RevRateCalculator

    /// Speed calculator
    private let speedCalculator = SpeedCalculator()

    /// Angle calculator
    private let angleCalculator = AngleCalculator()

    /// Strike probability calculator
    private let strikeCalculator = StrikeProbabilityCalculator()

    /// Calibration profile
    private var calibration: CalibrationProfile?

    /// Hand preference for calculations
    private var handPreference: HandPreference = .right

    /// Current target ball color (stored for marker tracking configuration)
    private var currentTargetColor: HSVColor

    /// Current color tolerance
    private var currentTolerance: ColorTolerance

    /// Processing queue
    private let processingQueue = DispatchQueue(
        label: "com.bowlertrax.frameprocessor",
        qos: .userInteractive
    )

    /// Publishers
    let metricsPublisher = PassthroughSubject<RealTimeMetrics, Never>()
    let shotCompletedPublisher = PassthroughSubject<ShotAnalysis, Never>()
    let trackingStatePublisher = PassthroughSubject<TrackingState, Never>()

    /// Performance tracking
    private var frameCount: Int = 0
    private var startTime: TimeInterval = 0
    private var lastProcessingTime: TimeInterval = 0

    // Real-time metrics buffer
    private var currentMetrics = RealTimeMetrics.empty
    private var recentSpeeds: [Double] = []
    private var recentAngles: [Double] = []

    // MARK: - Initialization

    init(
        targetColor: HSVColor = HSVColor(h: 220, s: 80, v: 80),
        tolerance: ColorTolerance = .default
    ) {
        self.currentTargetColor = targetColor
        self.currentTolerance = tolerance

        let config = BallDetectorConfiguration(
            targetColor: targetColor,
            tolerance: tolerance,
            minimumConfidence: 0.4,
            detectMarker: false,
            markerColor: nil
        )
        self.ballDetector = BallDetector(configuration: config)
        self.trajectoryTracker = TrajectoryTracker()
        self.revRateCalculator = RevRateCalculator()

        setupTrajectoryTrackerDelegate()
    }

    // MARK: - Configuration

    /// Set calibration for real-world coordinate conversion
    func setCalibration(_ calibration: CalibrationProfile?) {
        self.calibration = calibration
        trajectoryTracker.setCalibration(calibration)
    }

    /// Update target ball color
    func updateBallColor(_ color: HSVColor, tolerance: ColorTolerance = .default) {
        currentTargetColor = color
        currentTolerance = tolerance
        ballDetector.updateTargetColor(color)
        ballDetector.updateTolerance(tolerance)
    }

    /// Set hand preference for calculations
    func setHandPreference(_ hand: HandPreference) {
        self.handPreference = hand
    }

    /// Enable marker tracking for rev rate
    func enableMarkerTracking(markerColor: HSVColor) {
        let config = BallDetectorConfiguration(
            targetColor: currentTargetColor,
            tolerance: currentTolerance,
            minimumConfidence: 0.4,
            detectMarker: true,
            markerColor: markerColor
        )
        ballDetector.updateConfiguration(config)
    }

    // MARK: - Processing Control

    /// Start processing frames
    func startProcessing() {
        isProcessing = true
        frameCount = 0
        startTime = CACurrentMediaTime()
        currentMetrics = .empty
        recentSpeeds.removeAll()
        recentAngles.removeAll()

        ballDetector.reset()
        trajectoryTracker.reset()
        revRateCalculator.reset()

        trajectoryTracker.startSearching()
        updateTrackingState(.searching)
    }

    /// Stop processing frames
    func stopProcessing() {
        isProcessing = false

        // If we were tracking, complete the shot
        if trackingState.isActive {
            completeCurrentShot()
        }

        updateTrackingState(.idle)
    }

    /// Reset for new shot (while continuing to process)
    func resetForNewShot() {
        ballDetector.reset()
        trajectoryTracker.reset()
        revRateCalculator.reset()
        currentMetrics = .empty
        recentSpeeds.removeAll()
        recentAngles.removeAll()

        trajectoryTracker.startSearching()
        updateTrackingState(.searching)
    }

    // MARK: - Frame Processing

    /// Process a camera frame
    /// - Parameters:
    ///   - pixelBuffer: Frame data
    ///   - timestamp: Frame timestamp
    func processFrame(_ pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        guard isProcessing else { return }

        let timestampSeconds = CMTimeGetSeconds(timestamp)
        let processStart = CACurrentMediaTime()

        processingQueue.async { [weak self] in
            guard let self = self else { return }

            self.frameCount += 1

            // Step 1: Detect ball
            let detection = self.ballDetector.detectBallSync(
                in: pixelBuffer,
                timestamp: timestampSeconds
            )

            // Step 2: Update trajectory tracker
            self.trajectoryTracker.processDetection(detection)

            // Step 3: Update real-time metrics
            self.updateRealTimeMetrics(detection: detection)

            // Step 4: Process marker for rev rate (if detected)
            if let markerAngle = detection.markerAngle,
               let position = detection.pixelPosition {
                self.revRateCalculator.processMarkerAngle(
                    markerAngle,
                    timestamp: timestampSeconds,
                    ballPosition: position
                )
            }

            // Calculate processing time
            self.lastProcessingTime = CACurrentMediaTime() - processStart

            // Create result
            let result = FrameProcessingResult(
                frameNumber: self.frameCount,
                timestamp: timestampSeconds,
                detection: detection,
                trackingState: self.trackingState,
                metrics: self.currentMetrics,
                processed: true,
                processingTimeMs: self.lastProcessingTime * 1000
            )

            // Notify delegate on main thread
            DispatchQueue.main.async {
                self.delegate?.frameProcessor(self, didProcessFrame: result)
                self.metricsPublisher.send(self.currentMetrics)
            }
        }
    }

    // MARK: - Private Methods

    /// Setup trajectory tracker delegate
    private func setupTrajectoryTrackerDelegate() {
        trajectoryTracker.delegate = self
    }

    /// Update tracking state
    private func updateTrackingState(_ state: TrackingState) {
        guard trackingState != state else { return }

        trackingState = state

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.frameProcessor(self, trackingStateDidChange: state)
            self.trackingStatePublisher.send(state)
        }
    }

    /// Update real-time metrics from detection
    private func updateRealTimeMetrics(detection: BallDetectionResult) {
        guard detection.detected,
              let position = detection.pixelPosition else {
            return
        }

        currentMetrics.position = position

        // Apply calibration if available
        if let cal = calibration {
            let board = cal.pixelToBoard(Double(position.x))
            let distance = cal.pixelToDistanceFt(Double(position.y))

            currentMetrics.boardNumber = board
            currentMetrics.distanceFeet = distance

            // Determine ball phase based on distance
            if distance < 35 {
                currentMetrics.ballPhase = .skid
            } else if distance < 50 {
                currentMetrics.ballPhase = .hook
            } else {
                currentMetrics.ballPhase = .roll
            }
        }

        // Calculate running speed estimate
        let trajectory = trajectoryTracker.trajectory
        if trajectory.count >= 10 {
            if let speed = speedCalculator.calculateSpeed(from: Array(trajectory.suffix(10)), type: .average) {
                recentSpeeds.append(speed.speedMPH)
                if recentSpeeds.count > 20 {
                    recentSpeeds.removeFirst()
                }
                currentMetrics.speedMPH = recentSpeeds.reduce(0, +) / Double(recentSpeeds.count)
            }
        }

        // Calculate running angle estimate
        if trajectory.count >= 15 {
            if let angleResult = angleCalculator.calculateEntryAngle(from: Array(trajectory.suffix(15))) {
                recentAngles.append(angleResult.angleDegrees)
                if recentAngles.count > 10 {
                    recentAngles.removeFirst()
                }
                currentMetrics.entryAngleDegrees = recentAngles.reduce(0, +) / Double(recentAngles.count)
            }
        }

        // Calculate rev rate if available
        if let revResult = revRateCalculator.calculateFromMarker() {
            currentMetrics.revRatePM = revResult.rpm
        }

        // Calculate running strike probability
        if let speed = currentMetrics.speedMPH,
           let angle = currentMetrics.entryAngleDegrees,
           let board = currentMetrics.boardNumber {
            let targetPocket = handPreference == .right ? 17.5 : 22.5
            let pocketOffset = abs(board - targetPocket)

            currentMetrics.strikeProbability = strikeCalculator.quickProbability(
                pocketOffset: pocketOffset,
                entryAngle: angle,
                speedMPH: speed
            )
        }
    }

    /// Complete current shot and generate analysis
    private func completeCurrentShot() {
        let trajectory = trajectoryTracker.trajectory
        guard trajectory.count >= 10 else { return }

        // Calculate all metrics
        let launchSpeed = speedCalculator.calculateLaunchSpeed(from: trajectory)
        let impactSpeed = speedCalculator.calculateImpactSpeed(from: trajectory)
        let entryAngle = angleCalculator.calculateEntryAngle(from: trajectory, handPreference: handPreference)
        let revRate = revRateCalculator.calculateFromMarker() ?? revRateCalculator.estimateFromTrajectory(
            trajectory: trajectory,
            entryAngle: entryAngle?.angleDegrees ?? 5.0,
            speed: impactSpeed ?? 17.0
        )

        let arrowBoard = trajectoryTracker.positionAtArrows()
        let breakpoint = trajectoryTracker.findBreakpoint()
        let pocketBoard = trajectoryTracker.positionAtPins()

        // Calculate strike probability
        var strikeProbability: StrikeProbabilityResult? = nil
        if let pocket = pocketBoard,
           let angle = entryAngle?.angleDegrees,
           let speed = impactSpeed ?? launchSpeed {
            strikeProbability = strikeCalculator.calculateProbability(
                pocketBoard: pocket,
                entryAngle: angle,
                speedMPH: speed,
                revRPM: revRate?.rpm,
                handPreference: handPreference
            )
        }

        let duration = trajectory.last?.timestamp ?? 0

        let analysis = ShotAnalysis(
            id: UUID(),
            trajectory: trajectory,
            launchSpeed: launchSpeed,
            impactSpeed: impactSpeed,
            entryAngle: entryAngle,
            revRate: revRate,
            strikeProbability: strikeProbability,
            arrowBoard: arrowBoard,
            breakpoint: breakpoint,
            pocketBoard: pocketBoard,
            duration: duration,
            frameCount: frameCount
        )

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.frameProcessor(self, didCompleteShot: analysis)
            self.shotCompletedPublisher.send(analysis)
        }
    }

    // MARK: - Performance

    /// Get average processing time
    var averageProcessingTimeMs: Double {
        lastProcessingTime * 1000
    }

    /// Check if meeting frame budget
    var isMeetingFrameBudget: Bool {
        lastProcessingTime < 0.00833  // 8.33ms for 120fps
    }

    /// Get current FPS
    var currentFPS: Double {
        guard frameCount > 0 else { return 0 }
        let elapsed = CACurrentMediaTime() - startTime
        return Double(frameCount) / elapsed
    }
}

// MARK: - TrajectoryTrackerDelegate

extension FrameProcessor: TrajectoryTrackerDelegate {
    func trajectoryTracker(_ tracker: TrajectoryTracker, didReceiveEvent event: ShotEvent) {
        switch event {
        case .shotStarted:
            updateTrackingState(.tracking)

        case .shotCompleted:
            completeCurrentShot()
            updateTrackingState(.shotComplete)

        case .ballLost:
            updateTrackingState(.occluded(frames: 1))

        case .ballRecovered:
            updateTrackingState(.tracking)

        case .trackingFailed(let reason):
            updateTrackingState(.lost)
            // Log tracking failure for diagnostics
            CVLogger.frameProcessing.error("Tracking failed: \(reason)")
            // Create typed error for proper error handling downstream
            let error = FrameProcessingError.trajectoryTracking(
                TrajectoryTrackingError.analysisError(reason: reason)
            )
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.frameProcessor(self, didEncounterError: error)
            }

        default:
            break
        }
    }

    func trajectoryTracker(_ tracker: TrajectoryTracker, didUpdatePosition position: CGPoint, velocity: CGPoint) {
        // Position updates handled in updateRealTimeMetrics
    }
}

// MARK: - FrameProcessorDelegate Extension

extension FrameProcessor: FrameProcessorDelegate {
    func frameProcessor(_ processor: FrameProcessor, didProcessFrame result: FrameProcessingResult) {
        // Default implementation - forward to actual delegate
    }

    func frameProcessor(_ processor: FrameProcessor, didCompleteShot analysis: ShotAnalysis) {
        // Default implementation - forward to actual delegate
    }

    func frameProcessor(_ processor: FrameProcessor, trackingStateDidChange state: TrackingState) {
        // Default implementation - forward to actual delegate
    }

    func frameProcessor(_ processor: FrameProcessor, didEncounterError error: Error) {
        // Default implementation - forward to actual delegate
    }
}

// MARK: - ShotAnalysis to Shot Conversion

extension ShotAnalysis {
    /// Convert to domain Shot model
    func toShot(sessionId: UUID, shotNumber: Int) -> Shot {
        var shot = Shot(
            id: self.id,
            sessionId: sessionId,
            shotNumber: shotNumber,
            timestamp: Date(),
            frameNumber: frameCount,
            isFirstBall: true
        )

        shot.launchSpeed = launchSpeed
        shot.impactSpeed = impactSpeed
        shot.arrowBoard = arrowBoard
        shot.breakpointBoard = breakpoint?.board
        shot.breakpointDistance = breakpoint?.distance
        shot.pocketBoard = pocketBoard
        shot.entryAngle = entryAngle?.angleDegrees
        shot.revRate = revRate?.rpm
        shot.revCategory = revRate?.category
        shot.strikeProbability = strikeProbability?.probability
        shot.trajectory = trajectory

        // Calculate pocket offset
        if let pocket = pocketBoard {
            shot.pocketOffset = abs(pocket - 17.5)  // Default to right-handed
        }

        return shot
    }
}
