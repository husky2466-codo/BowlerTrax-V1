//
//  MetricsOverlay.swift
//  BowlerTrax
//
//  Overlay components for the recording screen including
//  lane guides, trajectory path, and camera overlays.
//

import SwiftUI

// MARK: - Lane Guide Overlay

/// Overlay showing calibrated lane guides (foul line, arrows, etc.)
/// Now accepts CalibrationEntity directly for use with SwiftData.
struct LaneGuideOverlay: View {
    let calibration: CalibrationEntity
    let showFoulLine: Bool
    let showArrows: Bool
    let showBreakpoint: Bool

    init(
        calibration: CalibrationEntity,
        showFoulLine: Bool = true,
        showArrows: Bool = true,
        showBreakpoint: Bool = true
    ) {
        self.calibration = calibration
        self.showFoulLine = showFoulLine
        self.showArrows = showArrows
        self.showBreakpoint = showBreakpoint
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Foul line guide
                if showFoulLine {
                    foulLineGuide(in: geometry)
                }

                // Arrow markers
                if showArrows {
                    arrowGuides(in: geometry)
                }

                // Breakpoint zone
                if showBreakpoint {
                    breakpointZone(in: geometry)
                }

                // Lane edge guides
                laneEdgeGuides(in: geometry)
            }
        }
    }

    // MARK: - Guide Components

    private func foulLineGuide(in geometry: GeometryProxy) -> some View {
        // Scale Y position based on geometry
        let scaledY = calibration.foulLineY * geometry.size.height / 1080 // Assuming 1080p calibration

        return ZStack {
            // Dashed line
            Path { path in
                path.move(to: CGPoint(x: 0, y: scaledY))
                path.addLine(to: CGPoint(x: geometry.size.width, y: scaledY))
            }
            .stroke(
                Color.btWarning.opacity(0.6),
                style: StrokeStyle(lineWidth: 2, dash: [10, 5])
            )

            // Label
            Text("FOUL LINE")
                .font(BTFont.captionSmall())
                .foregroundColor(.btWarning)
                .padding(.horizontal, BTSpacing.xs)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.5))
                .cornerRadius(4)
                .position(x: 60, y: scaledY - 12)
        }
    }

    private func arrowGuides(in geometry: GeometryProxy) -> some View {
        let scaledY = calibration.arrowsY * geometry.size.height / 1080
        let arrowBoards = [5, 10, 15, 20, 25, 30, 35]

        return ZStack {
            // Dashed line at arrow distance
            Path { path in
                path.move(to: CGPoint(x: 0, y: scaledY))
                path.addLine(to: CGPoint(x: geometry.size.width, y: scaledY))
            }
            .stroke(
                Color.btPrimary.opacity(0.4),
                style: StrokeStyle(lineWidth: 1, dash: [5, 3])
            )

            // Arrow markers
            ForEach(arrowBoards, id: \.self) { board in
                let x = xPositionForBoard(board, width: geometry.size.width)
                ArrowMarker()
                    .frame(width: 12, height: 16)
                    .position(x: x, y: scaledY)
            }

            // Label
            Text("ARROWS (15 ft)")
                .font(BTFont.captionSmall())
                .foregroundColor(.btPrimary)
                .padding(.horizontal, BTSpacing.xs)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.5))
                .cornerRadius(4)
                .position(x: 80, y: scaledY - 12)
        }
    }

    private func breakpointZone(in geometry: GeometryProxy) -> some View {
        // Breakpoint typically at 35-45 feet
        let breakpointY = calibration.arrowsY * 0.4 * geometry.size.height / 1080

        return Path { path in
            path.move(to: CGPoint(x: 0, y: breakpointY))
            path.addLine(to: CGPoint(x: geometry.size.width, y: breakpointY))
        }
        .stroke(
            Color.btBreakpoint.opacity(0.3),
            style: StrokeStyle(lineWidth: 1, dash: [8, 4])
        )
    }

    private func laneEdgeGuides(in geometry: GeometryProxy) -> some View {
        let leftX = calibration.leftGutterX * geometry.size.width / 1920 // Assuming 1920 width calibration
        let rightX = calibration.rightGutterX * geometry.size.width / 1920

        return ZStack {
            // Left gutter
            Rectangle()
                .fill(Color.btTextMuted.opacity(0.2))
                .frame(width: 2)
                .position(x: leftX, y: geometry.size.height / 2)
                .frame(height: geometry.size.height)

            // Right gutter
            Rectangle()
                .fill(Color.btTextMuted.opacity(0.2))
                .frame(width: 2)
                .position(x: rightX, y: geometry.size.height / 2)
                .frame(height: geometry.size.height)
        }
    }

    private func xPositionForBoard(_ board: Int, width: CGFloat) -> CGFloat {
        let normalizedX = (Double(board) - 1.0) / 39.0
        let laneWidth = (calibration.rightGutterX - calibration.leftGutterX) * width / 1920
        let leftEdge = calibration.leftGutterX * width / 1920
        return leftEdge + (normalizedX * laneWidth)
    }
}

