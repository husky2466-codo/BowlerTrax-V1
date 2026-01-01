//
//  ShotCard.swift
//  BowlerTrax
//
//  List item component for individual shot results.
//  Displays shot number, result badge, and key metrics.
//

import SwiftUI

// MARK: - ShotResult Color Extension

extension ShotResult {
    var color: Color {
        switch self {
        case .strike: return .btSuccess
        case .spare: return .btPrimary
        case .open: return .btTextMuted
        case .split: return .btError
        case .washout: return .btWarning
        case .gutter: return .btError
        }
    }

    var resultDescription: String {
        switch self {
        case .strike: return "Strike"
        case .spare: return "Spare"
        case .open: return "Open Frame"
        case .split: return "Split"
        case .washout: return "Washout"
        case .gutter: return "Gutter Ball"
        }
    }
}

// MARK: - Shot Data Protocol

/// Protocol for shot data display
protocol ShotDisplayable {
    var id: UUID { get }
    var number: Int { get }
    var result: ShotResult { get }
    var speedMph: Double? { get }
    var entryAngle: Double? { get }
    var arrowBoard: Double? { get }
    var revRate: Double? { get }
}

// MARK: - Shot Card Component

struct ShotCard<Shot: ShotDisplayable>: View {
    // MARK: - Properties

    let shot: Shot
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: BTSpacing.md) {
                // Result badge
                ResultBadge(result: shot.result)

                // Shot number
                Text("#\(shot.number)")
                    .font(BTFont.monoLarge())
                    .foregroundColor(.btTextPrimary)
                    .frame(width: 44, alignment: .leading)

                // Metrics row
                HStack(spacing: BTSpacing.lg) {
                    MiniMetric(value: shot.speedMph, unit: "mph", color: .btSpeed)
                    MiniMetric(value: shot.entryAngle, unit: "deg", color: .btAngle)
                    MiniMetric(value: shot.arrowBoard, unit: "bd", color: .btBoard)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.btTextMuted)
            }
            .padding(.horizontal, BTLayout.listItemPadding)
            .padding(.vertical, BTSpacing.md)
            .background(Color.btSurface)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Result Badge

struct ResultBadge: View {
    let result: ShotResult
    var size: CGFloat = 36

    var body: some View {
        Text(result.symbol)
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundColor(result.color)
            .frame(width: size, height: size)
            .background(result.color.opacity(0.2))
            .cornerRadius(8)
    }
}

// MARK: - Mini Metric

struct MiniMetric: View {
    let value: Double?
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value.map { String(format: formatString, $0) } ?? "--")
                .font(BTFont.label())
                .foregroundColor(.btTextPrimary)
                .monospacedDigit()

            Text(unit)
                .font(BTFont.captionSmall())
                .foregroundColor(color)
        }
        .frame(minWidth: 40)
    }

    private var formatString: String {
        switch unit {
        case "mph", "deg", "bd": return "%.1f"
        case "rpm": return "%.0f"
        default: return "%.1f"
        }
    }
}

// MARK: - Expanded Shot Card

struct ShotCardExpanded<Shot: ShotDisplayable>: View {
    let shot: Shot
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: BTSpacing.md) {
                // Header row
                HStack {
                    ResultBadge(result: shot.result, size: 44)

                    VStack(alignment: .leading, spacing: BTSpacing.xxs) {
                        Text("Shot #\(shot.number)")
                            .font(BTFont.h4())
                            .foregroundColor(.btTextPrimary)

                        Text(shot.result.displayName)
                            .font(BTFont.caption())
                            .foregroundColor(.btTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.btTextMuted)
                }

                // Metrics grid
                HStack(spacing: BTSpacing.lg) {
                    ExpandedMetric(label: "Speed", value: shot.speedMph, unit: "mph", color: .btSpeed)
                    ExpandedMetric(label: "Angle", value: shot.entryAngle, unit: "deg", color: .btAngle)
                    ExpandedMetric(label: "Board", value: shot.arrowBoard, unit: "", color: .btBoard)
                    if let revRate = shot.revRate {
                        ExpandedMetric(label: "Rev Rate", value: revRate, unit: "rpm", color: .btRevRate)
                    }
                }
            }
            .padding(BTLayout.cardPadding)
            .background(Color.btSurface)
            .cornerRadius(BTLayout.cardCornerRadius)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Expanded Metric

private struct ExpandedMetric: View {
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
                Text(value.map { String(format: "%.1f", $0) } ?? "--")
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)
                    .monospacedDigit()

                if !unit.isEmpty {
                    Text(unit)
                        .font(BTFont.captionSmall())
                        .foregroundColor(color)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview Support

struct PreviewShot: ShotDisplayable {
    let id: UUID
    let number: Int
    let result: ShotResult
    let speedMph: Double?
    let entryAngle: Double?
    let arrowBoard: Double?
    let revRate: Double?
}

// MARK: - Preview

#Preview("Shot Cards") {
    ScrollView {
        VStack(spacing: BTSpacing.md) {
            Text("Compact Shot Cards")
                .btHeading3()
                .frame(maxWidth: .infinity, alignment: .leading)

            // Strike shot
            ShotCard(
                shot: PreviewShot(
                    id: UUID(),
                    number: 1,
                    result: .strike,
                    speedMph: 17.5,
                    entryAngle: 5.8,
                    arrowBoard: 15.2,
                    revRate: 350
                )
            ) {}

            // Spare shot
            ShotCard(
                shot: PreviewShot(
                    id: UUID(),
                    number: 2,
                    result: .spare,
                    speedMph: 16.8,
                    entryAngle: 4.2,
                    arrowBoard: 12.5,
                    revRate: 320
                )
            ) {}

            // Open frame
            ShotCard(
                shot: PreviewShot(
                    id: UUID(),
                    number: 3,
                    result: .open,
                    speedMph: 15.2,
                    entryAngle: 3.1,
                    arrowBoard: 18.0,
                    revRate: 280
                )
            ) {}

            // Split
            ShotCard(
                shot: PreviewShot(
                    id: UUID(),
                    number: 4,
                    result: .split,
                    speedMph: 18.2,
                    entryAngle: 7.5,
                    arrowBoard: 10.5,
                    revRate: 400
                )
            ) {}

            Text("Expanded Shot Card")
                .btHeading3()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, BTSpacing.lg)

            ShotCardExpanded(
                shot: PreviewShot(
                    id: UUID(),
                    number: 1,
                    result: .strike,
                    speedMph: 17.5,
                    entryAngle: 5.8,
                    arrowBoard: 15.2,
                    revRate: 350
                )
            ) {}
        }
        .padding(BTLayout.screenHorizontalPadding)
    }
    .background(Color.btBackground)
}
