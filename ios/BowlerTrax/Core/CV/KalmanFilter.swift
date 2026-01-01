//
//  KalmanFilter.swift
//  BowlerTrax
//
//  Kalman filter for smoothing ball position tracking and predicting position
//  during brief occlusions. Implements a 2D position + velocity state model.
//

import Foundation
import simd
import Accelerate

// MARK: - Kalman State

/// State vector for 2D position tracking with velocity
struct KalmanState: Sendable {
    var x: Double       // Position X (normalized 0-1)
    var y: Double       // Position Y (normalized 0-1)
    var vx: Double      // Velocity X (units per frame)
    var vy: Double      // Velocity Y (units per frame)

    var position: CGPoint {
        CGPoint(x: x, y: y)
    }

    var velocity: CGPoint {
        CGPoint(x: vx, y: vy)
    }

    static let zero = KalmanState(x: 0, y: 0, vx: 0, vy: 0)
}

// MARK: - Kalman Filter

/// 2D Kalman filter for ball position tracking
final class KalmanFilter: @unchecked Sendable {
    // MARK: - Properties

    /// Current state estimate
    private(set) var state: KalmanState

    /// State covariance matrix (4x4)
    /// Represents uncertainty in state estimate
    private var P: [[Double]]

    /// Process noise covariance (Q)
    /// How much we expect the state to vary between predictions
    private let processNoise: Double

    /// Measurement noise covariance (R)
    /// How noisy our measurements are
    private let measurementNoise: Double

    /// Time step (1/120 second at 120fps)
    private let dt: Double

    /// Whether filter has been initialized with first measurement
    private(set) var isInitialized: Bool = false

    // MARK: - Initialization

    /// Create Kalman filter for 120fps tracking
    /// - Parameters:
    ///   - frameRate: Camera frame rate (default 120fps)
    ///   - processNoise: Process noise variance (default 0.0001)
    ///   - measurementNoise: Measurement noise variance (default 0.001)
    init(
        frameRate: Double = 120.0,
        processNoise: Double = 0.0001,
        measurementNoise: Double = 0.001
    ) {
        self.dt = 1.0 / max(frameRate, 1.0)  // Guard against division by zero
        self.processNoise = processNoise
        self.measurementNoise = max(measurementNoise, 1e-10)  // Ensure non-zero for safe division
        self.state = .zero

        // Initialize covariance matrix with high uncertainty
        self.P = [
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        ]
    }

    /// Initialize with first measurement
    /// - Parameter position: Initial position measurement
    func initialize(with position: CGPoint) {
        state = KalmanState(
            x: Double(position.x),
            y: Double(position.y),
            vx: 0,
            vy: 0
        )

        // Reset covariance - certain about position, uncertain about velocity
        P = [
            [measurementNoise, 0, 0, 0],
            [0, measurementNoise, 0, 0],
            [0, 0, 1, 0],  // High uncertainty in velocity
            [0, 0, 0, 1]
        ]

        isInitialized = true
    }

    /// Reset filter to uninitialized state
    func reset() {
        state = .zero
        P = [
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        ]
        isInitialized = false
    }

    // MARK: - Prediction

    /// Predict next state without measurement
    /// - Returns: Predicted position
    @discardableResult
    func predict() -> CGPoint {
        guard isInitialized else { return .zero }

        // State transition: x' = x + v*dt
        state.x += state.vx * dt
        state.y += state.vy * dt
        // Velocity remains unchanged in prediction

        // Update covariance: P' = F*P*F' + Q
        // F is state transition matrix:
        // [1  0  dt 0 ]
        // [0  1  0  dt]
        // [0  0  1  0 ]
        // [0  0  0  1 ]

        // Simplified covariance update (add process noise)
        P[0][0] += processNoise + P[2][2] * dt * dt
        P[1][1] += processNoise + P[3][3] * dt * dt
        P[2][2] += processNoise
        P[3][3] += processNoise

        // Cross-covariance updates
        P[0][2] += P[2][2] * dt
        P[2][0] = P[0][2]
        P[1][3] += P[3][3] * dt
        P[3][1] = P[1][3]

        return state.position
    }