// MARK: - Arrow Marker Shape

struct ArrowMarker: View {
    var body: some View {
        Triangle()
            .fill(Color.btPrimary.opacity(0.8))
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Recording Indicator

struct RecordingIndicatorView: View {
    let isRecording: Bool
    let isPaused: Bool
    let recordingTime: TimeInterval

    @State private var isBlinking = false

    var body: some View {
        HStack(spacing: BTSpacing.sm) {
            // Pulsing red dot
            Circle()
                .fill(Color.btError)
                .frame(width: 12, height: 12)
                .opacity(isPaused ? 0.3 : (isBlinking ? 0.4 : 1.0))
                .animation(
                    isRecording && !isPaused
                        ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                        : .default,
                    value: isBlinking
                )
                .onAppear {
                    isBlinking = true
                }

            // Status text
            Text(isPaused ? "PAUSED" : "REC")
                .font(BTFont.labelSmall())
                .foregroundColor(.white)

            // Timer
            Text(formatTime(recordingTime))
                .font(BTFont.mono())
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, BTSpacing.md)
        .padding(.vertical, BTSpacing.xs)
        .background(Color.black.opacity(0.6))
        .cornerRadius(6)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - FPS Indicator

struct FPSIndicator: View {
    let currentFPS: Double
    let targetFPS: Double

    private var fpsColor: Color {
        if currentFPS >= targetFPS * 0.9 {
            return .btSuccess
        } else if currentFPS >= targetFPS * 0.7 {
            return .btWarning
        } else {
            return .btError
        }
    }

    var body: some View {
        HStack(spacing: BTSpacing.xs) {
            Circle()
                .fill(fpsColor)
                .frame(width: 8, height: 8)

            Text("\(Int(currentFPS)) fps")
                .font(BTFont.captionSmall())
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, BTSpacing.sm)
        .padding(.vertical, BTSpacing.xxs)
        .background(Color.black.opacity(0.5))
        .cornerRadius(4)
    }
}

// MARK: - Calibration Warning Banner

struct CalibrationWarningBanner: View {
    let onCalibrateTapped: () -> Void

    var body: some View {
        Button(action: onCalibrateTapped) {
            HStack(spacing: BTSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.btWarning)

                Text("NO CALIBRATION - Metrics may be inaccurate")
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)

                Spacer()

                Text("Tap to calibrate")
                    .font(BTFont.caption())
                    .foregroundColor(.btPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.btPrimary)
            }
            .padding(BTSpacing.md)
            .background(Color.btSurface.opacity(0.95))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shot Counter Badge

struct ShotCounterBadge: View {
    let shotCount: Int

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("Shots")
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)
            Text("\(shotCount)")
                .font(BTFont.monoLarge())
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.vertical, BTSpacing.sm)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
    }
}

// MARK: - Session Timer Badge

struct SessionTimerBadge: View {
    let sessionDuration: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Session Time")
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)
            Text(formatTime(sessionDuration))
                .font(BTFont.monoLarge())
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, BTSpacing.md)
        .padding(.vertical, BTSpacing.sm)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Previews

#Preview("Recording Indicator") {
    ZStack {
        Color.black
        RecordingIndicatorView(isRecording: true, isPaused: false, recordingTime: 154)
    }
}

#Preview("FPS Indicator") {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            FPSIndicator(currentFPS: 120, targetFPS: 120)
            FPSIndicator(currentFPS: 90, targetFPS: 120)
            FPSIndicator(currentFPS: 45, targetFPS: 120)
        }
    }
}

#Preview("Calibration Warning") {
    ZStack {
        Color.black
        CalibrationWarningBanner { }
            .padding()
    }
}
