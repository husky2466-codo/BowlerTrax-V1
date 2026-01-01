//
//  SessionLaneVisualizer.swift
//  BowlerTrax
//
//  Full-width lane visualizer for session reports with shot selection and comparison mode
//

import SwiftUI
import SwiftData

// MARK: - Session Lane Visualizer

/// Full-width lane visualizer for post-session analysis
/// Supports shot selection, comparison mode, and heat map overlay
struct SessionLaneVisualizer: View {
    // MARK: - Properties

    let session: SessionEntity
    let shots: [ShotEntity]
    let calibration: CalibrationEntity?

    // MARK: - State

    @State private var selectedShotIndex: Int = 0
    @State private var comparisonMode: Bool = false
    @State private var comparisonShotIndex: Int?
    @State private var showAllTrajectories: Bool = false

    // MARK: - Computed Properties

    private var selectedShot: ShotEntity? {
        guard selectedShotIndex >= 0, selectedShotIndex < shots.count else { return nil }
        return shots[selectedShotIndex]
    }

    private var comparisonShot: ShotEntity? {
        guard let index = comparisonShotIndex,
              index >= 0, index < shots.count else { return nil }
        return shots[index]
    }

    /// Get the shot with highest strike probability or actual strike
    private var bestStrikeIndex: Int? {
        // First, look for actual strikes
        if let strikeIndex = shots.firstIndex(where: { $0.result == ShotResult.strike.rawValue }) {
            return strikeIndex
        }

        // Otherwise, find shot with highest strike probability
        var bestIndex: Int?
        var bestProbability: Double = -1

        for (index, shot) in shots.enumerated() {
            if let prob = shot.strikeProbability, prob > bestProbability {
                bestProbability = prob
                bestIndex = index
            }
        }

        return bestIndex
    }

    /// Get trajectory for selected shot
    private var selectedTrajectory: [TrajectoryPoint]? {
        guard let shot = selectedShot,
              let data = shot.trajectoryData else { return nil }
        return try? JSONDecoder().decode([TrajectoryPoint].self, from: data)
    }

    /// Get trajectory for comparison shot
    private var comparisonTrajectory: [TrajectoryPoint]? {
        guard let shot = comparisonShot,
              let data = shot.trajectoryData else { return nil }
        return try? JSONDecoder().decode([TrajectoryPoint].self, from: data)
    }

