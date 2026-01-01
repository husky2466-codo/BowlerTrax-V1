//
//  BTNavigationBar.swift
//  BowlerTrax
//
//  Custom navigation bar with consistent styling.
//  Supports leading and trailing action buttons.
//

import SwiftUI

// MARK: - Navigation Bar Component

struct BTNavigationBar: View {
    // MARK: - Properties

    let title: String
    var leadingAction: (() -> Void)? = nil
    var leadingIcon: String? = nil
    var trailingAction: (() -> Void)? = nil
    var trailingIcon: String? = nil
    var subtitle: String? = nil

    // MARK: - Body

    var body: some View {
        HStack {
            // Leading button
            leadingButton

            Spacer()

            // Title (and optional subtitle)
            titleView

            Spacer()

            // Trailing button
            trailingButton
        }
        .frame(height: BTLayout.navBarHeight)
        .padding(.horizontal, BTSpacing.sm)
        .background(Color.btBackground)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var leadingButton: some View {
        if let action = leadingAction, let icon = leadingIcon {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.btTextPrimary)
                    .frame(width: 44, height: 44)
            }
        } else {
            Spacer().frame(width: 44)
        }
    }

    @ViewBuilder
    private var titleView: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(BTFont.caption())
                    .foregroundColor(.btTextMuted)
            }
        }
    }

    @ViewBuilder
    private var trailingButton: some View {
        if let action = trailingAction, let icon = trailingIcon {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.btTextPrimary)
                    .frame(width: 44, height: 44)
            }
        } else {
            Spacer().frame(width: 44)
        }
    }
}

// MARK: - Convenience Initializers

extension BTNavigationBar {
    /// Navigation bar with back button
    static func withBack(title: String, onBack: @escaping () -> Void) -> BTNavigationBar {
        BTNavigationBar(
            title: title,
            leadingAction: onBack,
            leadingIcon: "chevron.left"
        )
    }

    /// Navigation bar with close button
    static func withClose(title: String, onClose: @escaping () -> Void) -> BTNavigationBar {
        BTNavigationBar(
            title: title,
            trailingAction: onClose,
            trailingIcon: "xmark"
        )
    }

    /// Navigation bar with settings button
    static func withSettings(title: String, onSettings: @escaping () -> Void) -> BTNavigationBar {
        BTNavigationBar(
            title: title,
            trailingAction: onSettings,
            trailingIcon: "gearshape"
        )
    }

    /// Navigation bar with both back and action
    static func withBackAndAction(
        title: String,
        onBack: @escaping () -> Void,
        actionIcon: String,
        onAction: @escaping () -> Void
    ) -> BTNavigationBar {
        BTNavigationBar(
            title: title,
            leadingAction: onBack,
            leadingIcon: "chevron.left",
            trailingAction: onAction,
            trailingIcon: actionIcon
        )
    }
}

// MARK: - Large Title Navigation Bar

struct BTNavigationBarLarge: View {
    let title: String
    var subtitle: String? = nil
    var trailingAction: (() -> Void)? = nil
    var trailingIcon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            HStack {
                Spacer()

                if let action = trailingAction, let icon = trailingIcon {
                    Button(action: action) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.btTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                }
            }

            Text(title)
                .font(BTFont.h1())
                .foregroundColor(.btTextPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(BTFont.body())
                    .foregroundColor(.btTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BTLayout.screenHorizontalPadding)
        .padding(.bottom, BTSpacing.md)
        .background(Color.btBackground)
    }
}

// MARK: - Preview

#Preview("Navigation Bars") {
    VStack(spacing: 0) {
        // Standard navigation bar
        BTNavigationBar(title: "Dashboard")

        Divider().background(Color.btSurfaceHighlight)

        // With back button
        BTNavigationBar.withBack(title: "Session Detail") {}

        Divider().background(Color.btSurfaceHighlight)

        // With close button
        BTNavigationBar.withClose(title: "Settings") {}

        Divider().background(Color.btSurfaceHighlight)

        // With settings
        BTNavigationBar.withSettings(title: "Profile") {}

        Divider().background(Color.btSurfaceHighlight)

        // With back and action
        BTNavigationBar.withBackAndAction(
            title: "Shot #12",
            onBack: {},
            actionIcon: "square.and.arrow.up",
            onAction: {}
        )

        Divider().background(Color.btSurfaceHighlight)

        // With subtitle
        BTNavigationBar(
            title: "Recording",
            subtitle: "Shot 5 of 10"
        )

        Divider().background(Color.btSurfaceHighlight)

        // Large title
        BTNavigationBarLarge(
            title: "Dashboard",
            subtitle: "Welcome back, bowler!",
            trailingAction: {},
            trailingIcon: "gearshape"
        )

        Spacer()
    }
    .background(Color.btBackground)
}
