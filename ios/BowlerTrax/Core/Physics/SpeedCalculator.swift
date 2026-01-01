//
//  SpeedCalculator.swift
//  BowlerTrax
//
//  Calculates ball speed from trajectory data using distance/time measurements.
//  Provides launch speed, impact speed, and speed at specific distances.
//

import Foundation

// MARK: - Speed Calculation Result

/// Result of speed calculation
struct SpeedCalculationResult: Sendable {
    /// Speed in miles per hour
    let speedMPH: Double

    /// Speed in feet per second
    let speedFPS: Double

    /// Start point used for calculation
    let startPoint: TrajectoryPoint

    /// End point used for calculation
    let endPoint: TrajectoryPoint

    /// Confidence in the measurement (0-1)
    let confidence: Double

    /// Measurement type
    let measurementType: MeasurementType

    enum MeasurementType: Sendable {
        case launch         // Speed at release (first 5-10 feet)
        case impact         // Speed at pins (last 10 feet)
        case average        // Average over full trajectory
        case atDistance(feet: Double)  // Speed at specific distance
    }
}

// MARK: - Speed Calculator

/// Calculates ball speed from trajectory data
final class SpeedCalculator: @unchecked Sendable {
    // MARK: - Constants

    /// Conversion factor: feet per second to miles per hour
    static let fpsToMph: Double = 0.6818

    /// Conversion factor: miles per hour to feet per second
    static let mphToFps: Double = 1.4667

    /// Board width in feet
    static let boardWidthFeet: Double = 1.0641 / 12.0

    /// Lane length in feet
    static let laneLengthFeet: Double = 60.0

    // MARK: - Calculation Methods

    /// Calculate ball speed from trajectory
    /// - Parameters:
    ///   - trajectory: Array of trajectory points with calibrated coordinates
    ///   - type: Type of speed measurement desired
    /// - Returns: Speed calculation result or nil if insufficient data
    func calculateSpeed(
        from trajectory: [TrajectoryPoint],
        type: SpeedCalculationResult.MeasurementType = .impact
    ) -> SpeedCalculationResult? {
        // Filter to calibrated points only
        let calibratedPoints = trajectory.filter {
            $0.distanceFt != nil && $0.board != nil
        }

        guard calibratedPoints.count >= 2 else { return nil }

        let measurePoints: (TrajectoryPoint, TrajectoryPoint)?

        switch type {
        case .launch:
            // Use first 10 feet
            measurePoints = findPointsInRange(calibratedPoints, from: 0, to: 10)

        case .impact:
            // Use last 10 feet (50-60 feet from foul line)
            measurePoints = findPointsInRange(calibratedPoints, from: 50, to: 60)

        case .average:
            // Use full trajectory - safe because we already checked count >= 2 above
            guard let first = calibratedPoints.first, let last = calibratedPoints.last else {
                measurePoints = nil
                break
            }
            measurePoints = (first, last)

        case .atDistance(let feet):
            // Find points bracketing the target distance
            measurePoints = findPointsBracketing(calibratedPoints, distance: feet)
        }

        guard let (start, end) = measurePoints else { return nil }

        return calculateSpeedBetweenPoints(start: start, end: end, type: type)
    }

    /// Calculate launch speed (first 5-10 feet)
    func calculateLaunchSpeed(from trajectory: [TrajectoryPoint]) -> Double? {
        calculateSpeed(from: trajectory, type: .launch)?.speedMPH
    }

    /// Calculate impact speed (at pins)
    func calculateImpactSpeed(from trajectory: [TrajectoryPoint]) -> Double? {
        calculateSpeed(from: trajectory, type: .impact)?.speedMPH
    }

    /// Calculate average speed over full trajectory
    func calculateAverageSpeed(from trajectory: [TrajectoryPoint]) -> Double? {
        calculateSpeed(from: trajectory, type: .average)?.speedMPH
    }

    /// Calculate speed at specific distance from foul line
    func calculateSpeedAt(distance: Double, from trajectory: [TrajectoryPoint]) -> Double? {
        calculateSpeed(from: trajectory, type: .atDistance(feet: distance))?.speedMPH
    }