    /// Get oil pattern from session if available
    private var oilPattern: OilPattern? {
        // Create an oil pattern from session data
        let patternType = OilPatternType(rawValue: session.oilPattern) ?? .house
        let length: Int
        switch patternType {
        case .short: length = 35
        case .medium, .house: length = 40
        case .long, .sport: length = 45
        case .custom: length = 40
        }

        return OilPattern(
            name: session.oilPattern,
            category: .house,
            lengthFeet: length,
            difficulty: .medium
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: BTSpacing.lg) {
            // Control bar
            controlBar

            // Lane visualizer
            laneView

            // Metrics summary
            if !comparisonMode {
                selectedShotMetrics
            } else {
                comparisonMetrics
            }
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        VStack(spacing: BTSpacing.md) {
            // Primary controls row
            HStack(spacing: BTSpacing.md) {
                // Shot picker
                shotPicker

                Spacer()

                // Best strike button
                if let bestIndex = bestStrikeIndex {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedShotIndex = bestIndex
                        }
                    } label: {
                        Label("Best", systemImage: "star.fill")
                            .font(BTFont.labelSmall())
                            .foregroundColor(.btStrike)
                            .padding(.horizontal, BTSpacing.md)
                            .padding(.vertical, BTSpacing.xs)
                            .background(Color.btStrike.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }

            // Secondary controls row
            HStack(spacing: BTSpacing.lg) {
                // Comparison mode toggle
                Toggle(isOn: $comparisonMode) {
                    Label("Compare", systemImage: "arrow.left.arrow.right")
                        .font(BTFont.labelSmall())
                        .foregroundColor(.btTextSecondary)
                }
                .toggleStyle(.button)
                .tint(.btPrimary)

                // Show all trajectories toggle
                Toggle(isOn: $showAllTrajectories) {
                    Label("Heat Map", systemImage: "flame.fill")
                        .font(BTFont.labelSmall())
                        .foregroundColor(.btTextSecondary)
                }
                .toggleStyle(.button)
                .tint(.btWarning)

                Spacer()

                // Comparison shot picker (when in comparison mode)
                if comparisonMode {
                    comparisonShotPicker
                }
            }
        }
        .padding(.horizontal, BTSpacing.md)
    }

    // MARK: - Shot Picker

    private var shotPicker: some View {
        Menu {
            ForEach(Array(shots.enumerated()), id: \.element.id) { index, shot in
                Button {
                    selectedShotIndex = index
                } label: {
                    HStack {
                        Text("Shot #\(shot.shotNumber)")
                        if let result = shot.result, let shotResult = ShotResult(rawValue: result) {
                            Text(shotResult.symbol)
                                .foregroundColor(shotResult.color)
                        }
                        if index == selectedShotIndex {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: BTSpacing.xs) {
                Text("Shot #\(selectedShot?.shotNumber ?? 0)")
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)

                if let shot = selectedShot,
                   let result = shot.result,
                   let shotResult = ShotResult(rawValue: result) {
                    Text(shotResult.symbol)
                        .font(BTFont.label())
                        .foregroundColor(shotResult.color)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.btTextMuted)
            }
            .padding(.horizontal, BTSpacing.md)
            .padding(.vertical, BTSpacing.sm)
            .background(Color.btSurface)
            .cornerRadius(8)
        }
    }

    // MARK: - Comparison Shot Picker

    private var comparisonShotPicker: some View {
        Menu {
            ForEach(Array(shots.enumerated()), id: \.element.id) { index, shot in
                if index != selectedShotIndex {
                    Button {
                        comparisonShotIndex = index
                    } label: {
                        HStack {
                            Text("Shot #\(shot.shotNumber)")
                            if let result = shot.result, let shotResult = ShotResult(rawValue: result) {
                                Text(shotResult.symbol)
                                    .foregroundColor(shotResult.color)
                            }
                            if index == comparisonShotIndex {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: BTSpacing.xs) {
                Text(comparisonShot != nil ? "vs Shot #\(comparisonShot!.shotNumber)" : "Select...")
                    .font(BTFont.labelSmall())
                    .foregroundColor(comparisonShot != nil ? .btAccent : .btTextMuted)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.btTextMuted)
            }
            .padding(.horizontal, BTSpacing.md)
            .padding(.vertical, BTSpacing.sm)
            .background(Color.btSurfaceElevated)
            .cornerRadius(8)
        }
    }

    // MARK: - Lane View

    private var laneView: some View {
        ZStack {
            // Base lane visualizer
            if showAllTrajectories {
                // Heat map mode - show all trajectories with varying opacity
                heatMapLaneView
            } else if comparisonMode, let comparison = comparisonTrajectory {
                // Comparison mode - show two trajectories
                LaneVisualizer(
                    trajectory: selectedTrajectory ?? [],
                    comparisonTrajectory: comparison,
                    oilPattern: oilPattern,
                    showArrows: true,
                    showBoardNumbers: true,
                    showDistanceMarkers: true,
                    isAnimating: false
                )
            } else {
                // Single trajectory mode
                LaneVisualizer(
                    trajectory: selectedTrajectory ?? [],
                    showArrows: true,
                    showBoardNumbers: true,
                    showDistanceMarkers: true,
                    isAnimating: false,
                    oilPattern: oilPattern
                )
            }
        }
        .frame(height: 400)
    }

    // MARK: - Heat Map Lane View

    private var heatMapLaneView: some View {
        GeometryReader { geometry in
            ZStack {
                // Base lane
                LaneVisualizer(
                    showArrows: true,
                    showBoardNumbers: true,
                    showDistanceMarkers: true,
                    oilPattern: oilPattern
                )

                // Overlay all trajectories with varying opacity
                Canvas { context, size in
                    for (index, shot) in shots.enumerated() {
                        guard let data = shot.trajectoryData,
                              let trajectory = try? JSONDecoder().decode([TrajectoryPoint].self, from: data),
                              !trajectory.isEmpty else { continue }

                        // Calculate opacity based on position (newer = more opaque)
                        let opacity = 0.3 + (Double(index) / Double(max(1, shots.count - 1))) * 0.4

                        // Determine color based on result
                        let color: Color
                        if let result = shot.result, let shotResult = ShotResult(rawValue: result) {
                            color = shotResult.color
                        } else {
                            color = .btPrimary
                        }

                        // Draw trajectory path
                        var path = Path()
                        for (pointIndex, point) in trajectory.enumerated() {
                            guard let board = point.board, let distance = point.distanceFt else { continue }

                            let x = boardToX(board: board, width: size.width)
                            let y = distanceToY(feet: distance, height: size.height)

                            if pointIndex == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }

                        context.stroke(
                            path,
                            with: .color(color.opacity(opacity)),
                            lineWidth: 2
                        )
                    }

                    // Highlight selected shot
                    if let selected = selectedTrajectory, !selected.isEmpty {
                        var selectedPath = Path()
                        for (pointIndex, point) in selected.enumerated() {
                            guard let board = point.board, let distance = point.distanceFt else { continue }

                            let x = boardToX(board: board, width: size.width)
                            let y = distanceToY(feet: distance, height: size.height)

                            if pointIndex == 0 {
                                selectedPath.move(to: CGPoint(x: x, y: y))
                            } else {
                                selectedPath.addLine(to: CGPoint(x: x, y: y))
                            }
                        }

                        // Glow effect
                        context.stroke(
                            selectedPath,
                            with: .color(Color.btPrimaryLight.opacity(0.5)),
                            lineWidth: 6
                        )

                        // Main line
                        context.stroke(
                            selectedPath,
                            with: .color(Color.btPrimary),
                            lineWidth: 3
                        )
                    }
                }
            }
        }
        .aspectRatio(LaneConstants.laneLength / (LaneConstants.laneWidth / 12.0), contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: BTLayout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: BTLayout.cardCornerRadius)
                .stroke(Color.btBorder, lineWidth: 1)
        )
    }

    // MARK: - Coordinate Helpers

    private func boardToX(board: Double, width: CGFloat) -> CGFloat {
        let boardWidth = width / CGFloat(LaneConstants.boardCount)
        return CGFloat(board - 0.5) * boardWidth
    }

    private func distanceToY(feet: Double, height: CGFloat) -> CGFloat {
        let normalizedY = feet / LaneConstants.laneLength
        return CGFloat(normalizedY) * height
    }

    // MARK: - Selected Shot Metrics

    private var selectedShotMetrics: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            Text("Shot Metrics")
                .font(BTFont.h4())
                .foregroundColor(.btTextPrimary)

            if let shot = selectedShot {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: BTSpacing.md) {
                    CompactMetricView(
                        label: "Speed",
                        value: shot.launchSpeed ?? shot.impactSpeed,
                        unit: "mph",
                        color: .btSpeed
                    )

                    CompactMetricView(
                        label: "Angle",
                        value: shot.entryAngle,
                        unit: "deg",
                        color: .btAngle
                    )

                    CompactMetricView(
                        label: "Board",
                        value: shot.arrowBoard,
                        unit: "bd",
                        color: .btBoard
                    )

                    CompactMetricView(
                        label: "Strike %",
                        value: shot.strikeProbability.map { $0 * 100 },
                        unit: "%",
                        color: .btStrike
                    )
                }
            } else {
                Text("No shot selected")
                    .font(BTFont.body())
                    .foregroundColor(.btTextMuted)
            }
        }
        .padding(BTSpacing.md)
        .background(Color.btSurface)
        .cornerRadius(BTLayout.cardCornerRadius)
    }

    // MARK: - Comparison Metrics

    private var comparisonMetrics: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            HStack {
                Text("Comparison")
                    .font(BTFont.h4())
                    .foregroundColor(.btTextPrimary)

                Spacer()

                if comparisonShot != nil {
                    NavigationLink {
                        ShotComparisonView(
                            primaryShot: selectedShot!,
                            comparisonShot: comparisonShot!,
                            calibration: calibration
                        )
                    } label: {
                        Label("Details", systemImage: "arrow.right.circle")
                            .font(BTFont.labelSmall())
                            .foregroundColor(.btPrimary)
                    }
                }
            }

            if let primary = selectedShot, let comparison = comparisonShot {
                // Side by side metrics
                HStack(spacing: BTSpacing.lg) {
                    // Primary shot column
                    VStack(spacing: BTSpacing.sm) {
                        Text("Shot #\(primary.shotNumber)")
                            .font(BTFont.label())
                            .foregroundColor(.btPrimary)

                        MetricColumn(shot: primary)
                    }
                    .frame(maxWidth: .infinity)

                    // Divider
                    Rectangle()
                        .fill(Color.btBorder)
                        .frame(width: 1)

                    // Comparison shot column
                    VStack(spacing: BTSpacing.sm) {
                        Text("Shot #\(comparison.shotNumber)")
                            .font(BTFont.label())
                            .foregroundColor(.btAccent)

                        MetricColumn(shot: comparison)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text("Select a comparison shot")
                    .font(BTFont.body())
                    .foregroundColor(.btTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, BTSpacing.lg)
            }
        }
        .padding(BTSpacing.md)
        .background(Color.btSurface)
        .cornerRadius(BTLayout.cardCornerRadius)
    }
}

// MARK: - Compact Metric View

private struct CompactMetricView: View {
    let label: String
    let value: Double?
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: BTSpacing.xxs) {
            Text(label)
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formattedValue)
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)
                    .monospacedDigit()

                Text(unit)
                    .font(BTFont.captionSmall())
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BTSpacing.sm)
        .background(Color.btSurfaceElevated)
        .cornerRadius(8)
    }

    private var formattedValue: String {
        guard let value = value else { return "--" }
        if unit == "%" || unit == "rpm" {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Metric Column

private struct MetricColumn: View {
    let shot: ShotEntity

    var body: some View {
        VStack(spacing: BTSpacing.xs) {
            MetricRow(
                label: "Speed",
                value: shot.launchSpeed ?? shot.impactSpeed,
                unit: "mph",
                color: .btSpeed
            )
            MetricRow(
                label: "Angle",
                value: shot.entryAngle,
                unit: "deg",
                color: .btAngle
            )
            MetricRow(
                label: "Board",
                value: shot.arrowBoard,
                unit: "bd",
                color: .btBoard
            )
            MetricRow(
                label: "Strike %",
                value: shot.strikeProbability.map { $0 * 100 },
                unit: "%",
                color: .btStrike
            )
        }
    }
}

// MARK: - Metric Row

private struct MetricRow: View {
    let label: String
    let value: Double?
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formattedValue)
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)
                    .monospacedDigit()

                Text(unit)
                    .font(BTFont.captionSmall())
                    .foregroundColor(color)
            }
        }
    }

    private var formattedValue: String {
        guard let value = value else { return "--" }
        if unit == "%" || unit == "rpm" {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Preview

#Preview("Session Lane Visualizer") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SessionEntity.self, ShotEntity.self, configurations: config)

    // Create preview session
    let session = SessionEntity()
    session.centerName = "Preview Center"
    container.mainContext.insert(session)

    // Create preview shots with trajectory data
    for i in 1...5 {
        let shot = ShotEntity()
        shot.shotNumber = i
        shot.sessionId = session.id
        shot.launchSpeed = 16.0 + Double.random(in: -1...2)
        shot.entryAngle = 5.5 + Double.random(in: -1...1)
        shot.arrowBoard = 15.0 + Double.random(in: -3...3)
        shot.strikeProbability = 0.6 + Double.random(in: -0.2...0.3)
        shot.result = i == 1 || i == 3 ? ShotResult.strike.rawValue : ShotResult.open.rawValue
        shot.session = session
        container.mainContext.insert(shot)
    }

    return NavigationStack {
        ScrollView {
            SessionLaneVisualizer(
                session: session,
                shots: session.shots?.sorted { $0.shotNumber < $1.shotNumber } ?? [],
                calibration: nil
            )
            .padding()
        }
        .background(Color.btBackground)
        .navigationTitle("Lane Visualizer")
    }
    .modelContainer(container)
}
