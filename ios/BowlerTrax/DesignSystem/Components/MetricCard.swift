//
//  MetricCard.swift
//  BowlerTrax
//
//  Displays individual bowling metrics (speed, rev rate, angle, etc.)
//  in a compact card format with optional previous value comparison.
//

import SwiftUI

// MARK: - Metric Card Size

enum MetricCardSize {
    case compact    // 2 columns, shorter (80pt min height)
    case standard   // 2 columns, standard (100pt min height)
    case featured   // Full width, larger (120pt min height)

    var minHeight: CGFloat {
        switch self {
        case .compact: return 80
        case .standard: return 100
        case .featured: return 120
        }
    }

    var valueFont: Font {
        switch self {
        case .compact: return BTFont.displaySmall()
        case .standard: return BTFont.metricValue()
        case .featured: return BTFont.displayMedium()
        }
    }

    var padding: CGFloat {
        switch self {
        case .compact, .standard: return BTLayout.metricCardPadding
        case .featured: return BTLayout.cardPadding
        }
    }
}

// MARK: - Metric Card Component

struct MetricCard: View {
    // MARK: - Properties

    let title: String
    let value: String
    let unit: String
    var previousValue: String? = nil
    let accentColor: Color
    var size: MetricCardSize = .standard

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            // Label
            Text(title)
                .font(BTFont.metricLabel())
                .foregroundColor(.btMetricLabel)
                .textCase(.uppercase)
                .tracking(0.5)

            // Value + Unit
            HStack(alignment: .firstTextBaseline, spacing: BTSpacing.xs) {
                Text(value)
                    .font(size.valueFont)
                    .foregroundColor(.btMetricValue)
                    .monospacedDigit()

                Text(unit)
                    .font(BTFont.metricUnit())
                    .foregroundColor(.btMetricLabel)
            }

            // Previous value comparison (optional)
            if let prev = previousValue {
                Text("Prev: \(prev)")
                    .font(BTFont.metricDelta())
                    .foregroundColor(.btMetricDelta)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: size.minHeight)
        .padding(size.padding)
        .background(cardBackground)
    }

    // MARK: - Subviews

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.btSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Convenience Initializers

extension MetricCard {
    /// Create a speed metric card
    static func speed(value: Double, previousValue: Double? = nil, size: MetricCardSize = .standard) -> MetricCard {
        MetricCard(
            title: "Speed",
            value: String(format: "%.1f", value),
            unit: "mph",
            previousValue: previousValue.map { String(format: "%.1f", $0) },
            accentColor: .btSpeed,
            size: size
        )
    }

    /// Create a rev rate metric card
    static func revRate(value: Double, previousValue: Double? = nil, size: MetricCardSize = .standard) -> MetricCard {
        MetricCard(
            title: "Rev Rate",
            value: String(format: "%.0f", value),
            unit: "rpm",
            previousValue: previousValue.map { String(format: "%.0f", $0) },
            accentColor: .btRevRate,
            size: size
        )
    }

    /// Create an entry angle metric card
    static func entryAngle(value: Double, previousValue: Double? = nil, size: MetricCardSize = .standard) -> MetricCard {
        MetricCard(
            title: "Entry Angle",
            value: String(format: "%.1f", value),
            unit: "deg",
            previousValue: previousValue.map { String(format: "%.1f", $0) },
            accentColor: .btAngle,
            size: size
        )
    }

    /// Create a strike rate metric card
    static func strikeRate(value: Double, previousValue: Double? = nil, size: MetricCardSize = .standard) -> MetricCard {
        MetricCard(
            title: "Strike Rate",
            value: String(format: "%.0f", value),
            unit: "%",
            previousValue: previousValue.map { String(format: "%.0f", $0) },
            accentColor: .btStrike,
            size: size
        )
    }

    /// Create a board position metric card
    static func board(value: Double, label: String = "Board", size: MetricCardSize = .standard) -> MetricCard {
        MetricCard(
            title: label,
            value: String(format: "%.1f", value),
            unit: "bd",
            accentColor: .btBoard,
            size: size
        )
    }
}

// MARK: - Preview

#Preview("Metric Cards") {
    ScrollView {
        VStack(spacing: BTSpacing.lg) {
            // Standard size cards
            LazyVGrid(columns: BTGrid.columns2, spacing: BTSpacing.md) {
                MetricCard.speed(value: 17.2, previousValue: 16.8)
                MetricCard.revRate(value: 342, previousValue: 338)
                MetricCard.entryAngle(value: 5.8, previousValue: 5.6)
                MetricCard.strikeRate(value: 47, previousValue: 42)
            }

            // Compact size cards
            Text("Compact Size")
                .btHeading3()
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: BTGrid.columns2, spacing: BTSpacing.md) {
                MetricCard.speed(value: 17.2, size: .compact)
                MetricCard.revRate(value: 342, size: .compact)
            }

            // Featured size card
            Text("Featured Size")
                .btHeading3()
                .frame(maxWidth: .infinity, alignment: .leading)

            MetricCard(
                title: "Strike Probability",
                value: "73",
                unit: "%",
                accentColor: .btStrike,
                size: .featured
            )
        }
        .padding(BTLayout.screenHorizontalPadding)
    }
    .background(Color.btBackground)
}
