//
//  LaneVisualizer.swift
//  BowlerTrax
//
//  Main lane visualization container combining canvas, trajectory, and oil pattern
//

import SwiftUI

// MARK: - Oil Pattern Overlay

/// Overlay view showing oil pattern on lane
/// Uses the existing OilPattern model from Models/Domain/OilPattern.swift
struct OilPatternOverlay: View {
    let pattern: OilPattern

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                drawOilPattern(context: context, size: size)
            }
        }
    }

    private func drawOilPattern(context: GraphicsContext, size: CGSize) {
        let boardWidth = size.width / CGFloat(LaneConstants.boardCount)
        let oilEndY = (Double(pattern.lengthFeet) / LaneConstants.laneLength) * Double(size.height)

        // Calculate oil density based on pattern ratio
        // Higher ratio = more oil in center, less on edges (typical house pattern)
        // Lower ratio = more even distribution (sport pattern)
        let ratio = pattern.ratio ?? 10.0

        for board in 1...39 {
            let oilDensity = calculateOilDensity(board: board, ratio: ratio)
            guard oilDensity > 0 else { continue }

            let x = CGFloat(board - 1) * boardWidth
            let rect = CGRect(
                x: x,
                y: 0,
                width: boardWidth,
                height: CGFloat(oilEndY)
            )

            // Oil color with density-based opacity
            let oilColor = Color.btAccent.opacity(oilDensity * 0.2)
            context.fill(Path(rect), with: .color(oilColor))
        }

        // Draw oil pattern end line
        var endLine = Path()
        endLine.move(to: CGPoint(x: 0, y: oilEndY))
        endLine.addLine(to: CGPoint(x: size.width, y: oilEndY))

        context.stroke(
            endLine,
            with: .color(Color.btAccent.opacity(0.4)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 2])
        )
    }

    /// Calculate oil density for a board based on pattern ratio
    /// Higher ratio = more difference between center and edges
    private func calculateOilDensity(board: Int, ratio: Double) -> Double {
        // Center of lane is board 20
        let center = 20.0
        let distanceFromCenter = abs(Double(board) - center)

        // Normalize distance (0 at center, 1 at edge)
        let normalizedDistance = distanceFromCenter / 19.0

        // Calculate density based on ratio
        // High ratio (10:1): center = 0.9, edge = 0.1
        // Low ratio (2:1): center = 0.7, edge = 0.35
        let maxDensity = min(0.9, 0.5 + (ratio / 40.0))
        let minDensity = max(0.1, maxDensity / ratio)

        return maxDensity - (normalizedDistance * (maxDensity - minDensity))
    }
}

// MARK: - Lane Visualizer

/// Main lane visualization container
struct LaneVisualizer: View {
    // MARK: - Properties

    /// Primary trajectory to display
    let trajectory: [TrajectoryPoint]?

    /// Optional comparison trajectory
    var comparisonTrajectory: [TrajectoryPoint]?

    /// Optional oil pattern overlay
    var oilPattern: OilPattern?

    /// Show arrow markers
    var showArrows: Bool = true

    /// Show board numbers
    var showBoardNumbers: Bool = true

    /// Show distance markers
    var showDistanceMarkers: Bool = true

    /// Animate trajectory drawing
    var isAnimating: Bool = true

    /// Show glow effect on trajectory
    var showTrajectoryGlow: Bool = true

    // MARK: - Computed Properties

    /// Lane aspect ratio (length : width in feet)
    /// Lane is 60ft long, 41.5 inches (3.46 ft) wide = ~17.3:1
    private var laneAspectRatio: CGFloat {
        CGFloat(LaneConstants.laneLength / (LaneConstants.laneWidth / 12.0))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Lane canvas (background)
                LaneCanvas(
                    showBoardNumbers: showBoardNumbers,
                    showArrows: showArrows,
                    showDistanceMarkers: showDistanceMarkers
                )

                // Layer 2: Oil pattern overlay (if provided)
                if let pattern = oilPattern {
                    OilPatternOverlay(pattern: pattern)
                }

                // Layer 3: Trajectory path (if provided)
                if let points = trajectory, !points.isEmpty {
                    TrajectoryPathView(
                        trajectory: points,
                        comparisonTrajectory: comparisonTrajectory,
                        isAnimating: isAnimating,
                        showGlow: showTrajectoryGlow
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: BTLayout.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: BTLayout.cardCornerRadius)
                    .stroke(Color.btBorder, lineWidth: 1)
            )
        }
        .aspectRatio(laneAspectRatio, contentMode: .fit)
    }
}

// MARK: - Convenience Initializers

