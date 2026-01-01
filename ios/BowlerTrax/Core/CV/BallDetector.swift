//
//  BallDetector.swift
//  BowlerTrax
//
//  Full ball detection pipeline combining color masking, contour detection,
//  and circularity filtering to detect bowling balls in camera frames.
//

import CoreVideo
import CoreImage
import Vision
import UIKit

// MARK: - Ball Detection Result

/// Result of ball detection in a single frame
struct BallDetectionResult: Sendable {
    /// Whether a ball was detected
    let detected: Bool

    /// Ball center in normalized coordinates (0-1)
    let centroid: CGPoint?

    /// Ball center in pixel coordinates
    let pixelPosition: CGPoint?

    /// Ball radius in normalized coordinates
    let radiusNormalized: Double?

    /// Ball radius in pixels
    let radiusPixels: Double?

    /// Detection confidence (0-1)
    let confidence: Double

    /// Frame timestamp
    let timestamp: TimeInterval

    /// Sequential frame number
    let frameNumber: Int

    /// Marker angle for rev rate tracking (if detected)
    let markerAngle: Double?

    /// Static not-found result
    static func notFound(timestamp: TimeInterval, frameNumber: Int) -> BallDetectionResult {
        BallDetectionResult(
            detected: false,
            centroid: nil,
            pixelPosition: nil,
            radiusNormalized: nil,
            radiusPixels: nil,
            confidence: 0,
            timestamp: timestamp,
            frameNumber: frameNumber,
            markerAngle: nil
        )
    }
}

// MARK: - Ball Detector Configuration

/// Configuration for the ball detector
struct BallDetectorConfiguration: Sendable {
    /// Target ball color
    var targetColor: HSVColor

    /// Color matching tolerance
    var tolerance: ColorTolerance

    /// Minimum confidence threshold to report detection
    var minimumConfidence: Double

    /// Whether to detect PAP marker for rev rate
    var detectMarker: Bool

    /// Marker color (if detecting)
    var markerColor: HSVColor?

    static let `default` = BallDetectorConfiguration(
        targetColor: HSVColor(h: 220, s: 80, v: 80), // Blue ball
        tolerance: .default,
        minimumConfidence: 0.4,
        detectMarker: false,
        markerColor: nil
    )
}

// MARK: - Ball Detector

/// Main ball detection class orchestrating the CV pipeline
final class BallDetector: @unchecked Sendable {
    // MARK: - Properties

    private let colorMaskGenerator: ColorMaskGenerator
    private let contourDetector: ContourDetector
    private var configuration: BallDetectorConfiguration

    // Tracking state
    private var previousDetection: BallDetectionResult?
    private var frameCount: Int = 0

    // Performance monitoring
    private var lastProcessingTime: TimeInterval = 0

    // Frame dimensions cache
    private var lastFrameWidth: CGFloat = 0
    private var lastFrameHeight: CGFloat = 0

    // MARK: - Initialization

    init(configuration: BallDetectorConfiguration = .default) {
        self.configuration = configuration
        self.colorMaskGenerator = ColorMaskGenerator(
            targetColor: configuration.targetColor,
            tolerance: configuration.tolerance
        )
        self.contourDetector = ContourDetector()
    }

    // MARK: - Configuration

    /// Update target ball color
    func updateTargetColor(_ color: HSVColor) {
        configuration.targetColor = color
        colorMaskGenerator.updateTargetColor(color)
    }

    /// Update color tolerance
    func updateTolerance(_ tolerance: ColorTolerance) {
        configuration.tolerance = tolerance
        colorMaskGenerator.updateTolerance(tolerance)
    }

    /// Update full configuration
    func updateConfiguration(_ config: BallDetectorConfiguration) {
        self.configuration = config
        colorMaskGenerator.updateTargetColor(config.targetColor)
        colorMaskGenerator.updateTolerance(config.tolerance)
    }

    /// Reset tracking state
    func reset() {
        previousDetection = nil
        frameCount = 0
    }

    // MARK: - Detection

