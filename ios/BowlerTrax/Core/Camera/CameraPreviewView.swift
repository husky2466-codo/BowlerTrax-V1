//
//  CameraPreviewView.swift
//  BowlerTrax
//
//  UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer.
//  Provides SwiftUI-compatible camera preview with proper sizing and orientation.
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - Camera Preview View

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer
struct CameraPreviewView: UIViewRepresentable {
    // MARK: - Properties

    /// The camera session manager providing the capture session
    @ObservedObject var cameraManager: CameraSessionManager

    /// Video gravity for the preview layer
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill

    /// Whether to mirror the preview (typically for front camera)
    var isMirrored: Bool = false

    /// Background color when camera is not running
    var backgroundColor: UIColor = .black

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = backgroundColor
        view.setupPreviewLayer(
            session: cameraManager.captureSession,
            videoGravity: videoGravity
        )
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update video gravity if changed
        uiView.previewLayer?.videoGravity = videoGravity

        // Update mirroring for front camera
        if let connection = uiView.previewLayer?.connection {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = isMirrored
            }
        }

        // Ensure layer is connected to session
        if uiView.previewLayer?.session !== cameraManager.captureSession {
            uiView.previewLayer?.session = cameraManager.captureSession
        }
    }

    static func dismantleUIView(_ uiView: CameraPreviewUIView, coordinator: ()) {
        uiView.previewLayer?.session = nil
    }
}

// MARK: - Camera Preview UIView

/// UIView subclass that properly manages AVCaptureVideoPreviewLayer
class CameraPreviewUIView: UIView {
    // MARK: - Properties

    /// The preview layer displaying the camera feed
    var previewLayer: AVCaptureVideoPreviewLayer?

    /// Current device orientation
    private var currentOrientation: UIDeviceOrientation = .unknown

    // MARK: - Layer Setup

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    /// Setup the preview layer with a capture session
    func setupPreviewLayer(session: AVCaptureSession, videoGravity: AVLayerVideoGravity) {
        // Remove existing preview layer if any
        previewLayer?.removeFromSuperlayer()

        // Create new preview layer
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = videoGravity
        layer.frame = bounds

        // Add to view
        self.layer.addSublayer(layer)
        self.previewLayer = layer

        // Enable device orientation notifications
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        // Set initial orientation
        updateOrientation(for: layer)

        // Observe orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update preview layer frame
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer?.frame = bounds
        CATransaction.commit()

        // Also update orientation on layout changes (handles initial orientation)
        if let layer = previewLayer {
            updateOrientation(for: layer)
        }
    }

    // MARK: - Orientation

    @objc private func orientationDidChange(_ notification: Notification) {
        guard let layer = previewLayer else { return }
        updateOrientation(for: layer)
    }

    private func updateOrientation(for layer: AVCaptureVideoPreviewLayer) {
        guard let connection = layer.connection else { return }

        // Get the current interface orientation from the window scene
        // This is more reliable than UIDevice.current.orientation, especially for
        // landscape-locked apps where device orientation may not match interface orientation
        let rotationAngle: CGFloat = getVideoRotationAngle()

        // Use the modern videoRotationAngle API (iOS 17+)
        if connection.isVideoRotationAngleSupported(rotationAngle) {
            connection.videoRotationAngle = rotationAngle
        }
    }

