//
//  RevRateCalculator.swift
//  BowlerTrax
//
//  Calculates ball rev rate (RPM) from marker tracking or optical flow.
//  Rev rate is critical for understanding ball reaction and pin carry.
//

import Foundation
import CoreImage
import Vision

// MARK: - Rev Rate Result

/// Result of rev rate calculation
struct RevRateResult: Sendable {
    /// Revolutions per minute
    let rpm: Double

    /// Category classification
    let category: RevCategory

    /// Total rotation measured (degrees)
    let totalRotation: Double

    /// Time period of measurement (seconds)
    let timePeriod: Double

    /// Measurement method used
    let method: MeasurementMethod

    /// Confidence in the measurement (0-1)
    let confidence: Double

    enum MeasurementMethod: Sendable {
        case markerTracking    // PAP marker visible
        case opticalFlow       // Texture-based estimation
        case estimated         // Based on trajectory characteristics
    }
}

// MARK: - Rotation Tracker

/// Tracks rotation by following angle changes
final class RotationTracker: @unchecked Sendable {
    // MARK: - Properties

    /// History of angle measurements
    private var angleHistory: [(angle: Double, timestamp: TimeInterval)] = []

    /// Unwrapped cumulative angle
    private var unwrappedAngle: Double = 0

    /// Last raw angle (for wraparound detection)
    private var lastRawAngle: Double?

    /// Maximum angle jump considered valid (vs. wraparound)
    private let maxValidJump: Double = 90.0

    // MARK: - Methods

    /// Add new angle measurement
    /// - Parameters:
    ///   - angle: Raw angle in degrees (-180 to 180 or 0 to 360)
    ///   - timestamp: Frame timestamp
    /// - Returns: Total rotations so far
    @discardableResult
    func addAngle(_ angle: Double, timestamp: TimeInterval) -> Double {
        defer { lastRawAngle = angle }

        guard let previous = lastRawAngle else {
            angleHistory.append((angle, timestamp))
            return 0
        }

        // Calculate delta, handling wraparound
        var delta = angle - previous

        // Handle wraparound (e.g., 170 to -170 = 20 degrees, not -340)
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }

        // Check for unrealistic jumps (likely lost tracking)
        guard abs(delta) <= maxValidJump else {
            return totalRotations
        }

        unwrappedAngle += delta
        angleHistory.append((angle, timestamp))

        return totalRotations
    }

    /// Get total rotations
    var totalRotations: Double {
        abs(unwrappedAngle) / 360.0
    }

    /// Get total rotation in degrees
    var totalRotationDegrees: Double {
        abs(unwrappedAngle)
    }

    /// Get rotation direction
    var direction: RotationDirection {
        if unwrappedAngle > 0 {
            return .forward  // Top spin
        } else if unwrappedAngle < 0 {
            return .reverse  // Back spin
        }
        return .none
    }

    /// Reset tracker
    func reset() {
        angleHistory.removeAll()
        unwrappedAngle = 0
        lastRawAngle = nil
    }

    /// Get time span of measurements
    var timeSpan: TimeInterval {
        guard let first = angleHistory.first?.timestamp,
              let last = angleHistory.last?.timestamp else {
            return 0
        }
        return last - first
    }

    enum RotationDirection: Sendable {
        case forward
        case reverse
        case none
    }
}

// MARK: - Rev Rate Calculator

/// Calculates ball rev rate from tracked angles or optical flow
final class RevRateCalculator: @unchecked Sendable {
    // MARK: - Properties

    private let rotationTracker = RotationTracker()
    private var markerAngles: [(angle: Double, timestamp: TimeInterval, ballPosition: CGPoint)] = []

    // Optical flow history
    private var flowMagnitudes: [(magnitude: Double, timestamp: TimeInterval)] = []

    // Configuration
    private let minimumDataPoints: Int = 10
    private let minimumTimeSpan: TimeInterval = 0.1  // 100ms minimum

    // MARK: - Marker-Based Tracking

    /// Process marker angle from detection
    /// - Parameters:
    ///   - angle: Marker angle relative to ball center
    ///   - timestamp: Frame timestamp
    ///   - ballPosition: Ball center position
    func processMarkerAngle(
        _ angle: Double,
        timestamp: TimeInterval,
        ballPosition: CGPoint
    ) {
        markerAngles.append((angle, timestamp, ballPosition))
        rotationTracker.addAngle(angle, timestamp: timestamp)
    }

