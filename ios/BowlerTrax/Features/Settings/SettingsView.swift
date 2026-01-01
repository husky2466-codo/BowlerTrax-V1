//
//  SettingsView.swift
//  BowlerTrax
//
//  App settings including bowling preferences, ball profiles,
//  lane calibrations, recording options, and data management.
//

import SwiftUI
import SwiftData

// MARK: - User Settings Keys

enum SettingsKey {
    static let dominantHand = "dominantHand"
    static let defaultOilPattern = "defaultOilPattern"
    static let autoSaveVideos = "autoSaveVideos"
    static let showPreviousShot = "showPreviousShot"
    static let hapticFeedback = "hapticFeedback"
    static let frameRate = "frameRate"
}

// MARK: - Settings View

struct SettingsView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalibrationEntity.createdAt, order: .reverse) private var calibrations: [CalibrationEntity]
    @Query(sort: \BallProfileEntity.createdAt, order: .reverse) private var ballProfiles: [BallProfileEntity]

    // MARK: - State (with UserDefaults persistence)

    @AppStorage(SettingsKey.dominantHand) private var selectedHand: String = HandPreference.right.rawValue
    @AppStorage(SettingsKey.defaultOilPattern) private var selectedOilPattern: String = OilPatternType.house.rawValue
    @AppStorage(SettingsKey.autoSaveVideos) private var autoSaveVideos = true
    @AppStorage(SettingsKey.showPreviousShot) private var showPreviousShot = true
    @AppStorage(SettingsKey.hapticFeedback) private var hapticFeedback = true
    @AppStorage(SettingsKey.frameRate) private var frameRate: Int = 120

    @State private var showingExportSheet = false
    @State private var showingClearDataAlert = false
    @State private var showingAddBallProfile = false
    @State private var showingBallPicker = false

    // MARK: - Computed Properties

    private var handPreference: HandPreference {
        get { HandPreference(rawValue: selectedHand) ?? .right }
        set { selectedHand = newValue.rawValue }
    }

    private var oilPatternPreference: OilPatternType {
        get { OilPatternType(rawValue: selectedOilPattern) ?? .house }
        set { selectedOilPattern = newValue.rawValue }
    }

    private var frameRateOption: FrameRateOption {
        get {
            switch frameRate {
            case 60: return .fps60
            case 240: return .fps240
            default: return .fps120
            }
        }
        set { frameRate = newValue.value }
    }

    // MARK: - Body

    var body: some View {
        List {
            // Bowling Preferences
            bowlingPreferencesSection

            // Ball Profiles
            ballProfilesSection

            // Lane Calibrations
            calibrationsSection

            // Recording Settings
            recordingSection

            // Data Management
            dataSection

            // About
            aboutSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.btBackground)
        .navigationTitle("Settings")
        .sheet(isPresented: $showingExportSheet) {
            exportSheet
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all sessions, shots, and calibration data. This action cannot be undone.")
        }
    }

    // MARK: - Bowling Preferences Section

    private var bowlingPreferencesSection: some View {
        Section {
            // Hand selection
            VStack(alignment: .leading, spacing: BTSpacing.md) {
                Text("Dominant Hand")
                    .font(BTFont.body())
                    .foregroundColor(.btTextPrimary)

                HStack(spacing: BTSpacing.md) {
                    ForEach(HandPreference.allCases, id: \.self) { hand in
                        Button {
                            selectedHand = hand.rawValue
                        } label: {
                            Text(hand.displayName)
                                .font(BTFont.label())
                                .foregroundColor(handPreference == hand ? .btTextInverse : .btTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, BTSpacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(handPreference == hand ? Color.btPrimary : Color.btSurfaceElevated)
                                )
                        }
                    }
                }
            }
            .listRowBackground(Color.btSurface)

            // Oil pattern picker
            Picker("Default Oil Pattern", selection: Binding(
                get: { oilPatternPreference },
                set: { selectedOilPattern = $0.rawValue }
            )) {
                ForEach(OilPatternType.allCases, id: \.self) { pattern in
                    Text(pattern.displayName).tag(pattern)
                }
            }
            .listRowBackground(Color.btSurface)

        } header: {
            Text("Bowling Preferences")
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextMuted)
        }
    }

    // MARK: - Ball Profiles Section

    private var ballProfilesSection: some View {
        Section {
            if ballProfiles.isEmpty {
                Text("No ball profiles added yet")
                    .font(BTFont.body())
                    .foregroundColor(.btTextMuted)
                    .listRowBackground(Color.btSurface)
            } else {
                ForEach(ballProfiles) { ball in
                    NavigationLink {
                        Text("Edit \(ball.name)")
                            .navigationTitle("Ball Profile")
                    } label: {
                        HStack(spacing: BTSpacing.md) {
                            // Color preview using actual ball color
                            Circle()
                                .fill(Color(ball.uiColor))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.btSurfaceHighlight, lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: BTSpacing.xxs) {
                                HStack(spacing: BTSpacing.xs) {
                                    Text(ball.displayName)
                                        .font(BTFont.body())
                                        .foregroundColor(.btTextPrimary)

                                    // Show catalog badge if from catalog
                                    if ball.isFromCatalog {
                                        Text("Catalog")
                                            .font(BTFont.labelSmall())
                                            .foregroundColor(.btPrimary)
                                            .padding(.horizontal, BTSpacing.xs)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color.btPrimary.opacity(0.15))
                                            )
                                    }
                                }

                                Text("HSV: \(Int(ball.colorH)), \(Int(ball.colorS))%, \(Int(ball.colorV))%")
                                    .font(BTFont.caption())
                                    .foregroundColor(.btTextMuted)
                            }
                        }
                    }
                    .listRowBackground(Color.btSurface)
                }
                .onDelete(perform: deleteBallProfiles)
            }

            // Add new ball button - shows picker with catalog and custom options
            Button {
                showingBallPicker = true
            } label: {
                Label("Add Ball", systemImage: "plus.circle.fill")
                    .font(BTFont.body())
                    .foregroundColor(.btPrimary)
            }
            .listRowBackground(Color.btSurface)

        } header: {
            Text("Ball Profiles")
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextMuted)
        }
        .sheet(isPresented: $showingBallPicker) {
            BallPickerView()
        }
    }

    // MARK: - Ball Profile Deletion

    private func deleteBallProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = ballProfiles[index]
            modelContext.delete(profile)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete ball profiles: \(error)")
        }
    }

    // MARK: - Calibrations Section

    private var calibrationsSection: some View {
        Section {
            if calibrations.isEmpty {
                Text("No calibrations saved yet")
                    .font(BTFont.body())
                    .foregroundColor(.btTextMuted)
                    .listRowBackground(Color.btSurface)
            } else {
                ForEach(calibrations) { calibration in
                    NavigationLink {
                        Text("Edit \(calibration.centerName)")
                            .navigationTitle("Calibration")
                    } label: {
                        VStack(alignment: .leading, spacing: BTSpacing.xs) {
                            HStack {
                                Text(calibration.centerName)
                                    .font(BTFont.body())
                                    .foregroundColor(.btTextPrimary)

                                Spacer()

                                Text("Calibrated: \(formattedDate(calibration.createdAt))")
                                    .font(BTFont.caption())
                                    .foregroundColor(.btTextMuted)
                            }

                            HStack(spacing: BTSpacing.lg) {
                                if let lane = calibration.laneNumber {
                                    Text("Lane \(lane)")
                                        .font(BTFont.caption())
                                        .foregroundColor(.btTextSecondary)
                                }

                                Text("px/ft: \(String(format: "%.1f", calibration.pixelsPerFoot))")
                                    .font(BTFont.caption())
                                    .foregroundColor(.btTextMuted)

                                Text("px/bd: \(String(format: "%.1f", calibration.pixelsPerBoard))")
                                    .font(BTFont.caption())
                                    .foregroundColor(.btTextMuted)
                            }
                        }
                    }
                    .listRowBackground(Color.btSurface)
                }
            }

            // Add new calibration button - NavigationLink to CalibrationView
            NavigationLink(destination: CalibrationView()) {
                Label("New Calibration", systemImage: "plus.circle.fill")
                    .font(BTFont.body())
                    .foregroundColor(.btPrimary)
            }
            .listRowBackground(Color.btSurface)

        } header: {
            Text("Lane Calibrations")
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextMuted)
        }
    }

    // MARK: - Recording Section

    private var recordingSection: some View {
        Section {
            Toggle("Auto-save Videos", isOn: $autoSaveVideos)
                .listRowBackground(Color.btSurface)
                .tint(.btPrimary)

            Toggle("Show Previous Shot Comparison", isOn: $showPreviousShot)
                .listRowBackground(Color.btSurface)
                .tint(.btPrimary)

            Toggle("Haptic Feedback", isOn: $hapticFeedback)
                .listRowBackground(Color.btSurface)
                .tint(.btPrimary)

            Picker("Camera Frame Rate", selection: Binding(
                get: { frameRateOption },
                set: { frameRate = $0.value }
            )) {
                ForEach(FrameRateOption.allCases, id: \.self) { rate in
                    Text(rate.displayName).tag(rate)
                }
            }
            .listRowBackground(Color.btSurface)

        } header: {
            Text("Recording")
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextMuted)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section {
            Button {
                showingExportSheet = true
            } label: {
                HStack {
                    Text("Export All Data")
                        .font(BTFont.body())
                        .foregroundColor(.btTextPrimary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.btPrimary)
                }
            }
            .listRowBackground(Color.btSurface)

            Button {
                showingClearDataAlert = true
            } label: {
                HStack {
                    Text("Clear All Data")
                        .font(BTFont.body())
                        .foregroundColor(.btError)
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.btError)
                }
            }
            .listRowBackground(Color.btSurface)

        } header: {
            Text("Data")
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextMuted)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .font(BTFont.body())
                    .foregroundColor(.btTextPrimary)
                Spacer()
                Text("1.0.0")
                    .font(BTFont.body())
                    .foregroundColor(.btTextMuted)
            }
            .listRowBackground(Color.btSurface)

            NavigationLink {
                Text("Send Feedback")
                    .navigationTitle("Feedback")
            } label: {
                Text("Send Feedback")
                    .font(BTFont.body())
                    .foregroundColor(.btTextPrimary)
            }
            .listRowBackground(Color.btSurface)

            NavigationLink {
                Text("Privacy Policy")
                    .navigationTitle("Privacy Policy")
            } label: {
                Text("Privacy Policy")
                    .font(BTFont.body())
                    .foregroundColor(.btTextPrimary)
            }
            .listRowBackground(Color.btSurface)

        } header: {
            Text("About")
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextMuted)
        }
    }

    // MARK: - Export Sheet

    private var exportSheet: some View {
        NavigationStack {
            VStack(spacing: BTSpacing.xl) {
                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 48))
                    .foregroundColor(.btPrimary)

                Text("Export Your Data")
                    .font(BTFont.h2())
                    .foregroundColor(.btTextPrimary)

                Text("Choose a format to export all your sessions and shots.")
                    .font(BTFont.body())
                    .foregroundColor(.btTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BTSpacing.xl)

                VStack(spacing: BTSpacing.md) {
                    BTActionButton.primary(title: "Export as JSON", icon: "doc.text") {
                        // Export JSON
                    }

                    BTActionButton.secondary(title: "Export as CSV", icon: "tablecells") {
                        // Export CSV
                    }
                }
                .padding(.horizontal, BTLayout.screenHorizontalPadding)

                Spacer()
            }
            .background(Color.btBackground)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingExportSheet = false
                    }
                    .foregroundColor(.btPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helper Methods

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func clearAllData() {
        // Delete all sessions
        do {
            try modelContext.delete(model: SessionEntity.self)
            try modelContext.delete(model: ShotEntity.self)
            try modelContext.delete(model: CalibrationEntity.self)
            try modelContext.delete(model: BallProfileEntity.self)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

// MARK: - Frame Rate Option

enum FrameRateOption: CaseIterable {
    case fps60
    case fps120
    case fps240

    var displayName: String {
        switch self {
        case .fps60: return "60 fps"
        case .fps120: return "120 fps"
        case .fps240: return "240 fps"
        }
    }

    var value: Int {
        switch self {
        case .fps60: return 60
        case .fps120: return 120
        case .fps240: return 240
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [SessionEntity.self, ShotEntity.self, CalibrationEntity.self, BallProfileEntity.self, CenterEntity.self], inMemory: true)
}