    /// Detect ball in pixel buffer
    /// - Parameters:
    ///   - pixelBuffer: Input camera frame (BGRA format)
    ///   - timestamp: Frame timestamp
    /// - Returns: Ball detection result
    func detectBall(
        in pixelBuffer: CVPixelBuffer,
        timestamp: TimeInterval
    ) async throws -> BallDetectionResult {
        // Check for task cancellation early
        try Task.checkCancellation()

        let startTime = CACurrentMediaTime()
        frameCount += 1

        // Cache frame dimensions
        lastFrameWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        lastFrameHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        // Step 1: Generate color mask
        guard let mask = colorMaskGenerator.generateCleanedMask(from: pixelBuffer) else {
            return .notFound(timestamp: timestamp, frameNumber: frameCount)
        }

        // Check for cancellation before expensive contour detection
        try Task.checkCancellation()

        // Step 2: Detect circular contours
        let candidates = try await contourDetector.detectCircularContours(in: mask)

        // Step 3: Select best candidate
        let previousPosition = previousDetection?.centroid
        guard let bestCandidate = contourDetector.selectBestCandidate(
            from: candidates,
            previousPosition: previousPosition
        ) else {
            previousDetection = nil
            return .notFound(timestamp: timestamp, frameNumber: frameCount)
        }

        // Step 4: Calculate confidence
        let confidence = calculateConfidence(
            metrics: bestCandidate,
            previousDetection: previousDetection
        )

        // Check minimum confidence
        guard confidence >= configuration.minimumConfidence else {
            return .notFound(timestamp: timestamp, frameNumber: frameCount)
        }

        // Step 5: Convert to pixel coordinates
        let pixelPosition = CGPoint(
            x: bestCandidate.centroid.x * lastFrameWidth,
            y: (1 - bestCandidate.centroid.y) * lastFrameHeight  // Flip Y
        )

        // Calculate radius
        let radiusNormalized = sqrt(bestCandidate.area / .pi)
        let radiusPixels = radiusNormalized * min(lastFrameWidth, lastFrameHeight)

        // Check for cancellation before optional marker detection
        try Task.checkCancellation()

        // Step 6: Detect marker angle (optional)
        var markerAngle: Double? = nil
        if configuration.detectMarker, let markerColor = configuration.markerColor {
            markerAngle = try await detectMarkerAngle(
                in: pixelBuffer,
                ballCenter: pixelPosition,
                ballRadius: radiusPixels,
                markerColor: markerColor
            )
        }

        // Create result
        let result = BallDetectionResult(
            detected: true,
            centroid: bestCandidate.centroid,
            pixelPosition: pixelPosition,
            radiusNormalized: radiusNormalized,
            radiusPixels: radiusPixels,
            confidence: confidence,
            timestamp: timestamp,
            frameNumber: frameCount,
            markerAngle: markerAngle
        )

        // Update tracking state
        previousDetection = result
        lastProcessingTime = CACurrentMediaTime() - startTime

        return result
    }

    /// Synchronous detection for use in frame callback
    func detectBallSync(
        in pixelBuffer: CVPixelBuffer,
        timestamp: TimeInterval
    ) -> BallDetectionResult {
        let startTime = CACurrentMediaTime()
        frameCount += 1

        // Cache frame dimensions
        lastFrameWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        lastFrameHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        // Step 1: Generate color mask
        guard let mask = colorMaskGenerator.generateCleanedMask(from: pixelBuffer) else {
            return .notFound(timestamp: timestamp, frameNumber: frameCount)
        }

        // Step 2: Detect contours synchronously (no semaphore needed)
        let candidates: [ContourMetrics]
        do {
            candidates = try contourDetector.detectCircularContoursSync(in: mask)
        } catch {
            // Log Vision framework errors for diagnostics instead of silently ignoring
            CVLogger.ballDetection.warning(
                "Contour detection failed in frame \(self.frameCount): \(error.localizedDescription)"
            )
            return .notFound(timestamp: timestamp, frameNumber: frameCount)
        }

        // Step 3: Select best candidate
        let previousPosition = previousDetection?.centroid
        guard let bestCandidate = contourDetector.selectBestCandidate(
            from: candidates,
            previousPosition: previousPosition
        ) else {
            previousDetection = nil
            return .notFound(timestamp: timestamp, frameNumber: frameCount)
        }

        // Step 4: Calculate confidence
        let confidence = calculateConfidence(
            metrics: bestCandidate,
            previousDetection: previousDetection
        )

        // Check minimum confidence
        guard confidence >= configuration.minimumConfidence else {
            return .notFound(timestamp: timestamp, frameNumber: frameCount)
        }

        // Step 5: Convert to pixel coordinates
        let pixelPosition = CGPoint(
            x: bestCandidate.centroid.x * lastFrameWidth,
            y: (1 - bestCandidate.centroid.y) * lastFrameHeight
        )

        let radiusNormalized = sqrt(bestCandidate.area / .pi)
        let radiusPixels = radiusNormalized * min(lastFrameWidth, lastFrameHeight)

        // Create result
        let result = BallDetectionResult(
            detected: true,
            centroid: bestCandidate.centroid,
            pixelPosition: pixelPosition,
            radiusNormalized: radiusNormalized,
            radiusPixels: radiusPixels,
            confidence: confidence,
            timestamp: timestamp,
            frameNumber: frameCount,
            markerAngle: nil  // Skip marker detection in sync mode
        )

        previousDetection = result
        lastProcessingTime = CACurrentMediaTime() - startTime

        return result
    }

    // MARK: - Confidence Calculation

