//
//  Shot.swift
//  BowlerTrax
//
//  Individual shot with all tracked metrics
//

import Foundation

/// Individual shot with all tracked metrics
struct Shot: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let sessionId: UUID
    var shotNumber: Int
    let timestamp: Date
    var frameNumber: Int?
    var isFirstBall: Bool

    // Speed metrics
    var launchSpeed: Double?          // Launch speed off hand (mph)
    var impactSpeed: Double?          // Speed at pins (mph)

    // Position metrics (in boards)
    var foulLineBoard: Double?        // Board at foul line
    var arrowBoard: Double?           // Board crossed at arrows (15ft)
    var breakpointBoard: Double?      // Where ball starts hooking
    var breakpointDistance: Double?   // Distance to breakpoint (feet)
    var pocketBoard: Double?          // Board position at pins
    var pocketOffset: Double?         // Distance from ideal 17.5/22.5 board

    // Angle metrics
    var entryAngle: Double?           // Angle into pocket (optimal: 6 degrees)
    var launchAngle: Double?          // Angle at release

    // Rev rate
    var revRate: Double?              // Revolutions per minute
    var revCategory: RevCategory?     // stroker/tweener/cranker

    // Result
    var result: ShotResult?
    var pinsLeft: [Int]?              // Array of remaining pins (1-10)
    var strikeProbability: Double?    // 0-1 probability
    var predictedLeave: PredictedLeave?

    // Video reference
    var videoPath: String?
    var thumbnailPath: String?

    // Raw trajectory data (not persisted to DB, computed on load)
    var trajectory: [TrajectoryPoint]?

    let createdAt: Date

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        shotNumber: Int,
        timestamp: Date = Date(),
        frameNumber: Int? = nil,
        isFirstBall: Bool = true,
        launchSpeed: Double? = nil,
        impactSpeed: Double? = nil,
        foulLineBoard: Double? = nil,
        arrowBoard: Double? = nil,
        breakpointBoard: Double? = nil,
        breakpointDistance: Double? = nil,
        pocketBoard: Double? = nil,
        pocketOffset: Double? = nil,
        entryAngle: Double? = nil,
        launchAngle: Double? = nil,
        revRate: Double? = nil,
        revCategory: RevCategory? = nil,
        result: ShotResult? = nil,
        pinsLeft: [Int]? = nil,
        strikeProbability: Double? = nil,
        predictedLeave: PredictedLeave? = nil,
        videoPath: String? = nil,
        thumbnailPath: String? = nil,
        trajectory: [TrajectoryPoint]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.shotNumber = shotNumber
        self.timestamp = timestamp
        self.frameNumber = frameNumber
        self.isFirstBall = isFirstBall
        self.launchSpeed = launchSpeed
        self.impactSpeed = impactSpeed
        self.foulLineBoard = foulLineBoard
        self.arrowBoard = arrowBoard
        self.breakpointBoard = breakpointBoard
        self.breakpointDistance = breakpointDistance
        self.pocketBoard = pocketBoard
        self.pocketOffset = pocketOffset
        self.entryAngle = entryAngle
        self.launchAngle = launchAngle
        self.revRate = revRate
        self.revCategory = revCategory
        self.result = result
        self.pinsLeft = pinsLeft
        self.strikeProbability = strikeProbability
        self.predictedLeave = predictedLeave
        self.videoPath = videoPath
        self.thumbnailPath = thumbnailPath
        self.trajectory = trajectory
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties

extension Shot {
    /// Check if shot has complete metrics
    var isComplete: Bool {
        launchSpeed != nil && entryAngle != nil && result != nil
    }

    /// Check if shot has trajectory data
    var hasTrajectory: Bool {
        guard let trajectory = trajectory else { return false }
        return !trajectory.isEmpty
    }

    /// Formatted speed string
    var speedDisplay: String? {
        guard let speed = launchSpeed else { return nil }
        return String(format: "%.1f mph", speed)
    }

    /// Formatted rev rate string
    var revRateDisplay: String? {
        guard let rpm = revRate else { return nil }
        return String(format: "%.0f RPM", rpm)
    }

    /// Formatted entry angle string
    var entryAngleDisplay: String? {
        guard let angle = entryAngle else { return nil }
        return String(format: "%.1f°", angle)
    }

    /// Formatted strike probability string
    var strikeProbabilityDisplay: String? {
        guard let prob = strikeProbability else { return nil }
        return String(format: "%.0f%%", prob * 100)
    }
}

// MARK: - Mutating Methods

extension Shot {
    /// Calculate rev category from rev rate
    mutating func calculateRevCategory() {
        guard let rpm = revRate else {
            revCategory = nil
            return
        }
        revCategory = RevCategory.from(rpm: rpm)
    }

    /// Calculate pocket offset based on hand preference
    mutating func calculatePocketOffset(hand: HandPreference) {
        guard let pocketBoard = pocketBoard else {
            pocketOffset = nil
            return
        }
        pocketOffset = abs(pocketBoard - hand.pocketBoard)
    }

    /// Calculate strike probability based on current metrics
    mutating func calculateStrikeProbability(hand: HandPreference) {
        guard let entryAngle = entryAngle else {
            strikeProbability = nil
            return
        }

        let pocketOff = pocketOffset ?? 0
        let speed = launchSpeed ?? 17.0

        // Optimal: 6 degrees, 0 offset, 16-18 mph
        let angleFactor = 1.0 - abs(entryAngle - 6.0) / 10.0
        let pocketFactor = 1.0 - pocketOff / 3.0
        let speedFactor = 1.0 - abs(speed - 17.0) / 10.0

        strikeProbability = max(0, min(1, (angleFactor * 0.5) + (pocketFactor * 0.35) + (speedFactor * 0.15)))
    }
}
