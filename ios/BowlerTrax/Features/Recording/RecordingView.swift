//
//  RecordingView.swift
//  BowlerTrax
//
//  Live recording screen with camera preview, real-time metrics,
//  shot counter, and session controls. Designed for landscape mode.
//  Camera captures at 120fps for accurate rev rate tracking.
//

import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Recording View

struct RecordingView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Calibration Parameter

    /// The calibration to use for this recording session.
    /// Pass nil if no calibration is available.
    let calibration: CalibrationEntity?

    // MARK: - Camera Manager

    /// Use the shared singleton to avoid multiple camera session conflicts.
    /// Using @ObservedObject since the singleton is not owned by this view.
    @ObservedObject private var cameraManager = CameraSessionManager.shared

    // MARK: - Recording Store (CV Pipeline)

    @StateObject private var recordingStore = RecordingStore()

    // MARK: - State

    @State private var isRecording = false
    @State private var isPaused = false
    @State private var showingSettings = false
    @State private var showingCalibration = false
    @State private var showingEndSessionAlert = false

    // Session state
    @State private var sessionStartTime: Date = Date()
    @State private var recordingStartTime: Date = Date()
    @State private var sessionDuration: TimeInterval = 0
    @State private var recordingTime: TimeInterval = 0

    // Flag to control elapsed time updates (used with .task)
    @State private var isSessionActive = false

    // Shot popup state
    @State private var showShotPopup: Bool = false
    @State private var currentShotForPopup: ShotAnalysis?

    // MARK: - Initializer

    init(calibration: CalibrationEntity? = nil) {
        self.calibration = calibration
    }

    // MARK: - Computed Properties

    private var hasCalibration: Bool {
        calibration != nil
    }

    /// Display name for the calibration (center name + lane number)
    private var calibrationDisplayName: String? {
        guard let cal = calibration else { return nil }
        if let lane = cal.laneNumber {
            return "\(cal.centerName) - Lane \(lane)"
        }
        return cal.centerName
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Live camera preview (full background)
                cameraPreviewLayer
                    .ignoresSafeArea()

                // Crop mask overlay (if calibration has crop zone enabled)
                if let cal = calibration, cal.hasCropZone, let cropRect = cal.cropRect {
                    CropMaskOverlay(cropRect: cropRect)
                        .ignoresSafeArea()
                }

                // Lane guide overlay (if calibrated)
                if hasCalibration, let cal = calibration {
                    LaneGuideOverlay(calibration: cal)
                        .ignoresSafeArea()
                }

                // Main content layout
                HStack(spacing: 0) {
                    // Left side - Camera area with overlays
                    cameraOverlayArea(in: geometry)

                    // Right side - Metrics panel
                    metricsPanel
                        .frame(width: min(320, geometry.size.width * 0.32))
                }

                // Top bar
                topBar
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Bottom controls
                bottomControls
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Calibration warning banner (if no calibration)
                if !hasCalibration {
                    VStack {
                        Spacer()
                        CalibrationWarningBanner {
                            showingCalibration = true
                        }
                        .padding(.horizontal, BTSpacing.lg)
                        .padding(.bottom, 110)
                    }
                }

                // Shot popup overlay
                if showShotPopup, let shot = currentShotForPopup {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ShotPopup(shot: shot) {
                                withAnimation(BTAnimation.easeOutNormal) {
                                    showShotPopup = false
                                    currentShotForPopup = nil
                                }
                            }
                            .frame(maxWidth: 450)
                            .padding(.trailing, min(340, geometry.size.width * 0.34))
                        }
                        .padding(.bottom, 100)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .background(Color.black)
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startSession()
        }
        .onDisappear {
            stopSession()
        }
        .task(id: isSessionActive) {
            // Elapsed time update loop - automatically cancelled when view disappears
            // or when isSessionActive changes to false
            guard isSessionActive else { return }
            while !Task.isCancelled && isSessionActive {
                updateElapsedTime()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
        .sheet(isPresented: $showingSettings) {
            RecordingSettingsSheet()
        }
        .sheet(isPresented: $showingCalibration) {
            CalibrationView()
        }
        .alert("End Session?", isPresented: $showingEndSessionAlert) {
            Button("Continue Recording", role: .cancel) {}
            Button("End Session", role: .destructive) {
                endSession()
            }
        } message: {
            Text("You have recorded \(recordingStore.shotCount) shots. Are you sure you want to end this session?")
        }
        .onChange(of: recordingStore.shotCount) { oldValue, newValue in
            // Show shot popup when a new shot is completed
            if newValue > oldValue, let shot = recordingStore.lastShotAnalysis {
                currentShotForPopup = shot
                withAnimation(BTAnimation.easeOutNormal) {
                    showShotPopup = true
                }
            }
        }
    }

    // MARK: - Camera Preview Layer

    private var cameraPreviewLayer: some View {
        Group {
            if cameraManager.isAuthorized {
                CameraPreviewView(cameraManager: cameraManager)
            } else {
                cameraPermissionView
            }
        }
    }

    private var cameraPermissionView: some View {
        ZStack {
            Color.black

            VStack(spacing: BTSpacing.xl) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.btTextMuted)

                VStack(spacing: BTSpacing.sm) {
                    Text("Camera Access Required")
                        .font(BTFont.h2())
                        .foregroundColor(.btTextPrimary)

                    Text("BowlerTrax needs camera access to track your bowling shots.")
                        .font(BTFont.body())
                        .foregroundColor(.btTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BTSpacing.xxl)
                }

                BTActionButton.primary(title: "Enable Camera", icon: "camera") {
                    openSettings()
                }
                .frame(width: 200)
            }
        }
    }

    // MARK: - Camera Overlay Area

    private func cameraOverlayArea(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Recording indicator (top-left of camera area)
            VStack {
                HStack {
                    RecordingIndicatorView(
                        isRecording: isRecording,
                        isPaused: isPaused,
                        recordingTime: recordingTime
                    )

                    Spacer()

                    // FPS indicators stack
                    if cameraManager.state == .running {
                        VStack(alignment: .trailing, spacing: BTSpacing.xxs) {
                            // Camera FPS
                            FPSIndicator(
                                currentFPS: cameraManager.currentFPS,
                                targetFPS: cameraManager.actualFrameRate
                            )

                            // CV Processing FPS (if processing)
                            if recordingStore.isProcessing {
                                HStack(spacing: BTSpacing.xxs) {
                                    Circle()
                                        .fill(recordingStore.meetingFrameBudget ? Color.green : Color.orange)
                                        .frame(width: 6, height: 6)
                                    Text("CV: \(String(format: "%.0f", recordingStore.processingFPS)) fps")
                                        .font(BTFont.captionSmall())
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, BTSpacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding(.horizontal, BTSpacing.lg)
                .padding(.top, 60) // Below top bar

                Spacer()

                // Ball phase indicator (bottom of camera area)
                if let phase = recordingStore.ballPhase {
                    HStack(spacing: BTSpacing.sm) {
                        Text("Ball Phase:")
                            .font(BTFont.captionSmall())
                            .foregroundColor(.btTextMuted)
                        Text(phase.displayName.uppercased())
                            .font(BTFont.labelSmall())
                            .foregroundColor(.btPrimary)
                            .padding(.horizontal, BTSpacing.sm)
                            .padding(.vertical, 2)
                            .background(Color.btPrimary.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, BTSpacing.lg)
                    .padding(.bottom, 100) // Above bottom controls
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close button
            Button {
                showingEndSessionAlert = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(22)
            }

            Spacer()

            // Title with calibration info
            VStack(spacing: 2) {
                if let displayName = calibrationDisplayName {
                    // Show center name and lane
                    HStack(spacing: BTSpacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.btPrimary)
                        Text(displayName)
                            .font(BTFont.labelSmall())
                            .foregroundColor(.btTextSecondary)
                    }
                } else {
                    Text(isRecording ? "RECORDING" : "CAMERA READY")
                        .font(BTFont.labelSmall())
                        .foregroundColor(isRecording ? .btError : .btTextMuted)
                        .textCase(.uppercase)
                }

                Text(isRecording ? (recordingStore.shotCount > 0 ? "Shot \(recordingStore.shotCount)" : "Tracking...") : "Press Start to Begin")
                    .font(BTFont.h3())
                    .foregroundColor(.white)
            }

            Spacer()

            // Settings button
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(22)
            }
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.top, BTSpacing.lg)
    }

    // MARK: - Metrics Panel

    private var metricsPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BTSpacing.md) {
                // Header with tracking state
                HStack {
                    Text("Real-Time Metrics")
                        .font(BTFont.labelSmall())
                        .foregroundColor(.btTextMuted)
                        .textCase(.uppercase)

                    Spacer()

                    // Tracking state indicator
                    HStack(spacing: BTSpacing.xxs) {
                        Circle()
                            .fill(recordingStore.trackingState.indicatorColor)
                            .frame(width: 8, height: 8)
                        Text(recordingStore.trackingState.displayString)
                            .font(BTFont.captionSmall())
                            .foregroundColor(.btTextMuted)
                    }
                }

                // Speed
                LiveMetricCard(
                    title: "Speed",
                    value: recordingStore.currentSpeed.map { String(format: "%.1f", $0) } ?? "--",
                    unit: "mph",
                    previousValue: recordingStore.lastShotSpeed.map { "Prev: \(String(format: "%.1f", $0))" },
                    accentColor: .btSpeed
                )

                // Rev Rate
                LiveMetricCard(
                    title: "Rev Rate",
                    value: recordingStore.currentRevRate.map { String(format: "%.0f", $0) } ?? "--",
                    unit: "rpm",
                    previousValue: nil,
                    subtitle: recordingStore.currentRevRate.map { RevCategory.from(rpm: $0).displayName.uppercased() },
                    accentColor: .btRevRate
                )

                // Entry Angle
                LiveMetricCard(
                    title: "Entry Angle",
                    value: recordingStore.currentEntryAngle.map { String(format: "%.1f", $0) } ?? "--",
                    unit: "deg",
                    previousValue: "Optimal: 6.0",
                    progress: recordingStore.currentEntryAngle.map { $0 / 10.0 },
                    accentColor: .btAngle
                )

                // Arrow Board
                LiveMetricCard(
                    title: "Arrow Board",
                    value: recordingStore.arrowBoard.map { String(format: "%.1f", $0) } ?? "--",
                    unit: "bd",
                    previousValue: "Target: 15",
                    accentColor: .btBoard
                )

                // Breakpoint
                LiveMetricCard(
                    title: "Breakpoint",
                    value: recordingStore.breakpoint.map { String(format: "%.1f", $0.board) } ?? "--",
                    unit: "bd",
                    previousValue: recordingStore.breakpoint.map { "at \(String(format: "%.1f", $0.distance)) ft" },
                    accentColor: .btBreakpoint
                )

                // Strike Probability
                LiveMetricCard(
                    title: "Strike Prob",
                    value: recordingStore.strikeProbability.map { String(format: "%.0f", $0 * 100) } ?? "--",
                    unit: "%",
                    progress: recordingStore.strikeProbability,
                    accentColor: .btStrike
                )

                // Board Position (current tracking)
                if recordingStore.boardNumber != nil || recordingStore.distanceFeet != nil {
                    LiveMetricCard(
                        title: "Position",
                        value: recordingStore.boardNumber.map { String(format: "%.1f", $0) } ?? "--",
                        unit: "bd",
                        previousValue: recordingStore.distanceFeet.map { "\(String(format: "%.1f", $0)) ft" },
                        accentColor: .btPrimary
                    )
                }

                Divider()
                    .background(Color.btSurfaceHighlight)
                    .padding(.vertical, BTSpacing.sm)

                // Last Shot Result
                if let result = recordingStore.lastShotResult {
                    lastShotCard(result: result)
                } else {
                    emptyLastShotCard
                }

                // Shot Log (recent shots)
                if !recordingStore.recordedShots.isEmpty {
                    Divider()
                        .background(Color.btSurfaceHighlight)
                        .padding(.vertical, BTSpacing.sm)

                    InlineShotLog(
                        shots: recordingStore.recordedShots,
                        maxVisible: 5
                    )
                }
            }
            .padding(BTSpacing.md)
        }
        .background(Color.btSurface.opacity(0.95))
    }

    // MARK: - Last Shot Card

    private func lastShotCard(result: ShotResult) -> some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            Text("Last Shot Result")
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextMuted)
                .textCase(.uppercase)

            HStack {
                // Result badge
                Text(result.symbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(result == .strike ? .btSuccess : .btTextPrimary)
                    .frame(width: 44, height: 44)
                    .background((result == .strike ? Color.btSuccess : Color.btSurface).opacity(0.2))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.displayName)
                        .font(BTFont.h4())
                        .foregroundColor(.btTextPrimary)

                    if let speed = recordingStore.lastShotSpeed, let angle = recordingStore.lastShotAngle {
                        Text("Speed: \(String(format: "%.1f", speed)) mph | Angle: \(String(format: "%.1f", angle))deg")
                            .font(BTFont.caption())
                            .foregroundColor(.btTextMuted)
                    }
                }

                Spacer()
            }
        }
        .padding(BTSpacing.md)
        .background(Color.btSurfaceElevated)
        .cornerRadius(10)
    }

    private var emptyLastShotCard: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            Text("Last Shot Result")
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextMuted)
                .textCase(.uppercase)

            HStack {
                Image(systemName: "circle.dashed")
                    .font(.system(size: 24))
                    .foregroundColor(.btTextMuted)
                    .frame(width: 44, height: 44)
                    .background(Color.btSurface.opacity(0.5))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("No shots yet")
                        .font(BTFont.h4())
                        .foregroundColor(.btTextMuted)

                    Text("Roll a ball to start tracking")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextMuted)
                }

                Spacer()
            }
        }
        .padding(BTSpacing.md)
        .background(Color.btSurfaceElevated)
        .cornerRadius(10)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: BTSpacing.xl) {
            // Session timer
            SessionTimerBadge(sessionDuration: sessionDuration)

            // Shot counter
            ShotCounterBadge(shotCount: recordingStore.shotCount)

            Spacer()

            // Start button (only shown when not recording)
            if !isRecording {
                Button {
                    startRecording()
                } label: {
                    HStack(spacing: BTSpacing.sm) {
                        Image(systemName: "record.circle")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Start")
                            .font(BTFont.buttonLabel())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, BTSpacing.lg)
                    .frame(height: 56)
                    .background(Color.btSuccess)
                    .cornerRadius(28)
                }
            }

            // Pause/Resume button (only shown when recording)
            if isRecording {
                Button {
                    togglePause()
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.btPrimary)
                        .cornerRadius(28)
                }
            }

            // End session button
            Button {
                showingEndSessionAlert = true
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.btError)
                    .cornerRadius(28)
            }
        }
        .padding(.horizontal, BTSpacing.xl)
        .padding(.bottom, BTSpacing.xl)
    }

    // MARK: - Session Control

    /// Called on view appear - starts camera only, not recording
    private func startSession() {
        sessionStartTime = Date()

        // Start camera only (not recording yet)
        cameraManager.startSession()

        // Configure CV pipeline (but don't start it yet)
        let calibrationProfile = calibration?.toModel()
        recordingStore.configure(
            cameraManager: cameraManager,
            calibration: calibrationProfile,
            ballColor: HSVColor(h: 220, s: 80, v: 80), // Default blue ball
            handPreference: .right // TODO: Get from user settings
        )

        // Activate elapsed time updates via .task modifier
        isSessionActive = true
    }

    /// Called when user taps Start button - begins recording and CV pipeline
    private func startRecording() {
        isRecording = true
        isPaused = false
        recordingStartTime = Date()

        // Start CV pipeline
        recordingStore.startSession()
    }

    private func stopSession() {
        // Deactivate elapsed time updates - the .task will automatically cancel
        isSessionActive = false
        recordingStore.stopSession()
        cameraManager.stopSession()
    }

    private func endSession() {
        stopSession()
        saveSessionToDatabase()
        dismiss()
    }

    private func saveSessionToDatabase() {
        // Create new session entity
        let sessionEntity = SessionEntity()
        sessionEntity.id = UUID()
        sessionEntity.startTime = sessionStartTime
        sessionEntity.endTime = Date()
        sessionEntity.createdAt = sessionStartTime

        // Populate from calibration entity if available
        if let cal = calibration {
            sessionEntity.centerName = cal.centerName
            sessionEntity.calibrationId = cal.id
            sessionEntity.centerId = cal.centerId
            sessionEntity.lane = cal.laneNumber

            // Mark calibration as recently used
            cal.markUsed()
        } else {
            sessionEntity.centerName = "Practice Session"
        }

        // Insert into SwiftData context
        modelContext.insert(sessionEntity)

        // Create shot entities from recorded shots
        let shots = recordingStore.createShots(for: sessionEntity.id)
        for shot in shots {
            let shotEntity = ShotEntity(from: shot)
            shotEntity.session = sessionEntity
            modelContext.insert(shotEntity)
        }

        // Attempt to save immediately
        do {
            try modelContext.save()
        } catch {
            print("Failed to save session: \(error.localizedDescription)")
        }
    }

    private func togglePause() {
        isPaused.toggle()

        if isPaused {
            recordingStore.pauseSession()
            cameraManager.pauseSession()
        } else {
            cameraManager.resumeSession()
            recordingStore.resumeSession()
            recordingStartTime = Date().addingTimeInterval(-recordingTime)
        }
    }

    private func updateElapsedTime() {
        sessionDuration = Date().timeIntervalSince(sessionStartTime)

        if !isPaused {
            recordingTime = Date().timeIntervalSince(recordingStartTime)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Live Metric Card

struct LiveMetricCard: View {
    let title: String
    let value: String
    let unit: String
    var previousValue: String? = nil
    var subtitle: String? = nil
    var progress: Double? = nil
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            // Title
            Text(title)
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)
                .textCase(.uppercase)

            // Value row
            HStack(alignment: .firstTextBaseline, spacing: BTSpacing.xxs) {
                Text(value)
                    .font(BTFont.h3())
                    .foregroundColor(value == "--" ? .btTextMuted : .btTextPrimary)
                    .monospacedDigit()

                Text(unit)
                    .font(BTFont.caption())
                    .foregroundColor(accentColor)
            }

            // Previous value
            if let previousValue = previousValue {
                Text(previousValue)
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btTextMuted)
            }

            // Subtitle badge
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(BTFont.captionSmall())
                    .foregroundColor(accentColor)
                    .padding(.horizontal, BTSpacing.sm)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.2))
                    .cornerRadius(4)
            }

            // Progress bar
            if let progress = progress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.btSurfaceHighlight)
                            .frame(height: 4)

                        Rectangle()
                            .fill(accentColor)
                            .frame(width: geometry.size.width * min(1, max(0, progress)), height: 4)
                    }
                    .cornerRadius(2)
                }
                .frame(height: 4)
            }
        }
        .padding(BTSpacing.sm)
        .background(Color.btSurfaceElevated)
        .cornerRadius(8)
    }
}

