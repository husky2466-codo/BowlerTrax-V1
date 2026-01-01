//
//  Spacing.swift
//  BowlerTrax
//
//  Design System - Spacing, Layout, and Grid
//  Based on 8pt grid system for consistent visual rhythm
//

import SwiftUI

// MARK: - Spacing Scale

/// Spacing constants based on 8pt grid system
enum BTSpacing {
    /// Base unit: 8pt
    static let base: CGFloat = 8

    /// XXS: 2pt - Icon-to-text gap
    static let xxs: CGFloat = 2

    /// XS: 4pt - Tight spacing, inline elements
    static let xs: CGFloat = 4

    /// SM: 8pt - Related elements, list item padding
    static let sm: CGFloat = 8

    /// MD: 12pt - Form field padding, button padding
    static let md: CGFloat = 12

    /// LG: 16pt - Card padding, section spacing
    static let lg: CGFloat = 16

    /// XL: 24pt - Between sections, major breaks
    static let xl: CGFloat = 24

    /// XXL: 32pt - Screen padding, large separations
    static let xxl: CGFloat = 32

    /// XXXL: 48pt - Hero spacing, top margins
    static let xxxl: CGFloat = 48

    /// Huge: 64pt - Major section breaks
    static let huge: CGFloat = 64
}

// MARK: - Component Layout Constants

/// Layout constants for specific components
enum BTLayout {
    // MARK: Screen Layout

    /// Horizontal padding for screen edges: 16pt
    static let screenHorizontalPadding: CGFloat = 16

    /// Vertical padding for screen edges: 24pt
    static let screenVerticalPadding: CGFloat = 24

    /// Safe area top padding: 8pt
    static let safeAreaTop: CGFloat = 8

    /// Safe area bottom padding (home indicator): 34pt
    static let safeAreaBottom: CGFloat = 34

    // MARK: Card Layout

    /// Card internal padding: 16pt
    static let cardPadding: CGFloat = 16

    /// Spacing between card content elements: 12pt
    static let cardSpacing: CGFloat = 12

    /// Card corner radius: 16pt
    static let cardCornerRadius: CGFloat = 16

    // MARK: Metric Card Layout

    /// Metric card internal padding: 12pt
    static let metricCardPadding: CGFloat = 12

    /// Metric card minimum height: 100pt
    static let metricCardMinHeight: CGFloat = 100

    /// Metric card internal spacing: 4pt
    static let metricCardSpacing: CGFloat = 4

    // MARK: List Layout

    /// List item internal padding: 16pt
    static let listItemPadding: CGFloat = 16

    /// Spacing between list items: 8pt
    static let listItemSpacing: CGFloat = 8

    /// Spacing between list sections: 24pt
    static let listSectionSpacing: CGFloat = 24

    // MARK: Button Layout

    /// Button internal padding: 16pt
    static let buttonPadding: CGFloat = 16

    /// Button minimum height: 50pt
    static let buttonMinHeight: CGFloat = 50

    /// Button corner radius: 12pt
    static let buttonCornerRadius: CGFloat = 12

    /// Button radius (alias for buttonCornerRadius)
    static let buttonRadius: CGFloat = 12

    /// Button icon size: 20pt
    static let buttonIconSize: CGFloat = 20

    // MARK: Tab Bar Layout

    /// Tab bar total height (including safe area): 84pt
    static let tabBarHeight: CGFloat = 84

    /// Tab bar icon size: 24pt
    static let tabBarIconSize: CGFloat = 24

    // MARK: Navigation Bar Layout

    /// Navigation bar height: 44pt
    static let navBarHeight: CGFloat = 44

    /// Navigation bar horizontal padding: 16pt
    static let navBarPadding: CGFloat = 16

    // MARK: Touch Targets

    /// Minimum touch target size: 44pt (Apple HIG)
    static let minTouchTarget: CGFloat = 44
}

// MARK: - Grid System

/// Grid configurations for LazyVGrid layouts
enum BTGrid {
    /// 2-column grid for metric cards
    static let columns2 = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    /// 3-column grid for compact metrics
    static let columns3 = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    /// 4-column grid for dense layouts
    static let columns4 = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    /// Adaptive grid - minimum 160pt per item
    static let adaptive = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    /// Adaptive grid - minimum 120pt per item (compact)
    static let adaptiveCompact = [
        GridItem(.adaptive(minimum: 120), spacing: 8)
    ]

    /// Single column for full-width items
    static let single = [
        GridItem(.flexible())
    ]
}

// MARK: - Spacing View Modifiers

extension View {
    /// Apply standard screen padding
    func btScreenPadding() -> some View {
        self.padding(.horizontal, BTLayout.screenHorizontalPadding)
            .padding(.vertical, BTLayout.screenVerticalPadding)
    }

    /// Apply standard card padding
    func btCardPadding() -> some View {
        self.padding(BTLayout.cardPadding)
    }

    /// Apply metric card padding
    func btMetricCardPadding() -> some View {
        self.padding(BTLayout.metricCardPadding)
    }

    /// Apply standard card background with corner radius
    func btCardBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: BTLayout.cardCornerRadius)
                .fill(Color.btSurface)
        )
    }

    /// Apply surface background with custom corner radius
    func btSurfaceBackground(cornerRadius: CGFloat = 12) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.btSurface)
        )
    }

    /// Apply elevated surface background
    func btElevatedBackground(cornerRadius: CGFloat = 12) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.btSurfaceElevated)
        )
    }
}
