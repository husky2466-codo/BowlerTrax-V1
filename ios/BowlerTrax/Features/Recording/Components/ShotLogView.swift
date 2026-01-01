//
//  ShotLogView.swift
//  BowlerTrax
//
//  Scrolling list of shot cards during a recording session.
//  Shows latest shots at top with reverse chronological order.
//

import SwiftUI

// MARK: - Shot Log View

/// Scrollable list of recorded shots during a session
struct ShotLogView: View {
    // MARK: - Properties

    let shots: [ShotAnalysis]
    var maxVisible: Int = 5
    var onShotTap: ((ShotAnalysis, Int) -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            // Section header
            sectionHeader

            // Content
            if shots.isEmpty {
                emptyState
            } else {
                shotList
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text("Shot Log")
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextMuted)
                .textCase(.uppercase)

            Text("(\(shots.count) shots)")
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)

            Spacer()

            // Scroll indicator if more shots than visible
            if shots.count > maxVisible {
                HStack(spacing: BTSpacing.xxs) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 10))
                        .foregroundColor(.btTextMuted)
                    Text("scroll")
                        .font(BTFont.captionSmall())
                        .foregroundColor(.btTextMuted)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: BTSpacing.sm) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 32))
                .foregroundColor(.btTextMuted)

            Text("No shots recorded yet")
                .font(BTFont.body())
                .foregroundColor(.btTextSecondary)

            Text("Roll a ball to start tracking")
                .font(BTFont.caption())
                .foregroundColor(.btTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BTSpacing.xl)
        .background(Color.btSurface)
        .cornerRadius(10)
    }

    // MARK: - Shot List

    private var shotList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: BTSpacing.xs) {
                // Shots in reverse chronological order (latest first)
                ForEach(Array(shots.enumerated().reversed()), id: \.element.id) { index, shot in
                    let shotNumber = index + 1
                    let isLatest = index == shots.count - 1

                    Button {
                        onShotTap?(shot, shotNumber)
                    } label: {
                        ShotLogCard(
                            shot: shot,
                            shotNumber: shotNumber,
                            isLatest: isLatest
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, BTSpacing.xxs)
        }
        .frame(maxHeight: maxVisibleHeight)
    }

    // MARK: - Computed Properties

    /// Maximum height based on visible shot count
    private var maxVisibleHeight: CGFloat {
        // Each card is 50pt height + 4pt spacing
        let cardHeight: CGFloat = 50
        let spacing: CGFloat = BTSpacing.xs
        let visibleCount = min(shots.count, maxVisible)
        return CGFloat(visibleCount) * cardHeight + CGFloat(max(0, visibleCount - 1)) * spacing
    }
}

// MARK: - Inline Shot Log

/// Compact inline version for embedding in metrics panel
struct InlineShotLog: View {
    let shots: [ShotAnalysis]
    var maxVisible: Int = 3

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            // Mini header
            HStack {
                Text("Recent Shots")
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btTextMuted)
                    .textCase(.uppercase)

                Spacer()

                if !shots.isEmpty {
                    Text("\(shots.count)")
                        .font(BTFont.captionSmall())
                        .foregroundColor(.btPrimary)
                        .padding(.horizontal, BTSpacing.xs)
                        .padding(.vertical, 2)
                        .background(Color.btPrimary.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            if shots.isEmpty {
                Text("No shots yet")
                    .font(BTFont.caption())
                    .foregroundColor(.btTextMuted)
                    .padding(.vertical, BTSpacing.sm)
            } else {
                // Show last few shots in compact form
                ForEach(Array(shots.suffix(maxVisible).enumerated().reversed()), id: \.element.id) { index, shot in
                    let shotNumber = shots.count - maxVisible + index + 1
                    let isLatest = shotNumber == shots.count

                    CompactShotRow(
                        shot: shot,
                        shotNumber: shotNumber,
                        isLatest: isLatest
                    )
                }
            }
        }
        .padding(BTSpacing.sm)
        .background(Color.btSurfaceElevated)
        .cornerRadius(10)
    }
}

