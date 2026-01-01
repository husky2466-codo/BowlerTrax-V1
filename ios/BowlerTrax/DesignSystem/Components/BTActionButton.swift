//
//  BTActionButton.swift
//  BowlerTrax
//
//  Primary action buttons for major actions.
//  Supports primary, secondary, destructive, and ghost variants.
//

import SwiftUI

// MARK: - Button Variants

enum BTButtonVariant {
    case primary     // Filled with primary color (teal)
    case secondary   // Outlined with primary color border
    case destructive // Red for dangerous actions
    case ghost       // Text only, no background

    var backgroundColor: Color {
        switch self {
        case .primary: return .btPrimary
        case .secondary: return .clear
        case .destructive: return .btError
        case .ghost: return .clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary: return .btTextInverse
        case .secondary: return .btPrimary
        case .destructive: return .white
        case .ghost: return .btPrimary
        }
    }

    var borderColor: Color {
        switch self {
        case .secondary: return .btPrimary
        default: return .clear
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .secondary: return 1.5
        default: return 0
        }
    }
}

// MARK: - Button Style

struct BTButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Action Button Component

struct BTActionButton: View {
    // MARK: - Properties

    let title: String
    var icon: String? = nil
    var variant: BTButtonVariant = .primary
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: {
            if !isLoading {
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                action()
            }
        }) {
            buttonContent
        }
        .buttonStyle(BTButtonStyle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
    }

    // MARK: - Subviews

    private var buttonContent: some View {
        HStack(spacing: BTSpacing.sm) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: variant.foregroundColor))
                    .scaleEffect(0.8)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: BTLayout.buttonIconSize, weight: .semibold))
            }

            Text(title)
                .font(BTFont.label())
                .fontWeight(.semibold)
        }
        .foregroundColor(variant.foregroundColor)
        .frame(maxWidth: isFullWidth ? .infinity : nil)
        .frame(height: BTLayout.buttonMinHeight)
        .padding(.horizontal, BTLayout.buttonPadding)
        .background(variant.backgroundColor)
        .cornerRadius(BTLayout.buttonCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: BTLayout.buttonCornerRadius)
                .stroke(variant.borderColor, lineWidth: variant.borderWidth)
        )
    }
}

// MARK: - Convenience Initializers

extension BTActionButton {
    /// Create a primary button with icon
    static func primary(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> BTActionButton {
        BTActionButton(
            title: title,
            icon: icon,
            variant: .primary,
            isLoading: isLoading,
            action: action
        )
    }

    /// Create a secondary button with icon
    static func secondary(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> BTActionButton {
        BTActionButton(
            title: title,
            icon: icon,
            variant: .secondary,
            isLoading: isLoading,
            action: action
        )
    }

    /// Create a destructive button
    static func destructive(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> BTActionButton {
        BTActionButton(
            title: title,
            icon: icon,
            variant: .destructive,
            isLoading: isLoading,
            action: action
        )
    }

    /// Create a ghost button
    static func ghost(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> BTActionButton {
        BTActionButton(
            title: title,
            icon: icon,
            variant: .ghost,
            isFullWidth: false,
            action: action
        )
    }
}

// MARK: - Icon-Only Button

struct BTIconButton: View {
    let icon: String
    var variant: BTButtonVariant = .ghost
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(variant == .ghost ? .btTextPrimary : variant.foregroundColor)
                .frame(width: size, height: size)
                .background(variant == .ghost ? Color.clear : variant.backgroundColor)
                .cornerRadius(size / 2)
        }
        .buttonStyle(BTButtonStyle())
    }
}

// MARK: - Preview

#Preview("Action Buttons") {
    ScrollView {
        VStack(spacing: BTSpacing.xl) {
            // Primary buttons
            VStack(spacing: BTSpacing.md) {
                Text("Primary")
                    .btHeading3()
                    .frame(maxWidth: .infinity, alignment: .leading)

                BTActionButton.primary(title: "New Session", icon: "plus.circle.fill") {}
                BTActionButton.primary(title: "Start Recording", icon: "record.circle") {}
                BTActionButton(title: "Loading...", variant: .primary, isLoading: true) {}
            }

            // Secondary buttons
            VStack(spacing: BTSpacing.md) {
                Text("Secondary")
                    .btHeading3()
                    .frame(maxWidth: .infinity, alignment: .leading)

                BTActionButton.secondary(title: "Calibrate", icon: "scope") {}
                BTActionButton.secondary(title: "Export Data", icon: "square.and.arrow.up") {}
            }

            // Destructive buttons
            VStack(spacing: BTSpacing.md) {
                Text("Destructive")
                    .btHeading3()
                    .frame(maxWidth: .infinity, alignment: .leading)

                BTActionButton.destructive(title: "Delete Session", icon: "trash") {}
                BTActionButton.destructive(title: "Reset Calibration") {}
            }

            // Ghost buttons
            VStack(spacing: BTSpacing.md) {
                Text("Ghost")
                    .btHeading3()
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    BTActionButton.ghost(title: "Cancel") {}
                    BTActionButton.ghost(title: "Skip", icon: "chevron.right") {}
                }
            }

            // Icon buttons
            VStack(spacing: BTSpacing.md) {
                Text("Icon Buttons")
                    .btHeading3()
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: BTSpacing.lg) {
                    BTIconButton(icon: "chevron.left") {}
                    BTIconButton(icon: "gearshape") {}
                    BTIconButton(icon: "info.circle") {}
                    BTIconButton(icon: "xmark") {}
                }
            }
        }
        .padding(BTLayout.screenHorizontalPadding)
    }
    .background(Color.btBackground)
}