    /// Calculate instantaneous speed between two trajectory points
    func instantaneousSpeed(from p1: TrajectoryPoint, to p2: TrajectoryPoint) -> Double? {
        calculateSpeedBetweenPoints(start: p1, end: p2, type: .average)?.speedMPH
    }

    // MARK: - Private Methods

    /// Find trajectory points within a distance range
    private func findPointsInRange(
        _ points: [TrajectoryPoint],
        from minDist: Double,
        to maxDist: Double
    ) -> (TrajectoryPoint, TrajectoryPoint)? {
        let inRange = points.filter { point in
            guard let dist = point.distanceFt else { return false }
            return dist >= minDist && dist <= maxDist
        }

        guard inRange.count >= 2 else {
            // Fallback to closest available points
            let sorted = points.sorted { ($0.distanceFt ?? 0) < ($1.distanceFt ?? 0) }
            if minDist < 30 {
                // Looking for early points
                return sorted.count >= 2 ? (sorted[0], sorted[min(1, sorted.count - 1)]) : nil
            } else {
                // Looking for late points
                let count = sorted.count
                return count >= 2 ? (sorted[max(0, count - 2)], sorted[count - 1]) : nil
            }
        }

        // Safe unwrap - guard above ensures count >= 2
        guard let first = inRange.first, let last = inRange.last else {
            return nil
        }
        return (first, last)
    }

    /// Find points bracketing a target distance
    private func findPointsBracketing(
        _ points: [TrajectoryPoint],
        distance: Double
    ) -> (TrajectoryPoint, TrajectoryPoint)? {
        let sorted = points.sorted { ($0.distanceFt ?? 0) < ($1.distanceFt ?? 0) }

        guard let afterIndex = sorted.firstIndex(where: { ($0.distanceFt ?? 0) >= distance }),
              afterIndex > 0 else {
            return nil
        }

        return (sorted[afterIndex - 1], sorted[afterIndex])
    }

    /// Calculate speed between two points
    private func calculateSpeedBetweenPoints(
        start: TrajectoryPoint,
        end: TrajectoryPoint,
        type: SpeedCalculationResult.MeasurementType
    ) -> SpeedCalculationResult? {
        guard let startBoard = start.board, let endBoard = end.board,
              let startDist = start.distanceFt, let endDist = end.distanceFt else {
            return nil
        }

        // Calculate time elapsed
        let timeSeconds = end.timestamp - start.timestamp
        guard timeSeconds > 0 else { return nil }

        // Calculate distance traveled
        // Lateral distance (board change in feet)
        let lateralFeet = (endBoard - startBoard) * Self.boardWidthFeet

        // Forward distance (down the lane)
        let forwardFeet = endDist - startDist

        // Total distance (Pythagorean)
        let totalDistance = sqrt(lateralFeet * lateralFeet + forwardFeet * forwardFeet)

        // Speed in feet per second
        let speedFPS = totalDistance / timeSeconds

        // Convert to MPH
        let speedMPH = speedFPS * Self.fpsToMph

        // Calculate confidence based on measurement quality
        let confidence = calculateConfidence(
            timeSpan: timeSeconds,
            distanceSpan: totalDistance,
            pointCount: 2  // Just using start/end for now
        )

        return SpeedCalculationResult(
            speedMPH: speedMPH,
            speedFPS: speedFPS,
            startPoint: start,
            endPoint: end,
            confidence: confidence,
            measurementType: type
        )
    }

    /// Calculate confidence score for speed measurement
    private func calculateConfidence(
        timeSpan: TimeInterval,
        distanceSpan: Double,
        pointCount: Int
    ) -> Double {
        var confidence: Double = 0.5

        // Longer time span = more reliable (up to 0.3)
        let timeScore = min(timeSpan / 0.5, 1.0) * 0.3
        confidence += timeScore

        // Longer distance = more reliable (up to 0.2)
        let distScore = min(distanceSpan / 10.0, 1.0) * 0.2
        confidence += distScore

        return min(confidence, 1.0)
    }
}

