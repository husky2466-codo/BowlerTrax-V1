/**
 * Color-based Ball Tracker
 * Detects and tracks bowling ball using color sampling
 */

import { BallDetection, TrajectoryPoint, ColorMaskParams, HSVColor } from '@/types';
import { rgbToHsv, isColorMatch, DEFAULT_COLOR_TOLERANCE } from './hsvUtils';

export interface ColorTrackerConfig {
  targetColor: HSVColor;
  tolerance: typeof DEFAULT_COLOR_TOLERANCE;
  minContourArea: number;
  maxContourArea: number;
}

export interface FrameAnalysisResult {
  detected: boolean;
  detection: BallDetection | null;
  processingTimeMs: number;
}

/**
 * ColorTracker class for ball detection
 * Uses HSV color space for robust detection under varying lighting
 */
export class ColorTracker {
  private config: ColorTrackerConfig;
  private trajectoryHistory: TrajectoryPoint[] = [];
  private frameCount = 0;

  constructor(config?: Partial<ColorTrackerConfig>) {
    this.config = {
      targetColor: { h: 0, s: 0, v: 0 },
      tolerance: DEFAULT_COLOR_TOLERANCE,
      minContourArea: 500,   // Min pixels for valid ball detection
      maxContourArea: 50000, // Max pixels (ball shouldn't be huge)
      ...config,
    };
  }

  /**
   * Set target color from user tap on ball
   * @param rgb RGB color sampled from frame
   */
  setTargetColor(rgb: { r: number; g: number; b: number }): void {
    this.config.targetColor = rgbToHsv(rgb);
  }

  /**
   * Get current target color in HSV
   */
  getTargetColor(): HSVColor {
    return this.config.targetColor;
  }

  /**
   * Analyze a camera frame to detect ball position
   * TODO: Implement actual frame processing using camera frame data
   *
   * @param frameData Raw frame data from camera
   * @param width Frame width
   * @param height Frame height
   * @param timestamp Frame timestamp
   */
  analyzeFrame(
    frameData: Uint8Array,
    width: number,
    height: number,
    timestamp: number
  ): FrameAnalysisResult {
    const startTime = performance.now();
    this.frameCount++;

    // TODO: Implement actual frame processing
    // 1. Convert frame to HSV
    // 2. Create binary mask matching target color
    // 3. Find contours in mask
    // 4. Filter contours by size/circularity
    // 5. Return largest valid contour centroid

    // Placeholder - return no detection
    return {
      detected: false,
      detection: null,
      processingTimeMs: performance.now() - startTime,
    };
  }

  /**
   * Add detected position to trajectory history
   */
  addToTrajectory(point: TrajectoryPoint): void {
    this.trajectoryHistory.push(point);

    // Keep last 120 frames (1 second at 120fps)
    if (this.trajectoryHistory.length > 120) {
      this.trajectoryHistory.shift();
    }
  }

  /**
   * Get current trajectory history
   */
  getTrajectory(): TrajectoryPoint[] {
    return [...this.trajectoryHistory];
  }

  /**
   * Clear trajectory for new shot
   */
  clearTrajectory(): void {
    this.trajectoryHistory = [];
    this.frameCount = 0;
  }

  /**
   * Get frame count since last clear
   */
  getFrameCount(): number {
    return this.frameCount;
  }
}

/**
 * Create a new ColorTracker instance with default config
 */
export function createColorTracker(): ColorTracker {
  return new ColorTracker();
}
