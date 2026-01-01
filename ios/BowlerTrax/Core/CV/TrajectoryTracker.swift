//
//  TrajectoryTracker.swift
//  BowlerTrax
//
//  Frame-to-frame position tracking with shot detection, occlusion handling,
//  and trajectory history management. Coordinates with physics calculations.
//

import Foundation
import CoreGraphics
import Combine

// MARK: - Tracking State

/// Current state of ball tracking
enum TrackingState: Equatable, Sendable {
    case idle                    // Not tracking, waiting for ball
    case searching               // Looking for ball in frame
    case tracking                // Actively tracking ball
    case occluded(frames: Int)   // Ball temporarily lost
    case shotComplete            // Shot finished, trajectory captured
    case lost                    // Tracking failed

    var isActive: Bool {
        switch self {
        case .tracking, .occluded:
            return true
        default:
            return false
        }
    }
}

// MARK: - Shot Event

/// Events during shot tracking
enum ShotEvent: Sendable {
    case shotStarted(timestamp: TimeInterval)
    case ballDetected(position: CGPoint)
    case ballLost
    case ballRecovered
    case shotCompleted(trajectory: [TrajectoryPoint])
    case trackingFailed(reason: String)
}

// MARK: - Trajectory Tracker Configuration

struct TrajectoryTrackerConfiguration: Sendable {
    /// Maximum consecutive frames without detection before marking lost
    var maxConsecutiveMisses: Int = 5

    /// Confidence threshold for valid detection
    var confidenceThreshold: Double = 0.5

    /// Distance from foul line (in feet) to consider shot complete
    var shotEndDistance: Double = 55.0

    /// Minimum points required for valid trajectory
    var minimumTrajectoryPoints: Int = 30

    /// Whether to use Kalman filtering
    var useKalmanFilter: Bool = true

    /// Frame rate for timing calculations
    var frameRate: Double = 120.0

    static let `default` = TrajectoryTrackerConfiguration()
}

// MARK: - Trajectory Tracker Delegate

protocol TrajectoryTrackerDelegate: AnyObject {
    /// Called when a tracking event occurs
    func trajectoryTracker(_ tracker: TrajectoryTracker, didReceiveEvent event: ShotEvent)

    /// Called with real-time position updates
    func trajectoryTracker(_ tracker: TrajectoryTracker, didUpdatePosition position: CGPoint, velocity: CGPoint)
}

// MARK: - Trajectory Tracker

/// Tracks ball position across frames and manages shot lifecycle
final class TrajectoryTracker: @unchecked Sendable {
    // MARK: - Properties

    /// Current tracking state
    private(set) var state: TrackingState = .idle

    /// Current trajectory points for active shot
    private(set) var trajectory: [TrajectoryPoint] = []

    /// Delegate for events and updates
    weak var delegate: TrajectoryTrackerDelegate?

    /// Publisher for state changes
    let statePublisher = PassthroughSubject<TrackingState, Never>()

    /// Publisher for trajectory updates
    let trajectoryPublisher = PassthroughSubject<[TrajectoryPoint], Never>()

    /// Configuration
    private var config: TrajectoryTrackerConfiguration

    /// Kalman filter for smoothing
    private let kalmanFilter: KalmanFilter

    /// Calibration profile for coordinate conversion
    private var calibration: CalibrationProfile?

    // Tracking state
    private var lastValidDetection: BallDetectionResult?
    private var consecutiveMisses: Int = 0
    private var shotStartTime: TimeInterval?
    private var shotStartFrame: Int?

    // Shot detection thresholds
    private let foulLineThreshold: Double = 0.9  // Normalized Y near bottom of frame

    // MARK: - Initialization

    init(configuration: TrajectoryTrackerConfiguration = .default) {
        self.config = configuration
        self.kalmanFilter = KalmanFilter(frameRate: configuration.frameRate)
    }

    // MARK: - Configuration

    /// Set calibration for real-world coordinate conversion
    func setCalibration(_ calibration: CalibrationProfile?) {
        self.calibration = calibration
    }

    /// Update configuration
    func updateConfiguration(_ config: TrajectoryTrackerConfiguration) {
        self.config = config
    }

