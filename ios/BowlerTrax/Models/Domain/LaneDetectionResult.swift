//
//  LaneDetectionResult.swift
//  BowlerTrax
//
//  Result model for smart lane detection using computer vision.
//  Contains detected lane features including gutters, foul line, and arrows.
//

import Foundation
import CoreGraphics

// MARK: - Lane Detection Result

/// Result of lane detection analysis from camera frames
struct LaneDetectionResult: Sendable, Equatable {
    // MARK: - Detected Features

    /// Left lane edge/gutter line points (in normalized coordinates 0-1)
    var leftGutterLine: [CGPoint]?

    /// Right lane edge/gutter line points (in normalized coordinates 0-1)
    var rightGutterLine: [CGPoint]?

    /// Foul line endpoints (in normalized coordinates 0-1)
    var foulLine: LineSeg?

    /// Detected arrow positions
    var arrowPositions: [ArrowDetection]?

    /// Overall detection confidence (0-1)
    var confidence: Double

    /// Bounding rectangle of detected lane (in normalized coordinates)
    var laneRectangle: CGRect?

    /// Estimated perspective vanishing point
    var vanishingPoint: CGPoint?

    /// Timestamp of detection
    var timestamp: Date

    // MARK: - Computed Properties

    /// Whether all critical features were detected
    var isComplete: Bool {
        leftGutterLine != nil &&
        rightGutterLine != nil &&
        foulLine != nil &&
        (arrowPositions?.count ?? 0) >= 2
    }

    /// Whether detection has minimum usable data
    var isUsable: Bool {
        foulLine != nil && confidence >= 0.5
    }

    /// Number of arrows detected
    var arrowCount: Int {
        arrowPositions?.count ?? 0
    }

    /// Estimated lane width at foul line (in normalized coordinates)
    var estimatedLaneWidth: Double? {
        guard let left = leftGutterLine?.last,
              let right = rightGutterLine?.last else { return nil }
        return Double(abs(right.x - left.x))
    }

    // MARK: - Initialization

    init(
        leftGutterLine: [CGPoint]? = nil,
        rightGutterLine: [CGPoint]? = nil,
        foulLine: LineSeg? = nil,
        arrowPositions: [ArrowDetection]? = nil,
        confidence: Double = 0,
        laneRectangle: CGRect? = nil,
        vanishingPoint: CGPoint? = nil,
        timestamp: Date = Date()
    ) {
        self.leftGutterLine = leftGutterLine
        self.rightGutterLine = rightGutterLine
        self.foulLine = foulLine
        self.arrowPositions = arrowPositions
        self.confidence = confidence
        self.laneRectangle = laneRectangle
        self.vanishingPoint = vanishingPoint
        self.timestamp = timestamp
    }

    /// Empty result (no detections)
    static let empty = LaneDetectionResult(confidence: 0)

    // MARK: - Conversion Methods

    /// Convert all positions from normalized to pixel coordinates
    func toPixelCoordinates(width: CGFloat, height: CGFloat) -> LaneDetectionResult {
        var result = self

        result.leftGutterLine = leftGutterLine?.map { point in
            CGPoint(x: point.x * width, y: point.y * height)
        }

        result.rightGutterLine = rightGutterLine?.map { point in
            CGPoint(x: point.x * width, y: point.y * height)
        }

        if let foul = foulLine {
            result.foulLine = LineSeg(
                start: CGPoint(x: foul.start.x * width, y: foul.start.y * height),
                end: CGPoint(x: foul.end.x * width, y: foul.end.y * height)
            )
        }

        result.arrowPositions = arrowPositions?.map { arrow in
            var newArrow = arrow
            newArrow.position = CGPoint(
                x: arrow.position.x * width,
                y: arrow.position.y * height
            )
            return newArrow
        }

        if let rect = laneRectangle {
            result.laneRectangle = CGRect(
                x: rect.origin.x * width,
                y: rect.origin.y * height,
                width: rect.width * width,
                height: rect.height * height
            )
        }

        if let vp = vanishingPoint {
            result.vanishingPoint = CGPoint(x: vp.x * width, y: vp.y * height)
        }

        return result
    }
}

// MARK: - Line Segment

/// A line segment with start and end points
struct LineSeg: Sendable, Equatable {
    var start: CGPoint
    var end: CGPoint

    /// Length of the line segment
    var length: Double {
        hypot(Double(end.x - start.x), Double(end.y - start.y))
    }

    /// Midpoint of the line segment
    var midpoint: CGPoint {
        CGPoint(
            x: (start.x + end.x) / 2,
            y: (start.y + end.y) / 2
        )
    }

    /// Angle of the line in radians
    var angle: Double {
        atan2(Double(end.y - start.y), Double(end.x - start.x))
    }

    /// Angle in degrees
    var angleDegrees: Double {
        angle * 180.0 / .pi
    }

    /// Check if line is approximately horizontal (within threshold degrees)
    func isHorizontal(threshold: Double = 15) -> Bool {
        let deg = abs(angleDegrees)
        return deg < threshold || deg > (180 - threshold)
    }

