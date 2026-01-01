/**
 * Trajectory Analysis
 * Calculate ball path, breakpoint, and entry angle
 */

import { TrajectoryPoint } from '@/types';
import { LANE } from '@/lib/constants/laneDimensions';

export interface TrajectoryAnalysis {
  /** Ball speed at foul line in mph */
  launchSpeed: number;
  /** Ball speed at pins in mph */
  impactSpeed: number;
  /** Board position at foul line */
  foulLineBoard: number;
  /** Board position at arrows (15ft) */
  arrowBoard: number;
  /** Board position at breakpoint */
  breakpointBoard: number;
  /** Distance to breakpoint in feet */
  breakpointDistance: number;
  /** Entry angle in degrees */
  entryAngle: number;
  /** Board position at pins */
  pocketBoard: number;
  /** Offset from ideal pocket (17.5 for RH) in boards */
  pocketOffset: number;
}

/**
 * Calculate ball speed between two points
 * @param p1 Start point
 * @param p2 End point
 * @param fps Camera frame rate
 * @returns Speed in mph
 */
export function calculateSpeed(
  p1: TrajectoryPoint,
  p2: TrajectoryPoint,
  fps: number = 120
): number {
  // Need real-world coordinates
  if (p1.realWorldX === undefined || p1.realWorldY === undefined ||
      p2.realWorldX === undefined || p2.realWorldY === undefined) {
    return 0;
  }

  // Distance in feet (using real-world coordinates)
  const dx = p2.realWorldX - p1.realWorldX;
  const dy = p2.realWorldY - p1.realWorldY;
  const distanceFeet = Math.sqrt(dx * dx + dy * dy);

  // Time between frames
  const frames = Math.abs(p2.frameNumber - p1.frameNumber);
  const timeSeconds = frames / fps;

  if (timeSeconds === 0) return 0;

  // Convert ft/s to mph (multiply by 0.6818)
  const feetPerSecond = distanceFeet / timeSeconds;
  return feetPerSecond * 0.6818;
}

/**
 * Calculate entry angle from trajectory points near pins
 * @param trajectory Array of trajectory points
 * @returns Entry angle in degrees
 */
export function calculateEntryAngle(trajectory: TrajectoryPoint[]): number {
  // Need at least 2 points near the pins with real-world coordinates
  const pinsArea = trajectory.filter(
    p => p.realWorldY !== undefined && p.realWorldY >= LANE.LENGTH_FEET - 5
  );

  if (pinsArea.length < 2) return 0;

  // Use last two points to calculate angle
  const p1 = pinsArea[pinsArea.length - 2];
  const p2 = pinsArea[pinsArea.length - 1];

  if (p1.realWorldX === undefined || p2.realWorldX === undefined ||
      p1.realWorldY === undefined || p2.realWorldY === undefined) {
    return 0;
  }

  const dx = p2.realWorldX - p1.realWorldX; // Lateral movement (boards)
  const dy = p2.realWorldY - p1.realWorldY; // Forward movement (feet)

  // Convert board movement to inches, then to feet for consistent units
  const dxFeet = (dx * LANE.BOARD_WIDTH_INCHES) / 12;

  // Entry angle = arctan(lateral / forward)
  const angleRadians = Math.atan2(Math.abs(dxFeet), dy);
  return angleRadians * (180 / Math.PI);
}

/**
 * Find breakpoint (where ball starts hooking toward pocket)
 * @param trajectory Array of trajectory points
 * @returns Breakpoint data or null if not found
 */
export function findBreakpoint(
  trajectory: TrajectoryPoint[]
): { board: number; distance: number } | null {
  // Filter to only points with real-world coordinates
  const validPoints = trajectory.filter(
    p => p.realWorldX !== undefined && p.realWorldY !== undefined
  );

  if (validPoints.length < 10) return null;

  // Look for where lateral velocity changes sign (ball starts moving toward pocket)
  for (let i = 5; i < validPoints.length - 5; i++) {
    const curr = validPoints[i];
    const prev = validPoints[i - 5];
    const next = validPoints[i + 5];

    if (curr.realWorldX === undefined || prev.realWorldX === undefined ||
        next.realWorldX === undefined || curr.realWorldY === undefined) {
      continue;
    }

    const prevLateral = curr.realWorldX - prev.realWorldX;
    const nextLateral = next.realWorldX - curr.realWorldX;

    // Sign change indicates breakpoint (for right-handed, ball goes right then hooks left)
    if (prevLateral > 0 && nextLateral < 0) {
      return {
        board: curr.realWorldX,
        distance: curr.realWorldY,
      };
    }
  }

  return null;
}

/**
 * Analyze full trajectory and return metrics
 */
export function analyzeTrajectory(
  trajectory: TrajectoryPoint[],
  isRightHanded: boolean = true,
  fps: number = 120
): TrajectoryAnalysis | null {
  // Filter to only points with real-world coordinates
  const validPoints = trajectory.filter(
    p => p.realWorldX !== undefined && p.realWorldY !== undefined
  );

  if (validPoints.length < 20) return null;

  const firstPoint = validPoints[0];
  const lastPoint = validPoints[validPoints.length - 1];

  // Find arrow crossing (around 15 feet)
  const arrowPoint = validPoints.find(
    p => p.realWorldY !== undefined &&
         p.realWorldY >= LANE.ARROWS_DISTANCE_FEET - 0.5 &&
         p.realWorldY <= LANE.ARROWS_DISTANCE_FEET + 0.5
  );

  const breakpoint = findBreakpoint(trajectory);
  const entryAngle = calculateEntryAngle(trajectory);
  const launchSpeed = calculateSpeed(validPoints[0], validPoints[5], fps);
  const impactSpeed = calculateSpeed(
    validPoints[validPoints.length - 6],
    validPoints[validPoints.length - 1],
    fps
  );

  const idealPocket = isRightHanded ? LANE.POCKET_BOARD_RH : LANE.POCKET_BOARD_LH;
  const pocketOffset = (lastPoint.realWorldX ?? 0) - idealPocket;

  return {
    launchSpeed,
    impactSpeed,
    foulLineBoard: firstPoint.realWorldX ?? 0,
    arrowBoard: arrowPoint?.realWorldX ?? 0,
    breakpointBoard: breakpoint?.board ?? 0,
    breakpointDistance: breakpoint?.distance ?? 0,
    entryAngle,
    pocketBoard: lastPoint.realWorldX ?? 0,
    pocketOffset,
  };
}
