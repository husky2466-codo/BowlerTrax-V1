//
//  StrikeProbability.swift
//  BowlerTrax
//
//  Calculates strike probability based on entry metrics.
//  Uses pocket position, entry angle, speed, and rev rate to predict outcome.
//

import Foundation

// MARK: - Strike Probability Result

/// Result of strike probability calculation
struct StrikeProbabilityResult: Sendable {
    /// Overall probability (0-1)
    let probability: Double

    /// Percentage string for display
    var percentageString: String {
        String(format: "%.0f%%", probability * 100)
    }

    /// Individual factor scores
    let factors: StrikeFactors

    /// Predicted leave if not a strike
    let predictedLeave: LeaveType

    /// Recommendation for improvement
    let recommendation: String?

    /// Risk assessment
    let riskLevel: RiskLevel

    enum RiskLevel: String, Sendable {
        case low
        case medium
        case high

        var displayName: String {
            rawValue.capitalized
        }
    }
}

/// Individual factors contributing to strike probability
struct StrikeFactors: Sendable {
    /// Pocket accuracy score (0-1)
    let pocketScore: Double

    /// Entry angle score (0-1)
    let angleScore: Double

    /// Speed score (0-1)
    let speedScore: Double

    /// Rev rate score (0-1)
    let revScore: Double

    /// Factor weights used in calculation
    static let weights = (pocket: 0.40, angle: 0.30, speed: 0.15, rev: 0.15)
}

/// Types of leaves (pins remaining after first ball)
enum LeaveType: String, CaseIterable, Sendable {
    case strike = "Strike"
    case tenPin = "10-pin"
    case sevenPin = "7-pin"
    case fourPin = "4-pin"
    case sixPin = "6-pin"
    case split = "Split"
    case bucket = "Bucket"
    case washout = "Washout"
    case mixedLeave = "Mixed leave"
    case gutterBall = "Gutter"

    var difficulty: Int {
        switch self {
        case .strike: return 0
        case .tenPin, .sevenPin: return 1
        case .fourPin, .sixPin: return 2
        case .bucket, .washout: return 3
        case .mixedLeave: return 4
        case .split: return 5
        case .gutterBall: return 10
        }
    }

    var isConvertible: Bool {
        difficulty <= 3
    }

    var description: String {
        switch self {
        case .strike: return "All pins down"
        case .tenPin: return "Corner pin (right-handed)"
        case .sevenPin: return "Corner pin (left-handed)"
        case .fourPin: return "Front corner pin (right)"
        case .sixPin: return "Front corner pin (left)"
        case .split: return "Gap between remaining pins"
        case .bucket: return "2-4-5-8 or 3-5-6-9 cluster"
        case .washout: return "Headpin standing with corner"
        case .mixedLeave: return "Multiple pins remaining"
        case .gutterBall: return "Ball in gutter"
        }
    }
}

// MARK: - Strike Probability Calculator

/// Calculates strike probability from shot metrics
final class StrikeProbabilityCalculator: @unchecked Sendable {
    // MARK: - Constants

    /// Ideal pocket board for right-handed bowler
    static let idealPocketBoardRight: Double = 17.5

    /// Ideal pocket board for left-handed bowler
    static let idealPocketBoardLeft: Double = 22.5

    /// Ideal entry angle (degrees)
    static let idealEntryAngle: Double = 6.0

    /// Ideal speed range (mph)
    static let idealSpeedMin: Double = 16.0
    static let idealSpeedMax: Double = 18.0

    /// Ideal rev rate range (rpm)
    static let idealRevMin: Double = 300.0
    static let idealRevMax: Double = 450.0

    // MARK: - Calculation