    /// Reset tracker for new shot
    func reset() {
        state = .idle
        trajectory.removeAll()
        lastValidDetection = nil
        consecutiveMisses = 0
        shotStartTime = nil
        shotStartFrame = nil
        kalmanFilter.reset()
        statePublisher.send(.idle)
    }

    /// Start actively searching for ball
    func startSearching() {
        state = .searching
        statePublisher.send(.searching)
    }

    // MARK: - Detection Processing

    /// Process a ball detection result
    /// - Parameter detection: Detection result from BallDetector
    func processDetection(_ detection: BallDetectionResult) {
        switch state {
        case .idle:
            // Do nothing until startSearching() is called
            break

        case .searching:
            if detection.detected && detection.confidence >= config.confidenceThreshold {
                // Ball found, start tracking
                startTracking(with: detection)
            }

        case .tracking:
            if detection.detected && detection.confidence >= config.confidenceThreshold {
                // Continue tracking
                addTrajectoryPoint(from: detection, interpolated: false)
                lastValidDetection = detection
                consecutiveMisses = 0
            } else {
                // Lost detection
                handleMissedDetection(currentFrame: detection.frameNumber, timestamp: detection.timestamp)
            }

            // Check for shot completion
            checkShotCompletion()

        case .occluded(let frames):
            if detection.detected && detection.confidence >= config.confidenceThreshold {
                // Recovered from occlusion
                recoverFromOcclusion(with: detection)
            } else {
                // Still occluded
                let newFrameCount = frames + 1
                if newFrameCount >= config.maxConsecutiveMisses {
                    // Too long, mark as lost
                    state = .lost
                    statePublisher.send(.lost)
                    // Provide detailed error context for diagnostics
                    let reason = "Ball lost for \(newFrameCount) consecutive frames (max allowed: \(config.maxConsecutiveMisses))"
                    CVLogger.trajectoryTracking.warning("\(reason)")
                    delegate?.trajectoryTracker(self, didReceiveEvent: .trackingFailed(reason: reason))
                } else {
                    // Continue predicting
                    state = .occluded(frames: newFrameCount)
                    statePublisher.send(.occluded(frames: newFrameCount))
                    addInterpolatedPoint(timestamp: detection.timestamp, frameNumber: detection.frameNumber)
                }
            }

        case .shotComplete, .lost:
            // Do nothing, waiting for reset
            break
        }
    }

    // MARK: - Private Methods

    /// Start tracking with initial detection
    private func startTracking(with detection: BallDetectionResult) {
        // Check if ball is near foul line (shot starting)
        guard let centroid = detection.centroid, centroid.y >= foulLineThreshold else {
            // Ball not at starting position yet
            return
        }

        state = .tracking
        trajectory.removeAll()
        shotStartTime = detection.timestamp
        shotStartFrame = detection.frameNumber
        lastValidDetection = detection
        consecutiveMisses = 0

        // Initialize Kalman filter
        if config.useKalmanFilter, let position = detection.centroid {
            kalmanFilter.initialize(with: position)
        }

        addTrajectoryPoint(from: detection, interpolated: false)

        statePublisher.send(.tracking)
        delegate?.trajectoryTracker(self, didReceiveEvent: .shotStarted(timestamp: detection.timestamp))

        if let pos = detection.centroid {
            delegate?.trajectoryTracker(self, didReceiveEvent: .ballDetected(position: pos))
        }
    }

    /// Add trajectory point from detection
    private func addTrajectoryPoint(from detection: BallDetectionResult, interpolated: Bool) {
        guard let centroid = detection.centroid,
              let pixelPos = detection.pixelPosition else { return }

        // Apply Kalman filtering if enabled
        var filteredPosition = centroid
        if config.useKalmanFilter {
            filteredPosition = kalmanFilter.update(measurement: centroid)
        }

        let startTime = shotStartTime ?? detection.timestamp

        var point = TrajectoryPoint(
            x: Double(pixelPos.x),
            y: Double(pixelPos.y),
            timestamp: detection.timestamp - startTime,
            frameNumber: detection.frameNumber - (shotStartFrame ?? 0),
            board: nil,
            distanceFt: nil,
            phase: nil
        )

        // Apply calibration if available
        if let cal = calibration {
            point.board = cal.pixelToBoard(Double(pixelPos.x))
            point.distanceFt = cal.pixelToDistanceFt(Double(pixelPos.y))
            point.realWorldX = point.board
            point.realWorldY = point.distanceFt
        }

        trajectory.append(point)
        trajectoryPublisher.send(trajectory)

        // Notify delegate
        delegate?.trajectoryTracker(
            self,
            didUpdatePosition: filteredPosition,
            velocity: kalmanFilter.currentVelocity
        )
    }

