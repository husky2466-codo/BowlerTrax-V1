//
//  LaneDetector.swift
//  BowlerTrax
//
//  Smart lane detection using Vision framework.
//  Automatically detects lane boundaries, foul line, and arrow markers
//  from camera frames using edge detection and line analysis.
//

import Vision
import CoreImage
import CoreVideo
import CoreGraphics
import UIKit

// MARK: - Lane Detector

/// Detects bowling lane features from camera frames using computer vision
final class LaneDetector: @unchecked Sendable {
    // MARK: - Properties

    private let ciContext: CIContext
    private var configuration: LaneDetectionConfiguration

    // Analysis state
    private var frameResults: [LaneDetectionResult] = []
    private var analysisStartTime: Date?
    private var frameCount: Int = 0

    // Line detection parameters
    private let minContourArea: Double = 0.001  // Minimum contour area (normalized)
    private let maxContourArea: Double = 0.5    // Maximum contour area (normalized)

    // Lane color ranges (light wood color)
    private let laneHueRange: ClosedRange<Double> = 20...50     // Tan/wood hue
    private let laneSaturationMin: Double = 0.1
    private let laneValueMin: Double = 0.3

    // Gutter detection (darker than lane)
    private let gutterValueMax: Double = 0.4

    // MARK: - Initialization

