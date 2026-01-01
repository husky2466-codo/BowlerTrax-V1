//
//  LaneOverlayView.swift
//  BowlerTrax
//
//  Visual overlay showing detected lane features during calibration.
//  Displays gutters, foul line, and arrows with confidence-based coloring.
//

import SwiftUI

// MARK: - Lane Overlay View

/// Overlay view displaying detected lane features
struct LaneOverlayView: View {
    // MARK: - Properties

    let detectionResult: LaneDetectionResult
    let showLabels: Bool
    let animateDetection: Bool

    // Animation state
    @State private var pulseAnimation = false
    @State private var drawProgress: CGFloat = 0

    // MARK: - Initialization

    init(
        detectionResult: LaneDetectionResult,
        showLabels: Bool = true,
        animateDetection: Bool = true
    ) {
        self.detectionResult = detectionResult
        self.showLabels = showLabels
        self.animateDetection = animateDetection
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Lane rectangle background
                if let rect = detectionResult.laneRectangle {
                    laneRectangleOverlay(rect: rect, size: geometry.size)
                }

                // Left gutter line
                if let leftPoints = detectionResult.leftGutterLine {
                    gutterLineOverlay(
                        points: leftPoints,
                        size: geometry.size,
                        isLeft: true
                    )
                }

                // Right gutter line
                if let rightPoints = detectionResult.rightGutterLine {
                    gutterLineOverlay(
                        points: rightPoints,
                        size: geometry.size,
                        isLeft: false
                    )
                }

                // Foul line
                if let foulLine = detectionResult.foulLine {
                    foulLineOverlay(line: foulLine, size: geometry.size)
                }

                // Arrow markers
                if let arrows = detectionResult.arrowPositions {
                    ForEach(arrows) { arrow in
                        arrowMarkerOverlay(arrow: arrow, size: geometry.size)
                    }
                }

                // Confidence indicator
                if showLabels {
                    confidenceIndicator
                }
            }
            .onAppear {
                if animateDetection {
                    startAnimations()
                }
            }
        }
    }

    // MARK: - Lane Rectangle

    @ViewBuilder
    private func laneRectangleOverlay(rect: CGRect, size: CGSize) -> some View {
        let pixelRect = CGRect(
            x: rect.origin.x * size.width,
            y: rect.origin.y * size.height,
            width: rect.width * size.width,
            height: rect.height * size.height
        )

        Rectangle()
            .fill(Color.btPrimary.opacity(0.05))
            .frame(width: pixelRect.width, height: pixelRect.height)
            .position(
                x: pixelRect.midX,
                y: pixelRect.midY
            )
            .overlay(
                Rectangle()
                    .stroke(
                        Color.btPrimary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1, dash: [8, 4])
                    )
                    .frame(width: pixelRect.width, height: pixelRect.height)
                    .position(x: pixelRect.midX, y: pixelRect.midY)
            )
    }

    // MARK: - Gutter Lines

    @ViewBuilder
    private func gutterLineOverlay(points: [CGPoint], size: CGSize, isLeft: Bool) -> some View {
        let color = colorForConfidence(detectionResult.confidence)

        Path { path in
            guard !points.isEmpty else { return }

            let scaledPoints = points.map { point in
                CGPoint(x: point.x * size.width, y: point.y * size.height)
            }

            path.move(to: scaledPoints[0])
            for point in scaledPoints.dropFirst() {
                path.addLine(to: point)
            }
        }
        .trim(from: 0, to: animateDetection ? drawProgress : 1)
        .stroke(
            color,
            style: StrokeStyle(
                lineWidth: 3,
                lineCap: .round,
                lineJoin: .round
            )
        )
        .shadow(color: color.opacity(0.5), radius: 4)

        // Gutter label
        if showLabels, let firstPoint = points.first {
            let position = CGPoint(
                x: firstPoint.x * size.width + (isLeft ? 20 : -20),
                y: firstPoint.y * size.height
            )

            Text(isLeft ? "L" : "R")
                .font(BTFont.captionSmall())
                .foregroundColor(color)
                .padding(4)
                .background(Color.btSurface.opacity(0.8))
                .cornerRadius(4)
                .position(position)
        }
    }

    // MARK: - Foul Line

    @ViewBuilder
    private func foulLineOverlay(line: LineSeg, size: CGSize) -> some View {
        let color = colorForConfidence(detectionResult.confidence)
        let start = CGPoint(x: line.start.x * size.width, y: line.start.y * size.height)
        let end = CGPoint(x: line.end.x * size.width, y: line.end.y * size.height)

        // Main foul line
        Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .trim(from: 0, to: animateDetection ? drawProgress : 1)
        .stroke(
            Color.btWarning,
            style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .shadow(color: Color.btWarning.opacity(0.5), radius: 6)

        // Animated pulse effect
        if animateDetection && pulseAnimation {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(
                Color.btWarning.opacity(0.3),
                style: StrokeStyle(lineWidth: 8, lineCap: .round)
            )
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseAnimation)
        }

        // Foul line label
        if showLabels {
            let midpoint = CGPoint(
                x: (start.x + end.x) / 2,
                y: (start.y + end.y) / 2 - 20
            )

            Text("FOUL LINE")
                .font(BTFont.captionSmall())
                .fontWeight(.bold)
                .foregroundColor(.btWarning)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.btSurface.opacity(0.9))
                .cornerRadius(4)
                .position(midpoint)
        }
    }

    // MARK: - Arrow Markers

    @ViewBuilder
    private func arrowMarkerOverlay(arrow: ArrowDetection, size: CGSize) -> some View {
        let position = CGPoint(
            x: arrow.position.x * size.width,
            y: arrow.position.y * size.height
        )
        let color = colorForConfidence(arrow.confidence)

        ZStack {
            // Outer glow
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 36, height: 36)
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)

            // Main circle
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )

            // Arrow icon (triangle pointing up)
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 10))
                .foregroundColor(.white)
        }
        .position(position)
        .opacity(animateDetection ? (drawProgress > 0.5 ? 1 : 0) : 1)
        .animation(.easeIn(duration: 0.3), value: drawProgress)

        // Board label
        if showLabels {
            Text("Bd \(arrow.boardNumber)")
                .font(BTFont.captionSmall())
                .foregroundColor(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.btSurface.opacity(0.9))
                .cornerRadius(4)
                .position(x: position.x, y: position.y + 28)
        }
    }

    // MARK: - Confidence Indicator

    private var confidenceIndicator: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(colorForConfidence(detectionResult.confidence))
                    .frame(width: 10, height: 10)

                Text("\(Int(detectionResult.confidence * 100))%")
                    .font(BTFont.mono())
                    .foregroundColor(.btTextPrimary)
            }

            Text(confidenceLabel)
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextSecondary)
        }
        .padding(8)
        .background(Color.btSurface.opacity(0.9))
        .cornerRadius(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(12)
    }

    // MARK: - Helpers

    private func colorForConfidence(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...1.0:
            return .btSuccess  // Green - high confidence
        case 0.6..<0.8:
            return .btPrimary  // Teal - good confidence
        case 0.4..<0.6:
            return .btWarning  // Yellow/Orange - medium confidence
        default:
            return .btError    // Red - low confidence
        }
    }

    private var confidenceLabel: String {
        switch detectionResult.confidence {
        case 0.8...1.0:
            return "Excellent"
        case 0.6..<0.8:
            return "Good"
        case 0.4..<0.6:
            return "Fair"
        default:
            return "Low"
        }
    }

    private func startAnimations() {
        // Draw animation
        withAnimation(.easeOut(duration: 1.5)) {
            drawProgress = 1.0
        }

        // Start pulse animation after draw completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            pulseAnimation = true
        }
    }
}