    /// Predict position N frames ahead
    /// - Parameter framesAhead: Number of frames to predict
    /// - Returns: Predicted position
    func predictPosition(framesAhead: Int) -> CGPoint {
        guard isInitialized else { return .zero }

        let futureX = state.x + state.vx * dt * Double(framesAhead)
        let futureY = state.y + state.vy * dt * Double(framesAhead)

        return CGPoint(x: futureX, y: futureY)
    }

    // MARK: - Update

    /// Update state with new measurement
    /// - Parameter measurement: Observed position
    /// - Returns: Filtered (smoothed) position
    @discardableResult
    func update(measurement: CGPoint) -> CGPoint {
        guard isInitialized else {
            initialize(with: measurement)
            return measurement
        }

        // First predict
        predict()

        // Innovation (measurement residual)
        let zx = Double(measurement.x)
        let zy = Double(measurement.y)
        let innovationX = zx - state.x
        let innovationY = zy - state.y

        // Innovation covariance: S = H*P*H' + R
        // H is measurement matrix [1 0 0 0; 0 1 0 0] (we observe x and y)
        // Ensure minimum value to prevent division by zero
        let sx = max(P[0][0] + measurementNoise, 1e-10)
        let sy = max(P[1][1] + measurementNoise, 1e-10)

        // Kalman gain: K = P*H' * S^-1
        // For our H matrix, this simplifies to:
        let kx0 = P[0][0] / sx
        let kx2 = P[2][0] / sx
        let ky1 = P[1][1] / sy
        let ky3 = P[3][1] / sy

        // State update: x = x + K * innovation
        state.x += kx0 * innovationX
        state.y += ky1 * innovationY
        state.vx += kx2 * innovationX
        state.vy += ky3 * innovationY

        // Covariance update: P = (I - K*H) * P
        // Simplified update for our case
        let factor_x = 1 - kx0
        let factor_y = 1 - ky1

        P[0][0] *= factor_x
        P[1][1] *= factor_y
        P[2][0] -= kx2 * P[0][0]
        P[3][1] -= ky3 * P[1][1]
        P[0][2] = P[2][0]
        P[1][3] = P[3][1]

        return state.position
    }

    // MARK: - Convenience Methods

    /// Get current velocity estimate
    var currentVelocity: CGPoint {
        state.velocity
    }

    /// Get current speed (magnitude of velocity)
    var currentSpeed: Double {
        sqrt(state.vx * state.vx + state.vy * state.vy)
    }

    /// Get position uncertainty (sqrt of position variance)
    var positionUncertainty: (x: Double, y: Double) {
        (sqrt(P[0][0]), sqrt(P[1][1]))
    }

    /// Get velocity uncertainty
    var velocityUncertainty: (x: Double, y: Double) {
        (sqrt(P[2][2]), sqrt(P[3][3]))
    }
}

// MARK: - Extended Kalman Filter for Curved Trajectories

/// Extended Kalman filter that can handle curved ball trajectories
final class CurvedTrajectoryFilter: @unchecked Sendable {
    // MARK: - Properties

    /// State: [x, y, vx, vy, ax, ay] - position, velocity, acceleration
    private var state: [Double] = [0, 0, 0, 0, 0, 0]

    /// Covariance matrix (6x6)
    private var P: [[Double]]

    private let dt: Double
    private let processNoise: Double
    private let measurementNoise: Double

    private(set) var isInitialized: Bool = false

    // MARK: - Initialization

    init(
        frameRate: Double = 120.0,
        processNoise: Double = 0.00001,
        measurementNoise: Double = 0.001
    ) {
        self.dt = 1.0 / max(frameRate, 1.0)  // Guard against division by zero
        self.processNoise = processNoise
        self.measurementNoise = max(measurementNoise, 1e-10)  // Ensure non-zero for safe division

        // Initialize 6x6 covariance matrix
        self.P = Array(repeating: Array(repeating: 0.0, count: 6), count: 6)
        for i in 0..<6 {
            P[i][i] = 1.0
        }
    }