    /// Check if line is approximately vertical (within threshold degrees)
    func isVertical(threshold: Double = 15) -> Bool {
        let deg = abs(angleDegrees - 90)
        return deg < threshold
    }
}

// MARK: - Arrow Detection

/// Individual arrow detection result
struct ArrowDetection: Sendable, Equatable, Identifiable {
    var id: UUID = UUID()

    /// Position in image coordinates (normalized 0-1 or pixels depending on context)
    var position: CGPoint

    /// Estimated board number (5, 10, 15, 20, 25, 30, or 35)
    var boardNumber: Int

    /// Detection confidence (0-1)
    var confidence: Double

    /// Shape confidence - how triangular the detected shape is
    var shapeConfidence: Double

    // MARK: - Computed Properties

    /// Whether this is a valid arrow board number
    var isValidBoard: Bool {
        ArrowPoint.standardBoards.contains(boardNumber)
    }

    /// Arrow number (1-7) based on board number
    var arrowNumber: Int {
        switch boardNumber {
        case 5: return 1
        case 10: return 2
        case 15: return 3
        case 20: return 4
        case 25: return 5
        case 30: return 6
        case 35: return 7
        default: return 0
        }
    }

    // MARK: - Initialization

    init(
        position: CGPoint,
        boardNumber: Int,
        confidence: Double,
        shapeConfidence: Double = 0
    ) {
        self.position = position
        self.boardNumber = boardNumber
        self.confidence = confidence
        self.shapeConfidence = shapeConfidence
    }

    /// Convert to ArrowPoint for calibration
    func toArrowPoint() -> ArrowPoint {
        ArrowPoint(
            arrowNumber: arrowNumber,
            pixelX: Double(position.x),
            pixelY: Double(position.y),
            boardNumber: boardNumber
        )
    }
}

// MARK: - Detection State

/// State of the lane detection process
enum LaneDetectionState: Sendable, Equatable {
    case idle
    case detecting
    case analyzing(progress: Double)
    case completed(result: LaneDetectionResult)
    case failed(error: LaneDetectionError)

    var isProcessing: Bool {
        switch self {
        case .detecting, .analyzing:
            return true
        default:
            return false
        }
    }

    var progress: Double {
        switch self {
        case .analyzing(let p): return p
        case .completed: return 1.0
        default: return 0
        }
    }
}

// MARK: - Detection Error

/// Errors that can occur during lane detection
enum LaneDetectionError: Error, LocalizedError, Sendable, Equatable {
    case cameraNotAvailable
    case insufficientLighting
    case laneNotVisible
    case foulLineNotFound
    case arrowsNotFound
    case analysisTimeout
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available for lane detection"
        case .insufficientLighting:
            return "Lighting is too low for accurate detection"
        case .laneNotVisible:
            return "Could not detect bowling lane in frame"
        case .foulLineNotFound:
            return "Could not locate the foul line"
        case .arrowsNotFound:
            return "Could not detect arrow markers"
        case .analysisTimeout:
            return "Analysis took too long"
        case .processingFailed(let reason):
            return "Detection failed: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .cameraNotAvailable:
            return "Ensure camera permissions are granted"
        case .insufficientLighting:
            return "Move to a better lit position or wait for lanes to brighten"
        case .laneNotVisible:
            return "Position the camera to show the full lane width"
        case .foulLineNotFound:
            return "Ensure the foul line is visible in the camera view"
        case .arrowsNotFound:
            return "Position camera to clearly show the arrow markers"
        case .analysisTimeout:
            return "Try again with a clearer view of the lane"
        case .processingFailed:
            return "Try repositioning the camera and retry"
        }
    }
}

// MARK: - Detection Configuration

/// Configuration for lane detection sensitivity and behavior
struct LaneDetectionConfiguration: Sendable {
    /// Minimum confidence to accept a detection
    var minimumConfidence: Double

    /// Number of frames to analyze
    var framesToAnalyze: Int

    /// Timeout for detection in seconds
    var timeoutSeconds: Double

    /// Edge detection sensitivity (0-1)
    var edgeSensitivity: Double

    /// Line detection minimum length (normalized 0-1)
    var minLineLength: Double

    /// Whether to detect arrows
    var detectArrows: Bool

    /// Arrow shape detection sensitivity
    var arrowSensitivity: Double

    static let `default` = LaneDetectionConfiguration(
        minimumConfidence: 0.6,
        framesToAnalyze: 30,
        timeoutSeconds: 5.0,
        edgeSensitivity: 0.5,
        minLineLength: 0.3,
        detectArrows: true,
        arrowSensitivity: 0.5
    )

    static let sensitive = LaneDetectionConfiguration(
        minimumConfidence: 0.4,
        framesToAnalyze: 45,
        timeoutSeconds: 8.0,
        edgeSensitivity: 0.7,
        minLineLength: 0.2,
        detectArrows: true,
        arrowSensitivity: 0.7
    )

    static let fast = LaneDetectionConfiguration(
        minimumConfidence: 0.7,
        framesToAnalyze: 15,
        timeoutSeconds: 3.0,
        edgeSensitivity: 0.4,
        minLineLength: 0.4,
        detectArrows: true,
        arrowSensitivity: 0.4
    )
}
