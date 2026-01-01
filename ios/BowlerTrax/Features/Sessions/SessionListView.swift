//
//  SessionListView.swift
//  BowlerTrax
//
//  Browse past sessions with stats summary, search, and filtering.
//

import SwiftUI
import SwiftData

// MARK: - Session List View

struct SessionListView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionEntity.startTime, order: .reverse) private var sessions: [SessionEntity]

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedFilter: SessionFilter = .all
    @State private var selectedSort: SessionSort = .mostRecent
    @State private var showingFilterSheet = false
    @State private var showingSortSheet = false

    // Multi-select state
    @State private var isEditing = false
    @State private var selectedSessionIds: Set<UUID> = []
    @State private var showingDeleteConfirmation = false

    // MARK: - Computed Properties

    private var hasSessions: Bool {
        !sessions.isEmpty
    }

    private var allSelected: Bool {
        !filteredSessions.isEmpty && selectedSessionIds.count == filteredSessions.count
    }

    private var hasSelection: Bool {
        !selectedSessionIds.isEmpty
    }

    private var selectionCount: Int {
        selectedSessionIds.count
    }

    private var filteredSessions: [SessionEntity] {
        var result = sessions

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { session in
                (session.centerName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (session.name?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .strikes:
            // Filter sessions with high strike rate (placeholder logic)
            break
        case .misses:
            // Filter sessions with low strike rate (placeholder logic)
            break
        case .housePattern:
            result = result.filter { $0.oilPattern == OilPatternType.house.rawValue }
        case .sportPattern:
            result = result.filter { $0.oilPattern == OilPatternType.sport.rawValue }
        }

        // Apply sort
        switch selectedSort {
        case .mostRecent:
            result.sort { $0.startTime > $1.startTime }
        case .oldest:
            result.sort { $0.startTime < $1.startTime }
        case .mostShots:
            result.sort { $0.shotCount > $1.shotCount }
        case .highestStrikeRate:
            // Placeholder - would need actual strike rate calculation
            break
        case .fastestSpeed:
            // Placeholder - would need actual speed calculation
            break
        }

        return result
    }

    private var groupedSessions: [(String, [SessionEntity])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: filteredSessions) { session in
            formatter.string(from: session.startTime)
        }

        // Sort groups by date (most recent first)
        return grouped.sorted { first, second in
            guard let firstSession = first.value.first,
                  let secondSession = second.value.first else {
                return false
            }
            return firstSession.startTime > secondSession.startTime
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if hasSessions {
                sessionsListContent
            } else {
                emptyStateContent
            }
        }
        .background(Color.btBackground)
        .navigationTitle(isEditing ? "\(selectionCount) Selected" : "Sessions")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if hasSessions {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing.toggle()
                            if !isEditing {
                                selectedSessionIds.removeAll()
                            }
                        }
                    }
                    .foregroundColor(.btPrimary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    // Delete button when editing
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .labelStyle(.iconOnly)
                            .foregroundColor(hasSelection ? .btError : .btTextMuted)
                    }
                    .disabled(!hasSelection)
                } else {
                    HStack(spacing: BTSpacing.sm) {
                        // Filter button
                        Button {
                            showingFilterSheet = true
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                                .labelStyle(.iconOnly)
                                .foregroundColor(.btTextPrimary)
                        }

                        // Sort button
                        Button {
                            showingSortSheet = true
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                                .labelStyle(.iconOnly)
                                .foregroundColor(.btTextPrimary)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search sessions...")
        .sheet(isPresented: $showingFilterSheet) {
            filterSheet
        }
        .sheet(isPresented: $showingSortSheet) {
            sortSheet
        }
        .alert("Delete Sessions", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete \(selectionCount)", role: .destructive) {
                deleteSelectedSessions()
            }
        } message: {
            Text("Are you sure you want to delete \(selectionCount) session\(selectionCount == 1 ? "" : "s")? This action cannot be undone.")
        }
    }

    // MARK: - Sessions List Content

    private var sessionsListContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: BTSpacing.lg) {
                // Select All / None bar when editing
                if isEditing {
                    selectionToolbar
                }

                ForEach(groupedSessions, id: \.0) { month, sessions in
                    sessionMonthGroup(month: month, sessions: sessions)
                }
            }
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
            .padding(.vertical, BTSpacing.lg)
        }
    }

    // MARK: - Selection Toolbar

    private var selectionToolbar: some View {
        HStack {
            Button {
                selectAll()
            } label: {
                Text("Select All")
                    .font(BTFont.label())
                    .foregroundColor(allSelected ? .btTextMuted : .btPrimary)
            }
            .disabled(allSelected)

            Spacer()

            Text("\(selectionCount) of \(filteredSessions.count)")
                .font(BTFont.caption())
                .foregroundColor(.btTextSecondary)

            Spacer()

            Button {
                selectNone()
            } label: {
                Text("Select None")
                    .font(BTFont.label())
                    .foregroundColor(hasSelection ? .btPrimary : .btTextMuted)
            }
            .disabled(!hasSelection)
        }
        .padding(.horizontal, BTSpacing.md)
        .padding(.vertical, BTSpacing.sm)
        .background(Color.btSurfaceElevated)
        .cornerRadius(8)
    }

    // MARK: - Session Month Group

    private func sessionMonthGroup(month: String, sessions: [SessionEntity]) -> some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            // Month header
            Text(month)
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)
                .padding(.top, BTSpacing.sm)

            // Sessions in this month
            ForEach(sessions) { session in
                if isEditing {
                    // Selection mode - tap to select/deselect
                    Button {
                        toggleSelection(session.id)
                    } label: {
                        SelectableSessionCard(
                            session: SessionEntityWrapper(entity: session),
                            isSelected: selectedSessionIds.contains(session.id)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    // Normal mode - navigate to detail
                    NavigationLink(destination: SessionDetailView(sessionId: session.id)) {
                        SessionCardContent(session: SessionEntityWrapper(entity: session))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Empty State Content

    private var emptyStateContent: some View {
        VStack {
            Spacer()
            EmptyStateCard(
                icon: "figure.bowling",
                title: "No sessions recorded yet",
                message: "Start your first session to track your bowling metrics!",
                action: nil,
                actionTitle: nil
            )
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
            Spacer()
        }
    }

    // MARK: - Selection Actions

    private func selectAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedSessionIds = Set(filteredSessions.map { $0.id })
        }
    }

    private func selectNone() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedSessionIds.removeAll()
        }
    }

    private func toggleSelection(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedSessionIds.contains(id) {
                selectedSessionIds.remove(id)
            } else {
                selectedSessionIds.insert(id)
            }
        }
    }

    private func deleteSelectedSessions() {
        let idsToDelete = selectedSessionIds
        for session in sessions where idsToDelete.contains(session.id) {
            modelContext.delete(session)
        }
        try? modelContext.save()

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedSessionIds.removeAll()
            isEditing = false
        }
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            List {
                ForEach(SessionFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                        showingFilterSheet = false
                    } label: {
                        HStack {
                            Text(filter.displayName)
                                .foregroundColor(.btTextPrimary)
                            Spacer()
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.btPrimary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filter Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFilterSheet = false
                    }
                    .foregroundColor(.btPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Sort Sheet

    private var sortSheet: some View {
        NavigationStack {
            List {
                ForEach(SessionSort.allCases, id: \.self) { sort in
                    Button {
                        selectedSort = sort
                        showingSortSheet = false
                    } label: {
                        HStack {
                            Text(sort.displayName)
                                .foregroundColor(.btTextPrimary)
                            Spacer()
                            if selectedSort == sort {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.btPrimary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Sort Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSortSheet = false
                    }
                    .foregroundColor(.btPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Session Card Content (for NavigationLink)

struct SessionCardContent: View {
    let session: SessionDisplayable

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: BTSpacing.lg) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.btSurfaceElevated)
                    .frame(width: 60, height: 60)

                Image(systemName: "figure.bowling")
                    .font(.system(size: 24))
                    .foregroundColor(.btPrimary)
            }

            // Content
            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text(session.centerName ?? "Practice Session")
                    .font(BTFont.h4())
                    .foregroundColor(.btTextPrimary)
                    .lineLimit(1)

                HStack(spacing: BTSpacing.md) {
                    Label("\(session.shotCount) shots", systemImage: "circle.fill")
                    Label(Self.dateFormatter.string(from: session.date), systemImage: "calendar")
                }
                .font(BTFont.caption())
                .foregroundColor(.btTextMuted)

                // Stats row
                HStack(spacing: BTSpacing.md) {
                    if let speed = session.averageSpeed {
                        StatPill(value: String(format: "%.1f", speed), unit: "mph", color: .btSpeed)
                    }
                    if let strikeRate = session.strikeRate {
                        StatPill(value: String(format: "%.0f", strikeRate), unit: "% X", color: .btStrike)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.btTextMuted)
        }
        .padding(BTLayout.listItemPadding)
        .background(Color.btSurface)
        .cornerRadius(12)
    }
}

// MARK: - Selectable Session Card (for Edit Mode)

struct SelectableSessionCard: View {
    let session: SessionDisplayable
    let isSelected: Bool

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        HStack(spacing: BTSpacing.md) {
            // Selection checkbox
            ZStack {
                Circle()
                    .strokeBorder(isSelected ? Color.btPrimary : Color.btTextMuted, lineWidth: 2)
                    .frame(width: 24, height: 24)

                if isSelected {
                    Circle()
                        .fill(Color.btPrimary)
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.btTextInverse)
                }
            }

            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.btSurfaceElevated)
                    .frame(width: 50, height: 50)

                Image(systemName: "figure.bowling")
                    .font(.system(size: 20))
                    .foregroundColor(.btPrimary)
            }

            // Content
            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text(session.centerName ?? "Practice Session")
                    .font(BTFont.h4())
                    .foregroundColor(.btTextPrimary)
                    .lineLimit(1)

                HStack(spacing: BTSpacing.md) {
                    Label("\(session.shotCount) shots", systemImage: "circle.fill")
                    Label(Self.dateFormatter.string(from: session.date), systemImage: "calendar")
                }
                .font(BTFont.caption())
                .foregroundColor(.btTextMuted)

                // Stats row
                HStack(spacing: BTSpacing.md) {
                    if let speed = session.averageSpeed {
                        StatPill(value: String(format: "%.1f", speed), unit: "mph", color: .btSpeed)
                    }
                    if let strikeRate = session.strikeRate {
                        StatPill(value: String(format: "%.0f", strikeRate), unit: "% X", color: .btStrike)
                    }
                }
            }

            Spacer()
        }
        .padding(BTLayout.listItemPadding)
        .background(isSelected ? Color.btPrimary.opacity(0.1) : Color.btSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.btPrimary : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(value)
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextPrimary)

            Text(unit)
                .font(BTFont.captionSmall())
                .foregroundColor(color)
        }
        .padding(.horizontal, BTSpacing.sm)
        .padding(.vertical, BTSpacing.xxs)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }
}