    /// Calculate RPM from marker tracking data
    /// - Returns: Rev rate result or nil if insufficient data
    func calculateFromMarker() -> RevRateResult? {
        guard markerAngles.count >= minimumDataPoints else { return nil }

        let timeSpan = rotationTracker.timeSpan
        guard timeSpan >= minimumTimeSpan else { return nil }

        let totalRotations = rotationTracker.totalRotations

        // RPM = (rotations / seconds) * 60
        let rpm = (totalRotations / timeSpan) * 60

        // Validate reasonable range
        guard rpm > 50 && rpm < 800 else { return nil }

        let category = RevCategory.from(rpm: rpm)

        // Calculate confidence based on data quality
        let confidence = calculateMarkerConfidence()

        return RevRateResult(
            rpm: rpm,
            category: category,
            totalRotation: rotationTracker.totalRotationDegrees,
            timePeriod: timeSpan,
            method: .markerTracking,
            confidence: confidence
        )
    }

    // MARK: - Optical Flow Estimation

    /// Add optical flow measurement
    /// - Parameters:
    ///   - magnitude: Average flow magnitude in ball region
    ///   - timestamp: Frame timestamp
    ///   - ballRadius: Ball radius in pixels
    func addFlowMeasurement(
        magnitude: Double,
        timestamp: TimeInterval,
        ballRadius: Double
    ) {
        // Normalize flow by ball radius (tangential velocity = angular velocity * radius)
        let normalizedMagnitude = magnitude / max(ballRadius, 1.0)
        flowMagnitudes.append((normalizedMagnitude, timestamp))
    }

    /// Estimate RPM from optical flow data
    /// - Parameter frameRate: Camera frame rate
    /// - Returns: Rev rate result or nil
    func estimateFromOpticalFlow(frameRate: Double = 120.0) -> RevRateResult? {
        guard flowMagnitudes.count >= minimumDataPoints else { return nil }

        guard let firstTime = flowMagnitudes.first?.timestamp,
              let lastTime = flowMagnitudes.last?.timestamp else { return nil }

        let timeSpan = lastTime - firstTime
        guard timeSpan >= minimumTimeSpan else { return nil }

        // Average flow magnitude
        let avgMagnitude = flowMagnitudes.reduce(0.0) { $0 + $1.magnitude } / Double(flowMagnitudes.count)

        // Estimate angular velocity from tangential flow
        // Assuming normalized magnitude represents fraction of circumference per frame
        let radiansPerFrame = avgMagnitude * 2 * .pi
        let radiansPerSecond = radiansPerFrame * frameRate
        let rpm = (radiansPerSecond / (2 * .pi)) * 60

        // Validate reasonable range (with wider tolerance for estimates)
        guard rpm > 30 && rpm < 1000 else { return nil }

        let category = RevCategory.from(rpm: rpm)

        return RevRateResult(
            rpm: rpm,
            category: category,
            totalRotation: rpm * timeSpan / 60 * 360,  // Estimated
            timePeriod: timeSpan,
            method: .opticalFlow,
            confidence: 0.5  // Lower confidence for optical flow
        )
    }

    // MARK: - Trajectory-Based Estimation

    /// Estimate rev rate from ball trajectory characteristics
    /// - Parameters:
    ///   - trajectory: Ball trajectory
    ///   - entryAngle: Entry angle at pins
    ///   - speed: Ball speed in mph
    /// - Returns: Estimated rev rate result
    func estimateFromTrajectory(
        trajectory: [TrajectoryPoint],
        entryAngle: Double,
        speed: Double
    ) -> RevRateResult? {
        // Empirical estimation based on hook amount and speed
        // Higher entry angle with higher speed typically indicates higher revs

        // Hook amount from breakpoint to pocket
        guard let breakpoint = findBreakpoint(in: trajectory),
              let pocketBoard = trajectory.last?.board else {
            return nil
        }

        let hookBoards = abs(pocketBoard - breakpoint.board)
        let hookDistance = 60.0 - breakpoint.distance

        // Normalize hook per foot
        let hookPerFoot = hookBoards / max(hookDistance, 1.0)

        // Speed factor (faster ball = less time to hook = needs more revs)
        let speedFactor = speed / 17.0  // Normalize to average speed

        // Estimate RPM based on empirical model
        // This is a rough approximation - actual rev rate requires marker tracking
        let estimatedRPM = (hookPerFoot * speedFactor * 300) + 200

        // Clamp to reasonable range
        let rpm = min(max(estimatedRPM, 150), 600)

        let category = RevCategory.from(rpm: rpm)

        // Calculate time span from trajectory
        let timeSpan = trajectory.last?.timestamp ?? 2.0

        return RevRateResult(
            rpm: rpm,
            category: category,
            totalRotation: rpm * timeSpan / 60 * 360,
            timePeriod: timeSpan,
            method: .estimated,
            confidence: 0.3  // Low confidence for estimation
        )
    }

