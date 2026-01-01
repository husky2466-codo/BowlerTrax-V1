//
//  ContourDetector.swift
//  BowlerTrax
//
//  Contour detection using Apple's Vision framework.
//  Finds and filters circular contours in binary masks to identify bowling balls.
//

import Vision
import CoreImage
@preconcurrency import CoreGraphics
import simd

// MARK: - Contour Metrics

/// Metrics for a detected contour
struct ContourMetrics: Sendable {
    let area: Double
    let perimeter: Double
    let circularity: Double
    let centroid: CGPoint
    let boundingBox: CGRect
    let normalizedPath: CGPath

    /// Check if contour is likely a bowling ball based on circularity
    var isBallCandidate: Bool {
        circularity >= ContourDetector.circularityThreshold
    }
}

// MARK: - Contour Detector

/// Detects and analyzes contours in binary mask images
final class ContourDetector: @unchecked Sendable {
    // MARK: - Configuration

    /// Minimum circularity for ball detection (perfect circle = 1.0)
    static let circularityThreshold: Double = 0.65

    /// Expected ball size range in normalized coordinates (0-1)
    static let minBallArea: Double = 0.0005   // ~0.05% of frame
    static let maxBallArea: Double = 0.08     // ~8% of frame

    /// Maximum contours to process (for performance)
    static let maxContoursToProcess: Int = 20

    // MARK: - Properties

    private let ciContext: CIContext

