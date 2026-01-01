//
//  SessionDetailView.swift
//  BowlerTrax
//
//  Detailed session view showing stats summary, shot list with filtering.
//

import SwiftUI
import SwiftData

// MARK: - Session Detail Tab

enum SessionDetailTab: String, CaseIterable {
    case overview = "Overview"
    case visualizer = "Visualizer"

    var icon: String {
        switch self {
        case .overview: return "chart.bar.xaxis"
        case .visualizer: return "map"
        }
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    // MARK: - Properties

    let sessionId: UUID

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [SessionEntity]
    @Query private var calibrations: [CalibrationEntity]

    // MARK: - State

    @State private var selectedTab: SessionDetailTab = .overview
    @State private var selectedShotFilter: ShotFilterOption = .all
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false

    // MARK: - Computed Properties

    private var session: SessionEntity? {
        sessions.first { $0.id == sessionId }
    }

    private var sessionShots: [ShotEntity] {
        session?.shots?.sorted { $0.shotNumber < $1.shotNumber } ?? []
    }

    private var filteredShots: [ShotEntity] {
        switch selectedShotFilter {
        case .all:
            return sessionShots
        case .strikes:
            return sessionShots.filter { $0.isStrike }
        case .misses:
            return sessionShots.filter { !$0.isStrike }
        }
    }

    // Session stats computed from actual shots
    private var avgSpeed: Double {
        let speeds = sessionShots.compactMap { $0.launchSpeed ?? $0.impactSpeed }
        guard !speeds.isEmpty else { return 0 }
        return speeds.reduce(0, +) / Double(speeds.count)
    }

    private var avgRevRate: Double {
        let revRates = sessionShots.compactMap { $0.revRate }
        guard !revRates.isEmpty else { return 0 }
        return revRates.reduce(0, +) / Double(revRates.count)
    }

    private var avgEntryAngle: Double {
        let angles = sessionShots.compactMap { $0.entryAngle }
        guard !angles.isEmpty else { return 0 }
        return angles.reduce(0, +) / Double(angles.count)
    }

    private var avgArrowBoard: Double {
        let boards = sessionShots.compactMap { $0.arrowBoard }
        guard !boards.isEmpty else { return 0 }
        return boards.reduce(0, +) / Double(boards.count)
    }

    private var strikeRate: Double {
        let firstBallShots = sessionShots.filter { $0.isFirstBall }
        guard !firstBallShots.isEmpty else { return 0 }
        let strikes = firstBallShots.filter { $0.isStrike }.count
        return (Double(strikes) / Double(firstBallShots.count)) * 100
    }

    private var sessionDuration: String {
        guard let session = session else { return "--" }
        let end = session.endTime ?? Date()
        let duration = end.timeIntervalSince(session.startTime)
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            return "\(hours)h \(remainingMins)m"
        }
    }