    // MARK: - Private Methods

    /// Find breakpoint in trajectory
    private func findBreakpoint(in trajectory: [TrajectoryPoint]) -> (board: Double, distance: Double)? {
        // Need at least 11 elements: indices 0-4 for prev, 5 for curr, 6-10 for next
        guard trajectory.count >= 11 else { return nil }

        // Find where lateral direction changes most
        var maxCurvature: Double = 0
        var breakpointIndex: Int = 0

        for i in 5..<trajectory.count - 5 {
            guard let boardPrev = trajectory[i - 5].board,
                  let boardCurr = trajectory[i].board,
                  let boardNext = trajectory[i + 5].board else { continue }

            let curvature = abs(boardNext - 2 * boardCurr + boardPrev)

            if curvature > maxCurvature {
                maxCurvature = curvature
                breakpointIndex = i
            }
        }

        guard breakpointIndex > 0 else { return nil }

        let point = trajectory[breakpointIndex]
        // Safely unwrap optional values - return nil if data is incomplete
        guard let board = point.board, let distanceFt = point.distanceFt else {
            return nil
        }
        return (board, distanceFt)
    }

    /// Calculate confidence for marker-based measurement
    private func calculateMarkerConfidence() -> Double {
        var confidence: Double = 0.5

        // More data points = higher confidence (up to 0.3)
        let dataScore = min(Double(markerAngles.count) / 50.0, 1.0) * 0.3
        confidence += dataScore

        // Longer time span = higher confidence (up to 0.2)
        let timeScore = min(rotationTracker.timeSpan / 0.5, 1.0) * 0.2
        confidence += timeScore

        return min(confidence, 1.0)
    }

    /// Reset all tracking data
    func reset() {
        rotationTracker.reset()
        markerAngles.removeAll()
        flowMagnitudes.removeAll()
    }
}

// MARK: - Rev Rate Analysis Extensions

extension RevRateCalculator {
    /// Get rev rate trend over trajectory
    /// - Parameter windowSize: Number of samples per calculation window
    /// - Returns: Array of (distance, rpm) measurements
    func calculateRevRateTrend(windowSize: Int = 10) -> [(distance: Double, rpm: Double)] {
        guard markerAngles.count >= windowSize * 2 else { return [] }

        var trend: [(distance: Double, rpm: Double)] = []

        for i in stride(from: windowSize, to: markerAngles.count, by: windowSize / 2) {
            let window = Array(markerAngles[(i - windowSize)..<i])

            guard let firstTime = window.first?.timestamp,
                  let lastTime = window.last?.timestamp,
                  lastTime > firstTime else { continue }

            // Calculate rotation in window
            var rotation: Double = 0
            for j in 1..<window.count {
                var delta = window[j].angle - window[j - 1].angle
                if delta > 180 { delta -= 360 }
                if delta < -180 { delta += 360 }
                rotation += abs(delta)
            }

            let timeSpan = lastTime - firstTime
            let rpm = (rotation / 360.0 / timeSpan) * 60

            // Estimate distance (average of ball positions normalized to 60ft lane)
            let avgY = window.reduce(0.0) { $0 + $1.ballPosition.y } / Double(window.count)
            let estimatedDistance = (1 - avgY) * 60.0  // Assuming normalized Y

            trend.append((estimatedDistance, rpm))
        }

        return trend
    }

    /// Compare revs to typical categories
    static func describeRevRate(_ rpm: Double) -> String {
        switch rpm {
        case ..<250:
            return "Low revs (stroker style) - smooth roll with controlled hook"
        case 250..<350:
            return "Medium-low revs - balanced between control and power"
        case 350..<450:
            return "Medium-high revs (tweener style) - good combination of hook and control"
        case 450..<550:
            return "High revs (cranker style) - aggressive hook with strong backend reaction"
        default:
            return "Very high revs - exceptional hook potential, requires high ball speed"
        }
    }
}

// MARK: - Rev Category Extensions

extension RevCategory {
    /// Get optimal speed range for this rev category
    var optimalSpeedRange: ClosedRange<Double> {
        switch self {
        case .stroker:
            return 14...17  // Lower revs work better with lower speed
        case .tweener:
            return 16...19  // Balanced
        case .cranker:
            return 18...22  // High revs need higher speed
        }
    }

    /// Get typical entry angle range
    var typicalEntryAngle: ClosedRange<Double> {
        switch self {
        case .stroker:
            return 3...5
        case .tweener:
            return 5...7
        case .cranker:
            return 6...9
        }
    }
}
