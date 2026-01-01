//
//  ShotPopup.swift
//  BowlerTrax
//
//  5-second popup that appears after a shot is recorded.
//  Shows compact lane visualizer, key metrics, and auto-dismiss countdown.
//

import SwiftUI

// MARK: - Shot Popup

/// Popup overlay displaying shot results after recording
struct ShotPopup: View {
    // MARK: - Properties

    let shot: ShotAnalysis
    let onDismiss: () -> Void

    // MARK: - State

    @State private var timeRemaining: Double = 5.0
    @State private var isVisible: Bool = true
    @State private var timer: Timer?

    // MARK: - Constants

    private let totalDuration: Double = 5.0
    private let updateInterval: Double = 0.05

    // MARK: - Body

    var body: some View {
        if isVisible {
            HStack(spacing: BTSpacing.md) {
                // Compact lane visualizer
                CompactLaneVisualizer(trajectory: shot.trajectory)
                    .frame(width: 200, height: 120)

                // Metrics section
                VStack(alignment: .leading, spacing: BTSpacing.sm) {
                    // Header
                    Text("Shot Recorded")
                        .font(BTFont.labelSmall())
                        .foregroundColor(.btTextMuted)
                        .textCase(.uppercase)

                    // Speed
                    if let speed = shot.launchSpeed {
                        HStack(spacing: BTSpacing.xs) {
                            Text(String(format: "%.1f", speed))
                                .font(BTFont.h3())
                                .foregroundColor(.btTextPrimary)
                                .monospacedDigit()
                            Text("mph")
                                .font(BTFont.caption())
                                .foregroundColor(.btSpeed)
                        }
                    }

                    // Entry Angle
                    if let angle = shot.entryAngle?.angleDegrees {
                        HStack(spacing: BTSpacing.xs) {
                            Text(String(format: "%.1f", angle))
                                .font(BTFont.h4())
                                .foregroundColor(.btTextPrimary)
                                .monospacedDigit()
                            Text("deg")
                                .font(BTFont.caption())
                                .foregroundColor(.btAngle)
                        }
                    }

                    // Entry Board
                    if let board = shot.pocketBoard ?? shot.arrowBoard {
                        HStack(spacing: BTSpacing.xs) {
                            Text("Board")
                                .font(BTFont.captionSmall())
                                .foregroundColor(.btTextMuted)
                            Text(String(format: "%.1f", board))
                                .font(BTFont.label())
                                .foregroundColor(.btTextPrimary)
                                .monospacedDigit()
                        }
                    }
                }

                Spacer()

                // Timer and dismiss
                VStack(spacing: BTSpacing.sm) {
                    // Circular progress timer
                    ZStack {
                        Circle()
                            .stroke(Color.btSurfaceHighlight, lineWidth: 3)

                        Circle()
                            .trim(from: 0, to: timeRemaining / totalDuration)
                            .stroke(Color.btPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: updateInterval), value: timeRemaining)

                        Text(String(format: "%.0f", ceil(timeRemaining)))
                            .font(BTFont.labelSmall())
                            .foregroundColor(.btTextSecondary)
                            .monospacedDigit()
                    }
                    .frame(width: 36, height: 36)

                    // Dismiss button
                    Button {
                        dismissPopup()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.btTextMuted)
                            .frame(width: 28, height: 28)
                            .background(Color.btSurfaceHighlight)
                            .cornerRadius(14)
                    }
                }
            }
            .padding(BTSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.btSurface.opacity(0.95))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.btPrimary.opacity(0.3), lineWidth: 1)
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            ))
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    // MARK: - Timer Control

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= updateInterval
            } else {
                dismissPopup()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func dismissPopup() {
        stopTimer()
        withAnimation(BTAnimation.easeOutNormal) {
            isVisible = false
        }
        // Slight delay before calling dismiss callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Compact Lane Visualizer

/// Simplified lane view showing ball trajectory
struct CompactLaneVisualizer: View {
    let trajectory: [TrajectoryPoint]

    // Lane dimensions (in normalized 0-1 space)
    private let laneAspectRatio: CGFloat = 60.0 / 41.5 * 3  // Compressed for display

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Lane background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.btLaneWood.opacity(0.3))

                // Gutter lines
                HStack {
                    Rectangle()
                        .fill(Color.btTextMuted.opacity(0.3))
                        .frame(width: 2)
                    Spacer()
                    Rectangle()
                        .fill(Color.btTextMuted.opacity(0.3))
                        .frame(width: 2)
                }
                .padding(.horizontal, 4)

                // Arrow markers (at ~25% from bottom)
                arrowMarkers(in: geometry.size)

                // Foul line
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.btWarning.opacity(0.5))
                        .frame(height: 2)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                }

                // Pins area (at top)
                VStack {
                    pinArea
                        .padding(.top, 8)
                    Spacer()
                }

                // Ball trajectory
                if !trajectory.isEmpty {
                    trajectoryPath(in: geometry.size)
                }
            }
        }
    }

    @ViewBuilder
    private func arrowMarkers(in size: CGSize) -> some View {
        let arrowY = size.height * 0.65  // 65% from top
        let laneWidth = size.width - 8
        let arrowBoards: [Double] = [10, 15, 20, 25, 30]  // Main arrows

        ForEach(arrowBoards, id: \.self) { board in
            let normalizedX = (board - 1) / 38.0  // Boards 1-39
            let x = 4 + laneWidth * normalizedX

            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 6))
                .foregroundColor(.btPrimary.opacity(0.4))
                .position(x: x, y: arrowY)
        }
    }

    private var pinArea: some View {
        // Simplified pin triangle
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { _ in
                Circle()
                    .fill(Color.btTextPrimary.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }

    @ViewBuilder
    private func trajectoryPath(in size: CGSize) -> some View {
        let laneWidth = size.width - 8
        let laneHeight = size.height - 16

        Path { path in
            guard let firstPoint = trajectory.first else { return }

            // Convert trajectory points to view coordinates
            // Use board (real-world board number) or x position
            let startBoard = firstPoint.board ?? firstPoint.realWorldX ?? 20
            let startDist = firstPoint.distanceFt ?? firstPoint.realWorldY ?? 0
            let startX = 4 + laneWidth * normalizeBoard(startBoard)
            let startY = 8 + laneHeight * (1 - normalizeDistance(startDist))

            path.move(to: CGPoint(x: startX, y: startY))

            for point in trajectory.dropFirst() {
                let board = point.board ?? point.realWorldX ?? 20
                let dist = point.distanceFt ?? point.realWorldY ?? 0
                let x = 4 + laneWidth * normalizeBoard(board)
                let y = 8 + laneHeight * (1 - normalizeDistance(dist))
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        .stroke(
            LinearGradient(
                colors: [.btPrimary, .btAccent],
                startPoint: .bottom,
                endPoint: .top
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
        .shadow(color: .btPrimary.opacity(0.5), radius: 4)

        // Ball position at end of trajectory
        if let lastPoint = trajectory.last {
            let board = lastPoint.board ?? lastPoint.realWorldX ?? 20
            let dist = lastPoint.distanceFt ?? lastPoint.realWorldY ?? 0
            let x = 4 + laneWidth * normalizeBoard(board)
            let y = 8 + laneHeight * (1 - normalizeDistance(dist))

            Circle()
                .fill(Color.btAccent)
                .frame(width: 10, height: 10)
                .shadow(color: .btAccent.opacity(0.5), radius: 4)
                .position(x: x, y: y)
        }
    }

    private func normalizeBoard(_ board: Double) -> CGFloat {
        // Boards 1-39, normalize to 0-1
        return CGFloat((board - 1) / 38.0)
    }

    private func normalizeDistance(_ feet: Double) -> CGFloat {
        // Distance 0-60 feet, normalize to 0-1
        return CGFloat(min(feet / 60.0, 1.0))
    }
}

// MARK: - Preview Support

/// Creates sample trajectory points for previews
private func makeSampleTrajectory() -> [TrajectoryPoint] {
    [
        TrajectoryPoint(x: 540, y: 100, timestamp: 0, frameNumber: 0, board: 20, distanceFt: 0),
        TrajectoryPoint(x: 480, y: 300, timestamp: 0.25, frameNumber: 30, board: 18, distanceFt: 15),
        TrajectoryPoint(x: 400, y: 500, timestamp: 0.5, frameNumber: 60, board: 15, distanceFt: 35),
        TrajectoryPoint(x: 450, y: 720, timestamp: 0.75, frameNumber: 90, board: 17.5, distanceFt: 60)
    ]
}

/// Creates a sample ShotAnalysis for previews
private func makeSampleShotAnalysis() -> ShotAnalysis {
    ShotAnalysis(
        id: UUID(),
        trajectory: makeSampleTrajectory(),
        launchSpeed: 17.2,
        impactSpeed: 15.8,
        entryAngle: EntryAngleResult(
            angleDegrees: 5.8,
            isOptimal: true,
            direction: .left,
            recommendation: "Great angle!",
            pocketBoard: 17.5,
            confidence: 0.9
        ),
        revRate: RevRateResult(
            rpm: 350,
            category: .tweener,
            totalRotation: 720,
            timePeriod: 2.0,
            method: .markerTracking,
            confidence: 0.85
        ),
        strikeProbability: StrikeProbabilityResult(
            probability: 0.73,
            factors: StrikeFactors(pocketScore: 0.8, angleScore: 0.9, speedScore: 0.7, revScore: 0.75),
            predictedLeave: .strike,
            recommendation: nil,
            riskLevel: .low
        ),
        arrowBoard: 15.2,
        breakpoint: (board: 10.5, distance: 38.0),
        pocketBoard: 17.5,
        duration: 2.1,
        frameCount: 252
    )
}

// MARK: - Preview

#Preview("Shot Popup") {
    ZStack {
        Color.btBackground
            .ignoresSafeArea()

        VStack {
            Spacer()

            ShotPopup(
                shot: makeSampleShotAnalysis(),
                onDismiss: { print("Dismissed") }
            )
            .padding(.horizontal, BTSpacing.lg)
            .padding(.bottom, 100)
        }
    }
}

#Preview("Compact Lane Visualizer") {
    ZStack {
        Color.btBackground
            .ignoresSafeArea()

        CompactLaneVisualizer(trajectory: makeSampleTrajectory())
            .frame(width: 200, height: 120)
            .padding()
    }
}
