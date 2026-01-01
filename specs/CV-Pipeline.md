# BowlerTrax Computer Vision Pipeline Architecture

## Overview

This document specifies the native Swift computer vision pipeline for BowlerTrax, leveraging Apple's Vision framework, Core Image, and AVFoundation for real-time bowling ball tracking at 120fps on iPad M5.

---

## Table of Contents

1. [Camera Capture Pipeline](#1-camera-capture-pipeline)
2. [Ball Detection Algorithm](#2-ball-detection-algorithm)
3. [Trajectory Tracking](#3-trajectory-tracking)
4. [Rev Rate Detection](#4-rev-rate-detection)
5. [Physics Calculations](#5-physics-calculations)
6. [Performance Targets](#6-performance-targets)
7. [Calibration Math](#7-calibration-math)

---

## 1. CAMERA CAPTURE PIPELINE

### AVFoundation Setup for 120fps Capture

```swift
// MARK: - Camera Session Configuration

class BowlingCameraManager: NSObject {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.bowlertrax.cv", qos: .userInteractive)

    func configureSession() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Preset for high frame rate capture
        captureSession.sessionPreset = .inputPriority

        // Configure camera device
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: .back) else {
            throw CameraError.deviceNotFound
        }

        // Find and set 120fps format
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        let targetFPS: Float64 = 120.0
        var bestFormat: AVCaptureDevice.Format?
        var bestFrameRateRange: AVFrameRateRange?

        for format in device.formats {
            for range in format.videoSupportedFrameRateRanges {
                if range.maxFrameRate >= targetFPS {
                    // Prefer 1080p for balance of quality and performance
                    let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    if dimensions.height == 1080 {
                        bestFormat = format
                        bestFrameRateRange = range
                    }
                }
            }
        }

        if let format = bestFormat, let range = bestFrameRateRange {
            device.activeFormat = format
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFPS))
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFPS))
        }

        // Configure video output
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)

        captureSession.addOutput(videoOutput)
    }
}
```

### Frame Buffer Management Strategy

```
+------------------------------------------------------------------+
|                    FRAME BUFFER PIPELINE                          |
+------------------------------------------------------------------+
|                                                                   |
|  [Camera Sensor]                                                  |
|       |                                                           |
|       v (120 frames/sec)                                          |
|  +--------------------+                                           |
|  | CVPixelBuffer Pool |  <-- Pre-allocated pool (reduces alloc)   |
|  | (Triple Buffered)  |                                           |
|  +--------------------+                                           |
|       |                                                           |
|       v                                                           |
|  +--------------------+     +--------------------+                 |
|  | Buffer A (Current) | --> | Processing Queue   |                |
|  +--------------------+     | (Serial, User Int) |                |
|  | Buffer B (Next)    |     +--------------------+                |
|  +--------------------+           |                               |
|  | Buffer C (Ready)   |           v                               |
|  +--------------------+     +--------------------+                 |
|       ^                     | CV Pipeline        |                |
|       |                     | - Color Detection  |                |
|       +---------------------| - Position Extract |                |
|         (Recycle)           +--------------------+                |
|                                   |                               |
|                                   v                               |
|                             +--------------------+                |
|                             | Trajectory Store   |                |
|                             | (Ring Buffer 600)  |                |
|                             +--------------------+                |
+------------------------------------------------------------------+
```

**Key Buffer Management Rules:**

```swift
// Frame buffer ring for trajectory history (5 seconds at 120fps)
private let trajectoryBuffer = RingBuffer<TrackingPoint>(capacity: 600)

// Drop strategy: If processing falls behind, drop oldest frames
extension BowlingCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Log dropped frame for performance monitoring
        droppedFrameCount += 1
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Processing must complete in < 8.33ms to maintain 120fps
        let startTime = CACurrentMediaTime()

        defer {
            let processingTime = CACurrentMediaTime() - startTime
            if processingTime > 0.008 { // 8ms budget exceeded
                slowFrameCount += 1
            }
        }

        processFrame(sampleBuffer)
    }
}
```

### Resolution vs Performance Tradeoffs

| Resolution | Pixels    | Processing Time* | Accuracy | Recommendation           |
|------------|-----------|------------------|----------|--------------------------|
| 4K         | 8.3M      | ~15ms            | Highest  | Post-shot analysis only  |
| 1080p      | 2.1M      | ~5ms             | High     | **Recommended for live** |
| 720p       | 0.9M      | ~2ms             | Medium   | Fallback if thermal      |
| 540p       | 0.5M      | ~1ms             | Low      | Emergency fallback       |

*Estimated on iPad M5 Neural Engine

**Dynamic Resolution Scaling:**

```swift
enum QualityLevel: Int {
    case full = 1080
    case reduced = 720
    case minimal = 540

    var scaleFactor: CGFloat {
        switch self {
        case .full: return 1.0
        case .reduced: return 0.667
        case .minimal: return 0.5
        }
    }
}

class AdaptiveQualityManager {
    private var currentLevel: QualityLevel = .full
    private var consecutiveSlowFrames = 0

    func evaluatePerformance(frameTime: TimeInterval) {
        if frameTime > 0.0083 { // 8.33ms = 120fps budget
            consecutiveSlowFrames += 1
            if consecutiveSlowFrames > 10 {
                downgradeQuality()
            }
        } else {
            consecutiveSlowFrames = 0
        }
    }

    private func downgradeQuality() {
        switch currentLevel {
        case .full: currentLevel = .reduced
        case .reduced: currentLevel = .minimal
        case .minimal: break // Cannot go lower
        }
    }
}
```

### iPad M5 Specific Optimizations

1. **Neural Engine Acceleration:** Use VNGenerateOpticalFlowRequest for motion vectors
2. **Metal Compute Shaders:** HSV conversion on GPU via Core Image
3. **Unified Memory:** Zero-copy buffer sharing between CPU and GPU
4. **ProMotion Display:** 120Hz native = frame-perfect preview sync

```swift
// M-series optimization: Use Metal for color space conversion
let ciContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!,
                          options: [.useSoftwareRenderer: false,
                                    .priorityRequestLow: false])
```

---

## 2. BALL DETECTION ALGORITHM

### Pipeline Overview

```
+------------------------------------------------------------------+
|                    BALL DETECTION PIPELINE                        |
+------------------------------------------------------------------+
|                                                                   |
|  [Raw Frame (BGRA)]                                               |
|       |                                                           |
|       v                                                           |
|  +--------------------+                                           |
|  | Color Space Conv.  |  RGB -> HSV (Metal shader)                |
|  +--------------------+                                           |
|       |                                                           |
|       v                                                           |
|  +--------------------+                                           |
|  | Color Mask Create  |  Threshold with tolerance                 |
|  +--------------------+                                           |
|       |                                                           |
|       v                                                           |
|  +--------------------+                                           |
|  | Morphological Ops  |  Erode (noise) -> Dilate (fill)           |
|  +--------------------+                                           |
|       |                                                           |
|       v                                                           |
|  +--------------------+                                           |
|  | Contour Detection  |  VNDetectContoursRequest                  |
|  +--------------------+                                           |
|       |                                                           |
|       v                                                           |
|  +--------------------+                                           |
|  | Circularity Filter |  Keep only circular contours              |
|  +--------------------+                                           |
|       |                                                           |
|       v                                                           |
|  +--------------------+                                           |
|  | Centroid + Score   |  Calculate center, confidence             |
|  +--------------------+                                           |
|       |                                                           |
|       v                                                           |
|  [BallDetection Result]                                           |
|                                                                   |
+------------------------------------------------------------------+
```

### Step 1: Color Space Conversion (RGB to HSV)

```swift
// MARK: - HSV Conversion using Core Image

struct HSVColor {
    var hue: CGFloat        // 0-360 degrees
    var saturation: CGFloat // 0-1
    var value: CGFloat      // 0-1
    var hueTolerance: CGFloat = 15.0
    var satTolerance: CGFloat = 0.2
    var valTolerance: CGFloat = 0.3
}

class ColorSpaceConverter {
    private let ciContext: CIContext

    /// Convert RGB pixel to HSV
    func rgbToHSV(r: CGFloat, g: CGFloat, b: CGFloat) -> HSVColor {
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal

        // Calculate Value
        let v = maxVal

        // Calculate Saturation
        let s: CGFloat
        if maxVal == 0 {
            s = 0
        } else {
            s = delta / maxVal
        }

        // Calculate Hue
        var h: CGFloat = 0
        if delta != 0 {
            if maxVal == r {
                h = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
            } else if maxVal == g {
                h = 60 * (((b - r) / delta) + 2)
            } else {
                h = 60 * (((r - g) / delta) + 4)
            }
        }
        if h < 0 { h += 360 }

        return HSVColor(hue: h, saturation: s, value: v)
    }

    /// Metal-accelerated HSV conversion for entire frame
    func convertFrameToHSV(pixelBuffer: CVPixelBuffer) -> CIImage {
        let inputImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Custom CIColorKernel for RGB->HSV on GPU
        let hsvKernel = CIColorKernel(source: """
            kernel vec4 rgbToHSV(__sample s) {
                float maxVal = max(s.r, max(s.g, s.b));
                float minVal = min(s.r, min(s.g, s.b));
                float delta = maxVal - minVal;

                float h = 0.0;
                float sat = (maxVal == 0.0) ? 0.0 : delta / maxVal;
                float val = maxVal;

                if (delta != 0.0) {
                    if (maxVal == s.r) {
                        h = mod((s.g - s.b) / delta, 6.0);
                    } else if (maxVal == s.g) {
                        h = ((s.b - s.r) / delta) + 2.0;
                    } else {
                        h = ((s.r - s.g) / delta) + 4.0;
                    }
                    h *= 60.0;
                    if (h < 0.0) h += 360.0;
                }

                // Normalize h to 0-1 for storage
                return vec4(h / 360.0, sat, val, 1.0);
            }
        """)

        return hsvKernel?.apply(extent: inputImage.extent,
                                 arguments: [inputImage]) ?? inputImage
    }
}
```

### Step 2: Color Mask Creation with Tolerance

```swift
// MARK: - Color Mask Generation

class ColorMaskGenerator {
    private let targetColor: HSVColor

    init(targetColor: HSVColor) {
        self.targetColor = targetColor
    }

    /// Create binary mask of pixels matching target color
    func createMask(from hsvImage: CIImage) -> CIImage {
        // CIColorKernel for threshold masking
        let maskKernel = CIColorKernel(source: """
            kernel vec4 colorMask(__sample hsv,
                                  float targetH, float targetS, float targetV,
                                  float tolH, float tolS, float tolV) {
                // Denormalize hue from stored 0-1 to 0-360
                float h = hsv.r * 360.0;
                float s = hsv.g;
                float v = hsv.b;

                // Hue is circular, handle wraparound
                float hueDiff = abs(h - targetH);
                if (hueDiff > 180.0) hueDiff = 360.0 - hueDiff;

                // Check if within tolerance
                bool hueMatch = hueDiff <= tolH;
                bool satMatch = abs(s - targetS) <= tolS;
                bool valMatch = abs(v - targetV) <= tolV;

                if (hueMatch && satMatch && valMatch) {
                    return vec4(1.0, 1.0, 1.0, 1.0); // White = ball
                } else {
                    return vec4(0.0, 0.0, 0.0, 1.0); // Black = background
                }
            }
        """)

        return maskKernel?.apply(
            extent: hsvImage.extent,
            arguments: [
                hsvImage,
                targetColor.hue,
                targetColor.saturation,
                targetColor.value,
                targetColor.hueTolerance,
                targetColor.satTolerance,
                targetColor.valTolerance
            ]
        ) ?? hsvImage
    }
}
```

### Step 3: Morphological Operations (Erode/Dilate)

```swift
// MARK: - Morphological Operations

class MorphologyProcessor {
    /// Remove noise with erosion, then restore shape with dilation
    func cleanMask(_ mask: CIImage) -> CIImage {
        // Erosion: removes small noise spots
        let eroded = mask.applyingFilter("CIMorphologyMinimum",
                                          parameters: ["inputRadius": 2.0])

        // Dilation: restores ball shape, fills small gaps
        let dilated = eroded.applyingFilter("CIMorphologyMaximum",
                                             parameters: ["inputRadius": 3.0])

        return dilated
    }

    /// Alternative: Opening followed by Closing for better results
    func morphologicalClean(_ mask: CIImage) -> CIImage {
        // Opening: Erosion -> Dilation (removes noise)
        let opened = mask
            .applyingFilter("CIMorphologyMinimum", parameters: ["inputRadius": 2.0])
            .applyingFilter("CIMorphologyMaximum", parameters: ["inputRadius": 2.0])

        // Closing: Dilation -> Erosion (fills holes)
        let closed = opened
            .applyingFilter("CIMorphologyMaximum", parameters: ["inputRadius": 3.0])
            .applyingFilter("CIMorphologyMinimum", parameters: ["inputRadius": 3.0])

        return closed
    }
}
```

### Step 4: Contour Detection

```swift
// MARK: - Contour Detection using Vision Framework

class ContourDetector {
    /// Detect contours in binary mask
    func detectContours(in mask: CIImage) async throws -> [VNContour] {
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.0
        request.detectsDarkOnLight = false // White ball on black background
        request.maximumImageDimension = 1024 // Balance accuracy vs speed

        let handler = VNImageRequestHandler(ciImage: mask, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
            return []
        }

        // Get top-level contours (ignore nested)
        return (0..<observation.contourCount).compactMap { index in
            try? observation.contour(at: index)
        }
    }
}
```

### Step 5: Circularity Filtering

```swift
// MARK: - Circularity Analysis

struct ContourMetrics {
    let contour: VNContour
    let area: CGFloat
    let perimeter: CGFloat
    let circularity: CGFloat
    let centroid: CGPoint
    let boundingBox: CGRect
}

class CircularityFilter {
    /// Circularity = 4 * pi * Area / Perimeter^2
    /// Perfect circle = 1.0, Square = 0.785, Irregular < 0.7
    static let circularityThreshold: CGFloat = 0.65

    /// Expected ball size range in normalized coordinates (0-1)
    static let minBallArea: CGFloat = 0.001  // ~1% of frame
    static let maxBallArea: CGFloat = 0.05   // ~5% of frame

    func filterCircularContours(_ contours: [VNContour]) -> [ContourMetrics] {
        return contours.compactMap { contour -> ContourMetrics? in
            guard let path = contour.normalizedPath.copy() else { return nil }

            // Calculate area (absolute value for orientation independence)
            let area = abs(calculateSignedArea(path: path))

            // Filter by size
            guard area >= Self.minBallArea && area <= Self.maxBallArea else {
                return nil
            }

            // Calculate perimeter
            let perimeter = calculatePerimeter(path: path)
            guard perimeter > 0 else { return nil }

            // Calculate circularity
            let circularity = (4 * .pi * area) / (perimeter * perimeter)
            guard circularity >= Self.circularityThreshold else {
                return nil
            }

            // Calculate centroid
            let centroid = calculateCentroid(path: path)
            let boundingBox = path.boundingBox

            return ContourMetrics(
                contour: contour,
                area: area,
                perimeter: perimeter,
                circularity: circularity,
                centroid: centroid,
                boundingBox: boundingBox
            )
        }
    }

    private func calculateSignedArea(path: CGPath) -> CGFloat {
        var area: CGFloat = 0
        var previousPoint: CGPoint?
        var firstPoint: CGPoint?

        path.applyWithBlock { element in
            let point: CGPoint
            switch element.pointee.type {
            case .moveToPoint:
                point = element.pointee.points[0]
                firstPoint = point
            case .addLineToPoint:
                point = element.pointee.points[0]
                if let prev = previousPoint {
                    // Shoelace formula
                    area += (prev.x * point.y - point.x * prev.y)
                }
            case .closeSubpath:
                if let prev = previousPoint, let first = firstPoint {
                    area += (prev.x * first.y - first.x * prev.y)
                }
                return
            default:
                return
            }
            previousPoint = point
        }

        return area / 2.0
    }

    private func calculatePerimeter(path: CGPath) -> CGFloat {
        var perimeter: CGFloat = 0
        var previousPoint: CGPoint?

        path.applyWithBlock { element in
            guard element.pointee.type == .addLineToPoint else {
                if element.pointee.type == .moveToPoint {
                    previousPoint = element.pointee.points[0]
                }
                return
            }

            let point = element.pointee.points[0]
            if let prev = previousPoint {
                let dx = point.x - prev.x
                let dy = point.y - prev.y
                perimeter += sqrt(dx * dx + dy * dy)
            }
            previousPoint = point
        }

        return perimeter
    }

    private func calculateCentroid(path: CGPath) -> CGPoint {
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        var count: Int = 0

        path.applyWithBlock { element in
            guard element.pointee.type == .addLineToPoint ||
                  element.pointee.type == .moveToPoint else { return }

            let point = element.pointee.points[0]
            sumX += point.x
            sumY += point.y
            count += 1
        }

        guard count > 0 else { return .zero }
        return CGPoint(x: sumX / CGFloat(count), y: sumY / CGFloat(count))
    }
}
```

### Step 6: Centroid Calculation and Confidence Scoring

```swift
// MARK: - Ball Detection Result

struct BallDetection {
    let centroid: CGPoint          // Normalized 0-1 coordinates
    let pixelPosition: CGPoint     // Actual pixel coordinates
    let radiusNormalized: CGFloat  // Ball radius in normalized coords
    let radiusPixels: CGFloat      // Ball radius in pixels
    let confidence: CGFloat        // 0-1 detection confidence
    let timestamp: TimeInterval    // Frame timestamp
    let frameNumber: Int           // Sequential frame number
}

class BallDetector {
    private let colorConverter = ColorSpaceConverter()
    private let maskGenerator: ColorMaskGenerator
    private let morphology = MorphologyProcessor()
    private let contourDetector = ContourDetector()
    private let circularityFilter = CircularityFilter()

    private var previousDetection: BallDetection?
    private var frameCount = 0

    init(targetColor: HSVColor) {
        self.maskGenerator = ColorMaskGenerator(targetColor: targetColor)
    }

    func detectBall(in pixelBuffer: CVPixelBuffer,
                    timestamp: TimeInterval) async throws -> BallDetection? {
        frameCount += 1

        // Step 1: Convert to HSV
        let hsvImage = colorConverter.convertFrameToHSV(pixelBuffer: pixelBuffer)

        // Step 2: Create color mask
        let rawMask = maskGenerator.createMask(from: hsvImage)

        // Step 3: Morphological cleanup
        let cleanMask = morphology.morphologicalClean(rawMask)

        // Step 4: Detect contours
        let contours = try await contourDetector.detectContours(in: cleanMask)

        // Step 5: Filter circular contours
        let candidates = circularityFilter.filterCircularContours(contours)

        // Step 6: Select best candidate and calculate confidence
        guard let bestCandidate = selectBestCandidate(candidates) else {
            return nil
        }

        // Calculate confidence score
        let confidence = calculateConfidence(
            metrics: bestCandidate,
            previousDetection: previousDetection
        )

        // Get frame dimensions
        let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        // Convert normalized coordinates to pixels
        let pixelPosition = CGPoint(
            x: bestCandidate.centroid.x * width,
            y: (1 - bestCandidate.centroid.y) * height // Flip Y
        )

        let radiusPixels = sqrt(bestCandidate.area / .pi) * min(width, height)

        let detection = BallDetection(
            centroid: bestCandidate.centroid,
            pixelPosition: pixelPosition,
            radiusNormalized: sqrt(bestCandidate.area / .pi),
            radiusPixels: radiusPixels,
            confidence: confidence,
            timestamp: timestamp,
            frameNumber: frameCount
        )

        previousDetection = detection
        return detection
    }

    private func selectBestCandidate(_ candidates: [ContourMetrics]) -> ContourMetrics? {
        guard !candidates.isEmpty else { return nil }

        // If we have a previous detection, prefer the closest candidate
        if let previous = previousDetection {
            return candidates.min { a, b in
                let distA = distance(a.centroid, previous.centroid)
                let distB = distance(b.centroid, previous.centroid)
                return distA < distB
            }
        }

        // Otherwise, select by highest circularity
        return candidates.max { $0.circularity < $1.circularity }
    }

    private func calculateConfidence(metrics: ContourMetrics,
                                     previousDetection: BallDetection?) -> CGFloat {
        var confidence: CGFloat = 0

        // Base confidence from circularity (max 0.4)
        confidence += min(metrics.circularity, 1.0) * 0.4

        // Size confidence - penalize too small or too large (max 0.3)
        let idealArea: CGFloat = 0.01 // ~1% of frame
        let sizeRatio = min(metrics.area / idealArea, idealArea / metrics.area)
        confidence += sizeRatio * 0.3

        // Temporal consistency bonus (max 0.3)
        if let previous = previousDetection {
            let dist = distance(metrics.centroid, previous.centroid)
            // Expected max movement per frame at 120fps with 25mph ball
            let maxExpectedMovement: CGFloat = 0.02 // ~2% of frame
            if dist < maxExpectedMovement {
                confidence += (1 - dist / maxExpectedMovement) * 0.3
            }
        }

        return min(confidence, 1.0)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
}
```

---

## 3. TRAJECTORY TRACKING

### Frame-to-Frame Position Tracking

```swift
// MARK: - Trajectory Point Data Structure

struct TrajectoryPoint {
    let frameNumber: Int
    let timestamp: TimeInterval

    // Raw pixel coordinates
    let pixelX: CGFloat
    let pixelY: CGFloat

    // Normalized coordinates (0-1)
    let normalizedX: CGFloat
    let normalizedY: CGFloat

    // Calibrated real-world coordinates
    var boardNumber: CGFloat?        // 1-39 (left to right)
    var distanceFromFoul: CGFloat?   // In feet (0-60)

    // Detection quality
    let confidence: CGFloat
    let interpolated: Bool           // True if position was estimated

    // Physics (calculated after capture)
    var velocityX: CGFloat?          // feet/second
    var velocityY: CGFloat?          // feet/second
    var speed: CGFloat?              // mph
}

class TrajectoryTracker {
    private var trajectory: [TrajectoryPoint] = []
    private var calibration: LaneCalibration?

    // For tracking state
    private var isTracking = false
    private var shotStartFrame: Int?
    private var lastValidDetection: BallDetection?
    private var consecutiveMisses = 0

    // Thresholds
    private let maxConsecutiveMisses = 5
    private let shotEndDistanceThreshold: CGFloat = 55.0 // feet

    func processDetection(_ detection: BallDetection?) {
        if let detection = detection, detection.confidence > 0.5 {
            addPoint(from: detection, interpolated: false)
            lastValidDetection = detection
            consecutiveMisses = 0
        } else {
            consecutiveMisses += 1
            if consecutiveMisses <= maxConsecutiveMisses,
               let last = lastValidDetection {
                // Interpolate missing position
                let interpolated = interpolatePosition(from: last, frameCount: consecutiveMisses)
                addPoint(from: interpolated, interpolated: true)
            }
        }

        // Check for shot completion
        if let lastPoint = trajectory.last,
           let distance = lastPoint.distanceFromFoul,
           distance > shotEndDistanceThreshold {
            endShot()
        }
    }

    private func addPoint(from detection: BallDetection, interpolated: Bool) {
        var point = TrajectoryPoint(
            frameNumber: detection.frameNumber,
            timestamp: detection.timestamp,
            pixelX: detection.pixelPosition.x,
            pixelY: detection.pixelPosition.y,
            normalizedX: detection.centroid.x,
            normalizedY: detection.centroid.y,
            boardNumber: nil,
            distanceFromFoul: nil,
            confidence: detection.confidence,
            interpolated: interpolated,
            velocityX: nil,
            velocityY: nil,
            speed: nil
        )

        // Apply calibration if available
        if let cal = calibration {
            point.boardNumber = cal.pixelToBoard(x: detection.pixelPosition.x)
            point.distanceFromFoul = cal.pixelToFeet(y: detection.pixelPosition.y)
        }

        trajectory.append(point)
    }

    private func interpolatePosition(from last: BallDetection,
                                     frameCount: Int) -> BallDetection {
        // Simple linear extrapolation based on last known velocity
        // More sophisticated: use Kalman filter prediction
        guard trajectory.count >= 2 else { return last }

        let prev = trajectory[trajectory.count - 2]
        let curr = trajectory[trajectory.count - 1]

        let vx = curr.pixelX - prev.pixelX
        let vy = curr.pixelY - prev.pixelY

        let predictedX = curr.pixelX + vx * CGFloat(frameCount)
        let predictedY = curr.pixelY + vy * CGFloat(frameCount)

        return BallDetection(
            centroid: CGPoint(x: last.centroid.x + (vx / 1920) * CGFloat(frameCount),
                             y: last.centroid.y + (vy / 1080) * CGFloat(frameCount)),
            pixelPosition: CGPoint(x: predictedX, y: predictedY),
            radiusNormalized: last.radiusNormalized,
            radiusPixels: last.radiusPixels,
            confidence: max(last.confidence - 0.1 * CGFloat(frameCount), 0.1),
            timestamp: last.timestamp + Double(frameCount) / 120.0,
            frameNumber: last.frameNumber + frameCount
        )
    }

    private func endShot() {
        isTracking = false
        calculateVelocities()
        // Notify delegate or publish trajectory
    }

    private func calculateVelocities() {
        guard trajectory.count >= 2 else { return }

        for i in 1..<trajectory.count {
            let prev = trajectory[i - 1]
            let curr = trajectory[i]

            let dt = curr.timestamp - prev.timestamp
            guard dt > 0 else { continue }

            if let prevDist = prev.distanceFromFoul, let currDist = curr.distanceFromFoul,
               let prevBoard = prev.boardNumber, let currBoard = curr.boardNumber {

                // Convert board movement to feet (1 board = 1.0641 inches)
                let lateralFeet = (currBoard - prevBoard) * 1.0641 / 12.0
                let forwardFeet = currDist - prevDist

                trajectory[i].velocityX = lateralFeet / CGFloat(dt)
                trajectory[i].velocityY = forwardFeet / CGFloat(dt)

                let speedFPS = sqrt(pow(lateralFeet, 2) + pow(forwardFeet, 2)) / CGFloat(dt)
                trajectory[i].speed = speedFPS * 0.6818 // fps to mph
            }
        }
    }
}
```

### Optional Kalman Filter for Smoothing

```swift
// MARK: - Kalman Filter for Position Smoothing

struct KalmanState {
    var x: CGFloat       // Position X
    var y: CGFloat       // Position Y
    var vx: CGFloat      // Velocity X
    var vy: CGFloat      // Velocity Y
}

class KalmanFilter {
    // State estimate
    private var state: KalmanState

    // Covariance matrix (4x4 simplified as variances)
    private var P: [[CGFloat]] = [
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ]

    // Process noise
    private let Q: CGFloat = 0.1

    // Measurement noise
    private let R: CGFloat = 0.5

    // Time step (1/120 second at 120fps)
    private let dt: CGFloat = 1.0 / 120.0

    init(initialPosition: CGPoint) {
        state = KalmanState(x: initialPosition.x,
                           y: initialPosition.y,
                           vx: 0, vy: 0)
    }

    func predict() -> CGPoint {
        // State prediction: x' = x + v*dt
        state.x += state.vx * dt
        state.y += state.vy * dt

        // Covariance prediction (simplified)
        for i in 0..<4 {
            P[i][i] += Q
        }

        return CGPoint(x: state.x, y: state.y)
    }

    func update(measurement: CGPoint) -> CGPoint {
        // Kalman gain (simplified)
        let K = P[0][0] / (P[0][0] + R)

        // Innovation (measurement residual)
        let innovationX = measurement.x - state.x
        let innovationY = measurement.y - state.y

        // State update
        state.x += K * innovationX
        state.y += K * innovationY

        // Velocity update based on position change
        state.vx = (state.vx + innovationX / dt) / 2
        state.vy = (state.vy + innovationY / dt) / 2

        // Covariance update
        for i in 0..<4 {
            P[i][i] *= (1 - K)
        }

        return CGPoint(x: state.x, y: state.y)
    }

    func getPredictedPosition(framesAhead: Int) -> CGPoint {
        return CGPoint(
            x: state.x + state.vx * dt * CGFloat(framesAhead),
            y: state.y + state.vy * dt * CGFloat(framesAhead)
        )
    }
}
```

### Handling Occlusion and Lost Frames

```swift
// MARK: - Occlusion Handler

enum TrackingState {
    case searching          // Looking for ball
    case tracking           // Actively tracking
    case occluded(frames: Int)  // Temporarily lost
    case lost               // Tracking failed
}

class OcclusionHandler {
    private var trackingState: TrackingState = .searching
    private let kalmanFilter: KalmanFilter?
    private var occlusionBuffer: [CGPoint] = []

    private let maxOcclusionFrames = 10  // At 120fps = 83ms max occlusion
    private let recoverySearchRadius: CGFloat = 0.1  // 10% of frame

    func handleFrame(detection: BallDetection?,
                    previousPositions: [CGPoint]) -> (CGPoint?, Bool) {

        switch trackingState {
        case .searching:
            if let det = detection, det.confidence > 0.6 {
                trackingState = .tracking
                return (det.centroid, false)
            }
            return (nil, false)

        case .tracking:
            if let det = detection, det.confidence > 0.4 {
                return (det.centroid, false)
            } else {
                // Lost detection, start occlusion handling
                trackingState = .occluded(frames: 1)
                return (predictPosition(), true)
            }

        case .occluded(let frames):
            if let det = detection, det.confidence > 0.3 {
                // Recovered from occlusion
                trackingState = .tracking
                interpolateOccludedFrames(endPosition: det.centroid)
                return (det.centroid, false)
            } else if frames < maxOcclusionFrames {
                trackingState = .occluded(frames: frames + 1)
                return (predictPosition(), true)
            } else {
                // Too many frames lost
                trackingState = .lost
                return (nil, false)
            }

        case .lost:
            // Attempt recovery with relaxed thresholds
            if let det = detection, det.confidence > 0.5 {
                trackingState = .tracking
                return (det.centroid, false)
            }
            return (nil, false)
        }
    }

    private func predictPosition() -> CGPoint? {
        return kalmanFilter?.predict()
    }

    private func interpolateOccludedFrames(endPosition: CGPoint) {
        // Fill in occluded frames with interpolated positions
        guard let start = occlusionBuffer.first else { return }

        let frameCount = occlusionBuffer.count
        for i in 0..<frameCount {
            let t = CGFloat(i + 1) / CGFloat(frameCount + 1)
            let interpolated = CGPoint(
                x: start.x + (endPosition.x - start.x) * t,
                y: start.y + (endPosition.y - start.y) * t
            )
            // Update trajectory with interpolated position
        }
        occlusionBuffer.removeAll()
    }
}
```

### Real-World Coordinate Conversion

```swift
// MARK: - Coordinate Conversion (Pixels to Boards/Feet)

extension TrajectoryTracker {
    /// Convert pixel position to board number (1-39)
    func pixelToBoard(x: CGFloat, calibration: LaneCalibration) -> CGFloat {
        // Normalized position across lane width
        let normalizedX = (x - calibration.leftGutterPixel) /
                         (calibration.rightGutterPixel - calibration.leftGutterPixel)

        // Apply perspective correction
        let correctedX = calibration.applyPerspectiveCorrection(normalizedX: normalizedX)

        // Convert to board number (1-39)
        return 1 + correctedX * 38
    }

    /// Convert pixel position to distance from foul line (feet)
    func pixelToFeet(y: CGFloat, calibration: LaneCalibration) -> CGFloat {
        // Calculate normalized position along lane
        let normalizedY = (y - calibration.foulLinePixel) /
                         (calibration.pinsPixel - calibration.foulLinePixel)

        // Apply perspective correction for foreshortening
        let correctedY = calibration.applyPerspectiveCorrectionY(normalizedY: normalizedY)

        // Convert to feet (lane is 60 feet)
        return correctedY * 60.0
    }
}
```

---

## 4. REV RATE DETECTION

### PAP Marker Tracking Approach

```
+------------------------------------------------------------------+
|                    REV RATE DETECTION FLOW                        |
+------------------------------------------------------------------+
|                                                                   |
|                     Ball with PAP Marker                          |
|                           ______                                  |
|                         /   O   \    <-- White/colored tape       |
|                        |    |    |       on PAP location          |
|                         \__|___/                                  |
|                                                                   |
|  Frame N      Frame N+1    Frame N+2    Frame N+3                |
|    O             O            O            O                      |
|   /|\    -->    -|     -->    |/     -->   |\                    |
|                  /            |             |                     |
|                                                                   |
|  Marker position tracked across frames to detect rotation         |
+------------------------------------------------------------------+
```

### Marker Detection Algorithm

```swift
// MARK: - PAP Marker Tracker

struct MarkerColor {
    let hsv: HSVColor
    let minArea: CGFloat = 0.0001   // Marker is small
    let maxArea: CGFloat = 0.005
}

class PAPMarkerTracker {
    private let markerColor: MarkerColor
    private var markerAngles: [(angle: CGFloat, timestamp: TimeInterval)] = []
    private var rotationCount: Int = 0
    private var lastAngle: CGFloat?

    init(markerColor: MarkerColor) {
        self.markerColor = markerColor
    }

    /// Detect marker position relative to ball center
    func detectMarker(in frame: CVPixelBuffer,
                      ballCenter: CGPoint,
                      ballRadius: CGFloat,
                      timestamp: TimeInterval) -> CGFloat? {

        // Create color mask for marker
        let markerMask = createMarkerMask(frame: frame)

        // Find marker centroid within ball bounds
        guard let markerPosition = findMarkerInBall(
            mask: markerMask,
            ballCenter: ballCenter,
            ballRadius: ballRadius
        ) else {
            return nil
        }

        // Calculate angle from ball center to marker
        let dx = markerPosition.x - ballCenter.x
        let dy = markerPosition.y - ballCenter.y
        let angle = atan2(dy, dx) * 180 / .pi

        // Track rotation
        trackRotation(angle: angle, timestamp: timestamp)

        return angle
    }

    private func trackRotation(angle: CGFloat, timestamp: TimeInterval) {
        defer { lastAngle = angle }

        guard let previous = lastAngle else {
            markerAngles.append((angle, timestamp))
            return
        }

        // Detect rotation crossing (0 -> 360 or 360 -> 0)
        var angleDiff = angle - previous

        // Handle wraparound
        if angleDiff > 180 {
            angleDiff -= 360
        } else if angleDiff < -180 {
            angleDiff += 360
        }

        // Check for complete rotation (marker crossed starting position)
        if abs(angleDiff) > 90 {
            // Likely lost tracking, not a rotation
            return
        }

        markerAngles.append((angle, timestamp))

        // Detect complete revolution
        if markerAngles.count >= 2 {
            let totalRotation = calculateTotalRotation()
            rotationCount = Int(totalRotation / 360)
        }
    }

    private func calculateTotalRotation() -> CGFloat {
        var total: CGFloat = 0

        for i in 1..<markerAngles.count {
            var diff = markerAngles[i].angle - markerAngles[i-1].angle

            // Handle wraparound
            if diff > 180 { diff -= 360 }
            else if diff < -180 { diff += 360 }

            total += diff
        }

        return abs(total)
    }

    /// Calculate RPM from tracked rotations
    func calculateRPM() -> CGFloat? {
        guard markerAngles.count >= 2,
              let firstTime = markerAngles.first?.timestamp,
              let lastTime = markerAngles.last?.timestamp else {
            return nil
        }

        let duration = lastTime - firstTime
        guard duration > 0 else { return nil }

        let totalRotations = calculateTotalRotation() / 360.0

        // RPM = (rotations / seconds) * 60
        return (totalRotations / CGFloat(duration)) * 60
    }

    private func createMarkerMask(frame: CVPixelBuffer) -> CIImage {
        // Similar to ball detection but with marker color
        let converter = ColorSpaceConverter()
        let hsvImage = converter.convertFrameToHSV(pixelBuffer: frame)

        let maskGenerator = ColorMaskGenerator(targetColor: markerColor.hsv)
        return maskGenerator.createMask(from: hsvImage)
    }

    private func findMarkerInBall(mask: CIImage,
                                  ballCenter: CGPoint,
                                  ballRadius: CGFloat) -> CGPoint? {
        // Crop mask to ball bounding box (with padding)
        let padding = ballRadius * 0.2
        let cropRect = CGRect(
            x: ballCenter.x - ballRadius - padding,
            y: ballCenter.y - ballRadius - padding,
            width: (ballRadius + padding) * 2,
            height: (ballRadius + padding) * 2
        )

        let cropped = mask.cropped(to: cropRect)

        // Find centroid of white pixels in cropped region
        // (Implementation similar to ball centroid calculation)
        return calculateMaskCentroid(cropped)
    }

    private func calculateMaskCentroid(_ mask: CIImage) -> CGPoint? {
        // Simplified: use Vision to find the marker blob
        // In production: use Metal compute shader for speed
        return nil // Placeholder
    }
}
```

### Rotation Counting Algorithm

```swift
// MARK: - Rotation Counter

class RotationCounter {
    private var angleHistory: [CGFloat] = []
    private var unwrappedAngle: CGFloat = 0
    private var lastRawAngle: CGFloat?

    /// Add new angle measurement and return total rotations
    func addAngle(_ rawAngle: CGFloat) -> CGFloat {
        defer { lastRawAngle = rawAngle }

        guard let previous = lastRawAngle else {
            angleHistory.append(rawAngle)
            return 0
        }

        // Calculate delta, handling wraparound
        var delta = rawAngle - previous

        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }

        unwrappedAngle += delta
        angleHistory.append(rawAngle)

        return abs(unwrappedAngle) / 360.0
    }

    /// Get rotation direction (positive = forward/top spin)
    var rotationDirection: RotationDirection {
        if unwrappedAngle > 0 {
            return .forward
        } else if unwrappedAngle < 0 {
            return .backward
        }
        return .none
    }

    enum RotationDirection {
        case forward
        case backward
        case none
    }

    func reset() {
        angleHistory.removeAll()
        unwrappedAngle = 0
        lastRawAngle = nil
    }
}
```

### 120fps Requirement Justification

```
+------------------------------------------------------------------+
|                    WHY 120FPS IS REQUIRED                         |
+------------------------------------------------------------------+
|                                                                   |
|  Scenario: 400 RPM ball (common for tweener/cranker)              |
|                                                                   |
|  Rotation per second = 400 / 60 = 6.67 rotations/sec              |
|  Rotation per frame at different FPS:                             |
|                                                                   |
|  +----------+----------------+----------------+                   |
|  |   FPS    | Degrees/Frame  | Samples/Rev    |                   |
|  +----------+----------------+----------------+                   |
|  |    30    |     80.0       |     4.5        |  <-- Insufficient |
|  |    60    |     40.0       |     9.0        |  <-- Marginal     |
|  |   120    |     20.0       |    18.0        |  <-- Good         |
|  |   240    |     10.0       |    36.0        |  <-- Excellent    |
|  +----------+----------------+----------------+                   |
|                                                                   |
|  At 30 FPS: Only 4.5 samples per revolution                       |
|             - Cannot reliably track marker position               |
|             - Marker may move 80 degrees between frames           |
|             - Aliasing causes miscounts                           |
|                                                                   |
|  At 120 FPS: 18 samples per revolution                            |
|             - Marker moves only 20 degrees between frames         |
|             - Reliable tracking with angle interpolation          |
|             - Nyquist satisfied for 400 RPM detection             |
|                                                                   |
|  Nyquist Theorem: Sample rate must be > 2x signal frequency       |
|  For 500 RPM (8.33 Hz): Need > 16.67 samples/sec                  |
|  120 FPS provides 120 samples/sec = safe margin                   |
|                                                                   |
+------------------------------------------------------------------+
```

### Fallback When Marker Not Visible

```swift
// MARK: - Rev Rate Estimation Without Marker

class RevRateEstimator {
    /// Estimate rev rate from ball texture/pattern changes
    /// Less accurate but works without explicit marker
    func estimateFromTexture(frames: [CVPixelBuffer],
                             ballPositions: [CGPoint],
                             ballRadii: [CGFloat]) -> CGFloat? {
        // Use optical flow within ball region
        // Detect rotation from texture pattern movement

        // This is a fallback - accuracy is lower than marker tracking
        guard frames.count >= 10 else { return nil }

        // Calculate optical flow between consecutive frames
        var flowMagnitudes: [CGFloat] = []

        for i in 1..<min(frames.count, 20) {
            let flow = calculateOpticalFlow(
                previous: frames[i-1],
                current: frames[i],
                region: CGRect(
                    x: ballPositions[i].x - ballRadii[i],
                    y: ballPositions[i].y - ballRadii[i],
                    width: ballRadii[i] * 2,
                    height: ballRadii[i] * 2
                )
            )
            flowMagnitudes.append(flow)
        }

        // Estimate RPM from average tangential flow
        let avgFlow = flowMagnitudes.reduce(0, +) / CGFloat(flowMagnitudes.count)
        let avgRadius = ballRadii.reduce(0, +) / CGFloat(ballRadii.count)

        // Angular velocity from tangential velocity
        // v = omega * r, omega = v / r
        let angularVelocity = avgFlow / avgRadius // radians per frame
        let fps: CGFloat = 120
        let rpm = (angularVelocity * fps * 60) / (2 * .pi)

        return rpm
    }

    private func calculateOpticalFlow(previous: CVPixelBuffer,
                                      current: CVPixelBuffer,
                                      region: CGRect) -> CGFloat {
        // Use VNGenerateOpticalFlowRequest for this
        // Returns average flow magnitude in region
        return 0 // Placeholder
    }
}
```

---

## 5. PHYSICS CALCULATIONS

### Ball Speed (Distance/Time to MPH)

```swift
// MARK: - Speed Calculator

struct SpeedCalculation {
    let speedMPH: CGFloat
    let speedFPS: CGFloat      // Feet per second
    let measurementPoints: (start: TrajectoryPoint, end: TrajectoryPoint)
    let confidence: CGFloat
}

class SpeedCalculator {
    /// Calculate ball speed from trajectory points
    /// Uses last 10 feet before pins for "speed at impact"
    func calculateSpeed(trajectory: [TrajectoryPoint]) -> SpeedCalculation? {
        // Filter to calibrated points only
        let calibratedPoints = trajectory.filter {
            $0.distanceFromFoul != nil && !$0.interpolated
        }

        guard calibratedPoints.count >= 2 else { return nil }

        // Find points in the last 10 feet (50-60 feet from foul line)
        let impactZone = calibratedPoints.filter {
            ($0.distanceFromFoul ?? 0) >= 50 && ($0.distanceFromFoul ?? 0) <= 60
        }

        let measurePoints: (TrajectoryPoint, TrajectoryPoint)

        if impactZone.count >= 2 {
            // Use impact zone for "speed at pins"
            measurePoints = (impactZone.first!, impactZone.last!)
        } else {
            // Fallback: use full trajectory
            measurePoints = (calibratedPoints.first!, calibratedPoints.last!)
        }

        let (start, end) = measurePoints

        // Calculate distance traveled
        let distanceX = (end.boardNumber! - start.boardNumber!) * 1.0641 / 12.0 // boards to feet
        let distanceY = end.distanceFromFoul! - start.distanceFromFoul!
        let totalDistance = sqrt(distanceX * distanceX + distanceY * distanceY)

        // Calculate time elapsed
        let timeSeconds = end.timestamp - start.timestamp
        guard timeSeconds > 0 else { return nil }

        // Speed in feet per second
        let speedFPS = totalDistance / CGFloat(timeSeconds)

        // Convert to MPH: 1 fps = 0.6818 mph
        let speedMPH = speedFPS * 0.6818

        // Confidence based on measurement quality
        let avgConfidence = (start.confidence + end.confidence) / 2

        return SpeedCalculation(
            speedMPH: speedMPH,
            speedFPS: speedFPS,
            measurementPoints: measurePoints,
            confidence: avgConfidence
        )
    }

    /// Calculate speed at specific distance from foul line
    func speedAt(distance: CGFloat, trajectory: [TrajectoryPoint]) -> CGFloat? {
        // Find two points bracketing the target distance
        let sorted = trajectory
            .filter { $0.distanceFromFoul != nil }
            .sorted { $0.distanceFromFoul! < $1.distanceFromFoul! }

        guard let index = sorted.firstIndex(where: { $0.distanceFromFoul! >= distance }),
              index > 0 else {
            return nil
        }

        let before = sorted[index - 1]
        let after = sorted[index]

        // Interpolate speed at target distance
        let ratio = (distance - before.distanceFromFoul!) /
                   (after.distanceFromFoul! - before.distanceFromFoul!)

        if let speedBefore = before.speed, let speedAfter = after.speed {
            return speedBefore + (speedAfter - speedBefore) * ratio
        }

        return nil
    }
}
```

### Entry Angle (Arctan Calculation)

```swift
// MARK: - Entry Angle Calculator

struct EntryAngleResult {
    let angleDegrees: CGFloat
    let isOptimal: Bool           // 4-7 degrees
    let recommendation: String
    let pocketBoard: CGFloat      // Predicted pocket entry point
}

class EntryAngleCalculator {
    // Optimal entry angle range
    static let optimalMin: CGFloat = 4.0
    static let optimalMax: CGFloat = 7.0
    static let perfectAngle: CGFloat = 6.0

    /// Calculate entry angle at the pocket
    /// Entry angle = arctan(lateral movement / forward distance)
    func calculateEntryAngle(trajectory: [TrajectoryPoint]) -> EntryAngleResult? {
        // Use last 5 feet of trajectory (55-60 feet from foul)
        let finalPoints = trajectory.filter {
            ($0.distanceFromFoul ?? 0) >= 55 && ($0.distanceFromFoul ?? 0) <= 60
        }

        guard finalPoints.count >= 2 else { return nil }

        // Sort by distance
        let sorted = finalPoints.sorted { $0.distanceFromFoul! < $1.distanceFromFoul! }

        guard let first = sorted.first, let last = sorted.last,
              let startBoard = first.boardNumber, let endBoard = last.boardNumber,
              let startDist = first.distanceFromFoul, let endDist = last.distanceFromFoul else {
            return nil
        }

        // Calculate lateral movement (in feet)
        // Board width = 1.0641 inches
        let lateralBoards = endBoard - startBoard
        let lateralFeet = lateralBoards * 1.0641 / 12.0

        // Calculate forward distance
        let forwardFeet = endDist - startDist

        guard forwardFeet > 0 else { return nil }

        // Entry angle = arctan(lateral / forward)
        let angleRadians = atan(abs(lateralFeet) / forwardFeet)
        let angleDegrees = angleRadians * 180 / .pi

        // Determine if optimal
        let isOptimal = angleDegrees >= Self.optimalMin && angleDegrees <= Self.optimalMax

        // Generate recommendation
        let recommendation: String
        if angleDegrees < Self.optimalMin {
            recommendation = "Angle too flat (\(String(format: "%.1f", angleDegrees))). Increase hand rotation or move target left."
        } else if angleDegrees > Self.optimalMax {
            recommendation = "Angle too steep (\(String(format: "%.1f", angleDegrees))). Risk of splits. Reduce hand or move target right."
        } else {
            recommendation = "Optimal entry angle (\(String(format: "%.1f", angleDegrees))). Good pocket entry."
        }

        // Extrapolate pocket entry point (board at 60 feet)
        let pocketBoard = extrapolateToPins(trajectory: sorted, targetDistance: 60.0)

        return EntryAngleResult(
            angleDegrees: angleDegrees,
            isOptimal: isOptimal,
            recommendation: recommendation,
            pocketBoard: pocketBoard ?? endBoard
        )
    }

    private func extrapolateToPins(trajectory: [TrajectoryPoint],
                                   targetDistance: CGFloat) -> CGFloat? {
        guard trajectory.count >= 2 else { return nil }

        // Linear extrapolation from last two points
        let last = trajectory[trajectory.count - 1]
        let prev = trajectory[trajectory.count - 2]

        guard let lastBoard = last.boardNumber, let prevBoard = prev.boardNumber,
              let lastDist = last.distanceFromFoul, let prevDist = prev.distanceFromFoul else {
            return nil
        }

        let boardsPerFoot = (lastBoard - prevBoard) / (lastDist - prevDist)
        let remainingFeet = targetDistance - lastDist

        return lastBoard + boardsPerFoot * remainingFeet
    }
}
```

### Strike Probability Formula

```swift
// MARK: - Strike Probability Calculator

struct StrikeProbability {
    let probability: CGFloat      // 0-1
    let percentageString: String  // "85%"
    let factors: StrikeFactors
    let predictedLeave: String    // "Strike", "10-pin", "Split", etc.
}

struct StrikeFactors {
    let pocketScore: CGFloat      // 0-1, based on board 17.5
    let angleScore: CGFloat       // 0-1, based on 6 degrees
    let speedScore: CGFloat       // 0-1, based on 16-18 mph ideal
    let revScore: CGFloat         // 0-1, higher revs = more pin action
}

class StrikeProbabilityCalculator {
    // Ideal values for strike
    static let idealPocketBoard: CGFloat = 17.5  // Right-handed
    static let idealAngle: CGFloat = 6.0
    static let idealSpeedMin: CGFloat = 16.0
    static let idealSpeedMax: CGFloat = 18.0

    func calculateProbability(
        pocketBoard: CGFloat,
        entryAngle: CGFloat,
        speedMPH: CGFloat,
        revRPM: CGFloat?,
        isRightHanded: Bool
    ) -> StrikeProbability {

        // Adjust pocket for left-handed (22.5 board)
        let targetPocket = isRightHanded ? 17.5 : 22.5

        // Factor 1: Pocket Offset Score
        let pocketOffset = abs(pocketBoard - targetPocket)
        let pocketScore = max(0, 1 - (pocketOffset / 3.0)) // 0 at 3+ boards off

        // Factor 2: Entry Angle Score
        let angleDiff = abs(entryAngle - Self.idealAngle)
        let angleScore = max(0, 1 - (angleDiff / 4.0)) // 0 at 4+ degrees off

        // Factor 3: Speed Score
        let speedScore: CGFloat
        if speedMPH >= Self.idealSpeedMin && speedMPH <= Self.idealSpeedMax {
            speedScore = 1.0
        } else if speedMPH < Self.idealSpeedMin {
            speedScore = max(0, 1 - (Self.idealSpeedMin - speedMPH) / 4.0)
        } else {
            speedScore = max(0, 1 - (speedMPH - Self.idealSpeedMax) / 4.0)
        }

        // Factor 4: Rev Rate Score (optional)
        let revScore: CGFloat
        if let rpm = revRPM {
            // Higher revs = more pin action (up to a point)
            if rpm >= 300 && rpm <= 450 {
                revScore = 1.0
            } else if rpm < 300 {
                revScore = max(0.5, rpm / 300)
            } else {
                revScore = max(0.7, 1 - (rpm - 450) / 200)
            }
        } else {
            revScore = 0.7 // Neutral if unknown
        }

        // Weighted probability
        let weights = (pocket: 0.4, angle: 0.3, speed: 0.15, rev: 0.15)

        let probability =
            pocketScore * weights.pocket +
            angleScore * weights.angle +
            speedScore * weights.speed +
            revScore * weights.rev

        // Predict likely leave
        let predictedLeave = predictLeave(
            pocketOffset: pocketOffset,
            entryAngle: entryAngle,
            pocketBoard: pocketBoard,
            isRightHanded: isRightHanded
        )

        return StrikeProbability(
            probability: probability,
            percentageString: "\(Int(probability * 100))%",
            factors: StrikeFactors(
                pocketScore: pocketScore,
                angleScore: angleScore,
                speedScore: speedScore,
                revScore: revScore
            ),
            predictedLeave: predictedLeave
        )
    }

    private func predictLeave(
        pocketOffset: CGFloat,
        entryAngle: CGFloat,
        pocketBoard: CGFloat,
        isRightHanded: Bool
    ) -> String {

        // High probability = strike
        if pocketOffset < 1.0 && entryAngle >= 4 && entryAngle <= 7 {
            return "Strike"
        }

        // Low angle = weak hit
        if entryAngle < 4 {
            if isRightHanded {
                return pocketBoard > 17.5 ? "10-pin" : "7-pin"
            } else {
                return pocketBoard < 22.5 ? "7-pin" : "10-pin"
            }
        }

        // High angle = split risk
        if entryAngle > 7 {
            return "Split (4-6 or 7-10)"
        }

        // Off-pocket
        if pocketOffset > 2 {
            return "Off-pocket (multiple pins)"
        }

        // Light hit
        if isRightHanded && pocketBoard > 18.5 {
            return "Light pocket (bucket possible)"
        }

        return "Mixed leave"
    }
}
```

### Leave Prediction Logic

```swift
// MARK: - Leave Predictor

enum PinConfiguration {
    case strike
    case spare
    case split
    case bucket
    case washout

    var description: String {
        switch self {
        case .strike: return "Strike"
        case .spare: return "Makeable spare"
        case .split: return "Split"
        case .bucket: return "Bucket (2-4-5-8 or 3-5-6-9)"
        case .washout: return "Washout (1-2-10 or 1-3-7)"
        }
    }
}

class LeavePredictor {
    /// Predict remaining pins based on ball path
    func predictLeave(
        pocketBoard: CGFloat,
        entryAngle: CGFloat,
        speedMPH: CGFloat,
        revRPM: CGFloat,
        isRightHanded: Bool
    ) -> [Int] {

        // Pin numbering:
        //     7   8   9   10
        //       4   5   6
        //         2   3
        //           1

        var remainingPins: [Int] = []

        let idealPocket = isRightHanded ? 17.5 : 22.5
        let offset = pocketBoard - idealPocket

        // Low angle + light hit = weak 10 pin
        if entryAngle < 4 && offset > 0.5 && isRightHanded {
            remainingPins.append(10)
        }

        // High angle = split
        if entryAngle > 7 {
            if isRightHanded {
                remainingPins.append(contentsOf: [4, 6])  // or 7-10
            } else {
                remainingPins.append(contentsOf: [4, 6])
            }
        }

        // Too much speed = pins don't mix
        if speedMPH > 20 {
            if isRightHanded {
                remainingPins.append(8)  // Weak 8 pin
            }
        }

        // Low revs = less pin action
        if revRPM < 250 {
            remainingPins.append(5)  // 5-pin doesn't fly
        }

        // Heavy pocket = bucket potential
        if offset < -1.5 && isRightHanded {
            remainingPins.append(contentsOf: [2, 4, 5])
        }

        return remainingPins.sorted()
    }

    /// Categorize the leave type
    func categorizeLeave(_ pins: [Int]) -> PinConfiguration {
        if pins.isEmpty {
            return .strike
        }

        // Check for splits (separated pins with gap)
        let splits = [
            [4, 6], [7, 10], [4, 10], [6, 7], [7, 9], [8, 10],
            [4, 6, 7, 10], [3, 4, 6, 7], [2, 4, 6, 10]
        ]

        for split in splits {
            if Set(pins) == Set(split) {
                return .split
            }
        }

        // Check for bucket
        let buckets = [[2, 4, 5, 8], [3, 5, 6, 9], [2, 4, 5], [3, 5, 6]]
        for bucket in buckets {
            if Set(pins) == Set(bucket) {
                return .bucket
            }
        }

        // Check for washout
        let washouts = [[1, 2, 10], [1, 3, 7], [1, 2, 4, 10], [1, 3, 6, 7]]
        for washout in washouts {
            if Set(pins) == Set(washout) {
                return .washout
            }
        }

        return .spare
    }
}
```

---

## 6. PERFORMANCE TARGETS

### Frame Processing Latency Budget

```
+------------------------------------------------------------------+
|              FRAME PROCESSING LATENCY BUDGET (120fps)             |
+------------------------------------------------------------------+
|                                                                   |
|  Total budget per frame: 8.33ms (1/120 second)                    |
|                                                                   |
|  +---------------------------+----------+----------+              |
|  | Stage                     | Target   | Max      |              |
|  +---------------------------+----------+----------+              |
|  | Frame capture callback    | 0.1ms    | 0.2ms    |              |
|  | Buffer copy/retain        | 0.2ms    | 0.3ms    |              |
|  | RGB->HSV conversion (GPU) | 0.5ms    | 1.0ms    |              |
|  | Color masking (GPU)       | 0.3ms    | 0.5ms    |              |
|  | Morphology ops (GPU)      | 0.4ms    | 0.6ms    |              |
|  | Contour detection (CPU)   | 1.5ms    | 2.5ms    |              |
|  | Circularity filtering     | 0.3ms    | 0.5ms    |              |
|  | Centroid calculation      | 0.2ms    | 0.3ms    |              |
|  | Trajectory update         | 0.1ms    | 0.2ms    |              |
|  | Marker detection (if on)  | 1.0ms    | 1.5ms    |              |
|  +---------------------------+----------+----------+              |
|  | TOTAL (without marker)    | 3.6ms    | 6.1ms    |              |
|  | TOTAL (with marker)       | 4.6ms    | 7.6ms    |              |
|  +---------------------------+----------+----------+              |
|                                                                   |
|  Headroom: 0.7-4.7ms for UI updates and system overhead           |
|                                                                   |
+------------------------------------------------------------------+
```

### Memory Limits for Trajectory Storage

```swift
// MARK: - Memory Management

struct MemoryBudget {
    // Per-shot trajectory storage
    static let maxPointsPerShot = 600        // 5 seconds at 120fps
    static let bytesPerPoint = 96            // TrajectoryPoint struct size
    static let maxBytesPerShot = 57_600      // ~56 KB per shot

    // Session storage
    static let maxShotsInMemory = 50         // ~2.8 MB for trajectories
    static let maxFrameBufferMemory = 50_000_000  // 50 MB for frame cache

    // Ring buffer for real-time processing
    static let ringBufferCapacity = 120      // 1 second of positions
}

class MemoryMonitor {
    private var currentTrajectoryBytes = 0
    private var totalShotsBytes = 0

    func checkMemoryPressure() -> Bool {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        var info = mach_task_basic_info()
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMB = info.resident_size / (1024 * 1024)
            return usedMB > 500  // Pressure if > 500 MB
        }

        return false
    }

    func shouldEvictOldShots() -> Bool {
        return totalShotsBytes > MemoryBudget.maxShotsInMemory * MemoryBudget.maxBytesPerShot
    }
}
```

### CPU/GPU Utilization Targets

```
+------------------------------------------------------------------+
|                    RESOURCE UTILIZATION TARGETS                   |
+------------------------------------------------------------------+
|                                                                   |
|  iPad M5 Resources:                                               |
|  - CPU: 4 performance + 4 efficiency cores                        |
|  - GPU: 10-core Apple GPU                                         |
|  - Neural Engine: 16-core                                         |
|  - Unified Memory: 8-16 GB                                        |
|                                                                   |
|  Target Utilization During Recording:                             |
|  +------------------+----------+----------+                       |
|  | Resource         | Target   | Max      |                       |
|  +------------------+----------+----------+                       |
|  | CPU (any core)   | 40%      | 70%      |                       |
|  | GPU              | 30%      | 50%      |                       |
|  | Neural Engine    | 20%      | 40%      |                       |
|  | Memory           | 400 MB   | 700 MB   |                       |
|  +------------------+----------+----------+                       |
|                                                                   |
|  Distribution Strategy:                                           |
|  - Camera capture: Performance core 1                             |
|  - CV processing: Performance core 2                              |
|  - UI/Preview: Efficiency cores                                   |
|  - Color conversion: GPU compute                                  |
|  - Morphology: GPU compute                                        |
|  - Contour detection: Neural Engine (Vision framework)            |
|                                                                   |
+------------------------------------------------------------------+
```

### Battery Impact Considerations

```swift
// MARK: - Power Management

enum PowerMode {
    case performance   // Full 120fps, all features
    case balanced      // 60fps, reduced features
    case lowPower      // 30fps, minimal processing
}

class PowerManager {
    private var currentMode: PowerMode = .performance

    // Thermal state monitoring
    func monitorThermalState() {
        NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.adjustForThermalState()
        }
    }

    private func adjustForThermalState() {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            currentMode = .performance
        case .fair:
            currentMode = .performance  // Slightly reduced GPU
        case .serious:
            currentMode = .balanced     // Reduce to 60fps
        case .critical:
            currentMode = .lowPower     // Minimum viable tracking
        @unknown default:
            currentMode = .balanced
        }

        notifyModeChange()
    }

    // Battery level monitoring
    func shouldReducePower() -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState

        // Reduce power below 20% unless charging
        if level < 0.2 && state != .charging {
            return true
        }

        return false
    }

    // Estimated battery drain
    static let estimatedDrainPerMinute: [PowerMode: Float] = [
        .performance: 1.5,  // ~1.5% per minute at 120fps
        .balanced: 0.8,     // ~0.8% per minute at 60fps
        .lowPower: 0.4      // ~0.4% per minute at 30fps
    ]

    func estimatedRecordingTime() -> TimeInterval {
        let level = UIDevice.current.batteryLevel
        let drainRate = Self.estimatedDrainPerMinute[currentMode] ?? 1.0

        // Reserve 10% battery
        let usableLevel = max(0, level - 0.1)
        let minutes = usableLevel * 100 / drainRate

        return TimeInterval(minutes * 60)
    }

    private func notifyModeChange() {
        NotificationCenter.default.post(
            name: Notification.Name("PowerModeChanged"),
            object: currentMode
        )
    }
}
```

---

## 7. CALIBRATION MATH

### Pixel-to-Board Conversion

```swift
// MARK: - Lane Calibration

struct CalibrationPoint {
    let pixelPosition: CGPoint
    let realWorldBoard: CGFloat    // 1-39
    let realWorldFeet: CGFloat     // 0-60
}

class LaneCalibration {
    // Calibration data
    let foulLinePixelY: CGFloat
    let arrowsPixelY: CGFloat
    let pinsPixelY: CGFloat

    let leftGutterPixelX: CGFloat
    let rightGutterPixelX: CGFloat

    // Derived conversion factors
    private(set) var pixelsPerBoard: CGFloat = 0
    private(set) var pixelsPerFoot: CGFloat = 0

    // Perspective correction matrix (homography)
    private var homographyMatrix: simd_float3x3?

    init(calibrationPoints: [CalibrationPoint]) {
        // Extract key reference points
        // Assume user tapped foul line, two arrows, and gutters

        foulLinePixelY = calibrationPoints.first { $0.realWorldFeet == 0 }?.pixelPosition.y ?? 0
        arrowsPixelY = calibrationPoints.first { $0.realWorldFeet == 15 }?.pixelPosition.y ?? 0
        pinsPixelY = 0 // Calculated from arrows

        leftGutterPixelX = calibrationPoints.first { $0.realWorldBoard == 0 }?.pixelPosition.x ?? 0
        rightGutterPixelX = calibrationPoints.first { $0.realWorldBoard == 40 }?.pixelPosition.x ?? 0

        calculateConversionFactors()
        calculateHomography(from: calibrationPoints)
    }

    private func calculateConversionFactors() {
        // Lane is 41.5 inches wide = 39 boards + gutters
        // Each board = 1.0641 inches

        let laneWidthPixels = rightGutterPixelX - leftGutterPixelX
        pixelsPerBoard = laneWidthPixels / 39.0

        // Foul line to arrows = 15 feet
        let arrowDistancePixels = abs(arrowsPixelY - foulLinePixelY)
        pixelsPerFoot = arrowDistancePixels / 15.0

        // Extrapolate pins position (60 feet from foul)
        // Note: Perspective causes foreshortening, so this is approximate
    }

    /// Convert pixel X coordinate to board number
    func pixelToBoard(x: CGFloat) -> CGFloat {
        let normalizedX = (x - leftGutterPixelX) / (rightGutterPixelX - leftGutterPixelX)
        return 1 + normalizedX * 38  // Boards 1-39
    }

    /// Convert pixel Y coordinate to feet from foul line
    func pixelToFeet(y: CGFloat) -> CGFloat {
        // Simple linear (use homography for accuracy)
        let normalizedY = (y - foulLinePixelY) / (pinsPixelY - foulLinePixelY)
        return normalizedY * 60.0
    }

    /// Apply perspective correction
    func applyPerspectiveCorrection(pixelPoint: CGPoint) -> CGPoint {
        guard let matrix = homographyMatrix else {
            return pixelPoint
        }

        // Convert to homogeneous coordinates
        let input = simd_float3(Float(pixelPoint.x), Float(pixelPoint.y), 1.0)
        let output = matrix * input

        // Convert back from homogeneous
        return CGPoint(
            x: CGFloat(output.x / output.z),
            y: CGFloat(output.y / output.z)
        )
    }

    private func calculateHomography(from points: [CalibrationPoint]) {
        // Need at least 4 point correspondences for homography
        guard points.count >= 4 else { return }

        // Build the homography matrix using DLT algorithm
        // This corrects for perspective distortion

        // For simplicity, use Vision framework's VNHomographicImageRegistrationRequest
        // in production, or implement DLT directly

        // Placeholder - real implementation would solve:
        // | x' |   | h11 h12 h13 | | x |
        // | y' | = | h21 h22 h23 | | y |
        // | 1  |   | h31 h32 h33 | | 1 |
    }
}
```

### Using Arrows as Reference Points

```
+------------------------------------------------------------------+
|                    ARROW CALIBRATION REFERENCE                    |
+------------------------------------------------------------------+
|                                                                   |
|  USBC Standard Arrow Positions:                                   |
|  - Located 15 feet from foul line                                 |
|  - 7 arrows total on boards: 5, 10, 15, 20, 25, 30, 35           |
|  - Each arrow is 5 boards (5.32 inches) apart                     |
|  - Total span: 30 boards = 31.9 inches                            |
|                                                                   |
|  Calibration Process:                                             |
|                                                                   |
|  Step 1: User taps foul line (establishes Y=0)                    |
|                                                                   |
|       Foul Line                                                   |
|  =====[TAP HERE]======================                            |
|                                                                   |
|  Step 2: User taps two arrows (establishes scale + Y=15ft)        |
|                                                                   |
|       |     |     |     |     |     |     |                       |
|       v     v     v     v     v     v     v                       |
|       5    10    15    20    25    30    35   <- Board numbers    |
|                                                                   |
|      [TAP]       [TAP]                         <- User taps 2     |
|       |<-- 15 boards -->|                                         |
|       |<-- 15.96 inches ->|                                       |
|                                                                   |
|  Step 3: Calculate pixels per board                               |
|                                                                   |
|    pixelsPerBoard = |arrow1.x - arrow2.x| / 15                    |
|                                                                   |
|  Step 4: Calculate pixels per foot                                |
|                                                                   |
|    pixelsPerFoot = |foulLine.y - arrows.y| / 15                   |
|                                                                   |
+------------------------------------------------------------------+
```

```swift
// MARK: - Arrow-Based Calibration

struct ArrowCalibrationResult {
    let pixelsPerBoard: CGFloat
    let pixelsPerFoot: CGFloat
    let foulLineY: CGFloat
    let arrowsY: CGFloat
    let laneLeftX: CGFloat
    let laneRightX: CGFloat
    let confidence: CGFloat
}

class ArrowCalibrator {
    // Known arrow board positions
    static let arrowBoards: [CGFloat] = [5, 10, 15, 20, 25, 30, 35]
    static let arrowDistanceFromFoul: CGFloat = 15.0  // feet
    static let boardsBetweenArrows: CGFloat = 5.0
    static let inchesPerBoard: CGFloat = 1.0641

    func calibrate(
        foulLineTap: CGPoint,
        arrow1Tap: CGPoint,
        arrow2Tap: CGPoint,
        arrow1Board: CGFloat,  // Which arrow (5, 10, 15, etc.)
        arrow2Board: CGFloat
    ) -> ArrowCalibrationResult {

        // Calculate pixels per board from arrow separation
        let arrowSeparationPixels = abs(arrow2Tap.x - arrow1Tap.x)
        let boardSeparation = abs(arrow2Board - arrow1Board)
        let pixelsPerBoard = arrowSeparationPixels / boardSeparation

        // Calculate pixels per foot from foul line to arrows
        let foulToArrowPixels = abs(arrow1Tap.y - foulLineTap.y)
        let pixelsPerFoot = foulToArrowPixels / Self.arrowDistanceFromFoul

        // Extrapolate lane edges
        // If arrow1 is on board 10, left gutter is 10 boards to the left
        let leftGutterX = arrow1Tap.x - (arrow1Board * pixelsPerBoard)
        let rightGutterX = leftGutterX + (39 * pixelsPerBoard)

        // Confidence based on consistency
        let confidence = calculateConfidence(
            pixelsPerBoard: pixelsPerBoard,
            pixelsPerFoot: pixelsPerFoot,
            arrowSeparation: arrowSeparationPixels
        )

        return ArrowCalibrationResult(
            pixelsPerBoard: pixelsPerBoard,
            pixelsPerFoot: pixelsPerFoot,
            foulLineY: foulLineTap.y,
            arrowsY: (arrow1Tap.y + arrow2Tap.y) / 2,
            laneLeftX: leftGutterX,
            laneRightX: rightGutterX,
            confidence: confidence
        )
    }

    private func calculateConfidence(
        pixelsPerBoard: CGFloat,
        pixelsPerFoot: CGFloat,
        arrowSeparation: CGFloat
    ) -> CGFloat {
        // Expected ratio: 15 feet = ~178 inches of visible lane
        // Lane width = 41.5 inches
        // So pixelsPerFoot / pixelsPerBoard should be ~4.3 (178/41.5)

        let expectedRatio: CGFloat = 4.3
        let actualRatio = pixelsPerFoot / pixelsPerBoard
        let ratioError = abs(actualRatio - expectedRatio) / expectedRatio

        // Also check arrow separation is reasonable (minimum 50 pixels)
        let separationOK = arrowSeparation > 50

        if separationOK && ratioError < 0.3 {
            return 1.0 - ratioError
        } else {
            return 0.5
        }
    }
}
```

### Perspective Correction Approach

```
+------------------------------------------------------------------+
|                    PERSPECTIVE CORRECTION                         |
+------------------------------------------------------------------+
|                                                                   |
|  Problem: Camera views lane at an angle, causing:                 |
|  - Far objects (pins) appear smaller than near objects (arrows)   |
|  - Parallel lane edges appear to converge (vanishing point)       |
|  - Distance measurements are compressed at far end                |
|                                                                   |
|  Camera View (with distortion):                                   |
|                                                                   |
|              Pins (60 ft)                                         |
|                  /\                                               |
|                 /  \                                              |
|                /    \      <- Lines converge                      |
|               /      \                                            |
|              /        \                                           |
|             /          \                                          |
|            /            \                                         |
|           /   Arrows     \                                        |
|          |    (15 ft)     |                                       |
|          |                |                                       |
|          |    Foul Line   |                                       |
|          ==================                                       |
|              (0 ft)                                               |
|                                                                   |
|  Solution: Homography Transformation                              |
|                                                                   |
|  1. Identify 4 reference points (corners of rectangle)            |
|  2. Calculate 3x3 homography matrix H                             |
|  3. Transform each pixel: p' = H * p                              |
|                                                                   |
|  Reference Points Used:                                           |
|  - Foul line left edge (board 1, 0 ft)                           |
|  - Foul line right edge (board 39, 0 ft)                         |
|  - Arrow left (board 5, 15 ft)                                   |
|  - Arrow right (board 35, 15 ft)                                 |
|                                                                   |
+------------------------------------------------------------------+
```

```swift
// MARK: - Homography Calculator

class HomographyCalculator {
    /// Calculate homography matrix from 4 point correspondences
    /// Maps pixel coordinates to normalized lane coordinates
    func calculateHomography(
        sourcePoints: [CGPoint],    // 4 pixel positions
        destPoints: [CGPoint]       // 4 normalized positions (0-1)
    ) -> simd_float3x3? {

        guard sourcePoints.count == 4 && destPoints.count == 4 else {
            return nil
        }

        // Build the 8x9 matrix for DLT (Direct Linear Transform)
        // For each point correspondence: (x, y) -> (x', y')
        // We get two equations:
        //   -x*h31*x' - y*h32*x' - h33*x' + h11*x + h12*y + h13 = 0
        //   -x*h31*y' - y*h32*y' - h33*y' + h21*x + h22*y + h23 = 0

        var A: [[Float]] = []

        for i in 0..<4 {
            let x = Float(sourcePoints[i].x)
            let y = Float(sourcePoints[i].y)
            let xp = Float(destPoints[i].x)
            let yp = Float(destPoints[i].y)

            A.append([x, y, 1, 0, 0, 0, -x*xp, -y*xp, -xp])
            A.append([0, 0, 0, x, y, 1, -x*yp, -y*yp, -yp])
        }

        // Solve using SVD (Singular Value Decomposition)
        // The homography h is the null space of A (last column of V in SVD)

        // Simplified: Use Accelerate framework's LAPACK bindings
        // For production, use the Vision framework's built-in registration

        return nil  // Placeholder - real implementation uses LAPACK
    }

    /// Apply homography to transform a point
    func transformPoint(_ point: CGPoint, using H: simd_float3x3) -> CGPoint {
        let input = simd_float3(Float(point.x), Float(point.y), 1.0)
        let output = H * input

        // Convert from homogeneous coordinates
        return CGPoint(
            x: CGFloat(output.x / output.z),
            y: CGFloat(output.y / output.z)
        )
    }
}

// MARK: - Practical Perspective Correction

class PerspectiveCorrector {
    private let calibration: LaneCalibration

    init(calibration: LaneCalibration) {
        self.calibration = calibration
    }

    /// Correct for foreshortening (compression at far end of lane)
    func correctY(rawY: CGFloat) -> CGFloat {
        // Simple quadratic model for perspective correction
        // Objects at pins appear ~2x smaller than at foul line

        let normalizedY = (rawY - calibration.foulLinePixelY) /
                         (calibration.pinsPixelY - calibration.foulLinePixelY)

        // Correction factor increases with distance
        // Based on typical camera angle (~15-20 degrees)
        let correctionFactor = 1.0 + (normalizedY * 0.3)  // 30% correction at pins

        return rawY * correctionFactor
    }

    /// Correct for lane edge convergence
    func correctX(rawX: CGFloat, atY rawY: CGFloat) -> CGFloat {
        // At foul line, lane appears full width
        // At pins, lane appears narrower due to convergence

        let normalizedY = (rawY - calibration.foulLinePixelY) /
                         (calibration.pinsPixelY - calibration.foulLinePixelY)

        // Lane center doesn't shift, only edges
        let laneCenterX = (calibration.leftGutterPixelX + calibration.rightGutterPixelX) / 2
        let distanceFromCenter = rawX - laneCenterX

        // Edges appear to converge ~15% at pins
        let convergenceFactor = 1.0 + (normalizedY * 0.15)

        return laneCenterX + (distanceFromCenter * convergenceFactor)
    }
}
```

---

## Data Flow Diagram

```
+==================================================================+
|                    COMPLETE CV PIPELINE DATA FLOW                 |
+==================================================================+
|                                                                   |
|  [iPad Camera Sensor]                                             |
|         |                                                         |
|         v 120 fps                                                 |
|  +----------------+                                               |
|  | AVCaptureSession|                                              |
|  | (CVPixelBuffer) |                                              |
|  +----------------+                                               |
|         |                                                         |
|         v                                                         |
|  +----------------+     +-------------------+                     |
|  | Frame Dispatcher|--->| Preview Pipeline  |---> [UI Display]   |
|  +----------------+     | (30fps subset)    |                     |
|         |               +-------------------+                     |
|         v                                                         |
|  +------------------+                                             |
|  | Ball Detection   |                                             |
|  | Pipeline (GPU)   |                                             |
|  +------------------+                                             |
|         |                                                         |
|    +----+----+                                                    |
|    |         |                                                    |
|    v         v                                                    |
|  +------+  +--------+                                             |
|  | Ball |  | Marker |   (Parallel detection)                      |
|  | HSV  |  | HSV    |                                             |
|  +------+  +--------+                                             |
|    |         |                                                    |
|    v         v                                                    |
|  +------+  +--------+                                             |
|  | Mask |  | Mask   |                                             |
|  +------+  +--------+                                             |
|    |         |                                                    |
|    v         v                                                    |
|  +------+  +--------+                                             |
|  |Morph |  | Morph  |                                             |
|  +------+  +--------+                                             |
|    |         |                                                    |
|    v         v                                                    |
|  +-------+ +--------+                                             |
|  |Contour| |Centroid|                                             |
|  +-------+ +--------+                                             |
|    |         |                                                    |
|    v         |                                                    |
|  +-------+   |                                                    |
|  |Circle |   |                                                    |
|  |Filter |   |                                                    |
|  +-------+   |                                                    |
|    |         |                                                    |
|    v         v                                                    |
|  +-------------------+                                            |
|  | Position Fusion   |                                            |
|  | (Ball + Marker)   |                                            |
|  +-------------------+                                            |
|         |                                                         |
|         v                                                         |
|  +-------------------+                                            |
|  | Trajectory Tracker|                                            |
|  | (Kalman Filter)   |                                            |
|  +-------------------+                                            |
|         |                                                         |
|         v                                                         |
|  +-------------------+     +-------------------+                   |
|  | Calibration       |<--->| Lane Calibration  |                  |
|  | Transformation    |     | Data              |                  |
|  +-------------------+     +-------------------+                   |
|         |                                                         |
|         v                                                         |
|  +-------------------+                                            |
|  | Physics Engine    |                                            |
|  | - Speed           |                                            |
|  | - Entry Angle     |                                            |
|  | - Rev Rate        |                                            |
|  | - Strike Prob     |                                            |
|  +-------------------+                                            |
|         |                                                         |
|         v                                                         |
|  +-------------------+     +-------------------+                   |
|  | Results Publisher |---->| UI / Analytics    |                  |
|  +-------------------+     +-------------------+                   |
|         |                                                         |
|         v                                                         |
|  +-------------------+                                            |
|  | SQLite Storage    |                                            |
|  +-------------------+                                            |
|                                                                   |
+==================================================================+
```

---

## Summary

This CV pipeline architecture provides:

1. **High-Performance Capture**: 120fps using AVFoundation with optimized buffer management for iPad M5
2. **Robust Ball Detection**: Color-based HSV filtering with morphological cleanup and circularity validation
3. **Accurate Tracking**: Kalman-filtered trajectory with occlusion handling and perspective correction
4. **Rev Rate Analysis**: PAP marker tracking with rotation counting, justified by Nyquist sampling requirements
5. **Physics Engine**: Real-world speed, entry angle, and strike probability calculations
6. **Efficient Calibration**: Arrow-based reference with homography for perspective correction

The pipeline is designed to process frames within the 8.33ms budget while maintaining accuracy suitable for competitive bowling analysis.
