//
//  DashboardView.swift
//  BowlerTrax
//
//  Main dashboard screen showing welcome message, quick actions,
//  stats overview, and recent sessions.
//

import SwiftUI
import SwiftData

// MARK: - Dashboard View

struct DashboardView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionEntity.startTime, order: .reverse) private var sessions: [SessionEntity]
    @Query(sort: \CalibrationEntity.createdAt, order: .reverse) private var calibrations: [CalibrationEntity]
    @Query private var allShots: [ShotEntity]

    // MARK: - App Storage

    @AppStorage("lastCalibrationId") private var lastCalibrationIdString: String = ""

    // MARK: - State

    @State private var selectedSession: UUID?
    @State private var selectedCalibration: CalibrationEntity?
    @State private var showingCalibrationPicker = false
    @State private var showingNoCalibrationAlert = false
    @State private var navigateToRecording = false

    // MARK: - Computed Properties

    private var hasStats: Bool {
        // Only show stats if we have actual shot data with metrics
        !allShots.isEmpty && (avgSpeed > 0 || avgRevRate > 0 || avgEntryAngle > 0 || strikeRate > 0)
    }

    private var hasSessions: Bool {
        !sessions.isEmpty
    }

    private var recentSessions: [SessionEntity] {
        Array(sessions.prefix(3))
    }

    // Stats computed from actual shot data
    private var avgSpeed: Double {
        let speeds = allShots.compactMap { $0.launchSpeed ?? $0.impactSpeed }
        guard !speeds.isEmpty else { return 0 }
        return speeds.reduce(0, +) / Double(speeds.count)
    }

    private var avgRevRate: Double {
        let revRates = allShots.compactMap { $0.revRate }
        guard !revRates.isEmpty else { return 0 }
        return revRates.reduce(0, +) / Double(revRates.count)
    }

    private var avgEntryAngle: Double {
        let angles = allShots.compactMap { $0.entryAngle }
        guard !angles.isEmpty else { return 0 }
        return angles.reduce(0, +) / Double(angles.count)
    }

    private var strikeRate: Double {
        // Only count first ball shots for strike rate
        let firstBallShots = allShots.filter { $0.isFirstBall }
        guard !firstBallShots.isEmpty else { return 0 }
        let strikes = firstBallShots.filter { $0.isStrike }.count
        return (Double(strikes) / Double(firstBallShots.count)) * 100
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // Logo header
                logoHeader

                // Welcome header
                welcomeHeader

                // Quick action buttons
                quickActions

                // Current calibration selection
                calibrationSelectionSection

                // Stats overview (if user has sessions)
                if hasStats {
                    statsOverview
                }

                // Recent sessions
                recentSessionsSection
            }
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
            .padding(.vertical, BTSpacing.lg)
        }
        .background(Color.btBackground)
        .navigationTitle("BowlerTrax")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLastCalibration()
        }
        .onChange(of: calibrations) { _, _ in
            // Reload calibration if list changes (e.g., new calibration created)
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
        .alert("Calibration Required", isPresented: $showingNoCalibrationAlert) {
            Button("Create Calibration") {
                showingCalibrationPicker = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You need to create a lane calibration before starting a recording session.")
        }
        .navigationDestination(isPresented: $navigateToRecording) {
            RecordingView(calibration: selectedCalibration)
        }
    }

    // MARK: - Logo Header

    private var logoHeader: some View {
        VStack(spacing: 0) {
            Image("FullLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200)
                .shadow(color: Color.btPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, BTSpacing.md)
        .padding(.bottom, BTSpacing.sm)
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            Text("Welcome back, Bowler!")
                .font(BTFont.h2())
                .foregroundColor(.btTextPrimary)

            Text("Ready to track your next session?")
                .font(BTFont.body())
                .foregroundColor(.btTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BTLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: BTLayout.cardCornerRadius)
                .fill(Color.btSurface)
        )
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: BTSpacing.md) {
            // New Session button - checks calibration first
            Button {
                handleNewSessionTap()
            } label: {
                QuickActionCard(
                    title: "New Session",
                    subtitle: selectedCalibration != nil
                        ? "Ready to record"
                        : "Select calibration first",
                    icon: "record.circle",
                    accentColor: .btPrimary
                )
            }
            .buttonStyle(.plain)

            // Calibrate button - NavigationLink to CalibrationView
            NavigationLink(destination: CalibrationView()) {
                QuickActionCard(
                    title: "Calibrate",
                    subtitle: "Set up lane reference",
                    icon: "scope",
                    accentColor: .btAccent
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Calibration Selection Section

    private var calibrationSelectionSection: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            HStack {
                Text("Active Calibration")
                    .font(BTFont.h3())
                    .foregroundColor(.btTextPrimary)

                Spacer()

                if !calibrations.isEmpty {
                    Button {
                        showingCalibrationPicker = true
                    } label: {
                        Text("Change")
                            .font(BTFont.label())
                            .foregroundColor(.btPrimary)
                    }
                }
            }

            if let calibration = selectedCalibration {
                // Selected calibration card
                selectedCalibrationCard(calibration)
            } else if calibrations.isEmpty {
                // No calibrations exist - prompt to create
                noCalibrationCard
            } else {
                // Calibrations exist but none selected - prompt to select
                selectCalibrationPromptCard
            }
        }
    }

    private func selectedCalibrationCard(_ calibration: CalibrationEntity) -> some View {
        HStack(spacing: BTSpacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.btPrimary.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: "scope")
                    .font(.system(size: 20))
                    .foregroundColor(.btPrimary)
            }

            // Content
            VStack(alignment: .leading, spacing: BTSpacing.xxs) {
                HStack(spacing: BTSpacing.sm) {
                    Text(calibration.centerName.isEmpty ? "Unnamed" : calibration.centerName)
                        .font(BTFont.h4())
                        .foregroundColor(.btTextPrimary)
                        .lineLimit(1)

                    if let lane = calibration.laneNumber {
                        Text("Lane \(lane)")
                            .font(BTFont.caption())
                            .foregroundColor(.btPrimary)
                            .padding(.horizontal, BTSpacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.btPrimary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                Text("Ready to record")
                    .font(BTFont.caption())
                    .foregroundColor(.btSuccess)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.btSuccess)
        }
        .padding(BTLayout.cardPadding)
        .background(Color.btSurface)
        .cornerRadius(BTLayout.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: BTLayout.cardCornerRadius)
                .stroke(Color.btSuccess.opacity(0.3), lineWidth: 1)
        )
    }

    private var noCalibrationCard: some View {
        Button {
            showingCalibrationPicker = true
        } label: {
            HStack(spacing: BTSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.btWarning.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 20))
                        .foregroundColor(.btWarning)
                }

                // Content
                VStack(alignment: .leading, spacing: BTSpacing.xxs) {
                    Text("No Calibration")
                        .font(BTFont.h4())
                        .foregroundColor(.btTextPrimary)

                    Text("Create one to start tracking shots")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextMuted)
                }

                Spacer()

                Image(systemName: "plus.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.btPrimary)
            }
            .padding(BTLayout.cardPadding)
            .background(Color.btSurface)
            .cornerRadius(BTLayout.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: BTLayout.cardCornerRadius)
                    .stroke(Color.btWarning.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var selectCalibrationPromptCard: some View {
        Button {
            showingCalibrationPicker = true
        } label: {
            HStack(spacing: BTSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.btAccent.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "scope")
                        .font(.system(size: 20))
                        .foregroundColor(.btAccent)
                }

                // Content
                VStack(alignment: .leading, spacing: BTSpacing.xxs) {
                    Text("Select Calibration")
                        .font(BTFont.h4())
                        .foregroundColor(.btTextPrimary)

                    Text("\(calibrations.count) calibration\(calibrations.count == 1 ? "" : "s") available")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.btTextMuted)
            }
            .padding(BTLayout.cardPadding)
            .background(Color.btSurface)
            .cornerRadius(BTLayout.cardCornerRadius)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func handleNewSessionTap() {
        if calibrations.isEmpty {
            // No calibrations exist - show alert to create one
            showingNoCalibrationAlert = true
        } else if selectedCalibration == nil {
            // Calibrations exist but none selected - show picker
            showingCalibrationPicker = true
        } else {
            // Calibration selected - navigate to recording
            navigateToRecording = true
        }
    }

    private func loadLastCalibration() {
        // If already selected, don't override
        guard selectedCalibration == nil else { return }

        // Try to find the last used calibration from UserDefaults
        if !lastCalibrationIdString.isEmpty,
           let uuid = UUID(uuidString: lastCalibrationIdString),
           let calibration = calibrations.first(where: { $0.id == uuid }) {
            selectedCalibration = calibration
        } else if let firstCalibration = calibrations.first {
            // Fall back to most recent calibration
            selectedCalibration = firstCalibration
            saveLastCalibration(firstCalibration)
        }
    }

    private func saveLastCalibration(_ calibration: CalibrationEntity) {
        lastCalibrationIdString = calibration.id.uuidString
    }

    // MARK: - Stats Overview

    private var statsOverview: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("Quick Stats")
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)

            LazyVGrid(columns: BTGrid.columns2, spacing: BTSpacing.md) {
                MetricCard.speed(value: avgSpeed, previousValue: nil)
                MetricCard.revRate(value: avgRevRate, previousValue: nil)
                MetricCard.entryAngle(value: avgEntryAngle, previousValue: nil)
                MetricCard.strikeRate(value: strikeRate, previousValue: nil)
            }
        }
    }

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            HStack {
                Text("Recent Sessions")
                    .font(BTFont.h3())
                    .foregroundColor(.btTextPrimary)

                Spacer()

                NavigationLink(destination: SessionListView()) {
                    Text("View All")
                        .font(BTFont.label())
                        .foregroundColor(.btPrimary)
                }
            }

            if hasSessions {
                recentSessionsList
            } else {
                emptySessionsState
            }
        }
    }

    // MARK: - Recent Sessions List

    private var recentSessionsList: some View {
        VStack(spacing: BTSpacing.sm) {
            ForEach(recentSessions) { session in
                NavigationLink(destination: SessionDetailView(sessionId: session.id)) {
                    SessionCardContent(session: SessionEntityWrapper(entity: session))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty Sessions State

    private var emptySessionsState: some View {
        Button {
            handleNewSessionTap()
        } label: {
            EmptyStateCard(
                icon: "figure.bowling",
                title: "No sessions yet",
                message: "Start your first session to see your stats here",
                action: nil,
                actionTitle: nil
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Session Entity Wrapper for SessionDisplayable

struct SessionEntityWrapper: SessionDisplayable {
    let entity: SessionEntity

    var id: UUID { entity.id }
    var centerName: String? { entity.centerName }
    var shotCount: Int { entity.shotCount }
    var date: Date { entity.startTime }
    var averageSpeed: Double? { nil } // Would calculate from shots
    var strikeRate: Double? { nil } // Would calculate from shots
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: BTSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            // Text
            VStack(spacing: BTSpacing.xxs) {
                Text(title)
                    .font(BTFont.h4())
                    .foregroundColor(.btTextPrimary)

                Text(subtitle)
                    .font(BTFont.caption())
                    .foregroundColor(.btTextMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(BTLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: BTLayout.cardCornerRadius)
                .fill(Color.btSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: BTLayout.cardCornerRadius)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview("Dashboard") {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [SessionEntity.self, ShotEntity.self, CalibrationEntity.self, BallProfileEntity.self, CenterEntity.self], inMemory: true)
}

#Preview("Dashboard - Empty State") {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [SessionEntity.self, ShotEntity.self, CalibrationEntity.self, BallProfileEntity.self, CenterEntity.self], inMemory: true)
}

// MARK: - Calibration Picker View

struct CalibrationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalibrationEntity.lastUsed, order: .reverse) private var calibrations: [CalibrationEntity]
    @Binding var selectedCalibration: CalibrationEntity?

    var body: some View {
        NavigationStack {
            List {
                if calibrations.isEmpty {
                    VStack(spacing: BTSpacing.md) {
                        Image(systemName: "scope")
                            .font(.system(size: 48))
                            .foregroundColor(.btTextMuted)

                        Text("No calibrations yet")
                            .font(BTFont.h4())
                            .foregroundColor(.btTextPrimary)

                        Text("Go to Calibrate from the dashboard to create your first lane calibration.")
                            .font(BTFont.body())
                            .foregroundColor(.btTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BTSpacing.xl)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(calibrations) { calibration in
                        Button {
                            selectedCalibration = calibration
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(calibration.centerName.isEmpty ? "Unnamed" : calibration.centerName)
                                        .font(BTFont.label())
                                        .foregroundColor(.btTextPrimary)

                                    if let lane = calibration.laneNumber {
                                        Text("Lane \(lane)")
                                            .font(BTFont.caption())
                                            .foregroundColor(.btTextSecondary)
                                    }

                                    if let lastUsed = calibration.lastUsed {
                                        Text("Last used: \(lastUsed, style: .relative) ago")
                                            .font(BTFont.captionSmall())
                                            .foregroundColor(.btTextMuted)
                                    } else {
                                        Text("Created: \(calibration.createdAt, style: .relative) ago")
                                            .font(BTFont.captionSmall())
                                            .foregroundColor(.btTextMuted)
                                    }
                                }

                                Spacer()

                                if selectedCalibration?.id == calibration.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.btPrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteCalibrations)
                }
            }
            .navigationTitle("Select Calibration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !calibrations.isEmpty {
                        EditButton()
                            .foregroundColor(.btPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.btPrimary)
                }
            }
        }
    }

    private func deleteCalibrations(at offsets: IndexSet) {
        for index in offsets {
            let calibration = calibrations[index]
            // Clear selection if we're deleting the selected one
            if selectedCalibration?.id == calibration.id {
                selectedCalibration = nil
            }
            modelContext.delete(calibration)
        }
    }
}