    /// Calculate strike probability from shot metrics
    /// - Parameters:
    ///   - pocketBoard: Board position at pins
    ///   - entryAngle: Entry angle in degrees
    ///   - speedMPH: Ball speed at impact
    ///   - revRPM: Rev rate (optional)
    ///   - handPreference: Bowler's hand preference
    /// - Returns: Strike probability result
    func calculateProbability(
        pocketBoard: Double,
        entryAngle: Double,
        speedMPH: Double,
        revRPM: Double? = nil,
        handPreference: HandPreference = .right
    ) -> StrikeProbabilityResult {
        // Determine target pocket
        let targetPocket = handPreference == .right ? Self.idealPocketBoardRight : Self.idealPocketBoardLeft

        // Calculate individual factor scores
        let pocketScore = calculatePocketScore(pocketBoard: pocketBoard, targetPocket: targetPocket)
        let angleScore = calculateAngleScore(entryAngle: entryAngle)
        let speedScore = calculateSpeedScore(speedMPH: speedMPH)
        let revScore = calculateRevScore(revRPM: revRPM)

        let factors = StrikeFactors(
            pocketScore: pocketScore,
            angleScore: angleScore,
            speedScore: speedScore,
            revScore: revScore
        )

        // Calculate weighted probability
        let probability =
            pocketScore * StrikeFactors.weights.pocket +
            angleScore * StrikeFactors.weights.angle +
            speedScore * StrikeFactors.weights.speed +
            revScore * StrikeFactors.weights.rev

        // Predict leave type
        let predictedLeave = predictLeave(
            pocketBoard: pocketBoard,
            entryAngle: entryAngle,
            targetPocket: targetPocket,
            handPreference: handPreference
        )

        // Generate recommendation
        let recommendation = generateRecommendation(
            factors: factors,
            pocketBoard: pocketBoard,
            entryAngle: entryAngle,
            speedMPH: speedMPH,
            handPreference: handPreference
        )

        // Assess risk level
        let riskLevel = assessRiskLevel(factors: factors, entryAngle: entryAngle)

        return StrikeProbabilityResult(
            probability: probability,
            factors: factors,
            predictedLeave: predictedLeave,
            recommendation: recommendation,
            riskLevel: riskLevel
        )
    }

    /// Quick probability calculation with minimal inputs
    func quickProbability(
        pocketOffset: Double,
        entryAngle: Double,
        speedMPH: Double
    ) -> Double {
        // Simplified formula from project spec
        let angleFactor = 1.0 - abs(entryAngle - 6.0) / 10.0
        let pocketFactor = 1.0 - abs(pocketOffset) / 3.0
        let speedFactor = 1.0 - abs(speedMPH - 17.0) / 10.0

        return max(0, min(1, (angleFactor * 0.5) + (pocketFactor * 0.35) + (speedFactor * 0.15)))
    }

    // MARK: - Factor Calculations

    /// Calculate pocket accuracy score
    private func calculatePocketScore(pocketBoard: Double, targetPocket: Double) -> Double {
        let offset = abs(pocketBoard - targetPocket)

        // 0 offset = 1.0 score, 3+ boards off = 0.0
        return max(0, 1 - (offset / 3.0))
    }

    /// Calculate entry angle score
    private func calculateAngleScore(entryAngle: Double) -> Double {
        let diff = abs(entryAngle - Self.idealEntryAngle)

        // 0 diff = 1.0 score, 4+ degrees off = 0.0
        return max(0, 1 - (diff / 4.0))
    }

    /// Calculate speed score
    private func calculateSpeedScore(speedMPH: Double) -> Double {
        if speedMPH >= Self.idealSpeedMin && speedMPH <= Self.idealSpeedMax {
            return 1.0
        } else if speedMPH < Self.idealSpeedMin {
            // Too slow
            return max(0, 1 - (Self.idealSpeedMin - speedMPH) / 4.0)
        } else {
            // Too fast
            return max(0, 1 - (speedMPH - Self.idealSpeedMax) / 4.0)
        }
    }

