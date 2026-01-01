//
//  ShotComparisonView.swift
//  BowlerTrax
//
//  Detailed comparison view for two shots with side-by-side metrics
//

import SwiftUI
import SwiftData

// MARK: - Shot Comparison View

/// Detailed comparison view for analyzing two shots side-by-side
struct ShotComparisonView: View {
    // MARK: - Properties

    let primaryShot: ShotEntity
    let comparisonShot: ShotEntity
    let calibration: CalibrationEntity?

    // MARK: - State

    @State private var viewMode: ComparisonViewMode = .overlay

    // MARK: - Computed Properties

    private var primaryTrajectory: [TrajectoryPoint]? {
        guard let data = primaryShot.trajectoryData else { return nil }
        return try? JSONDecoder().decode([TrajectoryPoint].self, from: data)
    }

    private var comparisonTrajectory: [TrajectoryPoint]? {
        guard let data = comparisonShot.trajectoryData else { return nil }
        return try? JSONDecoder().decode([TrajectoryPoint].self, from: data)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // View mode toggle
                viewModeToggle

                // Lane visualization
                laneVisualization

                // Shot labels
                shotLabels

                // Metrics comparison table
                metricsComparisonTable

                // Summary insights
                summaryInsights
            }
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
            .padding(.vertical, BTSpacing.lg)
        }
        .background(Color.btBackground)
        .navigationTitle("Shot Comparison")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: BTSpacing.xs) {
            ForEach(ComparisonViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = mode
                    }
                } label: {
                    HStack(spacing: BTSpacing.xs) {
                        Image(systemName: mode.icon)
                        Text(mode.displayName)
                    }
                    .font(BTFont.labelSmall())
                    .foregroundColor(viewMode == mode ? .btTextInverse : .btTextSecondary)
                    .padding(.horizontal, BTSpacing.md)
                    .padding(.vertical, BTSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewMode == mode ? Color.btPrimary : Color.btSurfaceElevated)
                    )
                }
            }

            Spacer()
        }
    }

    // MARK: - Lane Visualization

    @ViewBuilder
    private var laneVisualization: some View {
        switch viewMode {
        case .overlay:
            overlayLaneView
        case .sideBySide:
            sideBySideLaneView
        }
    }

    private var overlayLaneView: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            // Legend
            HStack(spacing: BTSpacing.lg) {
                LegendItem(color: .btPrimary, label: "Shot #\(primaryShot.shotNumber)")
                LegendItem(color: .btAccent, label: "Shot #\(comparisonShot.shotNumber)")
            }
            .padding(.horizontal, BTSpacing.sm)

            LaneVisualizer(
                trajectory: primaryTrajectory ?? [],
                comparisonTrajectory: comparisonTrajectory,
                oilPattern: nil,
                showArrows: true,
                showBoardNumbers: true,
                showDistanceMarkers: true,
                isAnimating: false
            )
            .frame(height: 350)
        }
    }

    private var sideBySideLaneView: some View {
        HStack(spacing: BTSpacing.md) {
            // Primary shot lane
            VStack(alignment: .center, spacing: BTSpacing.sm) {
                Text("Shot #\(primaryShot.shotNumber)")
                    .font(BTFont.label())
                    .foregroundColor(.btPrimary)

                LaneVisualizer(
                    trajectory: primaryTrajectory ?? [],
                    showArrows: true,
                    showBoardNumbers: false,
                    showDistanceMarkers: true,
                    isAnimating: false
                )
            }

            // Comparison shot lane
            VStack(alignment: .center, spacing: BTSpacing.sm) {
                Text("Shot #\(comparisonShot.shotNumber)")
                    .font(BTFont.label())
                    .foregroundColor(.btAccent)

                LaneVisualizer(
                    trajectory: comparisonTrajectory ?? [],
                    showArrows: true,
                    showBoardNumbers: false,
                    showDistanceMarkers: true,
                    isAnimating: false
                )
            }
        }
        .frame(height: 350)
    }

    // MARK: - Shot Labels

    private var shotLabels: some View {
        HStack(spacing: BTSpacing.lg) {
            // Primary shot label
            ShotLabelCard(
                shot: primaryShot,
                label: "Primary",
                color: .btPrimary
            )

            // Comparison shot label
            ShotLabelCard(
                shot: comparisonShot,
                label: "Comparison",
                color: .btAccent
            )
        }
    }

    // MARK: - Metrics Comparison Table

    private var metricsComparisonTable: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("Metrics Comparison")
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)

            VStack(spacing: 0) {
                // Header row
                MetricTableHeader(
                    primaryLabel: "Shot #\(primaryShot.shotNumber)",
                    comparisonLabel: "Shot #\(comparisonShot.shotNumber)"
                )

                Divider()
                    .background(Color.btBorder)

                // Speed row
                MetricComparisonRow(
                    metric: "Speed",
                    primaryValue: primaryShot.launchSpeed ?? primaryShot.impactSpeed,
                    comparisonValue: comparisonShot.launchSpeed ?? comparisonShot.impactSpeed,
                    unit: "mph",
                    color: .btSpeed,
                    higherIsBetter: true
                )

                Divider()
                    .background(Color.btBorder)

                // Entry angle row
                MetricComparisonRow(
                    metric: "Entry Angle",
                    primaryValue: primaryShot.entryAngle,
                    comparisonValue: comparisonShot.entryAngle,
                    unit: "deg",
                    color: .btAngle,
                    targetValue: 6.0 // Optimal entry angle
                )

                Divider()
                    .background(Color.btBorder)

                // Arrow board row
                MetricComparisonRow(
                    metric: "Arrow Board",
                    primaryValue: primaryShot.arrowBoard,
                    comparisonValue: comparisonShot.arrowBoard,
                    unit: "bd",
                    color: .btBoard,
                    higherIsBetter: nil // No preference
                )

                Divider()
                    .background(Color.btBorder)

                // Breakpoint board row
                MetricComparisonRow(
                    metric: "Breakpoint Board",
                    primaryValue: primaryShot.breakpointBoard,
                    comparisonValue: comparisonShot.breakpointBoard,
                    unit: "bd",
                    color: .btBreakpoint,
                    higherIsBetter: nil
                )

                Divider()
                    .background(Color.btBorder)

                // Breakpoint distance row
                MetricComparisonRow(
                    metric: "Breakpoint Dist",
                    primaryValue: primaryShot.breakpointDistance,
                    comparisonValue: comparisonShot.breakpointDistance,
                    unit: "ft",
                    color: .btBreakpoint,
                    higherIsBetter: nil
                )

                Divider()
                    .background(Color.btBorder)

                // Rev rate row
                MetricComparisonRow(
                    metric: "Rev Rate",
                    primaryValue: primaryShot.revRate,
                    comparisonValue: comparisonShot.revRate,
                    unit: "rpm",
                    color: .btRevRate,
                    higherIsBetter: nil
                )

                Divider()
                    .background(Color.btBorder)

                // Strike probability row
                MetricComparisonRow(
                    metric: "Strike Prob.",
                    primaryValue: primaryShot.strikeProbability.map { $0 * 100 },
                    comparisonValue: comparisonShot.strikeProbability.map { $0 * 100 },
                    unit: "%",
                    color: .btStrike,
                    higherIsBetter: true
                )
            }
            .background(Color.btSurface)
            .cornerRadius(BTLayout.cardCornerRadius)
        }
    }

    // MARK: - Summary Insights

    private var summaryInsights: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("Key Differences")
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)

            VStack(spacing: BTSpacing.sm) {
                // Speed difference insight
                if let primary = primaryShot.launchSpeed ?? primaryShot.impactSpeed,
                   let comparison = comparisonShot.launchSpeed ?? comparisonShot.impactSpeed {
                    let diff = primary - comparison
                    if abs(diff) > 0.5 {
                        InsightRow(
                            icon: "speedometer",
                            text: "Shot #\(primaryShot.shotNumber) was \(abs(diff).formatted(.number.precision(.fractionLength(1)))) mph \(diff > 0 ? "faster" : "slower")",
                            color: .btSpeed
                        )
                    }
                }

                // Angle difference insight
                if let primary = primaryShot.entryAngle,
                   let comparison = comparisonShot.entryAngle {
                    let diff = primary - comparison
                    let optimalDiff1 = abs(primary - 6.0)
                    let optimalDiff2 = abs(comparison - 6.0)

                    if abs(diff) > 0.5 {
                        let betterShot = optimalDiff1 < optimalDiff2 ? primaryShot.shotNumber : comparisonShot.shotNumber
                        InsightRow(
                            icon: "angle",
                            text: "Shot #\(betterShot) had better entry angle (closer to optimal 6 deg)",
                            color: .btAngle
                        )
                    }
                }

                // Strike probability insight
                if let primary = primaryShot.strikeProbability,
                   let comparison = comparisonShot.strikeProbability {
                    let diff = (primary - comparison) * 100
                    if abs(diff) > 5 {
                        let betterShot = primary > comparison ? primaryShot.shotNumber : comparisonShot.shotNumber
                        InsightRow(
                            icon: "flame.fill",
                            text: "Shot #\(betterShot) had \(abs(diff).formatted(.number.precision(.fractionLength(0))))% higher strike probability",
                            color: .btStrike
                        )
                    }
                }

                // Board position insight
                if let primary = primaryShot.arrowBoard,
                   let comparison = comparisonShot.arrowBoard {
                    let diff = primary - comparison
                    if abs(diff) > 1 {
                        InsightRow(
                            icon: "arrow.left.arrow.right",
                            text: "Board position differed by \(abs(diff).formatted(.number.precision(.fractionLength(1)))) boards",
                            color: .btBoard
                        )
                    }
                }
            }
            .padding(BTSpacing.md)
            .background(Color.btSurface)
            .cornerRadius(BTLayout.cardCornerRadius)
        }
    }
}