    /// Handle missed detection
    private func handleMissedDetection(currentFrame: Int, timestamp: TimeInterval) {
        consecutiveMisses += 1

        if consecutiveMisses >= config.maxConsecutiveMisses {
            state = .occluded(frames: consecutiveMisses)
            statePublisher.send(.occluded(frames: consecutiveMisses))
            delegate?.trajectoryTracker(self, didReceiveEvent: .ballLost)
        } else {
            // Interpolate position
            addInterpolatedPoint(timestamp: timestamp, frameNumber: currentFrame)
        }
    }

    /// Add interpolated point during brief occlusion
    private func addInterpolatedPoint(timestamp: TimeInterval, frameNumber: Int) {
        guard config.useKalmanFilter else { return }

        // Predict position using Kalman filter
        let predictedPos = kalmanFilter.predict()
        let startTime = shotStartTime ?? timestamp

        let point = TrajectoryPoint(
            x: Double(predictedPos.x) * Double(CVPixelBufferGetWidth),
            y: Double(predictedPos.y) * Double(CVPixelBufferGetHeight),
            timestamp: timestamp - startTime,
            frameNumber: frameNumber - (shotStartFrame ?? 0)
        )

        // Note: Marking as interpolated would require extending TrajectoryPoint
        // For now, we add with slightly lower implied confidence

        trajectory.append(point)
        trajectoryPublisher.send(trajectory)
    }

    // Placeholder constants for interpolation (would be from actual frame dimensions)
    private let CVPixelBufferGetWidth: CGFloat = 1920
    private let CVPixelBufferGetHeight: CGFloat = 1080

    /// Recover from occlusion with new detection
    private func recoverFromOcclusion(with detection: BallDetectionResult) {
        state = .tracking
        consecutiveMisses = 0
        lastValidDetection = detection
        statePublisher.send(.tracking)
        delegate?.trajectoryTracker(self, didReceiveEvent: .ballRecovered)

        addTrajectoryPoint(from: detection, interpolated: false)
    }

    /// Check if shot is complete
    private func checkShotCompletion() {
        guard let lastPoint = trajectory.last else { return }

        // Check if ball has traveled far enough
        if let distance = lastPoint.distanceFt, distance >= config.shotEndDistance {
            completeShot()
            return
        }

        // Alternative: check normalized Y position
        if let centroid = lastValidDetection?.centroid, centroid.y <= 0.1 {
            completeShot()
            return
        }
    }

    /// Complete the current shot
    private func completeShot() {
        guard trajectory.count >= config.minimumTrajectoryPoints else {
            state = .lost
            statePublisher.send(.lost)
            // Provide detailed error context for diagnostics
            let reason = "Insufficient trajectory points: collected \(trajectory.count), minimum required \(config.minimumTrajectoryPoints)"
            CVLogger.trajectoryTracking.warning("\(reason)")
            delegate?.trajectoryTracker(self, didReceiveEvent: .trackingFailed(reason: reason))
            return
        }

        // Calculate velocities for all points
        calculateVelocities()

        // Determine ball phases (skid-hook-roll)
        determineBallPhases()

        state = .shotComplete
        statePublisher.send(.shotComplete)
        delegate?.trajectoryTracker(self, didReceiveEvent: .shotCompleted(trajectory: trajectory))
    }

    /// Calculate velocities for trajectory points
    private func calculateVelocities() {
        guard trajectory.count >= 2, calibration != nil else { return }

        for i in 1..<trajectory.count {
            let prev = trajectory[i - 1]
            let curr = trajectory[i]

            let dt = curr.timestamp - prev.timestamp
            guard dt > 0 else { continue }

            // We would calculate velocity here and store in an extended model
            // For now, velocity is calculated on-demand by physics calculators
        }
    }