    /// Calculate rev rate score
    private func calculateRevScore(revRPM: Double?) -> Double {
        guard let rpm = revRPM else {
            return 0.7  // Neutral score if unknown
        }

        if rpm >= Self.idealRevMin && rpm <= Self.idealRevMax {
            return 1.0
        } else if rpm < Self.idealRevMin {
            // Low revs - less pin action
            return max(0.5, rpm / Self.idealRevMin)
        } else {
            // High revs - can cause over-hook but more pin action
            return max(0.7, 1 - (rpm - Self.idealRevMax) / 200)
        }
    }

    // MARK: - Leave Prediction

    /// Predict likely leave based on entry metrics
    private func predictLeave(
        pocketBoard: Double,
        entryAngle: Double,
        targetPocket: Double,
        handPreference: HandPreference
    ) -> LeaveType {
        let offset = pocketBoard - targetPocket

        // High probability of strike
        if abs(offset) < 1.0 && entryAngle >= 4 && entryAngle <= 7 {
            return .strike
        }

        // Low angle = weak hit
        if entryAngle < 4 {
            if handPreference == .right {
                return offset > 0 ? .tenPin : .sevenPin
            } else {
                return offset < 0 ? .sevenPin : .tenPin
            }
        }

        // High angle = split risk
        if entryAngle > 7 {
            return .split
        }

        // Off-pocket
        if abs(offset) > 2 {
            return .mixedLeave
        }

        // Light hit
        if handPreference == .right && offset > 1 {
            return .bucket
        } else if handPreference == .left && offset < -1 {
            return .bucket
        }

        // High hit (opposite side)
        if handPreference == .right && offset < -1 {
            return .washout
        } else if handPreference == .left && offset > 1 {
            return .washout
        }

        return .mixedLeave
    }

    // MARK: - Recommendations

    /// Generate improvement recommendation
    private func generateRecommendation(
        factors: StrikeFactors,
        pocketBoard: Double,
        entryAngle: Double,
        speedMPH: Double,
        handPreference: HandPreference
    ) -> String? {
        // Find weakest factor
        let weakest: String
        let minScore = min(factors.pocketScore, factors.angleScore, factors.speedScore)

        if minScore >= 0.8 {
            return nil  // All factors good
        }

        if factors.pocketScore == minScore {
            let targetPocket = handPreference == .right ? Self.idealPocketBoardRight : Self.idealPocketBoardLeft
            let offset = pocketBoard - targetPocket
            if abs(offset) > 1 {
                let direction = offset > 0 ? "left" : "right"
                weakest = "Adjust target \(direction) to hit pocket"
            } else {
                weakest = "Fine-tune target line for pocket"
            }
        } else if factors.angleScore == minScore {
            if entryAngle < 4 {
                weakest = "Increase entry angle with more hand rotation"
            } else if entryAngle > 7 {
                weakest = "Reduce entry angle to avoid splits"
            } else {
                weakest = "Entry angle is marginal"
            }
        } else if factors.speedScore == minScore {
            if speedMPH < Self.idealSpeedMin {
                weakest = "Increase ball speed for better pin action"
            } else {
                weakest = "Reduce speed for better pin deflection"
            }
        } else {
            weakest = "Consider adjusting rev rate or ball surface"
        }

        return weakest
    }

    // MARK: - Risk Assessment

    /// Assess risk level of the shot
    private func assessRiskLevel(factors: StrikeFactors, entryAngle: Double) -> StrikeProbabilityResult.RiskLevel {
        // High entry angle = high split risk
        if entryAngle > 8 {
            return .high
        }

        // Very low angle = corner pin risk
        if entryAngle < 3 {
            return .high
        }

        // Check factor scores
        let avgScore = (factors.pocketScore + factors.angleScore + factors.speedScore + factors.revScore) / 4

        if avgScore >= 0.7 {
            return .low
        } else if avgScore >= 0.5 {
            return .medium
        } else {
            return .high
        }
    }
}

// MARK: - Session Statistics

