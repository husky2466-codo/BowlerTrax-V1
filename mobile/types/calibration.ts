/**
 * Lane calibration types
 */

/**
 * Calibration wizard step
 */
export type CalibrationStep =
  | 'position'        // Position camera
  | 'foul_line'       // Mark foul line
  | 'arrows'          // Mark arrows
  | 'verify'          // Verify calibration
  | 'complete';       // Done

/**
 * Calibration wizard state
 */
export interface CalibrationWizardState {
  step: CalibrationStep;
  foulLineY?: number;
  arrowPoints: ArrowPoint[];
  pixelsPerFoot?: number;
  pixelsPerBoard?: number;
  isValid: boolean;
  errorMessage?: string;
}

/**
 * Arrow point for calibration
 */
export interface ArrowPoint {
  arrowNumber: number;  // 1-7 (arrows on boards 5,10,15,20,25,30,35)
  pixelX: number;
  pixelY: number;
  boardNumber: number;  // 5, 10, 15, 20, 25, 30, or 35
}

/**
 * USBC standard lane dimensions (constant)
 */
export interface LaneDimensions {
  lengthFt: number;           // 60 feet (foul line to head pin)
  widthInches: number;        // 41.5 inches
  boardCount: number;         // 39 boards
  boardWidthInches: number;   // ~1.0641 inches each
  arrowsDistanceFt: number;   // 15 feet from foul line
  dotsDistanceFt: number;     // 12 feet from foul line
  pinDeckLengthInches: number; // 34.1875 inches (2ft 10-3/16")
  gutterWidthInches: number;  // ~1.25 inches each side
}

/**
 * Arrow positions on the lane (USBC standard)
 */
export interface ArrowPositions {
  boards: number[];           // [5, 10, 15, 20, 25, 30, 35]
  distanceFromFoulLineFt: number; // 15 feet
  spacingBoards: number;      // 5 boards apart
}

/**
 * Pixel-to-real-world conversion
 */
export interface PixelConversion {
  // Given a pixel position, calculate real-world position
  pixelToBoard: (pixelX: number) => number;
  pixelToDistanceFt: (pixelY: number) => number;

  // Given real-world position, calculate pixel
  boardToPixel: (board: number) => number;
  distanceFtToPixel: (distanceFt: number) => number;
}

/**
 * Calibration profile saved for a center
 */
export interface CalibrationProfile {
  id: string;
  centerId: string;
  centerName: string;
  laneNumber?: number;

  // Conversion factors
  pixelsPerFoot: number;
  pixelsPerBoard: number;

  // Reference points
  foulLineY: number;
  arrowsY: number;
  leftGutterX: number;
  rightGutterX: number;

  // Camera info
  cameraHeightFt?: number;
  cameraAngleDeg?: number;

  createdAt: string;
  lastUsed?: string;
}
