//
//  TrajectoryPoint.swift
//  BowlerTrax
//
//  Single point in ball trajectory
//

import Foundation

/// Single point in ball trajectory
struct TrajectoryPoint: Codable, Equatable, Sendable {
    var x: Double              // Pixel X
    var y: Double              // Pixel Y
    var timestamp: TimeInterval // Seconds from shot start
    var frameNumber: Int       // Frame index
    var board: Double?         // Calculated board number (1-39)
    var distanceFt: Double?    // Calculated distance from foul line
    var phase: BallPhase?      // Current motion phase

    // Real-world coordinates (after calibration)
    var realWorldX: Double?    // Board position
    var realWorldY: Double?    // Distance from foul line in feet

    init(
        x: Double,
        y: Double,
        timestamp: TimeInterval,
        frameNumber: Int,
        board: Double? = nil,
        distanceFt: Double? = nil,
        phase: BallPhase? = nil,
        realWorldX: Double? = nil,
        realWorldY: Double? = nil
    ) {
        self.x = x
        self.y = y
        self.timestamp = timestamp
        self.frameNumber = frameNumber
        self.board = board
        self.distanceFt = distanceFt
        self.phase = phase
        self.realWorldX = realWorldX
        self.realWorldY = realWorldY
    }
}

// MARK: - Computed Properties

extension TrajectoryPoint {
    /// Check if real-world coordinates are available
    var hasRealWorldCoordinates: Bool {
        realWorldX != nil && realWorldY != nil
    }

    /// Distance from another point in pixels
    func pixelDistance(to other: TrajectoryPoint) -> Double {
        let dx = other.x - x
        let dy = other.y - y
        return sqrt(dx * dx + dy * dy)
    }

    /// Time elapsed since another point
    func timeElapsed(since other: TrajectoryPoint) -> TimeInterval {
        timestamp - other.timestamp
    }
}
