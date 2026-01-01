//
//  CVErrors.swift
//  BowlerTrax
//
//  Error types for the Computer Vision pipeline including ball detection,
//  trajectory tracking, and contour detection.
//

import Foundation
import os.log

// MARK: - CV Logger

/// Logger for CV pipeline errors and diagnostics
enum CVLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.bowlertrax"

    static let ballDetection = Logger(subsystem: subsystem, category: "BallDetection")
    static let trajectoryTracking = Logger(subsystem: subsystem, category: "TrajectoryTracking")
    static let contourDetection = Logger(subsystem: subsystem, category: "ContourDetection")
    static let frameProcessing = Logger(subsystem: subsystem, category: "FrameProcessing")
}

// MARK: - Ball Detection Errors

/// Errors that can occur during ball detection
enum BallDetectionError: Error, LocalizedError, Sendable {
    /// Failed to generate color mask from frame
    case maskGenerationFailed

    /// Vision framework contour detection failed
    case contourDetectionFailed(underlying: Error?)

    /// No circular contours found in mask
    case noContoursFound

    /// Detection confidence too low
    case lowConfidence(confidence: Double, threshold: Double)

    /// Invalid pixel buffer format
    case invalidPixelBuffer

    /// Marker detection failed (for rev rate tracking)
    case markerDetectionFailed(underlying: Error?)

    var errorDescription: String? {
        switch self {
        case .maskGenerationFailed:
            return "Failed to generate color mask from camera frame"
        case .contourDetectionFailed(let error):
            if let underlying = error {
                return "Contour detection failed: \(underlying.localizedDescription)"
            }
            return "Vision framework contour detection failed"
        case .noContoursFound:
            return "No circular contours found matching ball color"
        case .lowConfidence(let confidence, let threshold):
            return String(format: "Detection confidence %.1f%% below threshold %.1f%%",
                         confidence * 100, threshold * 100)
        case .invalidPixelBuffer:
            return "Invalid pixel buffer format for processing"
        case .markerDetectionFailed(let error):
            if let underlying = error {
                return "Marker detection failed: \(underlying.localizedDescription)"
            }
            return "Failed to detect ball marker for rev rate tracking"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .maskGenerationFailed:
            return "Ensure the ball color is correctly configured"
        case .contourDetectionFailed:
            return "Try repositioning the camera or adjusting lighting"
        case .noContoursFound:
            return "Verify ball color selection matches your bowling ball"
        case .lowConfidence:
            return "Improve lighting or move camera closer to the lane"
        case .invalidPixelBuffer:
            return "Restart the camera session"
        case .markerDetectionFailed:
            return "Ensure the PAP marker is visible on the ball"
        }
    }
}

// MARK: - Trajectory Tracking Errors

/// Errors that can occur during trajectory tracking
enum TrajectoryTrackingError: Error, LocalizedError, Sendable {
    /// Ball lost for too many consecutive frames
    case ballLostTooLong(consecutiveFrames: Int, maxAllowed: Int)

    /// Insufficient trajectory points for valid shot
    case insufficientPoints(collected: Int, minimum: Int)

    /// Shot did not travel far enough
    case insufficientDistance(distanceFeet: Double, minimumFeet: Double)

    /// Kalman filter prediction failed
    case predictionFailed

    /// Calibration required but not available
    case calibrationRequired

    /// Invalid detection data received
    case invalidDetectionData

    /// Trajectory analysis failed
    case analysisError(reason: String)

    var errorDescription: String? {
        switch self {
        case .ballLostTooLong(let frames, let max):
            return "Ball tracking lost for \(frames) frames (maximum: \(max))"
        case .insufficientPoints(let collected, let minimum):
            return "Only \(collected) trajectory points collected (minimum: \(minimum))"
        case .insufficientDistance(let distance, let minimum):
            return String(format: "Ball traveled only %.1f feet (minimum: %.1f feet)",
                         distance, minimum)
        case .predictionFailed:
            return "Failed to predict ball position during occlusion"
        case .calibrationRequired:
            return "Lane calibration is required for accurate tracking"
        case .invalidDetectionData:
            return "Received invalid detection data from ball detector"
        case .analysisError(let reason):
            return "Trajectory analysis failed: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .ballLostTooLong:
            return "Ensure the ball remains visible throughout the shot"
        case .insufficientPoints:
            return "Wait for the ball to travel further down the lane"
        case .insufficientDistance:
            return "The shot was too short - throw a complete shot"
        case .predictionFailed:
            return "Ensure consistent camera positioning"
        case .calibrationRequired:
            return "Complete the lane calibration wizard"
        case .invalidDetectionData:
            return "Try resetting the recording session"
        case .analysisError:
            return "Try recording the shot again"
        }
    }
}