// MARK: - Comparison View Mode

enum ComparisonViewMode: CaseIterable {
    case overlay
    case sideBySide

    var displayName: String {
        switch self {
        case .overlay: return "Overlay"
        case .sideBySide: return "Side by Side"
        }
    }

    var icon: String {
        switch self {
        case .overlay: return "square.on.square"
        case .sideBySide: return "rectangle.split.2x1"
        }
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: BTSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextSecondary)
        }
    }
}

// MARK: - Shot Label Card

private struct ShotLabelCard: View {
    let shot: ShotEntity
    let label: String
    let color: Color

    private var shotResult: ShotResult? {
        guard let result = shot.result else { return nil }
        return ShotResult(rawValue: result)
    }

    var body: some View {
        HStack(spacing: BTSpacing.sm) {
            // Result badge
            if let result = shotResult {
                Text(result.symbol)
                    .font(BTFont.label())
                    .foregroundColor(result.color)
                    .frame(width: 32, height: 32)
                    .background(result.color.opacity(0.2))
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: BTSpacing.xxs) {
                Text(label)
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btTextMuted)
                    .textCase(.uppercase)

                Text("Shot #\(shot.shotNumber)")
                    .font(BTFont.label())
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding(BTSpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.btSurface)
        .cornerRadius(10)
    }
}

// MARK: - Metric Table Header

private struct MetricTableHeader: View {
    let primaryLabel: String
    let comparisonLabel: String

