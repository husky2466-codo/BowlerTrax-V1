//
//  ShotLogCard.swift
//  BowlerTrax
//
//  Compact card for the shot log during recording.
//  Displays shot number, result indicator, and key metrics.
//

import SwiftUI

// MARK: - Shot Log Card

/// Compact card displaying shot info in the recording shot log
struct ShotLogCard: View {
    // MARK: - Properties

    let shot: ShotAnalysis
    let shotNumber: Int
    let isLatest: Bool

    // MARK: - State

    @State private var isHighlighted: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: BTSpacing.sm) {
            // Shot number badge
            Text("\(shotNumber)")
                .font(BTFont.monoLarge())
                .foregroundColor(isLatest ? .btTextPrimary : .btTextSecondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isLatest ? Color.btPrimary : Color.btSurfaceHighlight)
                )

            // Result indicator
            resultIndicator

            // Metrics (compact format)
            metricsText

            Spacer(minLength: 0)

            // Chevron for tappable
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.btTextMuted)
        }
        .padding(.horizontal, BTSpacing.sm)
        .padding(.vertical, BTSpacing.xs)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isLatest ? Color.btPrimary.opacity(0.1) : Color.btSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isLatest ? Color.btPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
        .onAppear {
            if isLatest {
                triggerHighlightAnimation()
            }
        }
        .onChange(of: isLatest) { _, newValue in
            if newValue {
                triggerHighlightAnimation()
            }
        }
    }

    // MARK: - Result Indicator

    @ViewBuilder
    private var resultIndicator: some View {
        let result = determineResult()

        Text(result.symbol)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(result.color)
            .frame(width: 28, height: 28)
            .background(result.color.opacity(0.2))
            .cornerRadius(6)
    }

    // MARK: - Metrics Text

    private var metricsText: some View {
        HStack(spacing: BTSpacing.xxs) {
            // Speed
            if let speed = shot.launchSpeed {
                Text(String(format: "%.1f", speed))
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)
                    .monospacedDigit()

                Text("mph")
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btSpeed)
            }

            // Separator dot
            if shot.launchSpeed != nil && shot.entryAngle != nil {
                Text(" - ")
                    .font(BTFont.caption())
                    .foregroundColor(.btTextMuted)
            }

            // Entry angle
            if let angle = shot.entryAngle?.angleDegrees {
                Text(String(format: "%.1f", angle))
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)
                    .monospacedDigit()

                Text("deg")
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btAngle)
            }
        }
    }

    // MARK: - Helpers

    private func determineResult() -> ShotResult {
        // Determine result based on strike probability
        guard let prob = shot.strikeProbability else {
            return .open
        }

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
            // These are spare-able leaves
            return prob.probability > 0.5 ? .spare : .open
        case .mixedLeave:
            return .open
        }
    }

    private func triggerHighlightAnimation() {
        withAnimation(.easeOut(duration: 0.15)) {
            isHighlighted = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.2)) {
                isHighlighted = false
            }
        }
    }
}

// MARK: - Preview Support

/// Creates a sample ShotAnalysis for previews with given metrics
private func makeSampleShot(
    speed: Double,
    angle: Double,
    probability: Double,
    leave: LeaveType = .strike
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
            recommendation: angle >= 4 && angle <= 7 ? "Good angle" : "Adjust angle",
            pocketBoard: 17.5,
            confidence: 0.85
        ),
        revRate: nil,
        strikeProbability: StrikeProbabilityResult(
            probability: probability,
            factors: StrikeFactors(pocketScore: 0.7, angleScore: 0.8, speedScore: 0.7, revScore: 0.6),
            predictedLeave: leave,
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

// MARK: - Preview

#Preview("Shot Log Cards") {
    ScrollView {
        VStack(spacing: BTSpacing.sm) {
            // Latest shot (highlighted)
            ShotLogCard(
                shot: makeSampleShot(speed: 17.2, angle: 5.8, probability: 0.85, leave: .strike),
                shotNumber: 5,
                isLatest: true
            )

            // Previous shots
            ShotLogCard(
                shot: makeSampleShot(speed: 16.8, angle: 4.5, probability: 0.65, leave: .tenPin),
                shotNumber: 4,
                isLatest: false
            )

            ShotLogCard(
                shot: makeSampleShot(speed: 18.1, angle: 7.2, probability: 0.35, leave: .split),
                shotNumber: 3,
                isLatest: false
            )

            ShotLogCard(
                shot: makeSampleShot(speed: 15.5, angle: 3.2, probability: 0.25, leave: .mixedLeave),
                shotNumber: 2,
                isLatest: false
            )

            ShotLogCard(
                shot: makeSampleShot(speed: 16.2, angle: 5.5, probability: 0.78, leave: .strike),
                shotNumber: 1,
                isLatest: false
            )
        }
        .padding(BTSpacing.md)
    }
    .frame(width: 300)
    .background(Color.btBackground)
}