// MARK: - Recording Settings Sheet

struct RecordingSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var frameRate: Double = 120
    @State private var autoSaveVideos = true
    @State private var hapticFeedback = true
    @State private var showPreviousComparison = true

    var body: some View {
        NavigationStack {
            List {
                Section("Camera") {
                    Picker("Frame Rate", selection: $frameRate) {
                        Text("60 fps").tag(60.0)
                        Text("120 fps").tag(120.0)
                        Text("240 fps").tag(240.0)
                    }
                }

                Section("Recording") {
                    Toggle("Auto-save videos", isOn: $autoSaveVideos)
                    Toggle("Haptic on shot detection", isOn: $hapticFeedback)
                    Toggle("Show previous comparison", isOn: $showPreviousComparison)
                }

                Section("Info") {
                    HStack {
                        Text("Dropped frames")
                        Spacer()
                        Text("0")
                            .foregroundColor(.btTextMuted)
                    }

                    HStack {
                        Text("Storage used")
                        Spacer()
                        Text("0 MB")
                            .foregroundColor(.btTextMuted)
                    }
                }
            }
            .navigationTitle("Recording Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.btPrimary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Recording View - No Calibration") {
    RecordingView(calibration: nil)
        .previewInterfaceOrientation(.landscapeRight)
}

#Preview("Recording View - With Calibration") {
    let calibration = CalibrationEntity()
    calibration.centerName = "Lucky Strike Lanes"
    calibration.laneNumber = 12
    calibration.pixelsPerFoot = 50.0
    calibration.pixelsPerBoard = 10.0
    calibration.foulLineY = 800
    calibration.arrowsY = 400
    calibration.leftGutterX = 100
    calibration.rightGutterX = 500

    return RecordingView(calibration: calibration)
        .previewInterfaceOrientation(.landscapeRight)
}

#Preview("Recording View - Portrait") {
    RecordingView(calibration: nil)
}

