//
//  BallDetection.swift
//  BowlerTrax
//
//  Ball detection result from a single frame
//

import Foundation

/// Ball detection result from a single frame
struct BallDetection: Codable, Equatable, Sendable {
    var found: Bool
    var x: Double?
    var y: Double?
    var radius: Double?
    var confidence: Double       // 0-1 how confident the detection is
    var markerAngle: Double?     // Rotation angle of PAP marker (for rev rate)

    static let notFound = BallDetection(found: false, confidence: 0)

    init(
        found: Bool,
        x: Double? = nil,
        y: Double? = nil,
        radius: Double? = nil,
        confidence: Double,
        markerAngle: Double? = nil
    ) {
        self.found = found
        self.x = x
        self.y = y
        self.radius = radius
        self.confidence = confidence
        self.markerAngle = markerAngle
    }
}

// MARK: - Computed Properties

extension BallDetection {
    /// Check if detection has valid position data
    var hasPosition: Bool {
        found && x != nil && y != nil
    }

    /// Check if detection has marker angle for rev tracking
    var hasMarkerAngle: Bool {
        markerAngle != nil
    }

    /// Check if detection is high confidence (above threshold)
    var isHighConfidence: Bool {
        confidence >= 0.7
    }

    /// Position as CGPoint (if available)
    var position: CGPoint? {
        guard let x = x, let y = y else { return nil }
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Factory Methods

extension BallDetection {
    /// Create a detection with position and confidence
    static func detected(
        x: Double,
        y: Double,
        radius: Double,
        confidence: Double,
        markerAngle: Double? = nil
    ) -> BallDetection {
        BallDetection(
            found: true,
            x: x,
            y: y,
            radius: radius,
            confidence: confidence,
            markerAngle: markerAngle
        )
    }
}