    init(configuration: LaneDetectionConfiguration = .default) {
        self.configuration = configuration

        if let device = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(
                mtlDevice: device,
                options: [.useSoftwareRenderer: false]
            )
        } else {
            self.ciContext = CIContext()
        }
    }

    // MARK: - Configuration

    func updateConfiguration(_ config: LaneDetectionConfiguration) {
        self.configuration = config
    }

    // MARK: - Detection

    /// Analyze a single frame for lane detection
    /// - Parameters:
    ///   - pixelBuffer: Input camera frame
    ///   - timestamp: Frame timestamp
    /// - Returns: Lane detection result for this frame
    func analyzeFrame(_ pixelBuffer: CVPixelBuffer, timestamp: Date = Date()) async throws -> LaneDetectionResult {
        let inputImage = CIImage(cvPixelBuffer: pixelBuffer)
        let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        // Step 1: Detect edges using contour detection
        let contours = try await detectContours(in: inputImage)

        // Step 2: Find vertical lines (gutter edges)
        let verticalLines = findVerticalLines(from: contours, imageSize: CGSize(width: width, height: height))

        // Step 3: Find horizontal lines (foul line)
        let horizontalLines = findHorizontalLines(from: contours, imageSize: CGSize(width: width, height: height))

        // Step 4: Analyze lane structure
        let (leftGutter, rightGutter) = identifyGutterLines(from: verticalLines)
        let foulLine = identifyFoulLine(from: horizontalLines, imageHeight: height)

        // Step 5: Detect arrows (if enabled)
        var arrows: [ArrowDetection]? = nil
        if configuration.detectArrows, let foul = foulLine {
            arrows = try await detectArrows(
                in: inputImage,
                foulLineY: foul.midpoint.y,
                imageSize: CGSize(width: width, height: height)
            )
        }

        // Step 6: Calculate confidence
        let confidence = calculateConfidence(
            leftGutter: leftGutter,
            rightGutter: rightGutter,
            foulLine: foulLine,
            arrows: arrows
        )

        // Step 7: Calculate lane rectangle
        let laneRect = calculateLaneRectangle(
            leftGutter: leftGutter,
            rightGutter: rightGutter,
            foulLine: foulLine,
            imageSize: CGSize(width: width, height: height)
        )

        return LaneDetectionResult(
            leftGutterLine: leftGutter?.map { normalizePoint($0, size: CGSize(width: width, height: height)) },
            rightGutterLine: rightGutter?.map { normalizePoint($0, size: CGSize(width: width, height: height)) },
            foulLine: foulLine.map { line in
                LineSeg(
                    start: normalizePoint(line.start, size: CGSize(width: width, height: height)),
                    end: normalizePoint(line.end, size: CGSize(width: width, height: height))
                )
            },
            arrowPositions: arrows,
            confidence: confidence,
            laneRectangle: laneRect.map { rect in
                CGRect(
                    x: rect.origin.x / width,
                    y: rect.origin.y / height,
                    width: rect.width / width,
                    height: rect.height / height
                )
            },
            timestamp: timestamp
        )
    }

    /// Analyze multiple frames and return best aggregated result
    /// - Parameters:
    ///   - frames: Array of pixel buffers to analyze
    ///   - progressHandler: Called with progress updates (0-1)
    /// - Returns: Best aggregated lane detection result
    func analyzeFrames(
        _ frames: [CVPixelBuffer],
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> LaneDetectionResult {
        guard !frames.isEmpty else {
            throw LaneDetectionError.processingFailed("No frames to analyze")
        }

        var results: [LaneDetectionResult] = []
        let total = Double(frames.count)

        for (index, frame) in frames.enumerated() {
            // Check for task cancellation before processing each frame
            try Task.checkCancellation()

            let result = try await analyzeFrame(frame)
            results.append(result)
            progressHandler?(Double(index + 1) / total)
        }

        return aggregateResults(results)
    }

    /// Start continuous detection with frame accumulation
    func startContinuousDetection() {
        frameResults.removeAll()
        frameCount = 0
        analysisStartTime = Date()
    }

    /// Add a frame to continuous detection
    func addFrame(_ pixelBuffer: CVPixelBuffer) async throws -> LaneDetectionResult? {
        guard frameCount < configuration.framesToAnalyze else {
            return nil
        }

        let result = try await analyzeFrame(pixelBuffer)
        frameResults.append(result)
        frameCount += 1

        // Check timeout
        if let start = analysisStartTime,
           Date().timeIntervalSince(start) > configuration.timeoutSeconds {
            throw LaneDetectionError.analysisTimeout
        }

        // Return aggregated result if we have enough frames
        if frameCount >= configuration.framesToAnalyze {
            return aggregateResults(frameResults)
        }

        return result
    }

    /// Get current aggregated result
    func getCurrentResult() -> LaneDetectionResult {
        aggregateResults(frameResults)
    }

    /// Reset detection state
    func reset() {
        frameResults.removeAll()
        frameCount = 0
        analysisStartTime = nil
    }

    // MARK: - Contour Detection

    private func detectContours(in image: CIImage) async throws -> [VNContour] {
        // Check for cancellation before expensive operation
        try Task.checkCancellation()

        // Prepare image for edge detection
        let grayscale = image.applyingFilter("CIPhotoEffectMono")

        // Apply edge enhancement
        let edges = grayscale
            .applyingFilter("CIEdges", parameters: ["inputIntensity": configuration.edgeSensitivity])
            .applyingFilter("CIColorControls", parameters: ["inputContrast": 2.0])

        // Detect contours - run on background to avoid blocking
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let request = VNDetectContoursRequest()
                    request.contrastAdjustment = 1.0
                    request.detectsDarkOnLight = true
                    request.maximumImageDimension = 1024

                    let handler = VNImageRequestHandler(ciImage: edges, options: [:])
                    try handler.perform([request])

                    guard let observation = request.results?.first else {
                        continuation.resume(returning: [])
                        return
                    }

                    // Get all contours
                    let contours = (0..<min(observation.contourCount, 50)).compactMap { index in
                        try? observation.contour(at: index)
                    }
                    continuation.resume(returning: contours)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Line Detection

    private func findVerticalLines(
        from contours: [VNContour],
        imageSize: CGSize
    ) -> [LineSeg] {
        var verticalLines: [LineSeg] = []

        for contour in contours {
            let path = contour.normalizedPath
            let points = path.allPoints

            guard points.count >= 2 else { continue }

            // Find longest approximately vertical segments
            for i in 0..<(points.count - 1) {
                let start = points[i]
                let end = points[i + 1]

                let dx = abs(end.x - start.x)
                let dy = abs(end.y - start.y)

                // Check if segment is more vertical than horizontal
                if dy > dx * 2 && dy > configuration.minLineLength {
                    let line = LineSeg(
                        start: CGPoint(x: start.x * imageSize.width, y: start.y * imageSize.height),
                        end: CGPoint(x: end.x * imageSize.width, y: end.y * imageSize.height)
                    )
                    if line.isVertical(threshold: 30) {
                        verticalLines.append(line)
                    }
                }
            }
        }

        return verticalLines
    }

    private func findHorizontalLines(
        from contours: [VNContour],
        imageSize: CGSize
    ) -> [LineSeg] {
        var horizontalLines: [LineSeg] = []

        for contour in contours {
            let path = contour.normalizedPath
            let points = path.allPoints

            guard points.count >= 2 else { continue }

            // Find horizontal segments
            for i in 0..<(points.count - 1) {
                let start = points[i]
                let end = points[i + 1]

                let dx = abs(end.x - start.x)
                let dy = abs(end.y - start.y)

                // Check if segment is more horizontal than vertical
                if dx > dy * 2 && dx > configuration.minLineLength {
                    let line = LineSeg(
                        start: CGPoint(x: start.x * imageSize.width, y: start.y * imageSize.height),
                        end: CGPoint(x: end.x * imageSize.width, y: end.y * imageSize.height)
                    )
                    if line.isHorizontal(threshold: 20) {
                        horizontalLines.append(line)
                    }
                }
            }
        }

        return horizontalLines
    }

    // MARK: - Feature Identification

    private func identifyGutterLines(
        from verticalLines: [LineSeg]
    ) -> (left: [CGPoint]?, right: [CGPoint]?) {
        // Need at least 3 lines to properly divide into thirds
        guard verticalLines.count >= 3 else { return (nil, nil) }

        // Sort lines by X position
        let sortedByX = verticalLines.sorted { $0.midpoint.x < $1.midpoint.x }

        // Group lines by proximity - use max(1, count/3) to ensure at least 1 element
        let thirdCount = max(1, sortedByX.count / 3)
        let leftCandidates = sortedByX.prefix(thirdCount)
        let rightCandidates = sortedByX.suffix(thirdCount)

        // Find the most prominent left and right lines
        var leftPoints: [CGPoint] = []
        var rightPoints: [CGPoint] = []

        // Aggregate left gutter points
        for line in leftCandidates {
            leftPoints.append(line.start)
            leftPoints.append(line.end)
        }

        // Aggregate right gutter points
        for line in rightCandidates {
            rightPoints.append(line.start)
            rightPoints.append(line.end)
        }

        // Sort by Y for proper line representation
        leftPoints.sort { $0.y < $1.y }
        rightPoints.sort { $0.y < $1.y }

        return (
            leftPoints.isEmpty ? nil : leftPoints,
            rightPoints.isEmpty ? nil : rightPoints
        )
    }

    private func identifyFoulLine(
        from horizontalLines: [LineSeg],
        imageHeight: CGFloat
    ) -> LineSeg? {
        guard !horizontalLines.isEmpty else { return nil }

        // Foul line should be in the lower portion of the frame
        // (camera is behind bowler, foul line is near bottom)
        let bottomThreshold = imageHeight * 0.5

        let candidateLines = horizontalLines.filter { line in
            line.midpoint.y > bottomThreshold
        }

        guard !candidateLines.isEmpty else { return nil }

        // Find the longest horizontal line in the bottom portion
        return candidateLines.max { $0.length < $1.length }
    }

    // MARK: - Arrow Detection

    private func detectArrows(
        in image: CIImage,
        foulLineY: CGFloat,
        imageSize: CGSize
    ) async throws -> [ArrowDetection] {
        // Check for cancellation before expensive operation
        try Task.checkCancellation()

        // Arrows are at 15 feet from foul line
        // In typical camera setup, this is roughly 1/4 to 1/3 up from foul line
        let arrowZoneTop = foulLineY * 0.6     // Start of arrow zone
        let arrowZoneBottom = foulLineY * 0.8  // End of arrow zone

        // Crop to arrow zone
        let arrowZoneRect = CGRect(
            x: 0,
            y: arrowZoneTop,
            width: imageSize.width,
            height: arrowZoneBottom - arrowZoneTop
        )

        // Apply bright spot detection (arrows are often reflective)
        let brightMask = image
            .applyingFilter("CIColorThreshold", parameters: ["inputThreshold": 0.7])

        let croppedImage = brightMask.cropped(to: arrowZoneRect)

        // Detect contours in the bright mask - run on background to avoid blocking
        let observation: VNContoursObservation? = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let request = VNDetectContoursRequest()
                    request.contrastAdjustment = 1.0
                    request.detectsDarkOnLight = false
                    request.maximumImageDimension = 512

                    let handler = VNImageRequestHandler(ciImage: croppedImage, options: [:])
                    try handler.perform([request])
                    continuation.resume(returning: request.results?.first)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        guard let observation = observation else {
            return []
        }

        var arrows: [ArrowDetection] = []

        // Analyze contours for triangular shapes
        for i in 0..<min(observation.contourCount, 20) {
            guard let contour = try? observation.contour(at: i) else { continue }

            let bounds = contour.normalizedPath.boundingBox
            let area = bounds.width * bounds.height

            // Filter by size (arrows are small but visible)
            guard area > 0.001 && area < 0.05 else { continue }

            // Check for triangular shape
            let shapeConfidence = calculateTriangularConfidence(contour: contour)

            if shapeConfidence > configuration.arrowSensitivity {
                // Convert position back to full image coordinates
                let centerX = (bounds.midX * arrowZoneRect.width + arrowZoneRect.origin.x) / imageSize.width
                let centerY = (bounds.midY * arrowZoneRect.height + arrowZoneRect.origin.y) / imageSize.height

                // Estimate board number based on X position
                let boardNumber = estimateBoardNumber(normalizedX: centerX)

                arrows.append(ArrowDetection(
                    position: CGPoint(x: centerX, y: centerY),
                    boardNumber: boardNumber,
                    confidence: Double(shapeConfidence),
                    shapeConfidence: Double(shapeConfidence)
                ))
            }
        }

        // Sort by X position and filter to most confident at each position
        return filterDuplicateArrows(arrows)
    }

    private func calculateTriangularConfidence(contour: VNContour) -> Double {
        let path = contour.normalizedPath
        let points = path.allPoints

        // Triangles have approximately 3 vertices
        // Simplify the contour and count corners
        guard points.count >= 3 else { return 0 }

        // Calculate aspect ratio (arrows are roughly equilateral or isosceles)
        let bounds = path.boundingBox
        let aspectRatio = bounds.width / max(bounds.height, 0.001)

        // Arrows typically have aspect ratio between 0.5 and 2
        guard aspectRatio > 0.3 && aspectRatio < 3 else { return 0 }

        // Simple triangularity score based on point count and regularity
        let expectedPoints = 3
        let pointPenalty = Double(abs(points.count - expectedPoints)) * 0.1

        return max(0, 1.0 - pointPenalty - (Swift.abs(aspectRatio - 1) * 0.2))
    }

    private func estimateBoardNumber(normalizedX: CGFloat) -> Int {
        // Assume lane spans roughly 0.2 to 0.8 of the frame width
        // Map to boards 1-39
        let laneStart: CGFloat = 0.15
        let laneEnd: CGFloat = 0.85
        let laneWidth = laneEnd - laneStart

        let relativeX = (normalizedX - laneStart) / laneWidth
        let board = Int(relativeX * 39) + 1

        // Snap to nearest arrow board
        let arrowBoards = [5, 10, 15, 20, 25, 30, 35]
        return arrowBoards.min { abs($0 - board) < abs($1 - board) } ?? 20
    }

    private func filterDuplicateArrows(_ arrows: [ArrowDetection]) -> [ArrowDetection] {
        // Group by board number and keep highest confidence
        var bestByBoard: [Int: ArrowDetection] = [:]

        for arrow in arrows {
            if let existing = bestByBoard[arrow.boardNumber] {
                if arrow.confidence > existing.confidence {
                    bestByBoard[arrow.boardNumber] = arrow
                }
            } else {
                bestByBoard[arrow.boardNumber] = arrow
            }
        }

        return Array(bestByBoard.values).sorted { $0.boardNumber < $1.boardNumber }
    }

    // MARK: - Result Aggregation

    private func aggregateResults(_ results: [LaneDetectionResult]) -> LaneDetectionResult {
        guard !results.isEmpty else { return .empty }

        // Find result with highest confidence
        guard let best = results.max(by: { $0.confidence < $1.confidence }) else {
            return .empty
        }

        // Aggregate gutter lines from all confident results
        let confidentResults = results.filter { $0.confidence >= configuration.minimumConfidence }

        // Average the foul line positions
        var avgFoulLine: LineSeg? = nil
        let foulLines = confidentResults.compactMap { $0.foulLine }
        if !foulLines.isEmpty {
            let avgStartX = foulLines.map { $0.start.x }.reduce(0, +) / CGFloat(foulLines.count)
            let avgStartY = foulLines.map { $0.start.y }.reduce(0, +) / CGFloat(foulLines.count)
            let avgEndX = foulLines.map { $0.end.x }.reduce(0, +) / CGFloat(foulLines.count)
            let avgEndY = foulLines.map { $0.end.y }.reduce(0, +) / CGFloat(foulLines.count)

            avgFoulLine = LineSeg(
                start: CGPoint(x: avgStartX, y: avgStartY),
                end: CGPoint(x: avgEndX, y: avgEndY)
            )
        }

        // Merge arrow detections, keeping most confident
        var mergedArrows: [ArrowDetection] = []
        for result in confidentResults {
            if let arrows = result.arrowPositions {
                for arrow in arrows {
                    if let existingIndex = mergedArrows.firstIndex(where: { $0.boardNumber == arrow.boardNumber }) {
                        if arrow.confidence > mergedArrows[existingIndex].confidence {
                            mergedArrows[existingIndex] = arrow
                        }
                    } else {
                        mergedArrows.append(arrow)
                    }
                }
            }
        }

        // Calculate average confidence
        let avgConfidence = confidentResults.map { $0.confidence }.reduce(0, +) / Double(max(confidentResults.count, 1))

        return LaneDetectionResult(
            leftGutterLine: best.leftGutterLine,
            rightGutterLine: best.rightGutterLine,
            foulLine: avgFoulLine ?? best.foulLine,
            arrowPositions: mergedArrows.isEmpty ? nil : mergedArrows.sorted { $0.boardNumber < $1.boardNumber },
            confidence: avgConfidence,
            laneRectangle: best.laneRectangle,
            vanishingPoint: best.vanishingPoint,
            timestamp: Date()
        )
    }

    // MARK: - Helpers

    private func calculateConfidence(
        leftGutter: [CGPoint]?,
        rightGutter: [CGPoint]?,
        foulLine: LineSeg?,
        arrows: [ArrowDetection]?
    ) -> Double {
        var confidence: Double = 0

        // Foul line is most important (40%)
        if foulLine != nil {
            confidence += 0.4
        }

        // Lane edges (30% total)
        if leftGutter != nil { confidence += 0.15 }
        if rightGutter != nil { confidence += 0.15 }

        // Arrows (30% total, 10% per arrow up to 3)
        let arrowCount = min(arrows?.count ?? 0, 3)
        confidence += Double(arrowCount) * 0.1

        return min(confidence, 1.0)
    }

    private func calculateLaneRectangle(
        leftGutter: [CGPoint]?,
        rightGutter: [CGPoint]?,
        foulLine: LineSeg?,
        imageSize: CGSize
    ) -> CGRect? {
        guard let left = leftGutter?.first,
              let right = rightGutter?.first,
              let foul = foulLine else {
            return nil
        }

        let minX = min(left.x, foul.start.x)
        let maxX = max(right.x, foul.end.x)
        let maxY = max(foul.start.y, foul.end.y)
        let minY: CGFloat = 0  // Top of frame

        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }

    private func normalizePoint(_ point: CGPoint, size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x / size.width,
            y: point.y / size.height
        )
    }
}

// MARK: - Lane Detector Factory

extension LaneDetector {
    /// Create detector optimized for bright bowling alley lighting
    static func forBrightLighting() -> LaneDetector {
        LaneDetector(configuration: .fast)
    }

    /// Create detector for challenging lighting conditions
    static func forLowLighting() -> LaneDetector {
        LaneDetector(configuration: .sensitive)
    }
}
