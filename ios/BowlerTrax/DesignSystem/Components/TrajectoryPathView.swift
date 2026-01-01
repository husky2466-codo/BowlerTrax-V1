//
//  TrajectoryPathView.swift
//  BowlerTrax
//
//  Animated ball trajectory path with phase-based colors
//

import SwiftUI

// MARK: - Phase Colors

extension Color {
    /// Skid phase color - Blue (#3B82F6)
    static let btPhaseSkid = Color(hex: "3B82F6")

    /// Hook phase color - Red (#EF4444)
    static let btPhaseHook = Color(hex: "EF4444")

    /// Roll phase color - Green (#22C55E)
    static let btPhaseRoll = Color(hex: "22C55E")

    /// Comparison trajectory color - Muted gray
    static let btTrajectoryComparison = Color(hex: "6B7280")
}

// MARK: - TrajectoryPathView

/// Animated ball trajectory with phase-based coloring
struct TrajectoryPathView: View {
    // MARK: - Properties

    /// Primary trajectory points
    let trajectory: [TrajectoryPoint]

    /// Optional comparison trajectory (rendered in muted color)
    var comparisonTrajectory: [TrajectoryPoint]?

    /// Whether to animate the path drawing
    var isAnimating: Bool = true

    /// Path line width
    var lineWidth: CGFloat = 3

    /// Ball indicator radius
    var ballRadius: CGFloat = 6

    /// Show glow effect on path
    var showGlow: Bool = true

    // MARK: - State

    @State private var animationProgress: CGFloat = 0
    @State private var currentPointIndex: Int = 0

    // MARK: - Constants

    private let animationDuration: Double = BTAnimation.trajectory

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Comparison trajectory (if provided)
                if let comparison = comparisonTrajectory, !comparison.isEmpty {
                    comparisonPath(points: comparison, size: geometry.size)
                }