    /// Determines the correct video rotation angle based on the current interface orientation.
    /// Uses the window scene's interface orientation for accurate detection,
    /// with fallback to device orientation and finally to landscape default.
    private func getVideoRotationAngle() -> CGFloat {
        // First, try to get orientation from the window scene (most reliable)
        if let windowScene = self.window?.windowScene {
            let interfaceOrientation = windowScene.interfaceOrientation
            switch interfaceOrientation {
            case .portrait:
                return 90
            case .portraitUpsideDown:
                return 270
            case .landscapeLeft:
                // Interface landscapeLeft = home button on right = camera rotation 0
                return 0
            case .landscapeRight:
                // Interface landscapeRight = home button on left = camera rotation 180
                return 180
            default:
                break
            }
        }

        // Fallback to device orientation if window scene is not available
        let deviceOrientation = UIDevice.current.orientation
        if deviceOrientation.isValidInterfaceOrientation {
            switch deviceOrientation {
            case .portrait:
                return 90
            case .portraitUpsideDown:
                return 270
            case .landscapeLeft:
                // Device landscapeLeft (home button on right) = camera rotation 0
                return 0
            case .landscapeRight:
                // Device landscapeRight (home button on left) = camera rotation 180
                return 180
            default:
                break
            }
        }

        // Default to landscape right (most common for bowling app usage)
        // This matches the preview orientation where the device is held in landscape
        // with the home button/indicator on the right side
        return 0
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
        // Dispatch to main actor for UIDevice call since deinit is nonisolated
        Task { @MainActor in
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }
}

// MARK: - UIDeviceOrientation Extension

extension UIDeviceOrientation {
    /// Returns true if this is a valid interface orientation (not faceUp, faceDown, or unknown)
    var isValidInterfaceOrientation: Bool {
        switch self {
        case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
            return true
        default:
            return false
        }
    }
}

// MARK: - Convenience Initializers

extension CameraPreviewView {
    /// Create a camera preview with default settings
    init(cameraManager: CameraSessionManager) {
        self.cameraManager = cameraManager
        self.videoGravity = .resizeAspectFill
        self.isMirrored = false
        self.backgroundColor = .black
    }

    /// Create a camera preview with mirroring for front camera
    init(cameraManager: CameraSessionManager, position: CameraPosition) {
        self.cameraManager = cameraManager
        self.videoGravity = .resizeAspectFill
        self.isMirrored = position == .front
        self.backgroundColor = .black
    }
}

// MARK: - Preview Modifiers

extension CameraPreviewView {
    /// Set the video gravity
    func videoGravity(_ gravity: AVLayerVideoGravity) -> CameraPreviewView {
        var copy = self
        copy.videoGravity = gravity
        return copy
    }

    /// Set whether the preview is mirrored
    func mirrored(_ isMirrored: Bool) -> CameraPreviewView {
        var copy = self
        copy.isMirrored = isMirrored
        return copy
    }

    /// Set the background color
    func previewBackgroundColor(_ color: UIColor) -> CameraPreviewView {
        var copy = self
        copy.backgroundColor = color
        return copy
    }
}

// MARK: - SwiftUI Preview

#Preview("Camera Preview") {
    CameraPreviewView(cameraManager: CameraSessionManager.shared)
        .ignoresSafeArea()
}

// MARK: - Alternative: Coordinator-based Preview

/// Alternative implementation using Coordinator pattern for more complex interactions
struct CameraPreviewViewWithCoordinator: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraSessionManager

    /// Called when user taps on preview (for focus/exposure)
    var onTapLocation: ((CGPoint) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer

        // Add tap gesture for focus
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tapGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds

        // Update mirroring based on camera position
        if let connection = context.coordinator.previewLayer?.connection {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = cameraManager.currentPosition == .front
            }
        }
    }

    @MainActor
    class Coordinator: NSObject {
        var parent: CameraPreviewViewWithCoordinator
        var previewLayer: AVCaptureVideoPreviewLayer?

        init(_ parent: CameraPreviewViewWithCoordinator) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let layer = previewLayer else { return }

            let location = gesture.location(in: gesture.view)
            let devicePoint = layer.captureDevicePointConverted(fromLayerPoint: location)

            parent.onTapLocation?(devicePoint)
        }
    }
}

// MARK: - Metal-accelerated Preview (for future enhancement)

/// Placeholder for Metal-accelerated preview layer
/// Use this for custom overlays and real-time annotations
struct MetalCameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraSessionManager

    func makeUIView(context: Context) -> MTKViewWrapper {
        let view = MTKViewWrapper()
        view.cameraManager = cameraManager
        return view
    }

    func updateUIView(_ uiView: MTKViewWrapper, context: Context) {
        // Metal rendering updates handled by frame callback
    }
}

/// Wrapper for MTKView that renders camera frames
/// Note: Full Metal implementation would require MetalKit and shader setup
class MTKViewWrapper: UIView {
    weak var cameraManager: CameraSessionManager?

    // Metal rendering would be implemented here for advanced overlays
    // This is a placeholder for future enhancement
}