    var body: some View {
        HStack {
            Text("Metric")
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)
                .textCase(.uppercase)
                .frame(width: 100, alignment: .leading)

            Spacer()

            Text(primaryLabel)
                .font(BTFont.captionSmall())
                .foregroundColor(.btPrimary)
                .textCase(.uppercase)
                .frame(width: 80, alignment: .trailing)

            Text(comparisonLabel)
                .font(BTFont.captionSmall())
                .foregroundColor(.btAccent)
                .textCase(.uppercase)
                .frame(width: 80, alignment: .trailing)

            Text("Delta")
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)
                .textCase(.uppercase)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, BTSpacing.md)
        .padding(.vertical, BTSpacing.sm)
        .background(Color.btSurfaceElevated)
    }
}

// MARK: - Metric Comparison Row

private struct MetricComparisonRow: View {
    let metric: String
    let primaryValue: Double?
    let comparisonValue: Double?
    let unit: String
    let color: Color
    var higherIsBetter: Bool? = nil
    var targetValue: Double? = nil

    private var delta: Double? {
        guard let primary = primaryValue, let comparison = comparisonValue else { return nil }
        return primary - comparison
    }

    private var deltaColor: Color {
        guard let delta = delta else { return .btTextMuted }

        // If there's a target value, determine which is closer
        if let target = targetValue,
           let primary = primaryValue,
           let comparison = comparisonValue {
            let primaryDiff = abs(primary - target)
            let comparisonDiff = abs(comparison - target)
            if primaryDiff < comparisonDiff {
                return .btSuccess
            } else if primaryDiff > comparisonDiff {
                return .btError
            }
            return .btTextMuted
        }

        // If higher is better is defined
        if let better = higherIsBetter {
            if better {
                return delta > 0 ? .btSuccess : (delta < 0 ? .btError : .btTextMuted)
            } else {
                return delta < 0 ? .btSuccess : (delta > 0 ? .btError : .btTextMuted)
            }
        }

        // Neutral - just show gray
        return .btTextMuted
    }