// MARK: - Compact Shot Row

/// Ultra-compact shot display for inline log
private struct CompactShotRow: View {
    let shot: ShotAnalysis
    let shotNumber: Int
    let isLatest: Bool

    var body: some View {
        HStack(spacing: BTSpacing.xs) {
            // Shot number
            Text("\(shotNumber)")
                .font(BTFont.labelSmall())
                .foregroundColor(isLatest ? .btPrimary : .btTextMuted)
                .frame(width: 20)

            // Result
            Text(determineResult().symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(determineResult().color)

            // Speed
            if let speed = shot.launchSpeed {
                Text(String(format: "%.1f", speed))
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btTextSecondary)
                    .monospacedDigit()
            }

            Spacer()

            // Entry angle
            if let angle = shot.entryAngle?.angleDegrees {
                Text(String(format: "%.1f", angle) + "deg")
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btAngle)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, BTSpacing.xxs)
    }

    private func determineResult() -> ShotResult {
        guard let prob = shot.strikeProbability else { return .open }

        // Map LeaveType to ShotResult
        switch prob.predictedLeave {
        case .strike:
            return .strike
        case .split:
            return .split
        case .washout:
            return .washout
        case .gutterBall:
            return .gutter
        case .tenPin, .sevenPin, .fourPin, .sixPin, .bucket:
            return prob.probability > 0.5 ? .spare : .open
        case .mixedLeave:
            return .open
        }
    }
}

// MARK: - Preview Support

/// Creates a sample ShotAnalysis for previews
private func makeSampleShot(
    speed: Double = 17.0,
    angle: Double = 5.5,
    probability: Double = 0.7
) -> ShotAnalysis {
    ShotAnalysis(
        id: UUID(),
        trajectory: [],
        launchSpeed: speed,
        impactSpeed: speed - 1.5,
        entryAngle: EntryAngleResult(
            angleDegrees: angle,
            isOptimal: angle >= 4 && angle <= 7,
            direction: .left,
            recommendation: "Good",
            pocketBoard: 17.5,
            confidence: 0.85
        ),
        revRate: nil,
        strikeProbability: StrikeProbabilityResult(
            probability: probability,
            factors: StrikeFactors(pocketScore: 0.7, angleScore: 0.8, speedScore: 0.7, revScore: 0.6),
            predictedLeave: probability > 0.7 ? .strike : (probability > 0.4 ? .tenPin : .split),
            recommendation: nil,
            riskLevel: probability > 0.7 ? .low : (probability > 0.4 ? .medium : .high)
        ),
        arrowBoard: 15.0,
        breakpoint: nil,
        pocketBoard: 17.5,
        duration: 2.1,
        frameCount: 250
    )
}

/// Creates an array of sample shots for previews
private func makeSampleShots(count: Int) -> [ShotAnalysis] {
    (0..<count).map { _ in
        makeSampleShot(
            speed: Double.random(in: 15...19),
            angle: Double.random(in: 3...8),
            probability: Double.random(in: 0.2...0.95)
        )
    }
}

// MARK: - Preview

#Preview("Shot Log View - With Shots") {
    ZStack {
        Color.btBackground
            .ignoresSafeArea()

        ShotLogView(shots: makeSampleShots(count: 8), maxVisible: 5)
            .frame(width: 300)
            .padding()
    }
}

#Preview("Shot Log View - Empty") {
    ZStack {
        Color.btBackground
            .ignoresSafeArea()

        ShotLogView(shots: [], maxVisible: 5)
            .frame(width: 300)
            .padding()
    }
}

#Preview("Inline Shot Log") {
    ZStack {
        Color.btBackground
            .ignoresSafeArea()

        InlineShotLog(shots: makeSampleShots(count: 5), maxVisible: 3)
            .frame(width: 280)
            .padding()
    }
}