    /// Calculate detection confidence based on multiple factors
    private func calculateConfidence(
        metrics: ContourMetrics,
        previousDetection: BallDetectionResult?
    ) -> Double {
        var confidence: Double = 0

        // Factor 1: Circularity (max 0.4)
        // Higher circularity = more likely a ball
        confidence += min(metrics.circularity, 1.0) * 0.4

        // Factor 2: Size appropriateness (max 0.3)
        // Penalize too small or too large
        let idealArea: Double = 0.01  // ~1% of frame
        let sizeRatio = min(metrics.area / idealArea, idealArea / max(metrics.area, 0.0001))
        confidence += sizeRatio * 0.3

        // Factor 3: Temporal consistency (max 0.3)
        // If detection is near previous position, more confident
        if let previous = previousDetection, let prevCentroid = previous.centroid {
            let dist = hypot(
                Double(metrics.centroid.x - prevCentroid.x),
                Double(metrics.centroid.y - prevCentroid.y)
            )
            // Expected max movement per frame at 120fps with 25mph ball
            let maxExpectedMovement: Double = 0.02  // ~2% of frame
            if dist < maxExpectedMovement {
                confidence += (1 - dist / maxExpectedMovement) * 0.3
            }
        }

        return min(confidence, 1.0)
    }

    // MARK: - Marker Detection

    /// Detect PAP marker angle for rev rate tracking
    private func detectMarkerAngle(
        in pixelBuffer: CVPixelBuffer,
        ballCenter: CGPoint,
        ballRadius: Double,
        markerColor: HSVColor
    ) async throws -> Double? {
        // Check for cancellation
        try Task.checkCancellation()

        // Create marker color mask generator
        let markerMaskGen = ColorMaskGenerator(
            targetColor: markerColor,
            tolerance: ColorTolerance(
                hueTolerance: 10.0,
                saturationTolerance: 0.3,
                valueTolerance: 0.4
            )
        )

        // Generate mask for marker
        let inputImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Crop to ball region with padding
        let padding = ballRadius * 0.2
        let cropRect = CGRect(
            x: ballCenter.x - ballRadius - padding,
            y: lastFrameHeight - ballCenter.y - ballRadius - padding,  // Flip Y for CIImage
            width: (ballRadius + padding) * 2,
            height: (ballRadius + padding) * 2
        )

        let croppedImage = inputImage.cropped(to: cropRect)

        guard let markerMask = markerMaskGen.generateMask(from: croppedImage) else {
            return nil
        }

        // Detect contours in marker mask
        let markerContours = try await contourDetector.detectContours(in: markerMask)

        // Find the marker (should be small and within ball bounds)
        let markerCandidates = markerContours.compactMap { contour -> CGPoint? in
            let bounds = contour.normalizedPath.boundingBox
            let area = bounds.width * bounds.height

            // Marker should be small relative to ball
            guard area > 0.0001 && area < 0.1 else { return nil }

            return contour.normalizedCentroid
        }

        guard let markerPosition = markerCandidates.first else {
            return nil
        }

        // Calculate angle from ball center to marker
        let relativeBallCenter = CGPoint(x: 0.5, y: 0.5)  // Center of cropped region
        let dx = markerPosition.x - relativeBallCenter.x
        let dy = markerPosition.y - relativeBallCenter.y
        let angle = atan2(Double(dy), Double(dx)) * 180 / .pi

        return angle
    }

    // MARK: - Performance

    /// Get last frame processing time in milliseconds
    var processingTimeMs: Double {
        lastProcessingTime * 1000
    }

    /// Check if processing is meeting 120fps budget (8.33ms)
    var isMeetingFrameBudget: Bool {
        lastProcessingTime < 0.00833
    }

    /// Current frame count
    var currentFrameCount: Int {
        frameCount
    }
}

// MARK: - Ball Detector Factory

extension BallDetector {
    /// Create detector configured for common ball colors
    static func forBallColor(_ preset: ColorMaskGenerator.BallColorPreset) -> BallDetector {
        let config = BallDetectorConfiguration(
            targetColor: preset.hsvColor,
            tolerance: preset.recommendedTolerance,
            minimumConfidence: 0.4,
            detectMarker: false,
            markerColor: nil
        )
        return BallDetector(configuration: config)
    }

    /// Create detector with marker tracking enabled
    static func withMarkerTracking(
        ballColor: HSVColor,
        markerColor: HSVColor
    ) -> BallDetector {
        let config = BallDetectorConfiguration(
            targetColor: ballColor,
            tolerance: .default,
            minimumConfidence: 0.4,
            detectMarker: true,
            markerColor: markerColor
        )
        return BallDetector(configuration: config)
    }
}

// MARK: - BallDetectionResult to BallDetection Conversion

extension BallDetectionResult {
    /// Convert to domain model BallDetection
    func toBallDetection() -> BallDetection {
        if detected, let x = pixelPosition?.x, let y = pixelPosition?.y, let radius = radiusPixels {
            return BallDetection.detected(
                x: Double(x),
                y: Double(y),
                radius: radius,
                confidence: confidence,
                markerAngle: markerAngle
            )
        } else {
            return .notFound
        }
    }
}