// MARK: - Speed Profile Analysis

extension SpeedCalculator {
    /// Analyze speed throughout the trajectory
    /// - Parameter trajectory: Full trajectory
    /// - Returns: Array of speed measurements at intervals
    func analyzeSpeedProfile(
        trajectory: [TrajectoryPoint],
        intervalFeet: Double = 5.0
    ) -> [SpeedMeasurement] {
        var measurements: [SpeedMeasurement] = []

        let calibrated = trajectory.filter { $0.distanceFt != nil && $0.board != nil }
            .sorted { ($0.distanceFt ?? 0) < ($1.distanceFt ?? 0) }

        guard calibrated.count >= 2 else { return measurements }

        let startDist = calibrated.first?.distanceFt ?? 0
        let endDist = calibrated.last?.distanceFt ?? 60

        var currentDist = startDist + intervalFeet

        while currentDist < endDist - intervalFeet {
            if let speed = calculateSpeedAt(distance: currentDist, from: calibrated) {
                measurements.append(SpeedMeasurement(
                    distanceFeet: currentDist,
                    speedMPH: speed
                ))
            }
            currentDist += intervalFeet
        }

        return measurements
    }

    /// Calculate speed loss from launch to impact
    func calculateSpeedLoss(from trajectory: [TrajectoryPoint]) -> SpeedLoss? {
        guard let launchSpeed = calculateLaunchSpeed(from: trajectory),
              let impactSpeed = calculateImpactSpeed(from: trajectory) else {
            return nil
        }

        let loss = launchSpeed - impactSpeed
        let lossPercentage = (loss / launchSpeed) * 100

        return SpeedLoss(
            launchSpeedMPH: launchSpeed,
            impactSpeedMPH: impactSpeed,
            lossAmount: loss,
            lossPercentage: lossPercentage
        )
    }
}

// MARK: - Supporting Types

/// Speed measurement at a specific distance
struct SpeedMeasurement: Sendable {
    let distanceFeet: Double
    let speedMPH: Double
}

/// Speed loss analysis
struct SpeedLoss: Sendable {
    let launchSpeedMPH: Double
    let impactSpeedMPH: Double
    let lossAmount: Double
    let lossPercentage: Double

    var description: String {
        String(format: "Launch: %.1f mph, Impact: %.1f mph, Loss: %.1f mph (%.1f%%)",
               launchSpeedMPH, impactSpeedMPH, lossAmount, lossPercentage)
    }
}

// MARK: - Speed Classification

extension SpeedCalculator {
    /// Speed classifications for bowling
    enum SpeedClassification: String, CaseIterable, Sendable {
        case slow       // < 13 mph
        case belowAvg   // 13-15 mph
        case average    // 15-18 mph
        case aboveAvg   // 18-20 mph
        case fast       // 20+ mph

        var displayName: String {
            switch self {
            case .slow: return "Slow"
            case .belowAvg: return "Below Average"
            case .average: return "Average"
            case .aboveAvg: return "Above Average"
            case .fast: return "Fast"
            }
        }

        var range: ClosedRange<Double> {
            switch self {
            case .slow: return 0...13
            case .belowAvg: return 13...15
            case .average: return 15...18
            case .aboveAvg: return 18...20
            case .fast: return 20...50
            }
        }

        static func from(speedMPH: Double) -> SpeedClassification {
            switch speedMPH {
            case ..<13: return .slow
            case 13..<15: return .belowAvg
            case 15..<18: return .average
            case 18..<20: return .aboveAvg
            default: return .fast
            }
        }
    }

    /// Classify ball speed
    func classifySpeed(_ speedMPH: Double) -> SpeedClassification {
        SpeedClassification.from(speedMPH: speedMPH)
    }

    /// Get optimal speed range for strike potential
    static var optimalSpeedRange: ClosedRange<Double> {
        16...18
    }

    /// Check if speed is in optimal range
    func isOptimalSpeed(_ speedMPH: Double) -> Bool {
        Self.optimalSpeedRange.contains(speedMPH)
    }
}
