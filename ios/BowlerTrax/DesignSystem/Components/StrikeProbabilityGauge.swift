//
//  StrikeProbabilityGauge.swift
//  BowlerTrax
//
//  Circular gauge displaying strike probability percentage.
//  Color changes based on probability: green (>=70%), amber (40-69%), red (<40%).
//

import SwiftUI

// MARK: - Strike Probability Gauge

struct StrikeProbabilityGauge: View {
    // MARK: - Properties

    let probability: Double  // 0.0 to 1.0
    var size: CGFloat = 120
    var trackWidth: CGFloat = 12
    var showLabel: Bool = true

    @State private var animatedProgress: Double = 0

    // MARK: - Body

    var body: some View {
        VStack(spacing: BTSpacing.md) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.btSurfaceHighlight, lineWidth: trackWidth)

                // Progress arc
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        gaugeGradient,
                        style: StrokeStyle(lineWidth: trackWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center content
                centerContent
            }
            .frame(width: size, height: size)

            // Label
            if showLabel {
                Text("Strike Probability")
                    .font(BTFont.metricLabel())
                    .foregroundColor(.btMetricLabel)
                    .textCase(.uppercase)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: BTAnimation.gauge).delay(0.2)) {
                animatedProgress = probability
            }
        }
        .onChange(of: probability) { _, newValue in
            withAnimation(.easeOut(duration: BTAnimation.gauge)) {
                animatedProgress = newValue
            }
        }
    }

    // MARK: - Subviews

    private var centerContent: some View {
        VStack(spacing: BTSpacing.xxs) {
            Text("\(Int(probability * 100))")
                .font(BTFont.displaySmall())
                .foregroundColor(.btMetricValue)
                .monospacedDigit()

            Text("%")
                .font(BTFont.metricUnit())
                .foregroundColor(.btMetricLabel)
        }
    }

    // MARK: - Computed Properties

    private var gaugeGradient: AngularGradient {
        AngularGradient(
            colors: gaugeColors,
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * probability)
        )
    }

    private var gaugeColors: [Color] {
        if probability >= 0.7 {
            return [.btSuccess, .btSuccessLight]
        } else if probability >= 0.4 {
            return [.btWarning, .btWarningLight]
        } else {
            return [.btError, .btErrorLight]
        }
    }
}

// MARK: - Compact Gauge

struct StrikeProbabilityGaugeCompact: View {
    let probability: Double
    var size: CGFloat = 60
    var trackWidth: CGFloat = 6

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.btSurfaceHighlight, lineWidth: trackWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gaugeColor,
                    style: StrokeStyle(lineWidth: trackWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(probability * 100))")
                .font(BTFont.label())
                .foregroundColor(.btMetricValue)
                .monospacedDigit()
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animatedProgress = probability
            }
        }
    }

    private var gaugeColor: Color {
        if probability >= 0.7 {
            return .btSuccess
        } else if probability >= 0.4 {
            return .btWarning
        } else {
            return .btError
        }
    }
}

// MARK: - Linear Probability Bar

struct StrikeProbabilityBar: View {
    let probability: Double
    var height: CGFloat = 8

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            HStack {
                Text("Strike Probability")
                    .font(BTFont.metricLabel())
                    .foregroundColor(.btMetricLabel)
                    .textCase(.uppercase)

                Spacer()

                Text("\(Int(probability * 100))%")
                    .font(BTFont.label())
                    .foregroundColor(.btMetricValue)
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.btSurfaceHighlight)

                    // Progress bar
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(barGradient)
                        .frame(width: geometry.size.width * animatedProgress)
                }
            }
            .frame(height: height)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedProgress = probability
            }
        }
    }

    private var barGradient: LinearGradient {
        LinearGradient(
            colors: barColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var barColors: [Color] {
        if probability >= 0.7 {
            return [.btSuccess, .btSuccessLight]
        } else if probability >= 0.4 {
            return [.btWarning, .btWarningLight]
        } else {
            return [.btError, .btErrorLight]
        }
    }
}

// MARK: - Preview

#Preview("Strike Probability Gauges") {
    ScrollView {
        VStack(spacing: BTSpacing.xxl) {
            // Standard gauges at different probabilities
            Text("Standard Gauge")
                .btHeading3()
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: BTSpacing.xl) {
                StrikeProbabilityGauge(probability: 0.85)
                StrikeProbabilityGauge(probability: 0.55)
                StrikeProbabilityGauge(probability: 0.25)
            }

            // Compact gauges
            Text("Compact Gauge")
                .btHeading3()
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: BTSpacing.lg) {
                StrikeProbabilityGaugeCompact(probability: 0.85)
                StrikeProbabilityGaugeCompact(probability: 0.55)
                StrikeProbabilityGaugeCompact(probability: 0.25)
            }

            // Linear bars
            Text("Linear Bar")
                .btHeading3()
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: BTSpacing.lg) {
                StrikeProbabilityBar(probability: 0.85)
                StrikeProbabilityBar(probability: 0.55)
                StrikeProbabilityBar(probability: 0.25)
            }

            // Different sizes
            Text("Custom Sizes")
                .btHeading3()
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: BTSpacing.lg) {
                StrikeProbabilityGauge(probability: 0.73, size: 80, trackWidth: 8)
                StrikeProbabilityGauge(probability: 0.73, size: 120, trackWidth: 12)
                StrikeProbabilityGauge(probability: 0.73, size: 160, trackWidth: 16)
            }
        }
        .padding(BTLayout.screenHorizontalPadding)
    }
    .background(Color.btBackground)
}