extension LaneVisualizer {
    /// Empty lane visualizer (no trajectory)
    init(
        showArrows: Bool = true,
        showBoardNumbers: Bool = true,
        showDistanceMarkers: Bool = true,
        oilPattern: OilPattern? = nil
    ) {
        self.trajectory = nil
        self.comparisonTrajectory = nil
        self.oilPattern = oilPattern
        self.showArrows = showArrows
        self.showBoardNumbers = showBoardNumbers
        self.showDistanceMarkers = showDistanceMarkers
        self.isAnimating = false
        self.showTrajectoryGlow = true
    }

    /// Lane visualizer with single trajectory
    init(
        trajectory: [TrajectoryPoint],
        showArrows: Bool = true,
        showBoardNumbers: Bool = true,
        showDistanceMarkers: Bool = true,
        isAnimating: Bool = true,
        oilPattern: OilPattern? = nil
    ) {
        self.trajectory = trajectory
        self.comparisonTrajectory = nil
        self.oilPattern = oilPattern
        self.showArrows = showArrows
        self.showBoardNumbers = showBoardNumbers
        self.showDistanceMarkers = showDistanceMarkers
        self.isAnimating = isAnimating
        self.showTrajectoryGlow = true
    }
}

// MARK: - Preview

#Preview("Lane Visualizer - Empty") {
    VStack {
        Text("Empty Lane")
            .font(.headline)
            .foregroundColor(.btTextPrimary)

        LaneVisualizer(
            showArrows: true,
            showBoardNumbers: true,
            showDistanceMarkers: true
        )
        .frame(height: 500)
    }
    .padding()
    .background(Color.btBackground)
}

#Preview("Lane Visualizer - With Trajectory") {
    let trajectory = createPreviewTrajectory()

    VStack {
        Text("With Trajectory")
            .font(.headline)
            .foregroundColor(.btTextPrimary)

        LaneVisualizer(
            trajectory: trajectory,
            showArrows: true,
            showBoardNumbers: true,
            isAnimating: true
        )
        .frame(height: 500)
    }
    .padding()
    .background(Color.btBackground)
}

#Preview("Lane Visualizer - With Oil Pattern") {
    let trajectory = createPreviewTrajectory()

    VStack {
        Text("With Oil Pattern")
            .font(.headline)
            .foregroundColor(.btTextPrimary)

        LaneVisualizer(
            trajectory: trajectory,
            comparisonTrajectory: nil,
            oilPattern: .houseShot,
            showArrows: true,
            showBoardNumbers: true,
            showDistanceMarkers: true,
            isAnimating: false
        )
        .frame(height: 500)
    }
    .padding()
    .background(Color.btBackground)
}

#Preview("Lane Visualizer - Comparison Mode") {
    let primary = createPreviewTrajectory()
    let comparison = createPreviewComparisonTrajectory()

    VStack {
        Text("Comparison Mode")
            .font(.headline)
            .foregroundColor(.btTextPrimary)

        LaneVisualizer(
            trajectory: primary,
            comparisonTrajectory: comparison,
            oilPattern: nil,
            showArrows: true,
            showBoardNumbers: true,
            showDistanceMarkers: true,
            isAnimating: false
        )
        .frame(height: 500)
    }
    .padding()
    .background(Color.btBackground)
}

// MARK: - Preview Helpers

private func createPreviewTrajectory() -> [TrajectoryPoint] {
    var points: [TrajectoryPoint] = []

    for i in 0..<60 {
        let distance = Double(i)
        let progress = distance / 60.0

        var board: Double
        let phase: BallPhase

        if distance < 35 {
            board = 15 + progress * 2
            phase = .skid
        } else if distance < 46 {
            let hookProgress = (distance - 35) / 11.0
            board = 17 + hookProgress * 1.5
            phase = .hook
        } else {
            let rollProgress = (distance - 46) / 14.0
            board = 18.5 - rollProgress * 1
            phase = .roll
        }

        points.append(TrajectoryPoint(
            x: 0, y: 0,
            timestamp: TimeInterval(i) * 0.05,
            frameNumber: i,
            board: board,
            distanceFt: distance,
            phase: phase
        ))
    }

    return points
}

private func createPreviewComparisonTrajectory() -> [TrajectoryPoint] {
    var points: [TrajectoryPoint] = []

    for i in 0..<60 {
        let distance = Double(i)
        let progress = distance / 60.0

        var board: Double
        if distance < 35 {
            board = 12 + progress * 3
        } else if distance < 46 {
            let hookProgress = (distance - 35) / 11.0
            board = 15 + hookProgress * 4
        } else {
            let rollProgress = (distance - 46) / 14.0
            board = 19 - rollProgress * 1.5
        }

        points.append(TrajectoryPoint(
            x: 0, y: 0,
            timestamp: TimeInterval(i) * 0.05,
            frameNumber: i,
            board: board,
            distanceFt: distance
        ))
    }

    return points
}
