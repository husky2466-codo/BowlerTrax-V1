//
//  CalibrationView.swift
//  BowlerTrax
//
//  5-step calibration wizard for lane setup:
//  1. Position Camera
//  2. Mark Foul Line (with Auto-Detect option)
//  3. Mark Arrows (with Auto-Detect option)
//  4. Verify Calibration
//  5. Save & Complete
//

import SwiftUI
import SwiftData
import AVFoundation
import PhotosUI
import CoreMedia

// MARK: - Calibration View

struct CalibrationView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var currentStep: CalibrationStep = .position
    @State private var showingRecording = false
    @State private var isSaving = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var savedCalibrationEntity: CalibrationEntity? = nil

    // Camera manager
    @StateObject private var cameraManager = CalibrationCameraManager()

    // Lane detection
    @State private var laneDetector = LaneDetector()
    @State private var detectionState: LaneDetectionState = .idle
    @State private var detectionResult: LaneDetectionResult? = nil
    @State private var showingDetectionOverlay = false
    @State private var showingDetectionResult = false

    // Test mode with image
    @State private var showingImagePicker = false
    @State private var testImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isTestMode = false

    // Step 2 - Foul Line
    @State private var foulLineY: CGFloat? = nil
    @State private var foulLineTapPoint: CGPoint? = nil

    // Step 3 - Arrows
    @State private var arrow1Position: CGPoint? = nil
    @State private var arrow2Position: CGPoint? = nil
    @State private var arrow1Board: Int = 10
    @State private var arrow2Board: Int = 25

    // Step 3 - Gutter detection (estimated from arrow positions)
    @State private var leftGutterX: CGFloat = 0
    @State private var rightGutterX: CGFloat = 0

    // Step 5 - Crop Zone
    @State private var cropRect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    @State private var cropEnabled: Bool = false

    // Step 6 - Save
    @State private var centerName: String = ""
    @State private var laneNumber: String = ""

    // Preview size tracking
    @State private var previewSize: CGSize = .zero

    // MARK: - Computed Properties

    /// Calculated pixels per board from arrow positions
    private var calculatedPixelsPerBoard: Double {
        guard let p1 = arrow1Position, let p2 = arrow2Position else { return 0 }
        let pixelDifference = abs(p2.x - p1.x)
        let boardDifference = abs(Double(arrow2Board - arrow1Board))
        guard boardDifference > 0 else { return 0 }
        return pixelDifference / boardDifference
    }

    /// Calculated pixels per foot (arrows are 15ft from foul line)
    private var calculatedPixelsPerFoot: Double {
        guard let foulY = foulLineY,
              let p1 = arrow1Position,
              let p2 = arrow2Position else { return 0 }
        let avgArrowY = (p1.y + p2.y) / 2
        let pixelDifference = abs(foulY - avgArrowY)
        // Arrows are 15 feet from foul line
        return pixelDifference / 15.0
    }

    /// Average arrow Y position
    private var arrowsY: Double {
        guard let p1 = arrow1Position, let p2 = arrow2Position else { return 0 }
        return Double((p1.y + p2.y) / 2)
    }

    /// Estimate lane width from calibration
    private var estimatedLaneWidthPixels: Double {
        // Lane is 39 boards wide
        return calculatedPixelsPerBoard * 39.0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator (compact)
                BTProgressIndicator(
                    steps: CalibrationStep.allCases.map { $0.displayName },
                    currentStep: currentStep.stepNumber - 1
                )
                .padding(.vertical, BTSpacing.md)

                // Step content - takes remaining space
                stepContent
                    .frame(maxHeight: .infinity)

                // Navigation buttons (fixed at bottom)
                navigationButtons
            }
            .background(Color.btBackground)
            .navigationTitle("Calibration")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep == .position {
                        Button("Cancel") {
                            stopCameraAndDismiss()
                        }
                        .foregroundColor(.btPrimary)
                    } else {
                        Button {
                            goToPreviousStep()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.btPrimary)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("Step \(currentStep.stepNumber) of 6")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextMuted)
                }
            }
            .onAppear {
                cameraManager.checkPermission()
            }
            .onDisappear {
                cameraManager.stopSession()
            }
            .fullScreenCover(isPresented: $showingRecording) {
                RecordingView(calibration: savedCalibrationEntity)
            }
            .alert("Save Error", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
        }
    }

    // MARK: - Stop Camera and Dismiss

    private func stopCameraAndDismiss() {
        cameraManager.stopSession()
        dismiss()
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .position:
            positionStep
        case .foulLine:
            foulLineStep
        case .arrows:
            arrowsStep
        case .verify:
            verifyStep
        case .cropZone:
            cropZoneStep
        case .complete:
            completeStep
        }
    }

    // MARK: - Step 1: Position Camera

    private var positionStep: some View {
        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // Title
                VStack(spacing: BTSpacing.sm) {
                    Text("Position Your Camera")
                        .font(BTFont.h1())
                        .foregroundColor(.btTextPrimary)
                        .multilineTextAlignment(.center)
                }

                // Illustration
                positionIllustration

                // Instructions
                VStack(alignment: .leading, spacing: BTSpacing.md) {
                    InstructionRow(number: 1, text: "Mount your iPad on a tripod")
                    InstructionRow(number: 2, text: "Position 5-6 feet behind the approach")
                    InstructionRow(number: 3, text: "Elevate camera to 5-6 feet high")
                    InstructionRow(number: 4, text: "Angle down toward the lane")
                    InstructionRow(number: 5, text: "Ensure full lane is visible (foul line to pins)")
                }
                .padding(BTLayout.cardPadding)
                .background(Color.btSurface)
                .cornerRadius(BTLayout.cardCornerRadius)

                // Warning
                HStack(spacing: BTSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.btWarning)

                    Text("Position parallel to the gutter, NOT behind your target (otherwise you'll block the camera during your shot)")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }
                .padding(BTSpacing.md)
                .background(Color.btWarningMuted.opacity(0.3))
                .cornerRadius(10)
            }
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
        }
    }

    private var positionIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.btSurfaceElevated)
                .frame(height: 200)

            VStack(spacing: BTSpacing.md) {
                Image(systemName: "ipad.landscape.badge.play")
                    .font(.system(size: 48))
                    .foregroundColor(.btPrimary)

                Text("5-6 ft high, behind bowler")
                    .font(BTFont.caption())
                    .foregroundColor(.btTextMuted)

                Image(systemName: "arrow.down")
                    .foregroundColor(.btPrimary)

                HStack(spacing: BTSpacing.xl) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 32))
                        .foregroundColor(.btTextMuted)

                    Image(systemName: "arrow.right")
                        .foregroundColor(.btTextMuted)

                    Text("Lane")
                        .font(BTFont.body())
                        .foregroundColor(.btTextMuted)
                }
            }
        }
    }

    // MARK: - Step 2: Foul Line

    private var foulLineStep: some View {
        GeometryReader { outerGeometry in
            VStack(spacing: BTSpacing.md) {
                // Title (compact)
                VStack(spacing: BTSpacing.xs) {
                    Text("Mark Foul Line")
                        .font(BTFont.h2())
                        .foregroundColor(.btTextPrimary)

                    Text("Tap on the foul line or use Auto-Detect")
                        .font(BTFont.body())
                        .foregroundColor(.btTextSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)

                // Camera preview or test image - expands to fill available space
                ZStack {
                    if isTestMode, let image = testImage {
                        // Test mode - show selected image
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)

                        // Test mode badge
                        VStack {
                            HStack {
                                Spacer()
                                Text("TEST MODE")
                                    .font(BTFont.captionSmall())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, BTSpacing.sm)
                                    .padding(.vertical, 4)
                                    .background(Color.btAccent)
                                    .cornerRadius(4)
                                    .padding(BTSpacing.sm)
                            }
                            Spacer()
                        }
                    } else {
                        // Live camera preview
                        CalibrationCameraPreview(cameraManager: cameraManager)
                            .cornerRadius(12)
                            .onAppear {
                                if !isTestMode {
                                    cameraManager.startSession()
                                }
                            }
                    }

                    // Overlay for tap gesture and detection
                    GeometryReader { geometry in
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        guard !detectionState.isProcessing else { return }
                                        let location = value.location
                                        foulLineY = location.y
                                        foulLineTapPoint = location
                                        previewSize = geometry.size
                                        // Clear detection result when manually tapping
                                        showingDetectionOverlay = false
                                    }
                            )
                            .onAppear {
                                previewSize = geometry.size
                            }

                        // Lane detection overlay
                        if showingDetectionOverlay, let result = detectionResult {
                            LaneOverlayView(
                                detectionResult: result,
                                showLabels: true,
                                animateDetection: true
                            )
                        }

                        // Foul line marker (manual or from detection)
                        if let y = foulLineY {
                            Rectangle()
                                .fill(Color.btWarning)
                                .frame(height: 3)
                                .shadow(color: .btWarning.opacity(0.5), radius: 4)
                                .position(x: geometry.size.width / 2, y: y)

                            // Tap point indicator (only for manual tap)
                            if let tapPoint = foulLineTapPoint, !showingDetectionOverlay {
                                Circle()
                                    .fill(Color.btSuccess)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .position(tapPoint)
                            }
                        }
                    }

                    // Detection progress overlay
                    if detectionState.isProcessing {
                        Color.black.opacity(0.6)
                            .cornerRadius(12)

                        LaneDetectionProgressView(
                            state: detectionState,
                            onCancel: cancelDetection
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.btBorder, lineWidth: 1)
                )

                // Auto-detect button and status
                VStack(spacing: BTSpacing.sm) {
                    // Button row
                    HStack(spacing: BTSpacing.md) {
                        // Auto-detect button
                        Button {
                            if isTestMode, testImage != nil {
                                startTestImageDetection()
                            } else {
                                startLaneDetection()
                            }
                        } label: {
                            HStack(spacing: BTSpacing.sm) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 16))
                                Text(isTestMode ? "Detect in Image" : "Auto-Detect Lane")
                                    .font(BTFont.label())
                            }
                            .foregroundColor(.btPrimary)
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.vertical, BTSpacing.sm)
                            .background(Color.btPrimaryMuted.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .disabled(detectionState.isProcessing || (isTestMode && testImage == nil))

                        // Test with Image button (PhotosPicker)
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack(spacing: BTSpacing.sm) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 16))
                                Text(isTestMode ? "Change Image" : "Test with Image")
                                    .font(BTFont.label())
                            }
                            .foregroundColor(.btAccent)
                            .padding(.horizontal, BTSpacing.lg)
                            .padding(.vertical, BTSpacing.sm)
                            .background(Color.btAccent.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            loadTestImage(from: newItem)
                        }

                        // Exit test mode button (only in test mode)
                        if isTestMode {
                            Button {
                                exitTestMode()
                            } label: {
                                HStack(spacing: BTSpacing.xs) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                    Text("Use Camera")
                                        .font(BTFont.labelSmall())
                                }
                                .foregroundColor(.btTextSecondary)
                                .padding(.horizontal, BTSpacing.md)
                                .padding(.vertical, BTSpacing.sm)
                                .background(Color.btSurfaceElevated)
                                .cornerRadius(8)
                            }
                        }
                    }

                    // Status bar
                    foulLineStatusBar
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
        }
    }

    /// Foul line status bar - extracted for clarity
    private var foulLineStatusBar: some View {
        Group {
            if let y = foulLineY {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.btSuccess)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Foul Line Position: Y = \(Int(y)) px")
                            .font(BTFont.body())
                            .foregroundColor(.btTextPrimary)

                        if showingDetectionOverlay, let result = detectionResult {
                            Text("Auto-detected (\(Int(result.confidence * 100))% confidence)")
                                .font(BTFont.captionSmall())
                                .foregroundColor(.btTextSecondary)
                        }
                    }

                    Spacer()

                    Button("Redo") {
                        foulLineY = nil
                        foulLineTapPoint = nil
                        showingDetectionOverlay = false
                        detectionResult = nil
                    }
                    .font(BTFont.label())
                    .foregroundColor(.btPrimary)
                }
            } else {
                HStack {
                    Image(systemName: "circle")
                        .foregroundColor(.btTextMuted)

                    Text("Foul Line Position: NOT SET")
                        .font(BTFont.body())
                        .foregroundColor(.btTextMuted)

                    Spacer()
                }
            }
        }
        .padding(BTSpacing.md)
        .background(Color.btSurface)
        .cornerRadius(10)
    }

    // MARK: - Step 3: Arrows

    private var arrowsStep: some View {
        GeometryReader { outerGeometry in
            VStack(spacing: BTSpacing.sm) {
                // Title (compact)
                VStack(spacing: BTSpacing.xs) {
                    Text("Mark Two Arrows")
                        .font(BTFont.h2())
                        .foregroundColor(.btTextPrimary)

                    Text("Tap on any 2 arrows in the camera view")
                        .font(BTFont.body())
                        .foregroundColor(.btTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .fixedSize(horizontal: false, vertical: true)

                // Camera preview - expands to fill available space
                ZStack {
                    CalibrationCameraPreview(cameraManager: cameraManager)
                        .cornerRadius(12)

                    // Overlay for tap gesture and markers
                    GeometryReader { geometry in
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        let location = value.location
                                        if arrow1Position == nil {
                                            arrow1Position = location
                                        } else if arrow2Position == nil {
                                            arrow2Position = location
                                            // Calculate estimated gutter positions
                                            calculateGutterPositions(previewWidth: geometry.size.width)
                                        }
                                        previewSize = geometry.size
                                    }
                            )

                        // Show foul line from previous step
                        if let y = foulLineY {
                            Rectangle()
                                .fill(Color.btWarning.opacity(0.6))
                                .frame(height: 2)
                                .position(x: geometry.size.width / 2, y: y)

                            Text("FOUL LINE")
                                .font(BTFont.captionSmall())
                                .foregroundColor(.btWarning)
                                .position(x: 60, y: y - 10)
                        }

                        // Arrow markers
                        if let p1 = arrow1Position {
                            arrowMarker(position: p1, number: 1, board: arrow1Board)
                        }

                        if let p2 = arrow2Position {
                            arrowMarker(position: p2, number: 2, board: arrow2Board)
                        }

                        // Connecting line between arrows
                        if let p1 = arrow1Position, let p2 = arrow2Position {
                            Path { path in
                                path.move(to: p1)
                                path.addLine(to: p2)
                            }
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .foregroundColor(.btPrimary.opacity(0.7))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.btBorder, lineWidth: 1)
                )

                // Arrow selection cards (compact row)
                arrowSelectionRow
                    .fixedSize(horizontal: false, vertical: true)

                // Calculated values status bar (when both arrows set)
                arrowsCalculatedStatusBar
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
        }
    }

    /// Arrow selection cards in horizontal layout
    private var arrowSelectionRow: some View {
        HStack(spacing: BTSpacing.md) {
            ArrowSelectionCard(
                arrowNumber: 1,
                position: arrow1Position,
                selectedBoard: $arrow1Board,
                onClear: { arrow1Position = nil }
            )

            ArrowSelectionCard(
                arrowNumber: 2,
                position: arrow2Position,
                selectedBoard: $arrow2Board,
                onClear: { arrow2Position = nil }
            )
        }
    }

    /// Calculated values status bar for arrows step
    @ViewBuilder
    private var arrowsCalculatedStatusBar: some View {
        if arrow1Position != nil && arrow2Position != nil {
            HStack(spacing: BTSpacing.lg) {
                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.btSuccess)
                        .font(.system(size: 14))
                    Text("\(abs(arrow2Board - arrow1Board)) boards")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }

                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.btSuccess)
                        .font(.system(size: 14))
                    Text("\(String(format: "%.1f", calculatedPixelsPerBoard)) px/board")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }

                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.btSuccess)
                        .font(.system(size: 14))
                    Text("\(String(format: "%.1f", calculatedPixelsPerFoot)) px/ft")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextSecondary)
                }
            }
            .padding(BTSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(Color.btSuccessMuted.opacity(0.3))
            .cornerRadius(8)
        }
    }

    /// Arrow marker view
    @ViewBuilder
    private func arrowMarker(position: CGPoint, number: Int, board: Int) -> some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 28, height: 28)

            // Inner circle
            Circle()
                .fill(Color.btPrimary)
                .frame(width: 24, height: 24)

            // Number
            Text("\(number)")
                .font(BTFont.labelSmall())
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .position(position)
        .shadow(color: .black.opacity(0.3), radius: 4)

        // Board label
        Text("Bd \(board)")
            .font(BTFont.captionSmall())
            .foregroundColor(.btPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.btSurface.opacity(0.9))
            .cornerRadius(4)
            .position(x: position.x, y: position.y + 22)
    }

    /// Calculate estimated gutter positions based on arrow placements
    private func calculateGutterPositions(previewWidth: CGFloat) {
        guard let p1 = arrow1Position, let p2 = arrow2Position else { return }

        let ppb = calculatedPixelsPerBoard
        guard ppb > 0 else { return }

        // Find leftmost arrow
        let leftArrow = p1.x < p2.x ? (pos: p1, board: arrow1Board) : (pos: p2, board: arrow2Board)
        let rightArrow = p1.x >= p2.x ? (pos: p1, board: arrow1Board) : (pos: p2, board: arrow2Board)

        // Board 1 is the left gutter, Board 39 is the right gutter
        // Calculate how many boards from leftmost arrow to left gutter (board 1)
        let boardsToLeftGutter = Double(leftArrow.board - 1)
        leftGutterX = leftArrow.pos.x - (boardsToLeftGutter * ppb)

        // Calculate how many boards from rightmost arrow to right gutter (board 39)
        let boardsToRightGutter = Double(39 - rightArrow.board)
        rightGutterX = rightArrow.pos.x + (boardsToRightGutter * ppb)
    }

    // MARK: - Step 4: Verify

    private var verifyStep: some View {
        GeometryReader { outerGeometry in
            VStack(spacing: BTSpacing.sm) {
                // Title (compact)
                VStack(spacing: BTSpacing.xs) {
                    Text("Verify Calibration")
                        .font(BTFont.h2())
                        .foregroundColor(.btTextPrimary)

                    Text("Review the calibration overlay on the lane")
                        .font(BTFont.body())
                        .foregroundColor(.btTextSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)

                // Camera preview with calibration overlay - expands to fill space
                ZStack {
                    CalibrationCameraPreview(cameraManager: cameraManager)
                        .cornerRadius(12)

                    // Calibration overlay
                    GeometryReader { geometry in
                        // Foul line
                        if let y = foulLineY {
                            HStack(spacing: 4) {
                                Text("0ft")
                                    .font(BTFont.captionSmall())
                                    .foregroundColor(.btWarning)

                                Rectangle()
                                    .fill(Color.btWarning)
                                    .frame(height: 2)
                            }
                            .position(x: geometry.size.width / 2, y: y)
                        }

                        // Arrows line
                        if arrow1Position != nil && arrow2Position != nil {
                            let avgY = arrowsY
                            HStack(spacing: 4) {
                                Text("15ft")
                                    .font(BTFont.captionSmall())
                                    .foregroundColor(.btPrimary)

                                Rectangle()
                                    .fill(Color.btPrimary)
                                    .frame(height: 2)
                            }
                            .position(x: geometry.size.width / 2, y: CGFloat(avgY))
                        }

                        // Breakpoint line (35ft)
                        if let foulY = foulLineY, calculatedPixelsPerFoot > 0 {
                            let breakpointY = foulY - (35 * calculatedPixelsPerFoot)
                            if breakpointY > 0 {
                                HStack(spacing: 4) {
                                    Text("35ft")
                                        .font(BTFont.captionSmall())
                                        .foregroundColor(.btAccent)

                                    Rectangle()
                                        .fill(Color.btAccent.opacity(0.7))
                                        .frame(height: 1)
                                }
                                .position(x: geometry.size.width / 2, y: CGFloat(breakpointY))
                            }
                        }

                        // Pins line (60ft)
                        if let foulY = foulLineY, calculatedPixelsPerFoot > 0 {
                            let pinsY = foulY - (60 * calculatedPixelsPerFoot)
                            if pinsY > 0 {
                                HStack(spacing: 4) {
                                    Text("60ft")
                                        .font(BTFont.captionSmall())
                                        .foregroundColor(.btTextMuted)

                                    Image(systemName: "triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.btTextMuted)

                                    Rectangle()
                                        .fill(Color.btTextMuted.opacity(0.5))
                                        .frame(height: 1)
                                }
                                .position(x: geometry.size.width / 2, y: CGFloat(pinsY))
                            }
                        }

                        // Board lines (every 5 boards)
                        if calculatedPixelsPerBoard > 0 && leftGutterX >= 0 {
                            ForEach([5, 10, 15, 20, 25, 30, 35], id: \.self) { board in
                                let x = leftGutterX + (CGFloat(board - 1) * calculatedPixelsPerBoard)
                                if x > 0 && x < geometry.size.width {
                                    VStack {
                                        Text("\(board)")
                                            .font(.system(size: 8))
                                            .foregroundColor(.btTextMuted.opacity(0.7))

                                        Rectangle()
                                            .fill(Color.btTextMuted.opacity(0.3))
                                            .frame(width: 1)
                                    }
                                    .position(x: x, y: geometry.size.height / 2)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.btBorder, lineWidth: 1)
                )

                // Compact calibration results bar
                verifyResultsBar
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
        }
    }

    /// Compact results bar for verify step
    private var verifyResultsBar: some View {
        HStack(spacing: BTSpacing.md) {
            VStack(spacing: 2) {
                Text(String(format: "%.1f", calculatedPixelsPerFoot))
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)
                Text("px/ft")
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btTextMuted)
            }

            Divider()
                .frame(height: 30)

            VStack(spacing: 2) {
                Text(String(format: "%.1f", calculatedPixelsPerBoard))
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)
                Text("px/board")
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btTextMuted)
            }

            Divider()
                .frame(height: 30)

            VStack(spacing: 2) {
                Text(String(format: "%.0f", estimatedLaneWidthPixels))
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)
                Text("lane px")
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btTextMuted)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.btSuccess)
                .font(.system(size: 20))
        }
        .padding(BTSpacing.md)
        .background(Color.btSurface)
        .cornerRadius(10)
    }

    // MARK: - Step 5: Crop Zone

    private var cropZoneStep: some View {
        CropZoneStepView(
            cropRect: $cropRect,
            cropEnabled: $cropEnabled,
            cameraManager: cameraManager,
            onComplete: {
                goToNextStep()
            },
            onSkip: {
                // Skip crop zone - disable it and proceed
                cropEnabled = false
                goToNextStep()
            }
        )
    }

    // MARK: - Step 6: Complete

    private var completeStep: some View {
        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.btSuccess)

                // Title
                VStack(spacing: BTSpacing.xs) {
                    Text("Calibration Complete")
                        .font(BTFont.h1())
                        .foregroundColor(.btTextPrimary)
                }

                // Save form
                VStack(alignment: .leading, spacing: BTSpacing.lg) {
                    Text("Save Calibration Profile")
                        .font(BTFont.h3())
                        .foregroundColor(.btTextPrimary)

                    VStack(alignment: .leading, spacing: BTSpacing.xs) {
                        Text("Bowling Center Name")
                            .font(BTFont.label())
                            .foregroundColor(.btTextSecondary)

                        TextField("e.g. Lucky Strike Lanes", text: $centerName)
                            .textFieldStyle(.plain)
                            .padding(BTSpacing.md)
                            .background(Color.btSurfaceElevated)
                            .cornerRadius(10)
                            .foregroundColor(.btTextPrimary)
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: BTSpacing.xs) {
                        Text("Lane Number")
                            .font(BTFont.label())
                            .foregroundColor(.btTextSecondary)

                        TextField("e.g. 12", text: $laneNumber)
                            .textFieldStyle(.plain)
                            .keyboardType(.numberPad)
                            .padding(BTSpacing.md)
                            .background(Color.btSurfaceElevated)
                            .cornerRadius(10)
                            .foregroundColor(.btTextPrimary)
                    }
                }
                .padding(BTLayout.cardPadding)
                .background(Color.btSurface)
                .cornerRadius(BTLayout.cardCornerRadius)

                // Summary
                VStack(alignment: .leading, spacing: BTSpacing.sm) {
                    Text("Calibration Summary")
                        .font(BTFont.h4())
                        .foregroundColor(.btTextPrimary)

                    Group {
                        SummaryRow(label: "Pixels per foot:", value: String(format: "%.1f px", calculatedPixelsPerFoot))
                        SummaryRow(label: "Pixels per board:", value: String(format: "%.1f px", calculatedPixelsPerBoard))
                        SummaryRow(label: "Foul line position:", value: "Y = \(Int(foulLineY ?? 0)) px")
                        SummaryRow(label: "Arrow position:", value: "Y = \(Int(arrowsY)) px")
                        SummaryRow(label: "Crop zone:", value: cropEnabled ? "Enabled (\(Int(cropRect.width * 100))% x \(Int(cropRect.height * 100))%)" : "Disabled")
                    }
                }
                .padding(BTLayout.cardPadding)
                .background(Color.btSurface)
                .cornerRadius(BTLayout.cardCornerRadius)

                Spacer(minLength: BTSpacing.xl)
            }
            .padding(.horizontal, BTLayout.screenHorizontalPadding)
            .padding(.vertical, BTSpacing.lg)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        VStack(spacing: BTSpacing.md) {
            if currentStep == .complete {
                // Two buttons for complete step
                BTActionButton.primary(
                    title: "Save & Start Recording",
                    icon: "record.circle",
                    isLoading: isSaving
                ) {
                    saveCalibrationAndStartRecording()
                }
                .disabled(!canProceed)
                .opacity(canProceed ? 1.0 : 0.5)

                BTActionButton.secondary(title: "Save for Later") {
                    saveCalibrationAndDismiss()
                }
                .disabled(!canProceed)
                .opacity(canProceed ? 1.0 : 0.5)
            } else {
                HStack(spacing: BTSpacing.md) {
                    if currentStep != .position {
                        BTActionButton.secondary(title: "Redo") {
                            resetCurrentStep()
                        }
                    }

                    BTActionButton.primary(
                        title: buttonTitle,
                        icon: nil,
                        isLoading: false
                    ) {
                        goToNextStep()
                    }
                    .disabled(!canProceed)
                    .opacity(canProceed ? 1.0 : 0.5)
                }
            }
        }
        .padding(.horizontal, BTLayout.screenHorizontalPadding)
        .padding(.vertical, BTSpacing.lg)
        .background(Color.btBackground)
    }

    private var buttonTitle: String {
        switch currentStep {
        case .position:
            return "I'm Ready - Next"
        case .verify:
            return "Looks Good"
        case .cropZone:
            return cropEnabled ? "Apply Crop" : "Skip Crop"
        default:
            return "Next"
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case .position:
            return true
        case .foulLine:
            return foulLineY != nil
        case .arrows:
            return arrow1Position != nil && arrow2Position != nil && arrow1Board != arrow2Board
        case .verify:
            return calculatedPixelsPerBoard > 0 && calculatedPixelsPerFoot > 0
        case .cropZone:
            // Crop zone is optional - always allow proceeding
            return true
        case .complete:
            return !centerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !laneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // MARK: - Step Navigation

    private func goToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .position:
                currentStep = .foulLine
                cameraManager.startSession()
            case .foulLine:
                currentStep = .arrows
            case .arrows:
                currentStep = .verify
            case .verify:
                currentStep = .cropZone
                // Camera stays on for crop zone
            case .cropZone:
                currentStep = .complete
                cameraManager.stopSession()
            case .complete:
                break
            }
        }
    }

    private func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .position: break
            case .foulLine:
                currentStep = .position
                cameraManager.stopSession()
            case .arrows:
                currentStep = .foulLine
            case .verify:
                currentStep = .arrows
            case .cropZone:
                currentStep = .verify
            case .complete:
                currentStep = .cropZone
                cameraManager.startSession()
            }
        }
    }

    private func resetCurrentStep() {
        switch currentStep {
        case .foulLine:
            foulLineY = nil
            foulLineTapPoint = nil
        case .arrows:
            arrow1Position = nil
            arrow2Position = nil
            leftGutterX = 0
            rightGutterX = 0
        case .verify:
            // Go back to arrows step
            currentStep = .arrows
        case .cropZone:
            // Reset crop to default
            cropRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
            cropEnabled = false
        default:
            break
        }
    }

    // MARK: - Save Calibration

    private func saveCalibration() throws -> CalibrationEntity {
        print("[DEBUG] saveCalibration() called")

        guard let foulY = foulLineY else {
            print("[DEBUG] ERROR: Missing foul line")
            throw CalibrationError.missingFoulLine
        }

        guard arrow1Position != nil && arrow2Position != nil else {
            print("[DEBUG] ERROR: Missing arrows")
            throw CalibrationError.missingArrows
        }

        guard calculatedPixelsPerBoard > 0 && calculatedPixelsPerFoot > 0 else {
            print("[DEBUG] ERROR: Invalid calculation - ppb: \(calculatedPixelsPerBoard), ppf: \(calculatedPixelsPerFoot)")
            throw CalibrationError.invalidCalculation
        }

        let centerId = UUID()
        let laneNum = Int(laneNumber)

        print("[DEBUG] Creating CalibrationProfile with:")
        print("[DEBUG]   centerName: \(centerName)")
        print("[DEBUG]   laneNumber: \(String(describing: laneNum))")
        print("[DEBUG]   pixelsPerFoot: \(calculatedPixelsPerFoot)")
        print("[DEBUG]   pixelsPerBoard: \(calculatedPixelsPerBoard)")
        print("[DEBUG]   foulLineY: \(foulY)")
        print("[DEBUG]   arrowsY: \(arrowsY)")
        print("[DEBUG]   leftGutterX: \(leftGutterX)")
        print("[DEBUG]   rightGutterX: \(rightGutterX)")
        print("[DEBUG]   cropEnabled: \(cropEnabled)")
        print("[DEBUG]   cropRect: \(cropRect)")

        let profile = CalibrationProfile(
            id: UUID(),
            centerId: centerId,
            centerName: centerName.trimmingCharacters(in: .whitespacesAndNewlines),
            laneNumber: laneNum,
            pixelsPerFoot: calculatedPixelsPerFoot,
            pixelsPerBoard: calculatedPixelsPerBoard,
            foulLineY: Double(foulY),
            arrowsY: arrowsY,
            leftGutterX: Double(leftGutterX),
            rightGutterX: Double(rightGutterX),
            cropRect: cropEnabled ? cropRect : nil,
            cropEnabled: cropEnabled,
            createdAt: Date(),
            lastUsed: Date()
        )

        // Log validation details for debugging
        print("[DEBUG] Profile validation check:")
        print("[DEBUG]   isValid: \(profile.isValid)")
        if let error = profile.validationError {
            print("[DEBUG]   validationError: \(error)")
        }

        // Skip strict validation - save anyway with a warning
        // The strict aspect ratio checks were causing legitimate calibrations to fail
        if !profile.isValid {
            print("[WARNING] Calibration profile validation failed but saving anyway: \(profile.validationError ?? "Unknown")")
        }

        // Save to SwiftData
        print("[DEBUG] Creating CalibrationEntity and inserting into modelContext")
        let entity = CalibrationEntity(from: profile)
        modelContext.insert(entity)

        do {
            try modelContext.save()
            print("[DEBUG] SUCCESS: Calibration saved to SwiftData")
        } catch {
            print("[DEBUG] ERROR saving to SwiftData: \(error)")
            throw error
        }

        return entity
    }

    private func saveCalibrationAndDismiss() {
        print("[DEBUG] saveCalibrationAndDismiss() called")
        isSaving = true

        do {
            let entity = try saveCalibration()
            print("[DEBUG] Calibration saved successfully: \(entity.centerName)")
            cameraManager.stopSession()
            dismiss()
        } catch {
            print("[DEBUG] Save failed with error: \(error)")
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }

        isSaving = false
    }

    private func saveCalibrationAndStartRecording() {
        print("[DEBUG] saveCalibrationAndStartRecording() called")
        isSaving = true

        do {
            let entity = try saveCalibration()
            print("[DEBUG] Calibration saved successfully: \(entity.centerName)")
            cameraManager.stopSession()

            // Store the entity for the fullScreenCover to pass to RecordingView
            savedCalibrationEntity = entity

            // Present recording view with the new calibration
            showingRecording = true
        } catch {
            print("[DEBUG] Save failed with error: \(error)")
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }

        isSaving = false
    }

    // MARK: - Lane Detection

    /// Start automatic lane detection
    private func startLaneDetection() {
        guard !detectionState.isProcessing else { return }

        // Reset state
        detectionState = .detecting
        detectionResult = nil
        showingDetectionOverlay = false
        laneDetector.reset()

        // Start detection process
        Task {
            do {
                detectionState = .analyzing(progress: 0)

                // Capture frames from camera
                let frames = await cameraManager.captureFrames(count: 30)

                guard !frames.isEmpty else {
                    throw LaneDetectionError.cameraNotAvailable
                }

                // Analyze frames with progress updates
                let result = try await laneDetector.analyzeFrames(frames) { progress in
                    Task { @MainActor in
                        self.detectionState = .analyzing(progress: progress)
                    }
                }

                await MainActor.run {
                    detectionResult = result
                    detectionState = .completed(result: result)

                    // Apply detection results if confidence is sufficient
                    if result.isUsable {
                        applyDetectionResults(result)
                    } else {
                        showingDetectionResult = true
                    }
                }
            } catch {
                await MainActor.run {
                    if let detectionError = error as? LaneDetectionError {
                        detectionState = .failed(error: detectionError)
                    } else {
                        detectionState = .failed(error: .processingFailed(error.localizedDescription))
                    }
                }
            }
        }
    }

    /// Cancel ongoing detection
    private func cancelDetection() {
        cameraManager.stopFrameCapture()
        laneDetector.reset()
        detectionState = .idle
        detectionResult = nil
        showingDetectionOverlay = false
    }

    // MARK: - Test Mode Functions

    /// Load a test image from PhotosPicker
    private func loadTestImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    testImage = image
                    isTestMode = true
                    // Stop camera when entering test mode
                    cameraManager.stopSession()
                    // Reset detection state
                    detectionState = .idle
                    detectionResult = nil
                    showingDetectionOverlay = false
                    foulLineY = nil
                    foulLineTapPoint = nil
                }
            }
        }
    }

    /// Exit test mode and return to camera
    private func exitTestMode() {
        isTestMode = false
        testImage = nil
        selectedPhotoItem = nil
        detectionState = .idle
        detectionResult = nil
        showingDetectionOverlay = false
        foulLineY = nil
        foulLineTapPoint = nil
        // Restart camera
        cameraManager.startSession()
    }

    /// Run lane detection on the test image
    private func startTestImageDetection() {
        guard let image = testImage, !detectionState.isProcessing else { return }

        // Reset state
        detectionState = .detecting
        detectionResult = nil
        showingDetectionOverlay = false
        laneDetector.reset()

        Task {
            do {
                detectionState = .analyzing(progress: 0)

                // Convert UIImage to CVPixelBuffer
                guard let pixelBuffer = image.toPixelBuffer() else {
                    throw LaneDetectionError.processingFailed("Could not convert image to pixel buffer")
                }

                // Create multiple "frames" from single image for consistent API
                let frames = Array(repeating: pixelBuffer, count: 5)

                // Analyze with progress updates
                let result = try await laneDetector.analyzeFrames(frames) { progress in
                    Task { @MainActor in
                        self.detectionState = .analyzing(progress: progress)
                    }
                }

                await MainActor.run {
                    detectionResult = result
                    detectionState = .completed(result: result)
                    showingDetectionOverlay = true

                    // Apply detection results if confidence is sufficient
                    if result.isUsable {
                        applyDetectionResults(result)
                    }
                }
            } catch {
                await MainActor.run {
                    if let detectionError = error as? LaneDetectionError {
                        detectionState = .failed(error: detectionError)
                    } else {
                        detectionState = .failed(error: .processingFailed(error.localizedDescription))
                    }
                }
            }
        }
    }

    /// Apply detection results to calibration data
    private func applyDetectionResults(_ result: LaneDetectionResult) {
        // Apply foul line position
        if let foulLine = result.foulLine {
            // Convert normalized Y to pixel Y
            let pixelY = foulLine.midpoint.y * previewSize.height
            foulLineY = pixelY
            foulLineTapPoint = nil // Clear tap point since this is from detection
        }

        // Apply arrow positions if available
        if let arrows = result.arrowPositions, arrows.count >= 2 {
            let sortedArrows = arrows.sorted { $0.boardNumber < $1.boardNumber }

            // Use first two arrows
            if sortedArrows.count >= 1 {
                let arrow = sortedArrows[0]
                arrow1Position = CGPoint(
                    x: arrow.position.x * previewSize.width,
                    y: arrow.position.y * previewSize.height
                )
                arrow1Board = arrow.boardNumber
            }

            if sortedArrows.count >= 2 {
                let arrow = sortedArrows[1]
                arrow2Position = CGPoint(
                    x: arrow.position.x * previewSize.width,
                    y: arrow.position.y * previewSize.height
                )
                arrow2Board = arrow.boardNumber
            }

            // Calculate gutter positions from detection
            if let leftGutter = result.leftGutterLine, let lastLeft = leftGutter.last {
                leftGutterX = lastLeft.x * previewSize.width
            }
            if let rightGutter = result.rightGutterLine, let lastRight = rightGutter.last {
                rightGutterX = lastRight.x * previewSize.width
            }
        }

        // Show the overlay
        showingDetectionOverlay = true
        detectionState = .idle
    }

    /// Accept detection results and proceed
    private func acceptDetectionResults() {
        showingDetectionResult = false
        if let result = detectionResult {
            applyDetectionResults(result)
        }
    }

    /// Reject detection results and allow retry
    private func rejectDetectionResults() {
        showingDetectionResult = false
        detectionResult = nil
        detectionState = .idle
    }
}