// MARK: - Detection Progress View

/// Animated view showing detection in progress
struct LaneDetectionProgressView: View {
    let state: LaneDetectionState
    let onCancel: () -> Void

    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: BTSpacing.lg) {
            // Animated scanner graphic
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.btSurfaceHighlight, lineWidth: 4)
                    .frame(width: 100, height: 100)

                // Progress arc
                Circle()
                    .trim(from: 0, to: state.progress)
                    .stroke(
                        Color.btPrimary,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: state.progress)

                // Scanning line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.btPrimary.opacity(0), Color.btPrimary, Color.btPrimary.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80, height: 3)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotation)

                // Center icon
                Image(systemName: "viewfinder")
                    .font(.system(size: 32))
                    .foregroundColor(.btPrimary)
            }

            // Status text
            VStack(spacing: BTSpacing.xs) {
                Text(statusTitle)
                    .font(BTFont.h3())
                    .foregroundColor(.btTextPrimary)

                Text(statusSubtitle)
                    .font(BTFont.body())
                    .foregroundColor(.btTextSecondary)
                    .multilineTextAlignment(.center)

                if state.isProcessing {
                    Text("\(Int(state.progress * 100))%")
                        .font(BTFont.mono())
                        .foregroundColor(.btPrimary)
                        .padding(.top, BTSpacing.xs)
                }
            }

            // Cancel button
            if state.isProcessing {
                Button("Cancel") {
                    onCancel()
                }
                .font(BTFont.label())
                .foregroundColor(.btError)
                .padding(.top, BTSpacing.md)
            }
        }
        .padding(BTLayout.cardPadding)
        .background(Color.btSurface)
        .cornerRadius(BTLayout.cardCornerRadius)
        .shadow(color: .black.opacity(0.3), radius: 20)
        .onAppear {
            rotation = 360
        }
    }

    private var statusTitle: String {
        switch state {
        case .detecting:
            return "Detecting Lane"
        case .analyzing:
            return "Analyzing"
        case .completed:
            return "Detection Complete"
        case .failed:
            return "Detection Failed"
        case .idle:
            return "Ready"
        }
    }

    private var statusSubtitle: String {
        switch state {
        case .detecting:
            return "Position camera to show the full lane"
        case .analyzing:
            return "Processing camera frames..."
        case .completed(let result):
            return "Found \(result.arrowCount) arrows, \(result.confidence >= 0.6 ? "high" : "low") confidence"
        case .failed(let error):
            return error.localizedDescription
        case .idle:
            return "Tap Auto-Detect to begin"
        }
    }
}

