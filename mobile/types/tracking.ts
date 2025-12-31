/**
 * Ball tracking and trajectory types
 */

/**
 * Single point in ball trajectory
 */
export interface TrajectoryPoint {
  x: number;           // Pixel X
  y: number;           // Pixel Y
  timestamp: number;   // Milliseconds from shot start
  board?: number;      // Calculated board number (1-39)
  distanceFt?: number; // Calculated distance from foul line
  phase?: BallPhase;   // Current motion phase
}

/**
 * Ball motion phases (Skid-Hook-Roll)
 */
export type BallPhase = 'skid' | 'hook' | 'roll';

/**
 * Ball detection result from a single frame
 */
export interface BallDetection {
  found: boolean;
  x?: number;
  y?: number;
  radius?: number;
  confidence: number;  // 0-1 how confident the detection is
  markerAngle?: number; // Rotation angle of PAP marker (for rev rate)
}

/**
 * Camera frame with metadata
 */
export interface CameraFrame {
  data: Uint8Array;    // Raw pixel data
  width: number;
  height: number;
  timestamp: number;
  frameNumber: number;
}

/**
 * Tracking session state
 */
export interface TrackingState {
  isTracking: boolean;
  isRecording: boolean;
  currentShot: TrajectoryPoint[];
  ballDetected: boolean;
  lastDetection?: BallDetection;
  frameCount: number;
  fps: number;
}

/**
 * Color mask parameters for ball detection
 */
export interface ColorMaskParams {
  hsv: {
    h: number;  // Center hue
    s: number;  // Center saturation
    v: number;  // Center value
  };
  tolerance: {
    h: number;  // Hue tolerance (degrees)
    s: number;  // Saturation tolerance (%)
    v: number;  // Value tolerance (%)
  };
}

/**
 * Contour detection result
 */
export interface Contour {
  points: { x: number; y: number }[];
  area: number;
  perimeter: number;
  circularity: number;  // 0-1, 1 = perfect circle
  center: { x: number; y: number };
  radius: number;
}

/**
 * Rev rate tracking state
 */
export interface RevTrackingState {
  rotationCount: number;
  lastMarkerAngle: number;
  startTime: number;
  samples: RevSample[];
}

/**
 * Single revolution sample
 */
export interface RevSample {
  timestamp: number;
  angle: number;        // Marker angle in degrees
  deltaAngle: number;   // Change from previous sample
}