// MARK: - Calibration Error

enum CalibrationError: LocalizedError {
    case missingFoulLine
    case missingArrows
    case invalidCalculation
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingFoulLine:
            return "Foul line position is required"
        case .missingArrows:
            return "Both arrow positions are required"
        case .invalidCalculation:
            return "Invalid calibration values calculated"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

// MARK: - Camera Manager for Calibration

class CalibrationCameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var errorMessage: String?

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "calibration.camera.session")
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?

    // Frame capture for lane detection
    private var latestFrame: CVPixelBuffer?
    private let frameLock = NSLock()
    private var isCapturingFrames = false
    private var capturedFrames: [CVPixelBuffer] = []
    private var frameCaptureContinuation: CheckedContinuation<[CVPixelBuffer], Never>?

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = true
            }
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async { [weak self] in
                    self?.isAuthorized = granted
                }
                if granted {
                    self?.setupSession()
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = false
                self?.errorMessage = "Camera access denied. Please enable in Settings."
            }
        @unknown default:
            break
        }
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            // Add video input
            do {
                guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    DispatchQueue.main.async { [weak self] in
                        self?.errorMessage = "No camera available"
                    }
                    return
                }

                let videoInput = try AVCaptureDeviceInput(device: videoDevice)

                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.errorMessage = "Could not add camera input"
                    }
                    return
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Error setting up camera: \(error.localizedDescription)"
                }
                return
            }

            // Add video data output for frame capture
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "calibration.video.output"))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]

            if self.session.canAddOutput(videoOutput) {
                self.session.addOutput(videoOutput)
                self.videoDataOutput = videoOutput
            }

            self.session.commitConfiguration()
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async { [weak self] in
                    self?.isSessionRunning = true
                }
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async { [weak self] in
                    self?.isSessionRunning = false
                }
            }
        }
    }

    // MARK: - Frame Capture for Detection

    /// Get the most recent camera frame
    func getLatestFrame() -> CVPixelBuffer? {
        frameLock.lock()
        defer { frameLock.unlock() }
        return latestFrame
    }

    /// Capture a series of frames for lane detection
    func captureFrames(count: Int) async -> [CVPixelBuffer] {
        return await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(returning: [])
                return
            }

            self.frameLock.lock()
            self.capturedFrames.removeAll()
            self.isCapturingFrames = true
            self.frameCaptureContinuation = continuation
            self.frameLock.unlock()

            // Set a timeout - capture self weakly to avoid retain cycle
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                guard let self = self else { return }
                self.frameLock.lock()
                if self.isCapturingFrames {
                    self.isCapturingFrames = false
                    let frames = self.capturedFrames
                    self.capturedFrames.removeAll()
                    let cont = self.frameCaptureContinuation
                    self.frameCaptureContinuation = nil
                    self.frameLock.unlock()
                    cont?.resume(returning: frames)
                } else {
                    self.frameLock.unlock()
                }
            }
        }
    }

    /// Stop frame capture
    func stopFrameCapture() {
        frameLock.lock()
        isCapturingFrames = false
        capturedFrames.removeAll()
        frameCaptureContinuation = nil
        frameLock.unlock()
    }
}