// MARK: - Filter Options

enum SessionFilter: CaseIterable {
    case all
    case strikes
    case misses
    case housePattern
    case sportPattern

    var displayName: String {
        switch self {
        case .all: return "All Sessions"
        case .strikes: return "Strikes Only"
        case .misses: return "Misses Only"
        case .housePattern: return "House Pattern"
        case .sportPattern: return "Sport Pattern"
        }
    }
}

// MARK: - Sort Options

enum SessionSort: CaseIterable {
    case mostRecent
    case oldest
    case mostShots
    case highestStrikeRate
    case fastestSpeed

    var displayName: String {
        switch self {
        case .mostRecent: return "Most Recent"
        case .oldest: return "Oldest First"
        case .mostShots: return "Most Shots"
        case .highestStrikeRate: return "Highest Strike %"
        case .fastestSpeed: return "Fastest Average Speed"
        }
    }
}

// MARK: - Preview

#Preview("Sessions List") {
    NavigationStack {
        SessionListView()
    }
    .modelContainer(for: [SessionEntity.self, ShotEntity.self, CalibrationEntity.self, BallProfileEntity.self, CenterEntity.self], inMemory: true)
}

#Preview("Sessions List - Empty") {
    NavigationStack {
        SessionListView()
    }
    .modelContainer(for: [SessionEntity.self, ShotEntity.self, CalibrationEntity.self, BallProfileEntity.self, CenterEntity.self], inMemory: true)
}