    // MARK: - Initialization

    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: device)
        } else {
            self.ciContext = CIContext()
        }
    }

    // MARK: - Public Methods

    /// Detect contours in binary mask image (synchronous)
    /// - Parameter mask: Binary CIImage mask (white = object, black = background)
    /// - Returns: Array of detected contours
    /// - Throws: Vision framework errors
    func detectContoursSync(in mask: CIImage) throws -> [VNContour] {
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.0
        request.detectsDarkOnLight = false  // White ball on black background
        request.maximumImageDimension = 1024  // Balance accuracy vs speed

        let handler = VNImageRequestHandler(ciImage: mask, options: [:])
        try handler.perform([request])

        guard let observation = request.results?.first else {
            return []
        }

        // Get top-level contours (ignore nested/child contours)
        return (0..<min(observation.contourCount, Self.maxContoursToProcess)).compactMap { index in
            try? observation.contour(at: index)
        }
    }

    /// Detect contours in binary mask image (async wrapper with proper background execution)
    /// - Parameter mask: Binary CIImage mask (white = object, black = background)
    /// - Returns: Array of detected contours
    func detectContours(in mask: CIImage) async throws -> [VNContour] {
        // Check for cancellation before expensive Vision operation
        try Task.checkCancellation()

        // Run Vision detection on background queue to avoid blocking
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    let result = try detectContoursSync(in: mask)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Detect contours and filter by circularity (synchronous)
    /// - Parameter mask: Binary CIImage mask
    /// - Returns: Array of ContourMetrics for circular contours
    /// - Throws: Vision framework errors
    func detectCircularContoursSync(in mask: CIImage) throws -> [ContourMetrics] {
        let contours = try detectContoursSync(in: mask)
        return filterCircularContours(contours)
    }

    /// Detect contours and filter by circularity (async wrapper with proper background execution)
    /// - Parameter mask: Binary CIImage mask
    /// - Returns: Array of ContourMetrics for circular contours
    func detectCircularContours(in mask: CIImage) async throws -> [ContourMetrics] {
        // Check for cancellation before expensive Vision operation
        try Task.checkCancellation()

        // Run Vision detection on background queue to avoid blocking
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                do {
                    let result = try detectCircularContoursSync(in: mask)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Filter contours by circularity and size
    /// - Parameter contours: Array of VNContour objects
    /// - Returns: Array of ContourMetrics for valid ball candidates
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

            // Calculate circularity: 4 * pi * Area / Perimeter^2
            // Perfect circle = 1.0, Square = 0.785
            let circularity = (4 * .pi * area) / (perimeter * perimeter)
            guard circularity >= Self.circularityThreshold else {
                return nil
            }

            // Calculate centroid
            let centroid = calculateCentroid(path: path)
            let boundingBox = path.boundingBox

            return ContourMetrics(
                area: area,
                perimeter: perimeter,
                circularity: circularity,
                centroid: centroid,
                boundingBox: boundingBox,
                normalizedPath: path
            )
        }
    }

    /// Find the best ball candidate from contours
    /// - Parameters:
    ///   - contours: Array of ContourMetrics
    ///   - previousPosition: Previous ball position (for temporal consistency)
    /// - Returns: Best ball candidate or nil
    func selectBestCandidate(
        from candidates: [ContourMetrics],
        previousPosition: CGPoint? = nil
    ) -> ContourMetrics? {
        guard !candidates.isEmpty else { return nil }

        // If we have a previous detection, prefer the closest candidate
        if let previous = previousPosition {
            return candidates.min { a, b in
                let distA = hypot(a.centroid.x - previous.x, a.centroid.y - previous.y)
                let distB = hypot(b.centroid.x - previous.x, b.centroid.y - previous.y)
                return distA < distB
            }
        }

        // Otherwise, select by highest circularity
        return candidates.max { $0.circularity < $1.circularity }
    }

    // MARK: - Geometry Calculations

    /// Calculate signed area using the Shoelace formula
    /// - Parameter path: CGPath to analyze
    /// - Returns: Signed area (positive = counterclockwise, negative = clockwise)
    private func calculateSignedArea(path: CGPath) -> Double {
        var area: Double = 0
        var previousPoint: CGPoint?
        var firstPoint: CGPoint?

        path.applyWithBlock { element in
            let type = element.pointee.type
            let point: CGPoint

            switch type {
            case .moveToPoint:
                point = element.pointee.points[0]
                firstPoint = point
                previousPoint = point
                return

            case .addLineToPoint:
                point = element.pointee.points[0]
                if let prev = previousPoint {
                    // Shoelace formula: sum of (x1 * y2 - x2 * y1)
                    area += Double(prev.x * point.y - point.x * prev.y)
                }
                previousPoint = point

            case .closeSubpath:
                if let prev = previousPoint, let first = firstPoint {
                    area += Double(prev.x * first.y - first.x * prev.y)
                }
                return

            default:
                return
            }
        }

        return area / 2.0
    }

    /// Calculate perimeter of a path
    /// - Parameter path: CGPath to analyze
    /// - Returns: Total perimeter length
    private func calculatePerimeter(path: CGPath) -> Double {
        var perimeter: Double = 0
        var previousPoint: CGPoint?
        var firstPoint: CGPoint?

        path.applyWithBlock { element in
            let type = element.pointee.type
            let point: CGPoint

            switch type {
            case .moveToPoint:
                point = element.pointee.points[0]
                firstPoint = point
                previousPoint = point
                return

            case .addLineToPoint:
                point = element.pointee.points[0]
                if let prev = previousPoint {
                    let dx = Double(point.x - prev.x)
                    let dy = Double(point.y - prev.y)
                    perimeter += sqrt(dx * dx + dy * dy)
                }
                previousPoint = point

            case .closeSubpath:
                if let prev = previousPoint, let first = firstPoint {
                    let dx = Double(first.x - prev.x)
                    let dy = Double(first.y - prev.y)
                    perimeter += sqrt(dx * dx + dy * dy)
                }
                return

            default:
                return
            }
        }

        return perimeter
    }

    /// Calculate centroid of a path
    /// - Parameter path: CGPath to analyze
    /// - Returns: Centroid point
    private func calculateCentroid(path: CGPath) -> CGPoint {
        var sumX: Double = 0
        var sumY: Double = 0
        var count: Int = 0

        path.applyWithBlock { element in
            let type = element.pointee.type
            guard type == .addLineToPoint || type == .moveToPoint else { return }

            let point = element.pointee.points[0]
            sumX += Double(point.x)
            sumY += Double(point.y)
            count += 1
        }

        guard count > 0 else { return .zero }
        return CGPoint(x: sumX / Double(count), y: sumY / Double(count))
    }

    /// Calculate bounding circle for a contour
    /// - Parameter metrics: ContourMetrics to analyze
    /// - Returns: Tuple of (center, radius)
    func calculateBoundingCircle(for metrics: ContourMetrics) -> (center: CGPoint, radius: Double) {
        let center = metrics.centroid

        // Approximate radius from area (A = pi * r^2)
        let radius = sqrt(metrics.area / .pi)

        return (center, radius)
    }

    /// Calculate distance between two contours
    /// - Parameters:
    ///   - a: First ContourMetrics
    ///   - b: Second ContourMetrics
    /// - Returns: Distance between centroids
    func distance(from a: ContourMetrics, to b: ContourMetrics) -> Double {
        let dx = Double(a.centroid.x - b.centroid.x)
        let dy = Double(a.centroid.y - b.centroid.y)
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - CGPath Extension for Analysis

extension CGPath {
    /// Get all points from the path
    var allPoints: [CGPoint] {
        var points: [CGPoint] = []

        self.applyWithBlock { element in
            let type = element.pointee.type
            guard type == .addLineToPoint || type == .moveToPoint else { return }
            points.append(element.pointee.points[0])
        }

        return points
    }

    /// Get point count
    var pointCount: Int {
        var count = 0
        self.applyWithBlock { element in
            let type = element.pointee.type
            if type == .addLineToPoint || type == .moveToPoint {
                count += 1
            }
        }
        return count
    }
}

// MARK: - Vision Contour Extension

extension VNContour {
    /// Convert normalized contour to pixel coordinates
    /// - Parameters:
    ///   - width: Frame width in pixels
    ///   - height: Frame height in pixels
    /// - Returns: Contour path in pixel coordinates
    func toPixelCoordinates(width: CGFloat, height: CGFloat) -> CGPath {
        let transform = CGAffineTransform(scaleX: width, y: height)
        return normalizedPath.copy(using: [transform]) ?? normalizedPath
    }

    /// Get centroid in normalized coordinates
    var normalizedCentroid: CGPoint {
        let bounds = normalizedPath.boundingBox
        return CGPoint(
            x: bounds.midX,
            y: bounds.midY
        )
    }

    /// Get centroid in pixel coordinates
    func pixelCentroid(width: CGFloat, height: CGFloat) -> CGPoint {
        let normalized = normalizedCentroid
        return CGPoint(
            x: normalized.x * width,
            y: (1 - normalized.y) * height  // Flip Y for screen coordinates
        )
    }
}
