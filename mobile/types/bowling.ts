/**
 * Core bowling types for BowlerTrax
 */

// Rev rate categories based on industry standards
export type RevCategory = 'stroker' | 'tweener' | 'cranker';

// Oil pattern types
export type OilPatternType = 'house' | 'sport' | 'short' | 'medium' | 'long' | 'custom';

// Hand preference
export type HandPreference = 'left' | 'right';

// Shot result types
export type ShotResult = 'strike' | 'spare' | 'open' | 'split' | 'washout';

// Predicted leave types
export type PredictedLeave =
  | 'clean'
  | '10-pin'
  | '7-pin'
  | 'split'
  | 'bucket'
  | 'washout'
  | 'greek-church'
  | 'other';

/**
 * Bowling center (saved location)
 */
export interface Center {
  id: string;
  name: string;
  address?: string;
  createdAt: string;
}

/**
 * Lane calibration data for a specific center/lane
 */
export interface Calibration {
  id: string;
  centerId: string;
  laneNumber?: number;
  pixelsPerFoot: number;
  pixelsPerBoard: number;
  foulLineY: number;           // Y pixel of foul line
  arrowsY: number;             // Y pixel of arrows (15ft)
  cameraHeightFt?: number;
  referencePoints: CalibrationPoint[];
  createdAt: string;
}

export interface CalibrationPoint {
  type: 'foul_line' | 'arrow' | 'pin_deck';
  pixelX: number;
  pixelY: number;
  boardNumber?: number;
  distanceFt?: number;
}

/**
 * Bowling session (practice or league)
 */
export interface Session {
  id: string;
  centerId?: string;
  centerName?: string;
  laneNumber?: number;
  oilPattern: OilPatternType;
  hand: HandPreference;
  date: string;
  notes?: string;
  createdAt: string;
}

/**
 * Individual shot with all tracked metrics
 */
export interface Shot {
  id: string;
  sessionId: string;
  shotNumber: number;
  frameNumber?: number;
  isFirstBall: boolean;

  // Core metrics
  speedMph?: number;           // Launch speed off hand
  impactSpeedMph?: number;     // Speed at pins
  revRateRpm?: number;         // Revolutions per minute
  revCategory?: RevCategory;   // stroker/tweener/cranker

  // Trajectory metrics
  entryAngleDeg?: number;      // Angle into pocket (optimal: 6°)
  launchAngleDeg?: number;     // Angle at release
  pocketOffsetBoards?: number; // Distance from ideal 17.5 board
  arrowBoard?: number;         // Board crossed at arrows (15ft)
  foulLineBoard?: number;      // Board at foul line
  breakpointBoard?: number;    // Where ball starts hooking
  breakpointDistanceFt?: number;

  // Strike analysis
  strikeProbability?: number;  // 0-1 probability
  predictedLeave?: PredictedLeave;
  actualResult?: ShotResult;
  pinsLeft?: number[];         // [1,2,3...10] pins remaining

  // Raw data
  trajectory?: TrajectoryPoint[];
  videoUri?: string;
  thumbnailUri?: string;

  createdAt: string;
}

/**
 * Ball profile for color-based tracking
 */
export interface BallProfile {
  id: string;
  name: string;
  colorHsv: HSVColor;
  colorTolerance: number;      // How much variance allowed
  markerColorHsv?: HSVColor;   // PAP marker color for rev tracking
  createdAt: string;
}

/**
 * HSV color representation (better for tracking than RGB)
 */
export interface HSVColor {
  h: number;  // Hue: 0-360
  s: number;  // Saturation: 0-100
  v: number;  // Value/Brightness: 0-100
}

/**
 * RGB color for display purposes
 */
export interface RGBColor {
  r: number;  // 0-255
  g: number;  // 0-255
  b: number;  // 0-255
}

/**
 * Session statistics summary
 */
export interface SessionStats {
  totalShots: number;
  strikes: number;
  spares: number;
  opens: number;
  avgSpeedMph: number;
  avgRevRateRpm: number;
  avgEntryAngle: number;
  consistencyScore: number;    // 0-100, how consistent the shots are
}

/**
 * User settings/preferences
 */
export interface UserSettings {
  hand: HandPreference;
  defaultOilPattern: OilPatternType;
  showPreviousShot: boolean;
  autoSaveVideos: boolean;
  hapticFeedback: boolean;
}