    /// Get calibration for this session if available
    private var sessionCalibration: CalibrationEntity? {
        guard let calibrationId = session?.calibrationId else { return nil }
        return calibrations.first { $0.id == calibrationId }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let session = session {
                sessionContent(session)
            } else {
                sessionNotFoundView
            }
        }
        .background(Color.btBackground)
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.btTextPrimary)
                }
            }
        }
        .alert("Delete Session", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSession()
            }
        } message: {
            Text("Are you sure you want to delete this session? This action cannot be undone.")
        }
    }

    // MARK: - Session Content

    private func sessionContent(_ session: SessionEntity) -> some View {
        VStack(spacing: 0) {
            // Tab picker
            tabPicker
                .padding(.horizontal, BTLayout.screenHorizontalPadding)
                .padding(.top, BTSpacing.sm)
                .padding(.bottom, BTSpacing.md)

            // Tab content
            switch selectedTab {
            case .overview:
                overviewContent(session)
            case .visualizer:
                visualizerContent(session)
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: BTSpacing.xs) {
            ForEach(SessionDetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: BTSpacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                        Text(tab.rawValue)
                            .font(BTFont.label())
                    }
                    .foregroundColor(selectedTab == tab ? .btTextInverse : .btTextSecondary)
                    .padding(.horizontal, BTSpacing.lg)
                    .padding(.vertical, BTSpacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedTab == tab ? Color.btPrimary : Color.btSurfaceElevated)
                    )
                }
            }
        }
    }

    // MARK: - Overview Content

    private func overviewContent(_ session: SessionEntity) -> some View {
        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // Session header
                sessionHeader(session)

                // Stats summary row
                statsSummary

                // Shots section with filter
                shotsSection
            }
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
            .padding(.vertical, BTSpacing.lg)
        }
    }

    // MARK: - Visualizer Content

    private func visualizerContent(_ session: SessionEntity) -> some View {
        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // Session header (compact)
                sessionHeaderCompact(session)

                // Lane visualizer
                if sessionShots.isEmpty {
                    emptyVisualizerState
                } else {
                    SessionLaneVisualizer(
                        session: session,
                        shots: sessionShots,
                        calibration: sessionCalibration
                    )
                }
            }
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
            .padding(.vertical, BTSpacing.lg)
        }
    }

    // MARK: - Empty Visualizer State

    private var emptyVisualizerState: some View {
        VStack(spacing: BTSpacing.lg) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(.btTextMuted)

            Text("No Shots to Visualize")
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)

            Text("Record some shots to see them on the lane visualizer")
                .font(BTFont.body())
                .foregroundColor(.btTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BTSpacing.xxxl)
        .background(Color.btSurface)
        .cornerRadius(BTLayout.cardCornerRadius)
    }

    // MARK: - Session Header Compact

    private func sessionHeaderCompact(_ session: SessionEntity) -> some View {
        HStack(spacing: BTSpacing.md) {
            VStack(alignment: .leading, spacing: BTSpacing.xxs) {
                Text(session.centerName ?? "Practice Session")
                    .font(BTFont.h4())
                    .foregroundColor(.btTextPrimary)

                HStack(spacing: BTSpacing.sm) {
                    if let lane = session.lane {
                        Text("Lane \(lane)")
                    }
                    Text(session.oilPattern)
                }
                .font(BTFont.caption())
                .foregroundColor(.btTextSecondary)
            }

            Spacer()

            // Quick stats
            HStack(spacing: BTSpacing.md) {
                VStack(spacing: 2) {
                    Text("\(sessionShots.count)")
                        .font(BTFont.h4())
                        .foregroundColor(.btTextPrimary)
                        .monospacedDigit()
                    Text("shots")
                        .font(BTFont.captionSmall())
                        .foregroundColor(.btTextMuted)
                }

                if strikeRate > 0 {
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f%%", strikeRate))
                            .font(BTFont.h4())
                            .foregroundColor(.btStrike)
                            .monospacedDigit()
                        Text("strikes")
                            .font(BTFont.captionSmall())
                            .foregroundColor(.btTextMuted)
                    }
                }
            }
        }
        .padding(BTSpacing.md)
        .background(Color.btSurface)
        .cornerRadius(10)
    }

    // MARK: - Session Not Found

    private var sessionNotFoundView: some View {
        VStack(spacing: BTSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.btWarning)

            Text("Session not found")
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)

            Button("Go Back") {
                dismiss()
            }
            .foregroundColor(.btPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Session Header

    private func sessionHeader(_ session: SessionEntity) -> some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            // Center name
            Text(session.centerName ?? "Practice Session")
                .font(BTFont.h2())
                .foregroundColor(.btTextPrimary)

            // Lane and pattern
            HStack(spacing: BTSpacing.md) {
                if let lane = session.lane {
                    Label("Lane \(lane)", systemImage: "number")
                }
                Label(session.oilPattern, systemImage: "drop.fill")
            }
            .font(BTFont.body())
            .foregroundColor(.btTextSecondary)

            // Date and duration
            HStack(spacing: BTSpacing.md) {
                Label(formattedDate(session.startTime), systemImage: "calendar")
                Label(sessionDuration, systemImage: "clock")
            }
            .font(BTFont.caption())
            .foregroundColor(.btTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BTLayout.cardPadding)
        .background(Color.btSurface)
        .cornerRadius(BTLayout.cardCornerRadius)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Stats Summary

    private var statsSummary: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("Session Stats")
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)

            if sessionShots.isEmpty {
                // Empty state for stats
                HStack {
                    Spacer()
                    VStack(spacing: BTSpacing.sm) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 32))
                            .foregroundColor(.btTextMuted)
                        Text("No shot data recorded")
                            .font(BTFont.body())
                            .foregroundColor(.btTextSecondary)
                    }
                    .padding(.vertical, BTSpacing.xl)
                    Spacer()
                }
                .background(Color.btSurface)
                .cornerRadius(BTLayout.cardCornerRadius)
            } else {
                // Primary stats row
                HStack(spacing: BTSpacing.md) {
                    StatSummaryCard(label: "Shots", value: "\(sessionShots.count)", color: .btTextPrimary)
                    StatSummaryCard(label: "Avg Speed", value: avgSpeed > 0 ? String(format: "%.1f", avgSpeed) : "--", unit: "mph", color: .btSpeed)
                    StatSummaryCard(label: "Avg Rev", value: avgRevRate > 0 ? String(format: "%.0f", avgRevRate) : "--", unit: "rpm", color: .btRevRate)
                    StatSummaryCard(label: "Strike %", value: strikeRate > 0 ? String(format: "%.0f", strikeRate) : "--", unit: "%", color: .btStrike)
                }

                // Secondary stats row
                HStack(spacing: BTSpacing.md) {
                    StatSummaryCard(label: "Avg Angle", value: avgEntryAngle > 0 ? String(format: "%.1f", avgEntryAngle) : "--", unit: "deg", color: .btAngle)
                    StatSummaryCard(label: "Avg Board", value: avgArrowBoard > 0 ? String(format: "%.1f", avgArrowBoard) : "--", unit: "bd", color: .btBoard)
                }
            }
        }
    }

    // MARK: - Shots Section

    private var shotsSection: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            // Header with filter
            HStack {
                Text("Shots")
                    .font(BTFont.h3())
                    .foregroundColor(.btTextPrimary)

                Spacer()

                if !sessionShots.isEmpty {
                    // Filter pills
                    shotFilterPicker
                }
            }

            // Shot list
            if filteredShots.isEmpty {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: BTSpacing.sm) {
                        Image(systemName: "figure.bowling")
                            .font(.system(size: 32))
                            .foregroundColor(.btTextMuted)
                        Text(sessionShots.isEmpty ? "No shots recorded yet" : "No shots match filter")
                            .font(BTFont.body())
                            .foregroundColor(.btTextSecondary)
                    }
                    .padding(.vertical, BTSpacing.xl)
                    Spacer()
                }
                .background(Color.btSurface)
                .cornerRadius(BTLayout.cardCornerRadius)
            } else {
                LazyVStack(spacing: BTSpacing.sm) {
                    ForEach(filteredShots, id: \.id) { shot in
                        NavigationLink(destination: ShotDetailView(shotId: shot.id)) {
                            ShotRowView(shot: shot)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Shot Filter Picker

    private var shotFilterPicker: some View {
        HStack(spacing: BTSpacing.xs) {
            ForEach(ShotFilterOption.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedShotFilter = option
                    }
                } label: {
                    Text(option.displayName)
                        .font(BTFont.labelSmall())
                        .foregroundColor(selectedShotFilter == option ? .btTextInverse : .btTextSecondary)
                        .padding(.horizontal, BTSpacing.md)
                        .padding(.vertical, BTSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedShotFilter == option ? Color.btPrimary : Color.btSurfaceElevated)
                        )
                }
            }
        }
    }

    // MARK: - Actions

    private func deleteSession() {
        if let session = session {
            modelContext.delete(session)
            try? modelContext.save()
        }
        dismiss()
    }
}

