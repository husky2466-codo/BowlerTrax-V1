//
//  AngleCalculator.swift
//  BowlerTrax
//
//  Calculates entry angle at the pins from trajectory data.
//  Entry angle is critical for strike probability - optimal is ~6 degrees.
//

import Foundation

// MARK: - Entry Angle Result

/// Result of entry angle calculation
struct EntryAngleResult: Sendable {
    /// Entry angle in degrees
    let angleDegrees: Double

    /// Whether angle is in optimal range (4-7 degrees)
    let isOptimal: Bool

    /// Direction of entry (left or right of center)
    let direction: EntryDirection

    /// Recommendation for adjustment
    let recommendation: String

    /// Predicted pocket board position
    let pocketBoard: Double?

    /// Confidence in the measurement (0-1)
    let confidence: Double

    enum EntryDirection: Sendable {
        case left       // Ball entering from right side (right-handed)
        case right      // Ball entering from left side (left-handed)
        case straight   // Very low angle
    }
}

// MARK: - Angle Calculator

/// Calculates entry angle and related metrics
final class AngleCalculator: @unchecked Sendable {
    // MARK: - Constants

    /// Optimal entry angle range (degrees)
    static let optimalMin: Double = 4.0
    static let optimalMax: Double = 7.0
    static let perfectAngle: Double = 6.0

    /// Board width in feet
    static let boardWidthFeet: Double = 1.0641 / 12.0

    /// Lane length in feet
    static let laneLengthFeet: Double = 60.0

    /// Distance to analyze for entry angle (last N feet)
    static let entryZoneDistance: Double = 5.0

    // MARK: - Calculation Methods

    /// Calculate entry angle from trajectory
    /// - Parameters:
    ///   - trajectory: Array of trajectory points
    ///   - handPreference: Bowler's hand preference (for direction interpretation)
    /// - Returns: Entry angle result or nil if insufficient data
    func calculateEntryAngle(
        from trajectory: [TrajectoryPoint],
        handPreference: HandPreference = .right
    ) -> EntryAngleResult? {
        // Get last segment of trajectory (55-60 feet)
        let finalPoints = trajectory.filter { point in
            guard let dist = point.distanceFt else { return false }
            return dist >= (Self.laneLengthFeet - Self.entryZoneDistance) && dist <= Self.laneLengthFeet
        }

        guard finalPoints.count >= 2 else {
            // Try with available points near end
            return calculateFromLastPoints(trajectory, handPreference: handPreference)
        }

        // Sort by distance
        let sorted = finalPoints.sorted { ($0.distanceFt ?? 0) < ($1.distanceFt ?? 0) }

        return calculateAngle(from: sorted, handPreference: handPreference)
    }

    /// Calculate launch angle at foul line
    /// - Parameter trajectory: Array of trajectory points
    /// - Returns: Launch angle in degrees or nil
    func calculateLaunchAngle(from trajectory: [TrajectoryPoint]) -> Double? {
        // Get first segment (0-10 feet)
        let launchPoints = trajectory.filter { point in
            guard let dist = point.distanceFt else { return false }
            return dist >= 0 && dist <= 10
        }

        guard launchPoints.count >= 2 else { return nil }

        let sorted = launchPoints.sorted { ($0.distanceFt ?? 0) < ($1.distanceFt ?? 0) }

        guard let first = sorted.first, let last = sorted.last,
              let startBoard = first.board, let endBoard = last.board,
              let startDist = first.distanceFt, let endDist = last.distanceFt else {
            return nil
        }

        // Calculate lateral movement
        let lateralFeet = (endBoard - startBoard) * Self.boardWidthFeet

        // Forward distance
        let forwardFeet = endDist - startDist
        guard forwardFeet > 0 else { return nil }

        // Angle = arctan(lateral / forward)
        let angleRadians = atan(abs(lateralFeet) / forwardFeet)
        return angleRadians * 180 / .pi
    }

    /// Calculate angle change between two segments
    /// - Parameters:
    ///   - trajectory: Full trajectory
    ///   - fromFeet: Start of first segment
    ///   - midFeet: Division point
    ///   - toFeet: End of second segment
    /// - Returns: Angle change in degrees (positive = increasing hook)
    func calculateAngleChange(
        trajectory: [TrajectoryPoint],
        fromFeet: Double,
        midFeet: Double,
        toFeet: Double
    ) -> Double? {
        // Get angle for first segment
        let firstSegment = trajectory.filter { ($0.distanceFt ?? 0) >= fromFeet && ($0.distanceFt ?? 0) <= midFeet }
        guard let angle1 = calculateAngleForSegment(firstSegment) else { return nil }

        // Get angle for second segment
        let secondSegment = trajectory.filter { ($0.distanceFt ?? 0) >= midFeet && ($0.distanceFt ?? 0) <= toFeet }
        guard let angle2 = calculateAngleForSegment(secondSegment) else { return nil }

        return angle2 - angle1
    }