// MARK: - Crop Mask Overlay

/// Darkens the area outside the crop zone to visually indicate the active recording area
struct CropMaskOverlay: View {
    /// Normalized crop rect (0-1 coordinates)
    let cropRect: CGRect

    var body: some View {
        GeometryReader { geometry in
            let frameSize = geometry.size

            // Convert normalized crop rect to pixel coordinates
            let cropPixelRect = CGRect(
                x: cropRect.origin.x * frameSize.width,
                y: cropRect.origin.y * frameSize.height,
                width: cropRect.width * frameSize.width,
                height: cropRect.height * frameSize.height
            )

            // Draw darkened mask around crop area
            Path { path in
                // Full frame rect
                path.addRect(CGRect(origin: .zero, size: frameSize))

                // Subtract the crop area (creates the hole)
                path.addRect(cropPixelRect)
            }
            .fill(style: FillStyle(eoFill: true))
            .foregroundColor(Color.black.opacity(0.6))

            // Draw border around crop area
            Rectangle()
                .stroke(Color.btPrimary.opacity(0.5), lineWidth: 2)
                .frame(width: cropPixelRect.width, height: cropPixelRect.height)
                .position(
                    x: cropPixelRect.midX,
                    y: cropPixelRect.midY
                )

            // Corner indicators
            ForEach(corners(for: cropPixelRect), id: \.x) { point in
                CornerIndicator()
                    .position(point)
            }
        }
    }

    /// Get corner positions for the crop rect
    private func corners(for rect: CGRect) -> [CGPoint] {
        [
            CGPoint(x: rect.minX, y: rect.minY),  // Top-left
            CGPoint(x: rect.maxX, y: rect.minY),  // Top-right
            CGPoint(x: rect.minX, y: rect.maxY),  // Bottom-left
            CGPoint(x: rect.maxX, y: rect.maxY)   // Bottom-right
        ]
    }
}

/// Corner indicator for crop zone visualization
private struct CornerIndicator: View {
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.btPrimary.opacity(0.3))
                .frame(width: 20, height: 20)

            // Inner dot
            Circle()
                .fill(Color.btPrimary)
                .frame(width: 8, height: 8)
        }
    }
}

#Preview("Crop Mask Overlay") {
    ZStack {
        // Simulated camera feed
        LinearGradient(
            colors: [.gray, Color(white: 0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        CropMaskOverlay(cropRect: CGRect(x: 0.1, y: 0.15, width: 0.8, height: 0.7))
    }
    .ignoresSafeArea()
}