    var body: some View {
        HStack {
            // Metric name with color indicator
            HStack(spacing: BTSpacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)

                Text(metric)
                    .font(BTFont.bodySmall())
                    .foregroundColor(.btTextSecondary)
            }
            .frame(width: 100, alignment: .leading)

            Spacer()

            // Primary value
            Text(formattedValue(primaryValue))
                .font(BTFont.label())
                .foregroundColor(.btTextPrimary)
                .monospacedDigit()
                .frame(width: 80, alignment: .trailing)

            // Comparison value
            Text(formattedValue(comparisonValue))
                .font(BTFont.label())
                .foregroundColor(.btTextPrimary)
                .monospacedDigit()
                .frame(width: 80, alignment: .trailing)

            // Delta
            HStack(spacing: 2) {
                if let delta = delta, delta != 0 {
                    Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                }
                Text(formattedDelta)
                    .font(BTFont.labelSmall())
                    .monospacedDigit()
            }
            .foregroundColor(deltaColor)
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, BTSpacing.md)
        .padding(.vertical, BTSpacing.sm)
    }

    private func formattedValue(_ value: Double?) -> String {
        guard let value = value else { return "--" }
        if unit == "%" || unit == "rpm" {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private var formattedDelta: String {
        guard let delta = delta else { return "--" }
        let prefix = delta > 0 ? "+" : ""
        if unit == "%" || unit == "rpm" {
            return "\(prefix)\(String(format: "%.0f", delta))"
        }
        return "\(prefix)\(String(format: "%.1f", delta))"
    }
}

// MARK: - Insight Row

private struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: BTSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(BTFont.bodySmall())
                .foregroundColor(.btTextSecondary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Shot Comparison View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SessionEntity.self, ShotEntity.self, configurations: config)

    // Create preview shots
    let shot1 = ShotEntity()
    shot1.shotNumber = 1
    shot1.launchSpeed = 17.2
    shot1.entryAngle = 5.8
    shot1.arrowBoard = 15.5
    shot1.breakpointBoard = 8.0
    shot1.breakpointDistance = 42.0
    shot1.revRate = 340
    shot1.strikeProbability = 0.72
    shot1.result = ShotResult.strike.rawValue
    container.mainContext.insert(shot1)

    let shot2 = ShotEntity()
    shot2.shotNumber = 3
    shot2.launchSpeed = 16.5
    shot2.entryAngle = 4.2
    shot2.arrowBoard = 13.0
    shot2.breakpointBoard = 6.5
    shot2.breakpointDistance = 40.0
    shot2.revRate = 320
    shot2.strikeProbability = 0.58
    shot2.result = ShotResult.spare.rawValue
    container.mainContext.insert(shot2)

    return NavigationStack {
        ShotComparisonView(
            primaryShot: shot1,
            comparisonShot: shot2,
            calibration: nil
        )
    }
    .modelContainer(container)
}