    // MARK: - Private Methods

    /// Calculate angle from sorted trajectory segment
    private func calculateAngle(
        from sorted: [TrajectoryPoint],
        handPreference: HandPreference
    ) -> EntryAngleResult? {
        guard let first = sorted.first, let last = sorted.last,
              let startBoard = first.board, let endBoard = last.board,
              let startDist = first.distanceFt, let endDist = last.distanceFt else {
            return nil
        }

        // Calculate lateral movement (in feet)
        let lateralBoards = endBoard - startBoard
        let lateralFeet = lateralBoards * Self.boardWidthFeet

        // Calculate forward distance
        let forwardFeet = endDist - startDist
        guard forwardFeet > 0 else { return nil }

        // Entry angle = arctan(lateral / forward)
        let angleRadians = atan(abs(lateralFeet) / forwardFeet)
        let angleDegrees = angleRadians * 180 / .pi

        // Determine if optimal
        let isOptimal = angleDegrees >= Self.optimalMin && angleDegrees <= Self.optimalMax

        // Determine direction based on lateral movement and hand preference
        let direction: EntryAngleResult.EntryDirection
        if abs(lateralBoards) < 0.5 {
            direction = .straight
        } else if (handPreference == .right && lateralBoards < 0) ||
                  (handPreference == .left && lateralBoards > 0) {
            direction = .left
        } else {
            direction = .right
        }

        // Generate recommendation
        let recommendation = generateRecommendation(
            angle: angleDegrees,
            isOptimal: isOptimal,
            handPreference: handPreference
        )

        // Extrapolate pocket entry point
        let pocketBoard = extrapolateToPins(trajectory: sorted, targetDistance: Self.laneLengthFeet)

        // Calculate confidence based on segment quality
        let confidence = calculateConfidence(points: sorted, forwardDist: forwardFeet)

        return EntryAngleResult(
            angleDegrees: angleDegrees,
            isOptimal: isOptimal,
            direction: direction,
            recommendation: recommendation,
            pocketBoard: pocketBoard,
            confidence: confidence
        )
    }

    /// Calculate angle for a segment of trajectory
    private func calculateAngleForSegment(_ segment: [TrajectoryPoint]) -> Double? {
        guard segment.count >= 2 else { return nil }

        let sorted = segment.sorted { ($0.distanceFt ?? 0) < ($1.distanceFt ?? 0) }

        guard let first = sorted.first, let last = sorted.last,
              let startBoard = first.board, let endBoard = last.board,
              let startDist = first.distanceFt, let endDist = last.distanceFt else {
            return nil
        }

        let lateralFeet = (endBoard - startBoard) * Self.boardWidthFeet
        let forwardFeet = endDist - startDist

        guard forwardFeet > 0 else { return nil }

        let angleRadians = atan(abs(lateralFeet) / forwardFeet)
        return angleRadians * 180 / .pi
    }

    /// Fallback: Calculate from last available points
    private func calculateFromLastPoints(
        _ trajectory: [TrajectoryPoint],
        handPreference: HandPreference
    ) -> EntryAngleResult? {
        let calibrated = trajectory.filter { $0.distanceFt != nil && $0.board != nil }
        guard calibrated.count >= 5 else { return nil }

        // Use last 5 points
        let lastPoints = Array(calibrated.suffix(5))
        return calculateAngle(from: lastPoints, handPreference: handPreference)
    }

    /// Extrapolate board position at pins
    private func extrapolateToPins(
        trajectory: [TrajectoryPoint],
        targetDistance: Double
    ) -> Double? {
        guard trajectory.count >= 2 else { return nil }

        // Linear extrapolation from last two points
        let last = trajectory[trajectory.count - 1]
        let prev = trajectory[trajectory.count - 2]

        guard let lastBoard = last.board, let prevBoard = prev.board,
              let lastDist = last.distanceFt, let prevDist = prev.distanceFt else {
            return nil
        }

        let distDiff = lastDist - prevDist
        guard distDiff > 0 else { return nil }

        let boardsPerFoot = (lastBoard - prevBoard) / distDiff
        let remainingFeet = targetDistance - lastDist

        return lastBoard + boardsPerFoot * remainingFeet
    }

    /// Generate recommendation based on angle
    private func generateRecommendation(
        angle: Double,
        isOptimal: Bool,
        handPreference: HandPreference
    ) -> String {
        if isOptimal {
            return "Optimal entry angle (\(String(format: "%.1f", angle)) degrees). Good pocket entry."
        } else if angle < Self.optimalMin {
            let target = handPreference == .right ? "left" : "right"
            return "Angle too flat (\(String(format: "%.1f", angle)) degrees). Increase hand rotation or move target \(target)."
        } else {
            return "Angle too steep (\(String(format: "%.1f", angle)) degrees). Risk of splits. Reduce hand rotation."
        }
    }