// MARK: - Stat Summary Card

struct StatSummaryCard: View {
    let label: String
    let value: String
    var unit: String = ""
    let color: Color

    var body: some View {
        VStack(spacing: BTSpacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(BTFont.h4())
                    .foregroundColor(.btTextPrimary)
                    .monospacedDigit()

                if !unit.isEmpty {
                    Text(unit)
                        .font(BTFont.captionSmall())
                        .foregroundColor(color)
                }
            }

            Text(label)
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(BTSpacing.md)
        .background(Color.btSurface)
        .cornerRadius(10)
    }
}

// MARK: - Shot Row View

struct ShotRowView: View {
    let shot: ShotEntity

    private var shotResult: ShotResult {
        if let resultString = shot.result,
           let result = ShotResult(rawValue: resultString) {
            return result
        }
        return .open
    }

    var body: some View {
        HStack(spacing: BTSpacing.md) {
            // Result badge
            ResultBadge(result: shotResult)

            // Shot number
            Text("#\(shot.shotNumber)")
                .font(BTFont.monoLarge())
                .foregroundColor(.btTextPrimary)
                .frame(width: 44, alignment: .leading)

            // Result text
            Text(shotResult.displayName)
                .font(BTFont.body())
                .foregroundColor(.btTextSecondary)
                .frame(maxWidth: 80, alignment: .leading)

            Spacer()

            // Key metrics
            HStack(spacing: BTSpacing.lg) {
                if let speed = shot.launchSpeed ?? shot.impactSpeed {
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", speed))
                            .font(BTFont.label())
                            .foregroundColor(.btTextPrimary)
                            .monospacedDigit()
                        Text("mph")
                            .font(BTFont.captionSmall())
                            .foregroundColor(.btSpeed)
                    }
                }

                if let angle = shot.entryAngle {
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", angle))
                            .font(BTFont.label())
                            .foregroundColor(.btTextPrimary)
                            .monospacedDigit()
                        Text("deg")
                            .font(BTFont.captionSmall())
                            .foregroundColor(.btAngle)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.btTextMuted)
        }
        .padding(.horizontal, BTLayout.listItemPadding)
        .padding(.vertical, BTSpacing.md)
        .background(Color.btSurface)
        .cornerRadius(10)
    }
}