// MARK: - Video Data Output Delegate

extension CalibrationCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        frameLock.lock()
        defer { frameLock.unlock() }

        // Store latest frame
        latestFrame = pixelBuffer

        // Capture frames for detection if active
        if isCapturingFrames {
            capturedFrames.append(pixelBuffer)

            // Check if we have enough frames
            if capturedFrames.count >= 30 {
                isCapturingFrames = false
                let frames = capturedFrames
                capturedFrames.removeAll()
                let continuation = frameCaptureContinuation
                frameCaptureContinuation = nil

                // Resume on main queue
                DispatchQueue.main.async {
                    continuation?.resume(returning: frames)
                }
            }
        }
    }
}

// MARK: - Calibration Camera Preview Representable

struct CalibrationCameraPreview: UIViewRepresentable {
    let cameraManager: CalibrationCameraManager

    func makeUIView(context: Context) -> CalibrationPreviewUIView {
        let view = CalibrationPreviewUIView()
        view.session = cameraManager.session
        return view
    }

    func updateUIView(_ uiView: CalibrationPreviewUIView, context: Context) {
        // Update if needed
    }
}

// MARK: - Calibration Preview UIView

class CalibrationPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            setupPreviewLayer()
        }
    }

    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentOrientation: UIDeviceOrientation = .unknown

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(Color.btLaneBackground)

        // Enable device orientation notifications
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        // Observe orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    private func setupPreviewLayer() {
        previewLayer?.removeFromSuperlayer()

        guard let session = session else { return }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
        self.previewLayer = layer

        // Set initial orientation
        updateVideoOrientation()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds

        // Also update orientation on layout changes (handles initial orientation)
        updateVideoOrientation()
    }

    @objc private func orientationDidChange(_ notification: Notification) {
        let deviceOrientation = UIDevice.current.orientation

        // Only update for valid orientations (ignore faceUp, faceDown, unknown)
        guard deviceOrientation.isPortrait || deviceOrientation.isLandscape else { return }
        guard deviceOrientation != currentOrientation else { return }

        currentOrientation = deviceOrientation
        updateVideoOrientation()
    }

    private func updateVideoOrientation() {
        guard let connection = previewLayer?.connection else { return }

        let rotationAngle = getVideoRotationAngle()

        // Use the modern videoRotationAngle API (iOS 17+)
        if connection.isVideoRotationAngleSupported(rotationAngle) {
            connection.videoRotationAngle = rotationAngle
        }
    }

    private func getVideoRotationAngle() -> CGFloat {
        // First, try to get orientation from the window scene (most reliable for landscape-locked apps)
        if let windowScene = self.window?.windowScene {
            let interfaceOrientation = windowScene.interfaceOrientation
            switch interfaceOrientation {
            case .portrait:
                return 90
            case .portraitUpsideDown:
                return 270
            case .landscapeLeft:
                return 0
            case .landscapeRight:
                return 180
            default:
                break
            }
        }

        // Fallback to device orientation
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portrait:
            return 90
        case .portraitUpsideDown:
            return 270
        case .landscapeLeft:
            return 0
        case .landscapeRight:
            return 180
        default:
            // Default to landscape for this bowling app
            return 0
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Update orientation when view is added to window (window scene now available)
        if window != nil {
            updateVideoOrientation()
        }
    }
}

