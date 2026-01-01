//
//  ShotEntity.swift
//  BowlerTrax
//
//  SwiftData entity for individual shots
//

import Foundation
import SwiftData

@Model
final class ShotEntity {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var shotNumber: Int
    var timestamp: Date
    var frameNumber: Int?
    var isFirstBall: Bool

    // Speed metrics
    var launchSpeed: Double?
    var impactSpeed: Double?

    // Position metrics
    var foulLineBoard: Double?
    var arrowBoard: Double?
    var breakpointBoard: Double?
    var breakpointDistance: Double?
    var pocketBoard: Double?
    var pocketOffset: Double?

    // Angle metrics
    var entryAngle: Double?
    var launchAngle: Double?

    // Rev rate
    var revRate: Double?
    var revCategory: String?

    // Result
    var result: String?
    var pinsLeftData: Data?  // JSON encoded [Int]
    var strikeProbability: Double?
    var predictedLeave: String?

    // Video reference
    var videoPath: String?
    var thumbnailPath: String?

    // Trajectory stored separately
    var trajectoryData: Data?  // JSON encoded [TrajectoryPoint]

    var createdAt: Date

    var session: SessionEntity?

    /// Default initializer required by SwiftData
    init() {
        self.id = UUID()
        self.sessionId = UUID()
        self.shotNumber = 1
        self.timestamp = Date()
        self.isFirstBall = true
        self.createdAt = Date()
    }

    init(from shot: Shot) {
        self.id = shot.id
        self.sessionId = shot.sessionId
        self.shotNumber = shot.shotNumber
        self.timestamp = shot.timestamp
        self.frameNumber = shot.frameNumber
        self.isFirstBall = shot.isFirstBall
        self.launchSpeed = shot.launchSpeed
        self.impactSpeed = shot.impactSpeed
        self.foulLineBoard = shot.foulLineBoard
        self.arrowBoard = shot.arrowBoard
        self.breakpointBoard = shot.breakpointBoard
        self.breakpointDistance = shot.breakpointDistance
        self.pocketBoard = shot.pocketBoard
        self.pocketOffset = shot.pocketOffset
        self.entryAngle = shot.entryAngle
        self.launchAngle = shot.launchAngle
        self.revRate = shot.revRate
        self.revCategory = shot.revCategory?.rawValue
        self.result = shot.result?.rawValue
        self.pinsLeftData = try? JSONEncoder().encode(shot.pinsLeft)
        self.strikeProbability = shot.strikeProbability
        self.predictedLeave = shot.predictedLeave?.rawValue
        self.videoPath = shot.videoPath
        self.thumbnailPath = shot.thumbnailPath
        self.trajectoryData = try? JSONEncoder().encode(shot.trajectory)
        self.createdAt = shot.createdAt
    }

    func toModel() -> Shot {
        let pinsLeft: [Int]? = pinsLeftData.flatMap { try? JSONDecoder().decode([Int].self, from: $0) }
        let trajectory: [TrajectoryPoint]? = trajectoryData.flatMap { try? JSONDecoder().decode([TrajectoryPoint].self, from: $0) }

        return Shot(
            id: id,
            sessionId: sessionId,
            shotNumber: shotNumber,
            timestamp: timestamp,
            frameNumber: frameNumber,
            isFirstBall: isFirstBall,
            launchSpeed: launchSpeed,
            impactSpeed: impactSpeed,
            foulLineBoard: foulLineBoard,
            arrowBoard: arrowBoard,
            breakpointBoard: breakpointBoard,
            breakpointDistance: breakpointDistance,
            pocketBoard: pocketBoard,
            pocketOffset: pocketOffset,
            entryAngle: entryAngle,
            launchAngle: launchAngle,
            revRate: revRate,
            revCategory: revCategory.flatMap { RevCategory(rawValue: $0) },
            result: result.flatMap { ShotResult(rawValue: $0) },
            pinsLeft: pinsLeft,
            strikeProbability: strikeProbability,
            predictedLeave: predictedLeave.flatMap { PredictedLeave(rawValue: $0) },
            videoPath: videoPath,
            thumbnailPath: thumbnailPath,
            trajectory: trajectory,
            createdAt: createdAt
        )
    }

    /// Update entity from domain model
    func update(from shot: Shot) {
        self.frameNumber = shot.frameNumber
        self.isFirstBall = shot.isFirstBall
        self.launchSpeed = shot.launchSpeed
        self.impactSpeed = shot.impactSpeed
        self.foulLineBoard = shot.foulLineBoard
        self.arrowBoard = shot.arrowBoard
        self.breakpointBoard = shot.breakpointBoard
        self.breakpointDistance = shot.breakpointDistance
        self.pocketBoard = shot.pocketBoard
        self.pocketOffset = shot.pocketOffset
        self.entryAngle = shot.entryAngle
        self.launchAngle = shot.launchAngle
        self.revRate = shot.revRate
        self.revCategory = shot.revCategory?.rawValue
        self.result = shot.result?.rawValue
        self.pinsLeftData = try? JSONEncoder().encode(shot.pinsLeft)
        self.strikeProbability = shot.strikeProbability
        self.predictedLeave = shot.predictedLeave?.rawValue
        self.videoPath = shot.videoPath
        self.thumbnailPath = shot.thumbnailPath
        self.trajectoryData = try? JSONEncoder().encode(shot.trajectory)
    }

    /// Check if shot has video
    var hasVideo: Bool {
        videoPath != nil
    }

    /// Check if shot was a strike
    var isStrike: Bool {
        result == ShotResult.strike.rawValue
    }

    /// Check if shot was a spare
    var isSpare: Bool {
        result == ShotResult.spare.rawValue
    }
}