                // Primary trajectory with phase colors
                if !trajectory.isEmpty {
                    // Glow layer
                    if showGlow {
                        glowPath(size: geometry.size)
                    }

                    // Main trajectory path
                    trajectoryPath(size: geometry.size)

                    // Ball position indicator
                    ballIndicator(size: geometry.size)
                }
            }
        }
        .onAppear {
            if isAnimating {
                startAnimation()
            } else {
                animationProgress = 1.0
                currentPointIndex = trajectory.count - 1
            }
        }
        .onChange(of: trajectory) { _, _ in
            if isAnimating {
                animationProgress = 0
                currentPointIndex = 0
                startAnimation()
            }
        }
    }

    // MARK: - Subviews

    private func trajectoryPath(size: CGSize) -> some View {
        Canvas { context, _ in
            guard trajectory.count >= 2 else { return }

            let visiblePoints = getVisiblePoints()
            guard visiblePoints.count >= 2 else { return }

            // Draw path segments with phase colors
            for i in 0..<(visiblePoints.count - 1) {
                let startPoint = visiblePoints[i]
                let endPoint = visiblePoints[i + 1]

                let startPos = pointToPosition(startPoint, size: size)
                let endPos = pointToPosition(endPoint, size: size)

                var segmentPath = Path()
                segmentPath.move(to: startPos)
                segmentPath.addLine(to: endPos)

                let phaseColor = colorForPhase(at: startPoint)

                context.stroke(
                    segmentPath,
                    with: .color(phaseColor),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }

    private func glowPath(size: CGSize) -> some View {
        Canvas { context, _ in
            guard trajectory.count >= 2 else { return }

            let visiblePoints = getVisiblePoints()
            guard visiblePoints.count >= 2 else { return }

            for i in 0..<(visiblePoints.count - 1) {
                let startPoint = visiblePoints[i]
                let endPoint = visiblePoints[i + 1]

                let startPos = pointToPosition(startPoint, size: size)
                let endPos = pointToPosition(endPoint, size: size)

                var segmentPath = Path()
                segmentPath.move(to: startPos)
                segmentPath.addLine(to: endPos)

                let phaseColor = colorForPhase(at: startPoint)

                // Glow effect - wider, semi-transparent stroke
                context.stroke(
                    segmentPath,
                    with: .color(phaseColor.opacity(0.3)),
                    style: StrokeStyle(lineWidth: lineWidth * 3, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .blur(radius: 4)
    }

    private func comparisonPath(points: [TrajectoryPoint], size: CGSize) -> some View {
        Canvas { context, _ in
            guard points.count >= 2 else { return }

            var path = Path()
            let firstPos = pointToPosition(points[0], size: size)
            path.move(to: firstPos)

            for i in 1..<points.count {
                let pos = pointToPosition(points[i], size: size)
                path.addLine(to: pos)
            }

            context.stroke(
                path,
                with: .color(Color.btTrajectoryComparison.opacity(0.5)),
                style: StrokeStyle(lineWidth: lineWidth * 0.8, lineCap: .round, lineJoin: .round, dash: [6, 4])
            )
        }
    }

    private func ballIndicator(size: CGSize) -> some View {
        let currentPoint = getCurrentPoint()
        let position = pointToPosition(currentPoint, size: size)
        let phaseColor = colorForPhase(at: currentPoint)

        return ZStack {
            // Outer glow
            Circle()
                .fill(phaseColor.opacity(0.3))
                .frame(width: ballRadius * 3, height: ballRadius * 3)
                .blur(radius: 4)

            // Main ball
            Circle()
                .fill(phaseColor)
                .frame(width: ballRadius * 2, height: ballRadius * 2)

            // Inner highlight
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: ballRadius * 0.8, height: ballRadius * 0.8)
                .offset(x: -ballRadius * 0.3, y: -ballRadius * 0.3)
        }
        .position(position)
    }

    // MARK: - Helper Methods

    private func startAnimation() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            animationProgress = 1.0
        }

        // Update current point index during animation
        let totalPoints = trajectory.count
        for i in 0..<totalPoints {
            let delay = animationDuration * Double(i) / Double(totalPoints)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                currentPointIndex = i
            }
        }
    }

    private func getVisiblePoints() -> [TrajectoryPoint] {
        guard !trajectory.isEmpty else { return [] }

        let visibleCount = Int(ceil(Double(trajectory.count) * Double(animationProgress)))
        return Array(trajectory.prefix(max(1, visibleCount)))
    }

    private func getCurrentPoint() -> TrajectoryPoint {
        guard !trajectory.isEmpty else {
            return TrajectoryPoint(x: 0, y: 0, timestamp: 0, frameNumber: 0)
        }

        let index = min(currentPointIndex, trajectory.count - 1)
        return trajectory[index]
    }

    private func pointToPosition(_ point: TrajectoryPoint, size: CGSize) -> CGPoint {
        // Use board and distanceFt if available, otherwise fall back to pixel coordinates
        let board = point.board ?? point.realWorldX ?? 20.0
        let distanceFt = point.distanceFt ?? point.realWorldY ?? 30.0

        let x = boardToX(board: board, width: size.width)
        let y = distanceToY(feet: distanceFt, height: size.height)

        return CGPoint(x: x, y: y)
    }

    private func boardToX(board: Double, width: CGFloat) -> CGFloat {
        let boardWidth = width / CGFloat(LaneConstants.boardCount)
        return CGFloat(board - 0.5) * boardWidth
    }

    private func distanceToY(feet: Double, height: CGFloat) -> CGFloat {
        let normalizedY = feet / LaneConstants.laneLength
        return CGFloat(normalizedY) * height
    }

    private func colorForPhase(at point: TrajectoryPoint) -> Color {
        // Use explicit phase if available
        if let phase = point.phase {
            switch phase {
            case .skid:
                return .btPhaseSkid
            case .hook:
                return .btPhaseHook
            case .roll:
                return .btPhaseRoll
            }
        }

        // Otherwise determine phase from distance
        let distance = point.distanceFt ?? point.realWorldY ?? 0

        if distance < LaneConstants.skidEndDistance {
            return .btPhaseSkid
        } else if distance < LaneConstants.hookEndDistance {
            return .btPhaseHook
        } else {
            return .btPhaseRoll
        }
    }
}

// MARK: - Preview

#Preview("Trajectory Path - Animated") {
    let sampleTrajectory = createSampleTrajectory()

    ZStack {
        LaneCanvas()

        TrajectoryPathView(
            trajectory: sampleTrajectory,
            isAnimating: true
        )
    }
    .frame(height: 600)
    .padding()
    .background(Color.btBackground)
}

#Preview("Trajectory Path - With Comparison") {
    let primary = createSampleTrajectory()
    let comparison = createComparisonTrajectory()

    ZStack {
        LaneCanvas()

        TrajectoryPathView(
            trajectory: primary,
            comparisonTrajectory: comparison,
            isAnimating: false
        )
    }
    .frame(height: 600)
    .padding()
    .background(Color.btBackground)
}

// MARK: - Preview Helpers

private func createSampleTrajectory() -> [TrajectoryPoint] {
    var points: [TrajectoryPoint] = []

    // Simulate a right-handed strike ball
    // Starts at board 15, hooks to pocket at board 17.5

    for i in 0..<60 {
        let distance = Double(i)
        let progress = distance / 60.0

        // Calculate board position with hook shape
        var board: Double
        let phase: BallPhase

        if distance < 35 {
            // Skid phase - relatively straight
            board = 15 + progress * 2
            phase = .skid
        } else if distance < 46 {
            // Hook phase - curve toward pocket
            let hookProgress = (distance - 35) / 11.0
            board = 17 + hookProgress * 1.5
            phase = .hook
        } else {
            // Roll phase - slight continuation to pocket
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

private func createComparisonTrajectory() -> [TrajectoryPoint] {
    var points: [TrajectoryPoint] = []

    // Different trajectory for comparison - more hook
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
