/**
 * USBC Standard Bowling Lane Dimensions
 * All measurements are official USBC specifications
 *
 * Reference: Bowling-Info-Ref.md
 */

import { LaneDimensions, ArrowPositions } from '../../types';

/**
 * Official USBC lane dimensions
 */
export const LANE_DIMENSIONS: LaneDimensions = {
  // Lane length from foul line to head pin center
  lengthFt: 60,

  // Lane width including boards (excluding gutters)
  widthInches: 41.5,

  // Number of boards across the lane
  boardCount: 39,

  // Width of each board
  boardWidthInches: 1.0641,  // 41.5 / 39 = ~1.0641"

  // Distance from foul line to arrows
  arrowsDistanceFt: 15,

  // Distance from foul line to dots
  dotsDistanceFt: 12,

  // Pin deck length (triangle of pins)
  pinDeckLengthInches: 34.1875,  // 2 feet 10-3/16 inches

  // Gutter width on each side
  gutterWidthInches: 1.25,
};

/**
 * Arrow positions on the lane (USBC standard)
 * Arrows are located 15 feet from foul line
 */
export const ARROW_POSITIONS: ArrowPositions = {
  // Board numbers where arrows are located (from right gutter for right-handed)
  boards: [5, 10, 15, 20, 25, 30, 35],

  // Distance from foul line
  distanceFromFoulLineFt: 15,

  // Arrows are 5 boards apart
  spacingBoards: 5,
};

/**
 * Pin positions (board numbers from right side for right-handed bowler)
 * Head pin (1) is at approximately board 17.5
 */
export const PIN_POSITIONS = {
  // Ideal pocket entry for right-handed strike
  pocketBoardRH: 17.5,

  // Ideal pocket entry for left-handed strike
  pocketBoardLH: 22.5,

  // Board positions of each pin (approximate, from right gutter)
  pins: {
    1: 20,   // Head pin (center)
    2: 17,
    3: 23,
    4: 14,
    5: 20,
    6: 26,
    7: 11,
    8: 17,
    9: 23,
    10: 29,
  } as Record<number, number>,
};

/**
 * Optimal shot parameters for strikes
 */
export const OPTIMAL_STRIKE_PARAMS = {
  // Optimal entry angle into pocket (degrees)
  entryAngleDeg: 6,

  // Entry angle range that typically results in strikes
  entryAngleMinDeg: 4,
  entryAngleMaxDeg: 7,

  // Typical ball speed range at pins (mph)
  speedMinMph: 14,
  speedMaxMph: 20,
  speedOptimalMph: 17,

  // Pocket offset tolerance (boards)
  pocketOffsetMaxBoards: 1.5,
};

/**
 * Rev rate categories (RPM ranges)
 */
export const REV_RATE_CATEGORIES = {
  stroker: {
    min: 200,
    max: 350,
    description: 'Lower rev rate, more accuracy-focused style',
  },
  tweener: {
    min: 300,
    max: 400,
    description: 'Balanced between power and accuracy',
  },
  cranker: {
    min: 400,
    max: 600,
    description: 'High rev rate, power-focused style',
  },
};

/**
 * Speed/Rev Rate ratio classifications
 * Used to determine bowler type
 */
export const SPEED_REV_RATIO = {
  // Speed dominant: speed_mph > rev_rate_rpm / 20
  speedDominant: {
    threshold: 1.05,  // speed / (revs/20) > 1.05
    description: 'Ball skids more, less hook',
  },
  // Rev dominant: rev_rate_rpm / 20 > speed_mph
  revDominant: {
    threshold: 0.95,  // speed / (revs/20) < 0.95
    description: 'Ball hooks more aggressively',
  },
  // Balanced: approximately equal
  balanced: {
    minThreshold: 0.95,
    maxThreshold: 1.05,
    description: 'Good balance of skid and hook',
  },
};

/**
 * Distance markers on the lane
 */
export const LANE_MARKERS = {
  foulLine: 0,
  dots: 12,
  arrows: 15,
  midlane: 30,
  breakpoint: 40,  // Typical breakpoint area
  pinDeck: 60,
};

/**
 * Ball phases and typical distances
 */
export const BALL_PHASES = {
  skid: {
    typicalStartFt: 0,
    typicalEndFt: 15,
    description: 'Ball slides on oil, minimal rotation',
  },
  hook: {
    typicalStartFt: 35,
    typicalEndFt: 50,
    description: 'Ball transitions and begins to hook',
  },
  roll: {
    typicalStartFt: 50,
    typicalEndFt: 60,
    description: 'Ball enters full roll toward pins',
  },
};

/**
 * Convert board number to inches from right gutter
 */
export function boardToInches(board: number): number {
  return board * LANE_DIMENSIONS.boardWidthInches;
}

/**
 * Convert inches from right gutter to board number
 */
export function inchesToBoard(inches: number): number {
  return inches / LANE_DIMENSIONS.boardWidthInches;
}

/**
 * Get the arrow number (1-7) from a board number
 * Returns null if not on an arrow
 */
export function getArrowNumber(board: number): number | null {
  const index = ARROW_POSITIONS.boards.indexOf(Math.round(board));
  return index >= 0 ? index + 1 : null;
}

/**
 * Classify rev rate into category
 */
export function classifyRevRate(rpm: number): 'stroker' | 'tweener' | 'cranker' {
  if (rpm < REV_RATE_CATEGORIES.stroker.max) return 'stroker';
  if (rpm < REV_RATE_CATEGORIES.cranker.min) return 'tweener';
  return 'cranker';
}

/**
 * Calculate strike probability based on entry angle and pocket offset
 */
export function calculateStrikeProbability(
  entryAngleDeg: number,
  pocketOffsetBoards: number
): number {
  const { entryAngleMinDeg, entryAngleMaxDeg, pocketOffsetMaxBoards } = OPTIMAL_STRIKE_PARAMS;

  // Angle penalty (0-1, 1 = perfect)
  let angleFactor = 1;
  if (entryAngleDeg < entryAngleMinDeg) {
    angleFactor = Math.max(0, 1 - (entryAngleMinDeg - entryAngleDeg) / 4);
  } else if (entryAngleDeg > entryAngleMaxDeg) {
    angleFactor = Math.max(0, 1 - (entryAngleDeg - entryAngleMaxDeg) / 3);
  }

  // Pocket offset penalty (0-1, 1 = perfect)
  const offsetFactor = Math.max(
    0,
    1 - Math.abs(pocketOffsetBoards) / pocketOffsetMaxBoards
  );

  // Combined probability
  return angleFactor * offsetFactor;
}

/**
 * Predict likely leave based on entry parameters
 */
export function predictLeave(
  entryAngleDeg: number,
  pocketOffsetBoards: number,
  isRightHanded: boolean
): string {
  const absOffset = Math.abs(pocketOffsetBoards);

  // Good pocket hit
  if (absOffset < 1 && entryAngleDeg >= 4 && entryAngleDeg <= 7) {
    return 'clean';
  }

  // Low entry angle - corner pins
  if (entryAngleDeg < 4) {
    return isRightHanded ? '10-pin' : '7-pin';
  }

  // High entry angle - splits
  if (entryAngleDeg > 7) {
    return 'split';
  }

  // High pocket (too much to headpin side)
  if (pocketOffsetBoards > 1) {
    return isRightHanded ? '7-pin' : '10-pin';
  }

  // Light pocket (too far from headpin)
  if (pocketOffsetBoards < -1) {
    return 'bucket';
  }

  return 'other';
}
