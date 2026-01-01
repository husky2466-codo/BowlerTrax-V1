// Animation.swift
// BowlerTrax
//
// Animation specifications including durations, transitions, and spring presets.
// Provides consistent motion design across the app.

import SwiftUI

// MARK: - BTAnimation

enum BTAnimation {
    // MARK: - Standard durations
    static let fast: Double = 0.15
    static let normal: Double = 0.25
    static let slow: Double = 0.4
    static let trajectory: Double = 1.5
    static let gauge: Double = 1.0
    static let metricCount: Double = 0.6

    // MARK: - Spring presets
    static var bounce: Animation {
        .spring(response: 0.35, dampingFraction: 0.7)
    }

    static var smooth: Animation {
        .spring(response: 0.4, dampingFraction: 0.9)
    }

    static var snappy: Animation {
        .spring(response: 0.25, dampingFraction: 0.8)
    }

    static var tabSwitch: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }

    /// Standard spring animation
    static var spring: Animation {
        .spring(response: 0.35, dampingFraction: 0.8)
    }

    // MARK: - Standard easing
    static var easeOutFast: Animation {
        .easeOut(duration: fast)
    }

    static var easeOutNormal: Animation {
        .easeOut(duration: normal)
    }

    static var easeOutSlow: Animation {
        .easeOut(duration: slow)
    }

    // MARK: - Button press
    static var buttonPress: Animation {
        .easeOut(duration: fast)
    }

    // MARK: - Card appearance
    static func cardAppear(delay: Double = 0) -> Animation {
        .easeOut(duration: slow).delay(delay)
    }

    // MARK: - Loading spinner
    static var loadingRotation: Animation {
        .linear(duration: 1.0).repeatForever(autoreverses: false)
    }

    // MARK: - Recording pulse
    static var recordingPulse: Animation {
        .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    }
}

// MARK: - Screen Transitions

extension AnyTransition {
    /// Slide transition for navigation push/pop
    static var btSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Modal transition from bottom
    static var btModal: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    /// Simple fade transition
    static var btFade: AnyTransition {
        .opacity.animation(.easeInOut(duration: 0.2))
    }

    /// Scale and fade for cards
    static var btScaleFade: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }
}

// MARK: - View Extensions for Animations

extension View {
    /// Apply card appearance animation with staggered delay
    func btCardAppearAnimation(delay: Double = 0) -> some View {
        self.modifier(CardAppearModifier(delay: delay))
    }

    /// Apply press animation for buttons
    func btPressAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(BTAnimation.buttonPress, value: isPressed)
    }
}

// MARK: - Card Appear Modifier

struct CardAppearModifier: ViewModifier {
    let delay: Double
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .onAppear {
                withAnimation(BTAnimation.cardAppear(delay: delay)) {
                    hasAppeared = true
                }
            }
    }
}

// MARK: - Animated Number View

struct AnimatedNumber: View {
    let value: Double
    let format: String
    let duration: Double

    @State private var displayValue: Double = 0

    init(value: Double, format: String = "%.1f", duration: Double = BTAnimation.metricCount) {
        self.value = value
        self.format = format
        self.duration = duration
    }

    var body: some View {
        Text(String(format: format, displayValue))
            .btMetricValue()
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Loading View

struct BTLoadingView: View {
    @State private var rotation: Double = 0
    let size: CGFloat
    let lineWidth: CGFloat

    init(size: CGFloat = 40, lineWidth: CGFloat = 4) {
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.btSurfaceHighlight, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.btPrimary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(BTAnimation.loadingRotation) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        BTLoadingView()

        AnimatedNumber(value: 17.5, format: "%.1f")
    }
    .padding()
    .background(Color.btBackground)
}
