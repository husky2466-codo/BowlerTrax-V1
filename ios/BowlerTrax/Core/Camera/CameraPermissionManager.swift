//
//  CameraPermissionManager.swift
//  BowlerTrax
//
//  Manages camera permission requests and status monitoring.
//  Provides observable state for SwiftUI binding.
//

import AVFoundation
import Combine
import UIKit

// MARK: - Permission State

/// Represents the current camera permission state
enum CameraPermissionState: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted

    /// User-friendly message for each state
    var message: String {
        switch self {
        case .notDetermined:
            return "Camera access is required to track your bowling shots."
        case .authorized:
            return "Camera access granted."
        case .denied:
            return "Camera access was denied. Please enable it in Settings to use BowlerTrax."
        case .restricted:
            return "Camera access is restricted on this device."
        }
    }

    /// Whether camera can be used
    var canUseCamera: Bool {
        self == .authorized
    }

    /// Whether user can change permission (for showing settings button)
    var canRequestPermission: Bool {
        self == .notDetermined
    }

    /// Whether to show settings redirect
    var shouldShowSettings: Bool {
        self == .denied
    }
}

// MARK: - Camera Permission Manager

/// Observable manager for camera permissions
@MainActor
final class CameraPermissionManager: ObservableObject {

    // MARK: - Published Properties

    /// Current permission state
    @Published private(set) var permissionState: CameraPermissionState = .notDetermined

    /// Whether permission request is in progress
    @Published private(set) var isRequestingPermission: Bool = false

    // MARK: - Singleton

    /// Shared instance for app-wide permission management
    static let shared = CameraPermissionManager()

    // MARK: - Initialization

    init() {
        // Check current status on init
        updatePermissionState()
    }

    // MARK: - Public Methods

    /// Check current permission status without requesting
    func checkPermission() {
        updatePermissionState()
    }

    /// Request camera permission from user
    /// - Returns: Whether permission was granted
    @discardableResult
    func requestPermission() async -> Bool {
        // Don't request if already determined
        guard permissionState == .notDetermined else {
            return permissionState == .authorized
        }

        isRequestingPermission = true
        defer { isRequestingPermission = false }

        let granted = await AVCaptureDevice.requestAccess(for: .video)
        updatePermissionState()

        return granted
    }

    /// Request permission with completion handler (for non-async contexts)
    func requestPermission(completion: @escaping @Sendable (Bool) -> Void) {
        guard permissionState == .notDetermined else {
            completion(permissionState == .authorized)
            return
        }

        isRequestingPermission = true

        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                self?.isRequestingPermission = false
                self?.updatePermissionState()
                completion(granted)
            }
        }
    }

    /// Open system Settings app to camera permissions
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }

    // MARK: - Private Methods

    /// Update permission state from system status
    private func updatePermissionState() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .notDetermined:
            permissionState = .notDetermined
        case .authorized:
            permissionState = .authorized
        case .denied:
            permissionState = .denied
        case .restricted:
            permissionState = .restricted
        @unknown default:
            permissionState = .notDetermined
        }
    }
}

// MARK: - SwiftUI Convenience Extensions

import SwiftUI

extension CameraPermissionManager {

    /// Binding for permission state (useful for sheet presentation)
    var isAuthorizedBinding: Binding<Bool> {
        Binding(
            get: { self.permissionState == .authorized },
            set: { _ in }
        )
    }

    /// Binding for showing permission denied alert
    var showPermissionDeniedBinding: Binding<Bool> {
        Binding(
            get: { self.permissionState == .denied },
            set: { _ in }
        )
    }
}

// MARK: - Permission View Modifier

/// View modifier that handles camera permission checking
struct CameraPermissionModifier: ViewModifier {
    @StateObject private var permissionManager = CameraPermissionManager()
    let onPermissionGranted: () -> Void
    let onPermissionDenied: () -> Void

    func body(content: Content) -> some View {
        content
            .task {
                await checkAndRequestPermission()
            }
    }

    private func checkAndRequestPermission() async {
        permissionManager.checkPermission()

        switch permissionManager.permissionState {
        case .authorized:
            onPermissionGranted()
        case .notDetermined:
            let granted = await permissionManager.requestPermission()
            if granted {
                onPermissionGranted()
            } else {
                onPermissionDenied()
            }
        case .denied, .restricted:
            onPermissionDenied()
        }
    }
}

extension View {
    /// Apply camera permission check with callbacks
    func withCameraPermission(
        onGranted: @escaping () -> Void,
        onDenied: @escaping () -> Void
    ) -> some View {
        modifier(CameraPermissionModifier(
            onPermissionGranted: onGranted,
            onPermissionDenied: onDenied
        ))
    }
}