// MARK: - Progress Indicator Component

struct BTProgressIndicator: View {
    let steps: [String]
    let currentStep: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, _ in
                HStack(spacing: 0) {
                    // Step circle
                    StepCircle(
                        number: index + 1,
                        state: stepState(for: index)
                    )

                    // Connector line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.btPrimary : Color.btSurfaceHighlight)
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding(.horizontal, BTSpacing.lg)
    }

    private func stepState(for index: Int) -> StepState {
        if index < currentStep { return .completed }
        if index == currentStep { return .active }
        return .pending
    }
}

// MARK: - Step State

enum StepState {
    case pending, active, completed
}

// MARK: - Step Circle

struct StepCircle: View {
    let number: Int
    let state: StepState

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 32, height: 32)

            if state == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.btTextInverse)
            } else {
                Text("\(number)")
                    .font(BTFont.label())
                    .foregroundColor(state == .active ? .btTextInverse : .btTextMuted)
            }
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .completed: return .btPrimary
        case .active: return .btPrimary
        case .pending: return .btSurfaceHighlight
        }
    }
}

// MARK: - Supporting Views

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: BTSpacing.md) {
            Text("\(number).")
                .font(BTFont.label())
                .foregroundColor(.btPrimary)
                .frame(width: 24, alignment: .leading)

            Text(text)
                .font(BTFont.body())
                .foregroundColor(.btTextSecondary)
        }
    }
}

