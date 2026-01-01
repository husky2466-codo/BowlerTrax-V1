//
//  CropZoneEditor.swift
//  BowlerTrax
//
//  Interactive crop zone editor for calibration
//  Allows users to define a crop rectangle over the camera preview
//

import SwiftUI

// MARK: - Crop Zone Editor

struct CropZoneEditor: View {
    // MARK: - Properties

    @Binding var cropRect: CGRect
    @Binding var cropEnabled: Bool
    let previewContent: AnyView
    let onComplete: (CGRect, Bool) -> Void
    let onSkip: () -> Void

    // MARK: - State

    @State private var viewSize: CGSize = .zero
    @State private var isDragging = false
    @State private var activeHandle: CropHandle? = nil
    @State private var dragStartRect: CGRect = .zero
    @State private var dragStartPoint: CGPoint = .zero
    @State private var showGrid: Bool = true
    @State private var maintainAspectRatio: Bool = false

    // MARK: - Constants

    private let handleSize: CGFloat = 24
    private let minCropSize: CGFloat = 0.1  // Minimum 10% of view dimension
    private let edgeInset: CGFloat = 2      // Inset from view edges

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background preview
                previewContent
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Dark overlay outside crop area
                cropOverlay(in: geometry.size)

                // Crop rectangle with handles
                cropRectangle(in: geometry.size)
            }
            .onAppear {
                viewSize = geometry.size
                // Initialize with default crop if not set
                if cropRect == .zero {
                    cropRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                viewSize = newSize
            }
        }
    }

    // MARK: - Crop Overlay

    @ViewBuilder
    private func cropOverlay(in size: CGSize) -> some View {
        let pixelRect = normalizedToPixel(cropRect, in: size)

        // Semi-transparent overlay with cutout
        ZStack {
            // Full overlay
            Color.black.opacity(0.6)

            // Clear cutout (using blend mode)
            Rectangle()
                .frame(width: pixelRect.width, height: pixelRect.height)
                .position(
                    x: pixelRect.midX,
                    y: pixelRect.midY
                )
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .allowsHitTesting(false)
    }

    // MARK: - Crop Rectangle

    @ViewBuilder
    private func cropRectangle(in size: CGSize) -> some View {
        let pixelRect = normalizedToPixel(cropRect, in: size)

        ZStack {
            // Border
            Rectangle()
                .strokeBorder(Color.btPrimary, lineWidth: 2)
                .frame(width: pixelRect.width, height: pixelRect.height)
                .position(x: pixelRect.midX, y: pixelRect.midY)

            // Grid lines inside crop area
            if showGrid {
                gridLines(in: pixelRect)
            }

            // Corner handles
            ForEach(CropHandle.corners, id: \.self) { handle in
                handleView(for: handle, in: size)
            }

            // Edge handles
            ForEach(CropHandle.edges, id: \.self) { handle in
                handleView(for: handle, in: size)
            }

            // Center drag area (invisible, larger hit area)
            Rectangle()
                .fill(Color.clear)
                .frame(width: max(pixelRect.width - handleSize * 2, 44),
                       height: max(pixelRect.height - handleSize * 2, 44))
                .position(x: pixelRect.midX, y: pixelRect.midY)
                .contentShape(Rectangle())
                .gesture(centerDragGesture(in: size))
        }
    }

    // MARK: - Grid Lines

    @ViewBuilder
    private func gridLines(in rect: CGRect) -> some View {
        let thirdWidth = rect.width / 3
        let thirdHeight = rect.height / 3

        // Vertical lines
        ForEach(1..<3, id: \.self) { i in
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: rect.height)
                .position(
                    x: rect.minX + CGFloat(i) * thirdWidth,
                    y: rect.midY
                )
        }

        // Horizontal lines
        ForEach(1..<3, id: \.self) { i in
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: rect.width, height: 1)
                .position(
                    x: rect.midX,
                    y: rect.minY + CGFloat(i) * thirdHeight
                )
        }
    }

    // MARK: - Handle View

    @ViewBuilder
    private func handleView(for handle: CropHandle, in size: CGSize) -> some View {
        let position = handlePosition(for: handle, in: size)

        ZStack {
            // Handle circle
            Circle()
                .fill(Color.btPrimary)
                .frame(width: handleSize, height: handleSize)

            // Inner circle
            Circle()
                .fill(Color.white)
                .frame(width: handleSize - 6, height: handleSize - 6)
        }
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        .position(position)
        .gesture(handleDragGesture(for: handle, in: size))
    }

    // MARK: - Handle Position

    private func handlePosition(for handle: CropHandle, in size: CGSize) -> CGPoint {
        let pixelRect = normalizedToPixel(cropRect, in: size)

        switch handle {
        case .topLeft:
            return CGPoint(x: pixelRect.minX, y: pixelRect.minY)
        case .topRight:
            return CGPoint(x: pixelRect.maxX, y: pixelRect.minY)
        case .bottomLeft:
            return CGPoint(x: pixelRect.minX, y: pixelRect.maxY)
        case .bottomRight:
            return CGPoint(x: pixelRect.maxX, y: pixelRect.maxY)
        case .top:
            return CGPoint(x: pixelRect.midX, y: pixelRect.minY)
        case .bottom:
            return CGPoint(x: pixelRect.midX, y: pixelRect.maxY)
        case .left:
            return CGPoint(x: pixelRect.minX, y: pixelRect.midY)
        case .right:
            return CGPoint(x: pixelRect.maxX, y: pixelRect.midY)
        }
    }

    // MARK: - Handle Drag Gesture

    private func handleDragGesture(for handle: CropHandle, in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    activeHandle = handle
                    dragStartRect = cropRect
                    dragStartPoint = value.startLocation
                }

                let delta = CGPoint(
                    x: value.location.x - dragStartPoint.x,
                    y: value.location.y - dragStartPoint.y
                )

                // Convert delta to normalized coordinates
                let normalizedDelta = CGPoint(
                    x: delta.x / size.width,
                    y: delta.y / size.height
                )

                updateCropRect(for: handle, delta: normalizedDelta)
            }
            .onEnded { _ in
                isDragging = false
                activeHandle = nil
            }
    }

    // MARK: - Center Drag Gesture

    private func centerDragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    activeHandle = nil
                    dragStartRect = cropRect
                    dragStartPoint = value.startLocation
                }

                let delta = CGPoint(
                    x: value.location.x - dragStartPoint.x,
                    y: value.location.y - dragStartPoint.y
                )

                // Convert delta to normalized coordinates
                let normalizedDelta = CGPoint(
                    x: delta.x / size.width,
                    y: delta.y / size.height
                )

                // Move entire rectangle
                var newRect = dragStartRect
                newRect.origin.x = clamp(
                    dragStartRect.origin.x + normalizedDelta.x,
                    min: 0,
                    max: 1 - dragStartRect.width
                )
                newRect.origin.y = clamp(
                    dragStartRect.origin.y + normalizedDelta.y,
                    min: 0,
                    max: 1 - dragStartRect.height
                )

                cropRect = newRect
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    // MARK: - Update Crop Rect

    private func updateCropRect(for handle: CropHandle, delta: CGPoint) {
        var newRect = dragStartRect

        switch handle {
        case .topLeft:
            let newX = clamp(dragStartRect.minX + delta.x, min: 0, max: dragStartRect.maxX - minCropSize)
            let newY = clamp(dragStartRect.minY + delta.y, min: 0, max: dragStartRect.maxY - minCropSize)
            newRect = CGRect(
                x: newX,
                y: newY,
                width: dragStartRect.maxX - newX,
                height: dragStartRect.maxY - newY
            )

        case .topRight:
            let newMaxX = clamp(dragStartRect.maxX + delta.x, min: dragStartRect.minX + minCropSize, max: 1)
            let newY = clamp(dragStartRect.minY + delta.y, min: 0, max: dragStartRect.maxY - minCropSize)
            newRect = CGRect(
                x: dragStartRect.minX,
                y: newY,
                width: newMaxX - dragStartRect.minX,
                height: dragStartRect.maxY - newY
            )

        case .bottomLeft:
            let newX = clamp(dragStartRect.minX + delta.x, min: 0, max: dragStartRect.maxX - minCropSize)
            let newMaxY = clamp(dragStartRect.maxY + delta.y, min: dragStartRect.minY + minCropSize, max: 1)
            newRect = CGRect(
                x: newX,
                y: dragStartRect.minY,
                width: dragStartRect.maxX - newX,
                height: newMaxY - dragStartRect.minY
            )

        case .bottomRight:
            let newMaxX = clamp(dragStartRect.maxX + delta.x, min: dragStartRect.minX + minCropSize, max: 1)
            let newMaxY = clamp(dragStartRect.maxY + delta.y, min: dragStartRect.minY + minCropSize, max: 1)
            newRect = CGRect(
                x: dragStartRect.minX,
                y: dragStartRect.minY,
                width: newMaxX - dragStartRect.minX,
                height: newMaxY - dragStartRect.minY
            )

        case .top:
            let newY = clamp(dragStartRect.minY + delta.y, min: 0, max: dragStartRect.maxY - minCropSize)
            newRect = CGRect(
                x: dragStartRect.minX,
                y: newY,
                width: dragStartRect.width,
                height: dragStartRect.maxY - newY
            )

        case .bottom:
            let newMaxY = clamp(dragStartRect.maxY + delta.y, min: dragStartRect.minY + minCropSize, max: 1)
            newRect = CGRect(
                x: dragStartRect.minX,
                y: dragStartRect.minY,
                width: dragStartRect.width,
                height: newMaxY - dragStartRect.minY
            )

        case .left:
            let newX = clamp(dragStartRect.minX + delta.x, min: 0, max: dragStartRect.maxX - minCropSize)
            newRect = CGRect(
                x: newX,
                y: dragStartRect.minY,
                width: dragStartRect.maxX - newX,
                height: dragStartRect.height
            )

        case .right:
            let newMaxX = clamp(dragStartRect.maxX + delta.x, min: dragStartRect.minX + minCropSize, max: 1)
            newRect = CGRect(
                x: dragStartRect.minX,
                y: dragStartRect.minY,
                width: newMaxX - dragStartRect.minX,
                height: dragStartRect.height
            )
        }

        cropRect = newRect
    }

    // MARK: - Helper Functions

    private func normalizedToPixel(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: rect.origin.x * size.width,
            y: rect.origin.y * size.height,
            width: rect.width * size.width,
            height: rect.height * size.height
        )
    }

    private func clamp(_ value: CGFloat, min minVal: CGFloat, max maxVal: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minVal), maxVal)
    }
}