// MARK: - Shot Filter Option

enum ShotFilterOption: CaseIterable {
    case all
    case strikes
    case misses

    var displayName: String {
        switch self {
        case .all: return "All"
        case .strikes: return "X"
        case .misses: return "Miss"
        }
    }
}

// MARK: - Shot Detail View

struct ShotDetailView: View {
    let shotId: UUID

    @Query private var shots: [ShotEntity]

    private var shot: ShotEntity? {
        shots.first { $0.id == shotId }
    }

    var body: some View {
        Group {
            if let shot = shot {
                shotDetailContent(shot)
            } else {
                Text("Shot not found")
                    .font(BTFont.h3())
                    .foregroundColor(.btTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.btBackground)
        .navigationTitle("Shot #\(shot?.shotNumber ?? 0)")
    }

    private func shotDetailContent(_ shot: ShotEntity) -> some View {
        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // Shot result badge
                if let resultString = shot.result,
                   let result = ShotResult(rawValue: resultString) {
                    VStack(spacing: BTSpacing.sm) {
                        ResultBadge(result: result, size: .large)
                        Text(result.displayName)
                            .font(BTFont.h2())
                            .foregroundColor(.btTextPrimary)
                    }
                    .padding(.vertical, BTSpacing.lg)
                }

                // Metrics grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BTSpacing.md) {
                    if let speed = shot.launchSpeed {
                        MetricCard.speed(value: speed, previousValue: nil)
                    }
                    if let revRate = shot.revRate {
                        MetricCard.revRate(value: revRate, previousValue: nil)
                    }
                    if let angle = shot.entryAngle {
                        MetricCard.entryAngle(value: angle, previousValue: nil)
                    }
                    if let board = shot.arrowBoard {
                        MetricCard(
                            title: "Arrow Board",
                            value: String(format: "%.1f", board),
                            unit: "bd",
                            previousValue: nil,
                            accentColor: .btBoard
                        )
                    }
                    if let strikeProbability = shot.strikeProbability {
                        MetricCard.strikeRate(value: strikeProbability * 100, previousValue: nil)
                    }
                }
                .padding(.horizontal, BTLayout.screenHorizontalPadding)
            }
            .padding(.vertical, BTSpacing.lg)
        }
    }
}

// MARK: - Result Badge Size

extension ResultBadge {
    enum BadgeSize {
        case small
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return 24
            case .large: return 48
            }
        }
    }

    init(result: ShotResult, size: BadgeSize) {
        self.init(result: result)
        // Note: Would need to modify ResultBadge to support sizes
    }
}

// MARK: - Preview

#Preview("Session Detail") {
    NavigationStack {
        SessionDetailView(sessionId: UUID())
    }
    .modelContainer(for: [SessionEntity.self, ShotEntity.self, CalibrationEntity.self], inMemory: true)
}
