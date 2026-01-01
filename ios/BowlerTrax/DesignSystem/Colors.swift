//
//  Colors.swift
//  BowlerTrax
//
//  Design System - Color Palette
//  Dark theme optimized for bowling alley environments
//

import SwiftUI

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Primary Brand Colors

extension Color {
    /// Primary Teal - Main brand color (#14B8A6)
    static let btPrimary = Color(hex: "14B8A6")

    /// Primary Light - Lighter teal variant (#5EEAD4)
    static let btPrimaryLight = Color(hex: "5EEAD4")

    /// Primary Dark - Darker teal variant (#0D9488)
    static let btPrimaryDark = Color(hex: "0D9488")

    /// Primary Muted - Subtle teal (#2DD4BF)
    static let btPrimaryMuted = Color(hex: "2DD4BF")
}

// MARK: - Accent Colors

extension Color {
    /// Cyan Accent - Secondary highlight (#22D3EE)
    static let btAccent = Color(hex: "22D3EE")

    /// Accent Light - Lighter cyan (#67E8F9)
    static let btAccentLight = Color(hex: "67E8F9")

    /// Accent Dark - Darker cyan (#06B6D4)
    static let btAccentDark = Color(hex: "06B6D4")
}

// MARK: - Background Colors (Dark Theme)

extension Color {
    /// Background - Deepest black (#0F0F0F)
    static let btBackground = Color(hex: "0F0F0F")

    /// Surface - Card/surface background (#1A1A1A)
    static let btSurface = Color(hex: "1A1A1A")

    /// Surface Elevated - Modals, popovers (#252525)
    static let btSurfaceElevated = Color(hex: "252525")

    /// Surface Highlight - Pressed/hover states (#2A2A2A)
    static let btSurfaceHighlight = Color(hex: "2A2A2A")

    /// Lane Background - Lane view specific (#1C1C1E)
    static let btLaneBackground = Color(hex: "1C1C1E")

    /// Lane Wood - Subtle wood color (#3D2817)
    static let btLaneWood = Color(hex: "3D2817")
}

// MARK: - Text Colors

extension Color {
    /// Text Primary - Main content (#FFFFFF)
    static let btTextPrimary = Color(hex: "FFFFFF")

    /// Text Secondary - Labels, descriptions (#A1A1AA)
    static let btTextSecondary = Color(hex: "A1A1AA")

    /// Text Muted - Disabled, hints (#71717A)
    static let btTextMuted = Color(hex: "71717A")

    /// Text Inverse - Text on light backgrounds (#18181B)
    static let btTextInverse = Color(hex: "18181B")

    /// Metric Value - Large numbers (#FAFAFA)
    static let btMetricValue = Color(hex: "FAFAFA")

    /// Metric Label - Metric labels (#9CA3AF)
    static let btMetricLabel = Color(hex: "9CA3AF")

    /// Metric Delta - Comparison text (#A1A1AA)
    static let btMetricDelta = Color(hex: "A1A1AA")
}

// MARK: - Semantic Colors

extension Color {
    // Success - Strike/Perfect
    /// Success - Green (#22C55E)
    static let btSuccess = Color(hex: "22C55E")

    /// Success Light - Lighter green (#4ADE80)
    static let btSuccessLight = Color(hex: "4ADE80")

    /// Success Muted - Background green (#166534)
    static let btSuccessMuted = Color(hex: "166534")

    // Warning - Attention needed
    /// Warning - Amber (#F59E0B)
    static let btWarning = Color(hex: "F59E0B")

    /// Warning Light - Lighter amber (#FBBF24)
    static let btWarningLight = Color(hex: "FBBF24")

    /// Warning Muted - Background amber (#92400E)
    static let btWarningMuted = Color(hex: "92400E")

    // Error - Danger/Reset
    /// Error - Red (#EF4444)
    static let btError = Color(hex: "EF4444")

    /// Error Light - Lighter red (#F87171)
    static let btErrorLight = Color(hex: "F87171")

    /// Error Muted - Background red (#991B1B)
    static let btErrorMuted = Color(hex: "991B1B")

    // Info - Informational
    /// Info - Blue (#3B82F6)
    static let btInfo = Color(hex: "3B82F6")

    /// Info Light - Lighter blue (#60A5FA)
    static let btInfoLight = Color(hex: "60A5FA")

    /// Info Muted - Background blue (#1E40AF)
    static let btInfoMuted = Color(hex: "1E40AF")
}

// MARK: - Metric Accent Colors

extension Color {
    // Speed metric - Energetic orange
    /// Speed - Orange (#F97316)
    static let btSpeed = Color(hex: "F97316")

    /// Speed Light - Lighter orange (#FB923C)
    static let btSpeedLight = Color(hex: "FB923C")

    // Rev Rate metric - Dynamic purple
    /// Rev Rate - Purple (#A855F7)
    static let btRevRate = Color(hex: "A855F7")

    /// Rev Rate Light - Lighter purple (#C084FC)
    static let btRevRateLight = Color(hex: "C084FC")

    // Entry Angle metric - Primary teal
    /// Angle - Teal (#14B8A6)
    static let btAngle = Color(hex: "14B8A6")

    /// Angle Light - Lighter teal (#2DD4BF)
    static let btAngleLight = Color(hex: "2DD4BF")

    // Strike Probability - Success green
    /// Strike - Green (#22C55E)
    static let btStrike = Color(hex: "22C55E")

    /// Strike Light - Lighter green (#4ADE80)
    static let btStrikeLight = Color(hex: "4ADE80")

    // Breakpoint - Cyan
    /// Breakpoint - Cyan (#06B6D4)
    static let btBreakpoint = Color(hex: "06B6D4")

    /// Breakpoint Light - Lighter cyan (#22D3EE)
    static let btBreakpointLight = Color(hex: "22D3EE")

    // Board Position - Slate blue
    /// Board - Indigo (#6366F1)
    static let btBoard = Color(hex: "6366F1")

    /// Board Light - Lighter indigo (#818CF8)
    static let btBoardLight = Color(hex: "818CF8")
}

// MARK: - Border Colors

extension Color {
    /// Border - Default border color (#27272A)
    static let btBorder = Color(hex: "27272A")

    /// Border Light - Lighter border (#3F3F46)
    static let btBorderLight = Color(hex: "3F3F46")

    /// Border Active - Active/focused border (uses primary)
    static let btBorderActive = Color(hex: "14B8A6")
}
