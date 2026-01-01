//
//  Typography.swift
//  BowlerTrax
//
//  Design System - Typography
//  SF Pro system font for native iOS feel
//

import SwiftUI

// MARK: - Font System

enum BTFont {
    // MARK: - Display (Hero Numbers/Metrics)

    /// Display Large - 56pt bold rounded (hero metrics)
    static func displayLarge() -> Font {
        .system(size: 56, weight: .bold, design: .rounded)
    }

    /// Display Medium - 44pt bold rounded (secondary hero)
    static func displayMedium() -> Font {
        .system(size: 44, weight: .bold, design: .rounded)
    }

    /// Display Small - 36pt bold rounded (tertiary metric)
    static func displaySmall() -> Font {
        .system(size: 36, weight: .bold, design: .rounded)
    }

    // MARK: - Headings

    /// H1 - 32pt bold (screen titles)
    static func h1() -> Font {
        .system(size: 32, weight: .bold)
    }

    /// H2 - 24pt semibold (section headers)
    static func h2() -> Font {
        .system(size: 24, weight: .semibold)
    }

    /// H3 - 20pt semibold (card titles)
    static func h3() -> Font {
        .system(size: 20, weight: .semibold)
    }

    /// H4 - 18pt medium (subsection headers)
    static func h4() -> Font {
        .system(size: 18, weight: .medium)
    }

    // MARK: - Body Text

    /// Body Large - 17pt regular (primary content)
    static func bodyLarge() -> Font {
        .system(size: 17, weight: .regular)
    }

    /// Body - 15pt regular (standard content)
    static func body() -> Font {
        .system(size: 15, weight: .regular)
    }

    /// Body Small - 13pt regular (dense content)
    static func bodySmall() -> Font {
        .system(size: 13, weight: .regular)
    }

    // MARK: - Labels & Captions

    /// Label - 14pt medium (form labels, buttons)
    static func label() -> Font {
        .system(size: 14, weight: .medium)
    }

    /// Label Small - 12pt medium (small labels)
    static func labelSmall() -> Font {
        .system(size: 12, weight: .medium)
    }

    /// Caption - 12pt regular (timestamps, hints)
    static func caption() -> Font {
        .system(size: 12, weight: .regular)
    }

    /// Caption Small - 10pt regular (fine print)
    static func captionSmall() -> Font {
        .system(size: 10, weight: .regular)
    }

    // MARK: - Metric-Specific

    /// Metric Value - 48pt bold rounded (metric cards)
    static func metricValue() -> Font {
        .system(size: 48, weight: .bold, design: .rounded)
    }

    /// Metric Unit - 16pt medium (units: mph, rpm, etc.)
    static func metricUnit() -> Font {
        .system(size: 16, weight: .medium)
    }

    /// Metric Label - 13pt medium (metric labels)
    static func metricLabel() -> Font {
        .system(size: 13, weight: .medium)
    }

    /// Metric Delta - 11pt regular (comparison values)
    static func metricDelta() -> Font {
        .system(size: 11, weight: .regular)
    }

    // MARK: - Monospaced (Board Numbers, Coordinates)

    /// Mono - 14pt medium monospaced (data values)
    static func mono() -> Font {
        .system(size: 14, weight: .medium, design: .monospaced)
    }

    /// Mono Large - 18pt semibold monospaced (shot numbers)
    static func monoLarge() -> Font {
        .system(size: 18, weight: .semibold, design: .monospaced)
    }

    // MARK: - Additional Fonts

    /// Large Title - 34pt bold (onboarding, welcome screens)
    static func largeTitle() -> Font {
        .system(size: 34, weight: .bold)
    }

    /// Title - 28pt bold (screen titles)
    static func title() -> Font {
        .system(size: 28, weight: .bold)
    }

    /// Button Label - 17pt semibold (button text)
    static func buttonLabel() -> Font {
        .system(size: 17, weight: .semibold)
    }

    /// Tab Label - 10pt medium (tab bar labels)
    static func tabLabel() -> Font {
        .system(size: 10, weight: .medium)
    }
}

// MARK: - Text Style Modifiers

extension View {
    /// Display large style - hero metric values
    func btDisplayLarge() -> some View {
        self
            .font(BTFont.displayLarge())
            .foregroundColor(.btMetricValue)
    }

    /// Display medium style - secondary metrics
    func btDisplayMedium() -> some View {
        self
            .font(BTFont.displayMedium())
            .foregroundColor(.btMetricValue)
    }

    /// Display small style - tertiary metrics
    func btDisplaySmall() -> some View {
        self
            .font(BTFont.displaySmall())
            .foregroundColor(.btMetricValue)
    }

    /// Heading 1 style - screen titles
    func btHeading1() -> some View {
        self
            .font(BTFont.h1())
            .foregroundColor(.btTextPrimary)
    }

    /// Heading 2 style - section headers
    func btHeading2() -> some View {
        self
            .font(BTFont.h2())
            .foregroundColor(.btTextPrimary)
    }

    /// Heading 3 style - card titles
    func btHeading3() -> some View {
        self
            .font(BTFont.h3())
            .foregroundColor(.btTextPrimary)
    }

    /// Heading 4 style - subsections
    func btHeading4() -> some View {
        self
            .font(BTFont.h4())
            .foregroundColor(.btTextPrimary)
    }

    /// Body style - standard content
    func btBody() -> some View {
        self
            .font(BTFont.body())
            .foregroundColor(.btTextSecondary)
    }

    /// Body large style - primary content
    func btBodyLarge() -> some View {
        self
            .font(BTFont.bodyLarge())
            .foregroundColor(.btTextSecondary)
    }

    /// Caption style - hints, timestamps
    func btCaption() -> some View {
        self
            .font(BTFont.caption())
            .foregroundColor(.btTextMuted)
    }

    /// Label style - buttons, form labels
    func btLabel() -> some View {
        self
            .font(BTFont.label())
            .foregroundColor(.btTextPrimary)
    }

    /// Metric value style - large numbers with monospaced digits
    func btMetricValue() -> some View {
        self
            .font(BTFont.metricValue())
            .foregroundColor(.btMetricValue)
            .monospacedDigit()
    }

    /// Metric label style - uppercase, tracked labels
    func btMetricLabel() -> some View {
        self
            .font(BTFont.metricLabel())
            .foregroundColor(.btMetricLabel)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    /// Metric unit style - units like mph, rpm
    func btMetricUnit() -> some View {
        self
            .font(BTFont.metricUnit())
            .foregroundColor(.btMetricLabel)
    }

    /// Metric delta style - comparison values
    func btMetricDelta() -> some View {
        self
            .font(BTFont.metricDelta())
            .foregroundColor(.btMetricDelta)
    }

    /// Monospaced style - data, coordinates
    func btMono() -> some View {
        self
            .font(BTFont.mono())
            .foregroundColor(.btTextPrimary)
    }

    /// Monospaced large style - shot numbers
    func btMonoLarge() -> some View {
        self
            .font(BTFont.monoLarge())
            .foregroundColor(.btTextPrimary)
    }
}