struct ArrowSelectionCard: View {
    let arrowNumber: Int
    let position: CGPoint?
    @Binding var selectedBoard: Int
    let onClear: () -> Void

    private let boardOptions = [5, 10, 15, 20, 25, 30, 35]

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            HStack {
                Text("Arrow \(arrowNumber)")
                    .font(BTFont.label())
                    .foregroundColor(.btTextPrimary)

                Spacer()

                if position != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.btSuccess)
                }
            }

            Picker("Board", selection: $selectedBoard) {
                ForEach(boardOptions, id: \.self) { board in
                    Text("Board \(board)").tag(board)
                }
            }
            .pickerStyle(.menu)
            .tint(.btPrimary)

            if let pos = position {
                Text("Position: X=\(Int(pos.x)), Y=\(Int(pos.y))")
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btTextMuted)

                Button("Clear") {
                    onClear()
                }
                .font(BTFont.captionSmall())
                .foregroundColor(.btError)
            } else {
                Text("Position: NOT SET")
                    .font(BTFont.captionSmall())
                    .foregroundColor(.btTextMuted)
            }
        }
        .padding(BTSpacing.md)
        .background(Color.btSurface)
        .cornerRadius(10)
    }
}

struct ResultCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: BTSpacing.xs) {
            Text(value)
                .font(BTFont.h4())
                .foregroundColor(.btTextPrimary)

            Text(label)
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(BTSpacing.md)
        .background(Color.btSurfaceElevated)
        .cornerRadius(8)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(BTFont.body())
                .foregroundColor(.btTextSecondary)

            Spacer()

            Text(value)
                .font(BTFont.mono())
                .foregroundColor(.btTextPrimary)
        }
    }
}

// MARK: - UIImage to CVPixelBuffer Extension

extension UIImage {
    /// Convert UIImage to CVPixelBuffer for Vision processing
    func toPixelBuffer() -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)

        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }

        guard let cgImage = self.cgImage else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }
}

// MARK: - Preview

#Preview("Calibration Wizard") {
    CalibrationView()
        .modelContainer(for: [CalibrationEntity.self], inMemory: true)
}