    /// Determine ball phases along trajectory
    private func determineBallPhases() {
        guard trajectory.count >= 10 else { return }

        // Analyze curvature changes to determine phases
        // Skid: Low curvature, ball sliding
        // Hook: Increasing curvature, ball curving
        // Roll: Constant direction, ball rolling out

        for i in 0..<trajectory.count {
            // Simple heuristic based on distance from foul line
            let distance = trajectory[i].distanceFt ?? (Double(i) / Double(trajectory.count) * 60)

            if distance < 35 {
                trajectory[i].phase = .skid
            } else if distance < 50 {
                trajectory[i].phase = .hook
            } else {
                trajectory[i].phase = .roll
            }
        }
    }

    // MARK: - Accessors

    /// Get current ball position (filtered)
    var currentPosition: CGPoint? {
        guard state.isActive else { return nil }
        return kalmanFilter.state.position
    }

    /// Get current ball velocity
    var currentVelocity: CGPoint {
        kalmanFilter.currentVelocity
    }

    /// Get trajectory point count
    var trajectoryPointCount: Int {
        trajectory.count
    }

    /// Check if tracking is active
    var isTracking: Bool {
        state.isActive
    }

    /// Get most recent valid detection
    var lastDetection: BallDetectionResult? {
        lastValidDetection
    }
}

// MARK: - Trajectory Analysis Extension

extension TrajectoryTracker {
    /// Get trajectory segment between two distances
    func trajectorySegment(fromFeet: Double, toFeet: Double) -> [TrajectoryPoint] {
        trajectory.filter { point in
            guard let dist = point.distanceFt else { return false }
            return dist >= fromFeet && dist <= toFeet
        }
    }

    /// Get breakpoint (where ball starts hooking)
    func findBreakpoint() -> (board: Double, distance: Double)? {
        // Find where trajectory curvature changes significantly
        // Need at least 11 elements for loop range 5..<(count-5) to have iterations
        guard trajectory.count >= 11 else { return nil }

        // Look for maximum lateral acceleration (curve change)
        var maxCurvatureChange: Double = 0
        var breakpointIndex: Int = 0

        for i in 5..<trajectory.count - 5 {
            guard let boardPrev = trajectory[i - 5].board,
                  let boardCurr = trajectory[i].board,
                  let boardNext = trajectory[i + 5].board else { continue }

            // Second derivative approximation
            let curvature = abs((boardNext - 2 * boardCurr + boardPrev))

            if curvature > maxCurvatureChange {
                maxCurvatureChange = curvature
                breakpointIndex = i
            }
        }

        guard breakpointIndex > 0,
              let board = trajectory[breakpointIndex].board,
              let distance = trajectory[breakpointIndex].distanceFt else {
            return nil
        }

        return (board, distance)
    }

    /// Get position at arrows (15 feet)
    func positionAtArrows() -> Double? {
        // Find point closest to 15 feet
        let arrowPoints = trajectory.filter { point in
            guard let dist = point.distanceFt else { return false }
            return abs(dist - 15.0) < 1.0  // Within 1 foot of arrows
        }

        return arrowPoints.first?.board
    }

    /// Get entry position at pins (~60 feet)
    func positionAtPins() -> Double? {
        // Extrapolate or use last point
        guard let last = trajectory.last else { return nil }

        if let dist = last.distanceFt, dist >= 58 {
            return last.board
        }

        // Linear extrapolation from last segment
        guard trajectory.count >= 5 else { return nil }

        let segment = trajectory.suffix(5)
        let boards = segment.compactMap { $0.board }
        let distances = segment.compactMap { $0.distanceFt }

        guard boards.count >= 2, distances.count >= 2,
              let firstBoard = boards.first,
              let lastBoard = boards.last,
              let firstDist = distances.first,
              let lastDist = distances.last else { return nil }

        // Linear regression slope
        let boardChange = lastBoard - firstBoard
        let distChange = lastDist - firstDist

        guard distChange > 0 else { return nil }

        let slope = boardChange / distChange
        let remainingDist = 60.0 - lastDist

        return lastBoard + slope * remainingDist
    }
}