    /// Initialize with first measurement
    func initialize(with position: CGPoint) {
        state = [Double(position.x), Double(position.y), 0, 0, 0, 0]

        // Reset covariance
        P = Array(repeating: Array(repeating: 0.0, count: 6), count: 6)
        P[0][0] = measurementNoise
        P[1][1] = measurementNoise
        for i in 2..<6 {
            P[i][i] = 1.0  // High uncertainty in derivatives
        }

        isInitialized = true
    }

    /// Reset filter
    func reset() {
        state = [0, 0, 0, 0, 0, 0]
        P = Array(repeating: Array(repeating: 0.0, count: 6), count: 6)
        for i in 0..<6 {
            P[i][i] = 1.0
        }
        isInitialized = false
    }

    // MARK: - Prediction

    /// Predict next state
    @discardableResult
    func predict() -> CGPoint {
        guard isInitialized else { return .zero }

        // State transition with constant acceleration model
        // x' = x + vx*dt + 0.5*ax*dt^2
        // vx' = vx + ax*dt
        // ax' = ax (constant)

        let dt2 = dt * dt / 2

        state[0] += state[2] * dt + state[4] * dt2  // x
        state[1] += state[3] * dt + state[5] * dt2  // y
        state[2] += state[4] * dt  // vx
        state[3] += state[5] * dt  // vy
        // acceleration unchanged

        // Add process noise to covariance
        for i in 0..<6 {
            P[i][i] += processNoise
        }

        return CGPoint(x: state[0], y: state[1])
    }

    /// Predict position N frames ahead
    func predictPosition(framesAhead: Int) -> CGPoint {
        guard isInitialized else { return .zero }

        let t = dt * Double(framesAhead)
        let t2 = t * t / 2

        let futureX = state[0] + state[2] * t + state[4] * t2
        let futureY = state[1] + state[3] * t + state[5] * t2

        return CGPoint(x: futureX, y: futureY)
    }

    // MARK: - Update

    /// Update with new measurement
    @discardableResult
    func update(measurement: CGPoint) -> CGPoint {
        guard isInitialized else {
            initialize(with: measurement)
            return measurement
        }

        predict()

        // Innovation
        let innovationX = Double(measurement.x) - state[0]
        let innovationY = Double(measurement.y) - state[1]

        // Simplified Kalman gain (only observing position)
        // Ensure minimum value to prevent division by zero
        let sx = max(P[0][0] + measurementNoise, 1e-10)
        let sy = max(P[1][1] + measurementNoise, 1e-10)

        // Update state using Kalman gain
        let kx = P[0][0] / sx
        let ky = P[1][1] / sy

        state[0] += kx * innovationX
        state[1] += ky * innovationY

        // Also update velocity and acceleration estimates
        state[2] += (P[2][0] / sx) * innovationX
        state[3] += (P[3][1] / sy) * innovationY
        state[4] += (P[4][0] / sx) * innovationX
        state[5] += (P[5][1] / sy) * innovationY

        // Update covariance (simplified)
        P[0][0] *= (1 - kx)
        P[1][1] *= (1 - ky)

        return CGPoint(x: state[0], y: state[1])
    }

    // MARK: - Accessors

    var position: CGPoint {
        CGPoint(x: state[0], y: state[1])
    }

    var velocity: CGPoint {
        CGPoint(x: state[2], y: state[3])
    }

    var acceleration: CGPoint {
        CGPoint(x: state[4], y: state[5])
    }

    var speed: Double {
        sqrt(state[2] * state[2] + state[3] * state[3])
    }
}

// MARK: - Kalman Filter Pool

/// Pool of Kalman filters for multiple object tracking
final class KalmanFilterPool: @unchecked Sendable {
    private var filters: [UUID: KalmanFilter] = [:]
    private let frameRate: Double

    init(frameRate: Double = 120.0) {
        self.frameRate = frameRate
    }

    /// Get or create filter for object ID
    func filter(for id: UUID) -> KalmanFilter {
        if let existing = filters[id] {
            return existing
        }
        let filter = KalmanFilter(frameRate: frameRate)
        filters[id] = filter
        return filter
    }

    /// Remove filter for object ID
    func removeFilter(for id: UUID) {
        filters.removeValue(forKey: id)
    }

    /// Clear all filters
    func clear() {
        filters.removeAll()
    }

    /// Number of active filters
    var count: Int {
        filters.count
    }
}