// MARK: - Contour Detection Errors

/// Errors that can occur during contour detection
enum ContourDetectionError: Error, LocalizedError, Sendable {
    /// Vision framework request failed
    case visionRequestFailed(underlying: Error)

    /// No contours found in image
    case noContoursDetected

    /// Image format not supported
    case unsupportedImageFormat

    /// Metal device not available for GPU acceleration
    case metalDeviceUnavailable

    var errorDescription: String? {
        switch self {
        case .visionRequestFailed(let error):
            return "Vision contour request failed: \(error.localizedDescription)"
        case .noContoursDetected:
            return "No contours detected in the image"
        case .unsupportedImageFormat:
            return "Image format is not supported for contour detection"
        case .metalDeviceUnavailable:
            return "GPU acceleration unavailable - using CPU fallback"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .visionRequestFailed:
            return "Ensure the image is valid and try again"
        case .noContoursDetected:
            return "Adjust color tolerance or ball color selection"
        case .unsupportedImageFormat:
            return "Ensure camera is configured correctly"
        case .metalDeviceUnavailable:
            return "Processing may be slower without GPU"
        }
    }
}

// MARK: - Frame Processing Errors

/// Errors that can occur during frame processing
enum FrameProcessingError: Error, LocalizedError, Sendable {
    /// Processing pipeline not configured
    case notConfigured

    /// Ball detection failed
    case ballDetection(BallDetectionError)

    /// Trajectory tracking failed
    case trajectoryTracking(TrajectoryTrackingError)

    /// Physics calculation failed
    case physicsCalculation(reason: String)

    /// Frame dropped due to processing overload
    case frameDropped(queueDepth: Int)

    /// Delegate not set
    case delegateNotSet

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Frame processor has not been configured"
        case .ballDetection(let error):
            return error.errorDescription
        case .trajectoryTracking(let error):
            return error.errorDescription
        case .physicsCalculation(let reason):
            return "Physics calculation failed: \(reason)"
        case .frameDropped(let depth):
            return "Frame dropped (queue depth: \(depth))"
        case .delegateNotSet:
            return "Frame processor delegate not configured"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notConfigured:
            return "Call startProcessing() to begin frame processing"
        case .ballDetection(let error):
            return error.recoverySuggestion
        case .trajectoryTracking(let error):
            return error.recoverySuggestion
        case .physicsCalculation:
            return "Ensure calibration is complete"
        case .frameDropped:
            return "Processing is overloaded - some frames may be skipped"
        case .delegateNotSet:
            return "Set a delegate to receive processing results"
        }
    }

    var underlyingError: Error? {
        switch self {
        case .ballDetection(let error):
            return error
        case .trajectoryTracking(let error):
            return error
        default:
            return nil
        }
    }
}

// MARK: - Error Extensions

extension BallDetectionError: Equatable {
    static func == (lhs: BallDetectionError, rhs: BallDetectionError) -> Bool {
        switch (lhs, rhs) {
        case (.maskGenerationFailed, .maskGenerationFailed),
             (.noContoursFound, .noContoursFound),
             (.invalidPixelBuffer, .invalidPixelBuffer):
            return true
        case (.lowConfidence(let lConf, let lThresh), .lowConfidence(let rConf, let rThresh)):
            return lConf == rConf && lThresh == rThresh
        case (.contourDetectionFailed, .contourDetectionFailed),
             (.markerDetectionFailed, .markerDetectionFailed):
            // Cannot compare underlying errors, consider equal by case
            return true
        default:
            return false
        }
    }
}

extension TrajectoryTrackingError: Equatable {
    static func == (lhs: TrajectoryTrackingError, rhs: TrajectoryTrackingError) -> Bool {
        switch (lhs, rhs) {
        case (.ballLostTooLong(let lFrames, let lMax), .ballLostTooLong(let rFrames, let rMax)):
            return lFrames == rFrames && lMax == rMax
        case (.insufficientPoints(let lColl, let lMin), .insufficientPoints(let rColl, let rMin)):
            return lColl == rColl && lMin == rMin
        case (.insufficientDistance(let lDist, let lMin), .insufficientDistance(let rDist, let rMin)):
            return lDist == rDist && lMin == rMin
        case (.predictionFailed, .predictionFailed),
             (.calibrationRequired, .calibrationRequired),
             (.invalidDetectionData, .invalidDetectionData):
            return true
        case (.analysisError(let lReason), .analysisError(let rReason)):
            return lReason == rReason
        default:
            return false
        }
    }
}