// MARK: - Crop Handle Enum

enum CropHandle: String, CaseIterable {
    // Corners
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    // Edges
    case top
    case bottom
    case left
    case right

    static var corners: [CropHandle] {
        [.topLeft, .topRight, .bottomLeft, .bottomRight]
    }

    static var edges: [CropHandle] {
        [.top, .bottom, .left, .right]
    }
}

// MARK: - Crop Zone Step View

/// Full-screen view for the crop zone calibration step
struct CropZoneStepView: View {
    // MARK: - Properties

    @Binding var cropRect: CGRect
    @Binding var cropEnabled: Bool
    let cameraManager: CalibrationCameraManager
    let onComplete: () -> Void
    let onSkip: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: BTSpacing.md) {
            // Title section
            VStack(spacing: BTSpacing.xs) {
                Text("Set Crop Zone")
                    .font(BTFont.h2())
                    .foregroundColor(.btTextPrimary)

                Text("Optionally crop the camera view to focus on the lane")
                    .font(BTFont.body())
                    .foregroundColor(.btTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: false, vertical: true)

            // Crop editor
            ZStack {
                CropZoneEditor(
                    cropRect: $cropRect,
                    cropEnabled: $cropEnabled,
                    previewContent: AnyView(
                        CalibrationCameraPreview(cameraManager: cameraManager)
                    ),
                    onComplete: { rect, enabled in
                        cropRect = rect
                        cropEnabled = enabled
                        onComplete()
                    },
                    onSkip: onSkip
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.btBorder, lineWidth: 1)
            )

            // Controls section
            VStack(spacing: BTSpacing.md) {
                // Enable/disable toggle
                HStack {
                    Toggle(isOn: $cropEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Crop Zone")
                                .font(BTFont.label())
                                .foregroundColor(.btTextPrimary)

                            Text("Focus tracking on selected area only")
                                .font(BTFont.captionSmall())
                                .foregroundColor(.btTextMuted)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .btPrimary))
                }
                .padding(BTSpacing.md)
                .background(Color.btSurface)
                .cornerRadius(10)

                // Crop info when enabled
                if cropEnabled {
                    HStack(spacing: BTSpacing.lg) {
                        CropInfoBadge(
                            label: "Width",
                            value: "\(Int(cropRect.width * 100))%"
                        )
                        CropInfoBadge(
                            label: "Height",
                            value: "\(Int(cropRect.height * 100))%"
                        )
                        CropInfoBadge(
                            label: "Position",
                            value: "(\(Int(cropRect.origin.x * 100))%, \(Int(cropRect.origin.y * 100))%)"
                        )

                        Spacer()

                        // Reset button
                        Button {
                            withAnimation {
                                cropRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
                            }
                        } label: {
                            HStack(spacing: BTSpacing.xs) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(BTFont.labelSmall())
                            .foregroundColor(.btPrimary)
                        }
                    }
                    .padding(BTSpacing.sm)
                    .background(Color.btSurfaceElevated)
                    .cornerRadius(8)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, BTLayout.screenHorizontalPadding)
    }
}

// MARK: - Crop Info Badge

struct CropInfoBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(BTFont.label())
                .foregroundColor(.btTextPrimary)
            Text(label)
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)
        }
    }
}

// MARK: - Preview

#Preview("Crop Zone Editor") {
    ZStack {
        Color.btBackground.ignoresSafeArea()

        CropZoneStepView(
            cropRect: .constant(CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)),
            cropEnabled: .constant(true),
            cameraManager: CalibrationCameraManager(),
            onComplete: {},
            onSkip: {}
        )
    }
}