    /// Calculate confidence score
    private func calculateConfidence(
        points: [TrajectoryPoint],
        forwardDist: Double
    ) -> Double {
        var confidence: Double = 0.3

        // More points = more confident (up to 0.4)
        let pointScore = min(Double(points.count) / 10.0, 1.0) * 0.4
        confidence += pointScore

        // Longer measurement distance = more confident (up to 0.3)
        let distScore = min(forwardDist / 5.0, 1.0) * 0.3
        confidence += distScore

        return min(confidence, 1.0)
    }
}

// MARK: - Angle Analysis Extensions

extension AngleCalculator {
    /// Analyze angle progression through trajectory
    /// - Parameters:
    ///   - trajectory: Full trajectory
    ///   - intervalFeet: Distance between measurements
    /// - Returns: Array of angle measurements at intervals
    func analyzeAngleProgression(
        trajectory: [TrajectoryPoint],
        intervalFeet: Double = 10.0
    ) -> [AngleMeasurement] {
        var measurements: [AngleMeasurement] = []

        let calibrated = trajectory.filter { $0.distanceFt != nil && $0.board != nil }
            .sorted { ($0.distanceFt ?? 0) < ($1.distanceFt ?? 0) }

        guard calibrated.count >= 2 else { return measurements }

        let endDist = calibrated.last?.distanceFt ?? 60

        var currentDist = intervalFeet

        while currentDist < endDist - intervalFeet {
            let segment = calibrated.filter {
                let dist = $0.distanceFt ?? 0
                return dist >= currentDist - intervalFeet / 2 && dist <= currentDist + intervalFeet / 2
            }

            if let angle = calculateAngleForSegment(segment) {
                measurements.append(AngleMeasurement(
                    distanceFeet: currentDist,
                    angleDegrees: angle
                ))
            }

            currentDist += intervalFeet
        }

        return measurements
    }

    /// Identify the hook phase (where ball starts curving)
    /// - Parameter trajectory: Full trajectory
    /// - Returns: Tuple of (start distance, peak angle)
    func identifyHookPhase(from trajectory: [TrajectoryPoint]) -> (startFeet: Double, peakAngle: Double)? {
        let angles = analyzeAngleProgression(trajectory: trajectory, intervalFeet: 5.0)

        guard angles.count >= 3 else { return nil }

        // Find where angle starts increasing significantly
        var maxAngleChange: Double = 0
        var hookStartIndex: Int = 0

        for i in 1..<angles.count {
            let change = angles[i].angleDegrees - angles[i - 1].angleDegrees
            if change > maxAngleChange {
                maxAngleChange = change
                hookStartIndex = i - 1
            }
        }

        guard hookStartIndex < angles.count else { return nil }

        // Find the peak angle in the hook phase
        let hookPhaseAngles = angles.suffix(from: hookStartIndex)
        guard let peakMeasurement = hookPhaseAngles.max(by: { $0.angleDegrees < $1.angleDegrees }) else {
            return nil
        }

        return (angles[hookStartIndex].distanceFeet, peakMeasurement.angleDegrees)
    }
}

// MARK: - Supporting Types

/// Angle measurement at a specific distance
struct AngleMeasurement: Sendable {
    let distanceFeet: Double
    let angleDegrees: Double
}

// MARK: - Entry Angle Classification

extension AngleCalculator {
    /// Entry angle classifications
    enum AngleClassification: String, CaseIterable, Sendable {
        case tooFlat    // < 4 degrees
        case slightFlat // 4-5 degrees
        case optimal    // 5-7 degrees
        case slightSteep // 7-8 degrees
        case tooSteep   // > 8 degrees

        var displayName: String {
            switch self {
            case .tooFlat: return "Too Flat"
            case .slightFlat: return "Slightly Flat"
            case .optimal: return "Optimal"
            case .slightSteep: return "Slightly Steep"
            case .tooSteep: return "Too Steep"
            }
        }

        var range: ClosedRange<Double> {
            switch self {
            case .tooFlat: return 0...4
            case .slightFlat: return 4...5
            case .optimal: return 5...7
            case .slightSteep: return 7...8
            case .tooSteep: return 8...90
            }
        }

        var strikeImpact: String {
            switch self {
            case .tooFlat: return "High risk of leaving corner pins (7 or 10)"
            case .slightFlat: return "May leave weak 10-pin"
            case .optimal: return "Best strike potential"
            case .slightSteep: return "May leave weak 7-pin or split"
            case .tooSteep: return "High risk of splits"
            }
        }

        static func from(angle: Double) -> AngleClassification {
            switch angle {
            case ..<4: return .tooFlat
            case 4..<5: return .slightFlat
            case 5..<7: return .optimal
            case 7..<8: return .slightSteep
            default: return .tooSteep
            }
        }
    }

    /// Classify entry angle
    func classifyAngle(_ angleDegrees: Double) -> AngleClassification {
        AngleClassification.from(angle: angleDegrees)
    }
}
