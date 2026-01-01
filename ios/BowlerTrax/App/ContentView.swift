//
//  ContentView.swift
//  BowlerTrax
//
//  Created by BowlerTrax Team
//

import SwiftUI
import SwiftData

// MARK: - Tab Enum

enum BTTab: String, CaseIterable, Identifiable {
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
        case .record: return "record.circle"
        case .sessions: return "list.bullet.rectangle.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var selectedIcon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .record: return "record.circle.fill"
        case .sessions: return "list.bullet.rectangle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    // MARK: - State

    @State private var selectedTab: BTTab = .dashboard
    @State private var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    // MARK: - Body

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabView
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }

    // MARK: - Main Tab View

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label(BTTab.dashboard.title, systemImage: BTTab.dashboard.icon)
            }
            .tag(BTTab.dashboard)

            NavigationStack {
                RecordTabView()
            }
            .tabItem {
                Label(BTTab.record.title, systemImage: BTTab.record.icon)
            }
            .tag(BTTab.record)

            NavigationStack {
                SessionListView()
            }
            .tabItem {
                Label(BTTab.sessions.title, systemImage: BTTab.sessions.icon)
            }
            .tag(BTTab.sessions)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(BTTab.settings.title, systemImage: BTTab.settings.icon)
            }
            .tag(BTTab.settings)
        }
        .tint(.btPrimary)
        .modifier(TabBarOnlyModifier())
    }
}

// MARK: - Tab Bar Only Modifier

/// Forces bottom tab bar only on iPad (no top segmented control or sidebar)
struct TabBarOnlyModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.tabViewStyle(.tabBarOnly)
        } else {
            // iOS 17 fallback: force compact horizontal size class to get iPhone-style bottom tab bar
            content.environment(\.horizontalSizeClass, .compact)
        }
    }
}

// MARK: - Record Tab View

/// Wrapper view for the Record tab that manages calibration selection before starting a recording session.
struct RecordTabView: View {
    @Query(sort: \CalibrationEntity.lastUsed, order: .reverse) private var calibrations: [CalibrationEntity]
    @AppStorage("lastCalibrationId") private var lastCalibrationIdString: String = ""

    @State private var selectedCalibration: CalibrationEntity?
    @State private var showingCalibrationPicker = false
    @State private var showingCalibrationCreate = false

    var body: some View {
        Group {
            if let calibration = selectedCalibration {
                // Calibration selected - show RecordingView
                RecordingView(calibration: calibration)
            } else if calibrations.isEmpty {
                // No calibrations exist - show prompt to create one
                noCalibrationView
            } else {
                // Calibrations exist but none selected - show prompt to select
                selectCalibrationView
            }
        }
        .onAppear {
            loadLastCalibration()
        }
        .onChange(of: calibrations) { _, _ in
            loadLastCalibration()
        }
        .sheet(isPresented: $showingCalibrationPicker) {
            CalibrationPickerView(selectedCalibration: $selectedCalibration)
                .onChange(of: selectedCalibration) { _, newValue in
                    if let calibration = newValue {
                        saveLastCalibration(calibration)
                    }
                }
        }
        .sheet(isPresented: $showingCalibrationCreate) {
            NavigationStack {
                CalibrationView()
            }
        }
    }

    private var noCalibrationView: some View {
        VStack(spacing: BTSpacing.xl) {
            Spacer()

            Image(systemName: "scope")
                .font(.system(size: 64))
                .foregroundColor(.btTextMuted)

            VStack(spacing: BTSpacing.sm) {
                Text("Calibration Required")
                    .font(BTFont.h2())
                    .foregroundColor(.btTextPrimary)

                Text("Create a lane calibration to start tracking your shots.")
                    .font(BTFont.body())
                    .foregroundColor(.btTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BTSpacing.xl)
            }

            BTActionButton.primary(title: "Create Calibration", icon: "scope") {
                showingCalibrationCreate = true
            }
            .frame(width: 220)

            Spacer()
        }
        .background(Color.btBackground)
    }

    private var selectCalibrationView: some View {
        VStack(spacing: BTSpacing.xl) {
            Spacer()

            Image(systemName: "scope")
                .font(.system(size: 64))
                .foregroundColor(.btPrimary)

            VStack(spacing: BTSpacing.sm) {
                Text("Select Calibration")
                    .font(BTFont.h2())
                    .foregroundColor(.btTextPrimary)

                Text("Choose a lane calibration to start recording.")
                    .font(BTFont.body())
                    .foregroundColor(.btTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BTSpacing.xl)
            }

            BTActionButton.primary(title: "Select Calibration", icon: "list.bullet") {
                showingCalibrationPicker = true
            }
            .frame(width: 220)

            Spacer()
        }
        .background(Color.btBackground)
    }

    private func loadLastCalibration() {
        guard selectedCalibration == nil else { return }

        if !lastCalibrationIdString.isEmpty,
           let uuid = UUID(uuidString: lastCalibrationIdString),
           let calibration = calibrations.first(where: { $0.id == uuid }) {
            selectedCalibration = calibration
        } else if let firstCalibration = calibrations.first {
            selectedCalibration = firstCalibration
            saveLastCalibration(firstCalibration)
        }
    }

    private func saveLastCalibration(_ calibration: CalibrationEntity) {
        lastCalibrationIdString = calibration.id.uuidString
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        ZStack {
            Color.btBackground.ignoresSafeArea()

            VStack(spacing: BTSpacing.xl) {
                Spacer()

                Image(systemName: "figure.bowling")
                    .font(.system(size: 100))
                    .foregroundColor(.btPrimary)

                Text("Welcome to BowlerTrax")
                    .font(BTFont.largeTitle())
                    .foregroundColor(.btTextPrimary)

                Text("Track your shots, improve your game")
                    .font(BTFont.body())
                    .foregroundColor(.btTextSecondary)

                Spacer()

                Button {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("Get Started")
                        .font(BTFont.buttonLabel())
                        .foregroundColor(.btBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BTSpacing.md)
                        .background(Color.btPrimary)
                        .cornerRadius(BTLayout.buttonRadius)
                }
                .padding(.horizontal, BTSpacing.xl)
                .padding(.bottom, BTSpacing.xxl)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
