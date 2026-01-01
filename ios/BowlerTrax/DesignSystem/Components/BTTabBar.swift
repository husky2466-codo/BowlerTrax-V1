//
//  BTTabBar.swift
//  BowlerTrax
//
//  Custom tab bar with bowling-themed navigation.
//  Supports dashboard, record, sessions, and settings tabs.
//

import SwiftUI

// MARK: - Tab Enum

enum Tab: String, CaseIterable, Identifiable {
    case dashboard
    case record
    case sessions
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .record: return "Record"
        case .sessions: return "Sessions"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .record: return "video.fill"
        case .sessions: return "list.bullet.rectangle.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var iconOutline: String {
        switch self {
        case .dashboard: return "chart.bar"
        case .record: return "video"
        case .sessions: return "list.bullet.rectangle"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Tab Bar Component

struct BTTabBar: View {
    // MARK: - Properties

    @Binding var selectedTab: Tab

    // MARK: - Body

    var body: some View {
        HStack {
            ForEach(Tab.allCases) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(BTAnimation.tabSwitch) {
                        selectedTab = tab
                    }

                    // Haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.top, BTSpacing.md)
        .padding(.bottom, BTSpacing.xxl) // Safe area for home indicator
        .background(tabBarBackground)
    }

    // MARK: - Subviews

    private var tabBarBackground: some View {
        Color.btSurface
            .shadow(color: .black.opacity(0.3), radius: 8, y: -4)
            .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    // MARK: - Properties

    let tab: Tab
    let isSelected: Bool
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            VStack(spacing: BTSpacing.xs) {
                Image(systemName: isSelected ? tab.icon : tab.iconOutline)
                    .font(.system(size: BTLayout.tabBarIconSize, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .btPrimary : .btTextMuted)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(tab.title)
                    .font(BTFont.captionSmall())
                    .foregroundColor(isSelected ? .btPrimary : .btTextMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .animation(BTAnimation.tabSwitch, value: isSelected)
    }
}

// MARK: - Tab Bar Container

/// A container view that manages tab navigation
struct BTTabBarContainer<Content: View>: View {
    @Binding var selectedTab: Tab
    let content: (Tab) -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            content(selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, BTLayout.tabBarHeight)

            // Tab bar
            BTTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Preview

#Preview("Tab Bar") {
    struct TabBarPreview: View {
        @State private var selectedTab: Tab = .dashboard

        var body: some View {
            BTTabBarContainer(selectedTab: $selectedTab) { tab in
                VStack {
                    Spacer()

                    Text("Selected: \(tab.title)")
                        .btHeading2()

                    Text("Tap tabs below to switch")
                        .btBody()

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color.btBackground)
        }
    }

    return TabBarPreview()
}

#Preview("Tab Bar Items") {
    VStack(spacing: BTSpacing.xxl) {
        // Selected state
        HStack {
            ForEach(Tab.allCases) { tab in
                VStack(spacing: BTSpacing.xs) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.btPrimary)

                    Text(tab.title)
                        .font(BTFont.captionSmall())
                        .foregroundColor(.btPrimary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.btSurface)

        // Unselected state
        HStack {
            ForEach(Tab.allCases) { tab in
                VStack(spacing: BTSpacing.xs) {
                    Image(systemName: tab.iconOutline)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.btTextMuted)

                    Text(tab.title)
                        .font(BTFont.captionSmall())
                        .foregroundColor(.btTextMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.btSurface)
    }
    .padding()
    .background(Color.btBackground)
}