extension StrikeProbabilityCalculator {
    /// Calculate session statistics from multiple shots
    func analyzeSession(probabilities: [Double]) -> SessionProbabilityStats {
        guard !probabilities.isEmpty else {
            return SessionProbabilityStats(
                average: 0,
                highest: 0,
                lowest: 0,
                trend: .stable
            )
        }

        let avg = probabilities.reduce(0, +) / Double(probabilities.count)
        let highest = probabilities.max() ?? 0
        let lowest = probabilities.min() ?? 0

        // Calculate trend from last 5 shots vs first 5
        let trend: SessionProbabilityStats.Trend
        if probabilities.count >= 10 {
            let first5Avg = probabilities.prefix(5).reduce(0, +) / 5
            let last5Avg = probabilities.suffix(5).reduce(0, +) / 5
            let diff = last5Avg - first5Avg

            if diff > 0.1 {
                trend = .improving
            } else if diff < -0.1 {
                trend = .declining
            } else {
                trend = .stable
            }
        } else {
            trend = .stable
        }

        return SessionProbabilityStats(
            average: avg,
            highest: highest,
            lowest: lowest,
            trend: trend
        )
    }
}

/// Session probability statistics
struct SessionProbabilityStats: Sendable {
    let average: Double
    let highest: Double
    let lowest: Double
    let trend: Trend

    enum Trend: String, Sendable {
        case improving
        case stable
        case declining

        var displayName: String {
            rawValue.capitalized
        }
    }

    var averagePercentage: String {
        String(format: "%.0f%%", average * 100)
    }
}

// MARK: - Pin Carry Prediction

extension StrikeProbabilityCalculator {
    /// Predict which pins will be knocked down based on entry metrics
    /// - Returns: Array of pin numbers (1-10) predicted to fall
    func predictPinCarry(
        pocketBoard: Double,
        entryAngle: Double,
        speedMPH: Double,
        revRPM: Double?,
        handPreference: HandPreference
    ) -> [Int] {
        let targetPocket = handPreference == .right ? Self.idealPocketBoardRight : Self.idealPocketBoardLeft
        let offset = pocketBoard - targetPocket

        // Perfect pocket hit
        if abs(offset) < 0.5 && entryAngle >= 5 && entryAngle <= 7 {
            return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]  // Strike
        }

        // Start with pins that will definitely fall
        var fallenPins: [Int] = []

        // Ball always hits headpin area first
        fallenPins.append(1)

        if handPreference == .right {
            // Right-handed pocket (1-3)
            if offset >= -1 {
                fallenPins.append(3)
                fallenPins.append(5)
            }
            if offset <= 1 {
                fallenPins.append(2)
                fallenPins.append(4)
            }

            // Second row
            if entryAngle >= 4 {
                if !fallenPins.contains(3) { fallenPins.append(3) }
                fallenPins.append(6)
                fallenPins.append(9)
            }
            if entryAngle >= 5 {
                fallenPins.append(8)
            }
            if offset < -1 || entryAngle < 4 {
                // Weak hit - might leave 10 pin
            } else {
                fallenPins.append(10)
            }
            if offset > 1 {
                fallenPins.append(7)
            }
        } else {
            // Left-handed pocket (1-2)
            if offset <= 1 {
                fallenPins.append(2)
                fallenPins.append(5)
            }
            if offset >= -1 {
                fallenPins.append(3)
                fallenPins.append(6)
            }

            // Second row
            if entryAngle >= 4 {
                if !fallenPins.contains(2) { fallenPins.append(2) }
                fallenPins.append(4)
                fallenPins.append(8)
            }
            if entryAngle >= 5 {
                fallenPins.append(9)
            }
            if offset > 1 || entryAngle < 4 {
                // Weak hit - might leave 7 pin
            } else {
                fallenPins.append(7)
            }
            if offset < -1 {
                fallenPins.append(10)
            }
        }

        return Array(Set(fallenPins)).sorted()
    }
}