// MARK: - Detection Result Card

/// Card displaying detection results with accept/reject actions
struct LaneDetectionResultCard: View {
    let result: LaneDetectionResult
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            // Header
            HStack {
                Image(systemName: result.isUsable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(result.isUsable ? .btSuccess : .btWarning)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Lane Detected")
                        .font(BTFont.h4())
                        .foregroundColor(.btTextPrimary)

                    Text("\(Int(result.confidence * 100))% confidence")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }

                Spacer()
            }

            Divider()
                .background(Color.btBorder)

            // Detection details
            VStack(alignment: .leading, spacing: BTSpacing.sm) {
                detectionRow(
                    icon: "line.horizontal.3",
                    label: "Foul Line",
                    detected: result.foulLine != nil
                )

                detectionRow(
                    icon: "arrow.left.and.right",
                    label: "Lane Edges",
                    detected: result.leftGutterLine != nil && result.rightGutterLine != nil
                )

                detectionRow(
                    icon: "arrowtriangle.up",
                    label: "Arrows",
                    detected: result.arrowCount >= 2,
                    detail: result.arrowCount > 0 ? "\(result.arrowCount) found" : nil
                )
            }

            Divider()
                .background(Color.btBorder)

            // Action buttons
            HStack(spacing: BTSpacing.md) {
                Button {
                    onReject()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Retry")
                    }
                    .font(BTFont.label())
                    .foregroundColor(.btError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BTSpacing.sm)
                    .background(Color.btErrorMuted.opacity(0.3))
                    .cornerRadius(8)
                }

                Button {
                    onAccept()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Use This")
                    }
                    .font(BTFont.label())
                    .fontWeight(.semibold)
                    .foregroundColor(.btTextInverse)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BTSpacing.sm)
                    .background(Color.btSuccess)
                    .cornerRadius(8)
                }
                .disabled(!result.isUsable)
                .opacity(result.isUsable ? 1 : 0.5)
            }
        }
        .padding(BTLayout.cardPadding)
        .background(Color.btSurface)
        .cornerRadius(BTLayout.cardCornerRadius)
    }

    @ViewBuilder
    private func detectionRow(
        icon: String,
        label: String,
        detected: Bool,
        detail: String? = nil
    ) -> some View {
        HStack(spacing: BTSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(detected ? .btSuccess : .btTextMuted)
                .frame(width: 20)

            Text(label)
                .font(BTFont.body())
                .foregroundColor(.btTextPrimary)

            Spacer()

            if let detail = detail {
                Text(detail)
                    .font(BTFont.caption())
                    .foregroundColor(.btTextSecondary)
            }

            Image(systemName: detected ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(detected ? .btSuccess : .btTextMuted)
        }
    }
}

// MARK: - Preview

#Preview("Lane Overlay") {
    ZStack {
        Color.btLaneBackground
            .ignoresSafeArea()

        LaneOverlayView(
            detectionResult: LaneDetectionResult(
                leftGutterLine: [
                    CGPoint(x: 0.15, y: 0.1),
                    CGPoint(x: 0.18, y: 0.5),
                    CGPoint(x: 0.2, y: 0.9)
                ],
                rightGutterLine: [
                    CGPoint(x: 0.85, y: 0.1),
                    CGPoint(x: 0.82, y: 0.5),
                    CGPoint(x: 0.8, y: 0.9)
                ],
                foulLine: LineSeg(
                    start: CGPoint(x: 0.2, y: 0.85),
                    end: CGPoint(x: 0.8, y: 0.85)
                ),
                arrowPositions: [
                    ArrowDetection(position: CGPoint(x: 0.3, y: 0.55), boardNumber: 10, confidence: 0.8),
                    ArrowDetection(position: CGPoint(x: 0.5, y: 0.55), boardNumber: 20, confidence: 0.9),
                    ArrowDetection(position: CGPoint(x: 0.7, y: 0.55), boardNumber: 30, confidence: 0.75)
                ],
                confidence: 0.85,
                laneRectangle: CGRect(x: 0.15, y: 0.1, width: 0.7, height: 0.8)
            )
        )
    }
}

#Preview("Detection Progress") {
    ZStack {
        Color.btBackground
            .ignoresSafeArea()

        LaneDetectionProgressView(
            state: .analyzing(progress: 0.65),
            onCancel: { }
        )
        .padding()
    }
}

#Preview("Result Card") {
    ZStack {
        Color.btBackground
            .ignoresSafeArea()

        LaneDetectionResultCard(
            result: LaneDetectionResult(
                foulLine: LineSeg(start: .zero, end: CGPoint(x: 1, y: 0)),
                arrowPositions: [
                    ArrowDetection(position: .zero, boardNumber: 10, confidence: 0.8),
                    ArrowDetection(position: .zero, boardNumber: 20, confidence: 0.9)
                ],
                confidence: 0.82
            ),
            onAccept: { },
            onReject: { }
        )
        .padding()
    }
}
