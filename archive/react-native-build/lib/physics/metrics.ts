/**
 * Bowling Metrics Calculations
 * Rev rate, strike probability, and leave prediction
 */

import { RevSample, RevCategory } from '@/types';
import {
  classifyRevRate,
  calculateStrikeProbability,
  predictLeave,
  OPTIMAL_ENTRY_ANGLE
} from '@/lib/constants/laneDimensions';

export interface RevRateAnalysis {
  /** Calculated RPM */
  rpm: number;
  /** Rev rate category */
  category: RevCategory;
  /** Confidence score 0-1 */
  confidence: number;
  /** Number of rotations counted */
  rotationCount: number;
  /** Analysis duration in seconds */
  durationSeconds: number;
}

/**
 * Calculate rev rate from PAP marker tracking
 * @param samples Array of rev tracking samples
 * @param fps Camera frame rate
 * @returns Rev rate analysis or null if insufficient data
 */
export function calculateRevRate(
  samples: RevSample[],
  fps: number = 120
): RevRateAnalysis | null {
  if (samples.length < 10) return null;

  // Count full rotations by tracking marker position
  // A rotation occurs when marker goes from visible -> not visible -> visible
  let rotationCount = 0;
  let wasVisible = samples[0].markerVisible;

  for (let i = 1; i < samples.length; i++) {
    const isVisible = samples[i].markerVisible;

    // Count when marker becomes visible again (completed rotation)
    if (!wasVisible && isVisible) {
      rotationCount++;
    }
    wasVisible = isVisible;
  }

  // Calculate duration
  const frames = samples.length;
  const durationSeconds = frames / fps;

  if (durationSeconds === 0) return null;

  // Calculate RPM
  const rpm = (rotationCount / durationSeconds) * 60;

  // Confidence based on sample count and duration
  const confidence = Math.min(1, samples.length / 60) * Math.min(1, durationSeconds);

  return {
    rpm: Math.round(rpm),
    category: classifyRevRate(rpm),
    confidence,
    rotationCount,
    durationSeconds,
  };
}

export interface StrikeAnalysis {
  /** Strike probability 0-1 */
  probability: number;
  /** Entry angle in degrees */
  entryAngle: number;
  /** Degrees from optimal (6) */
  angleDeviation: number;
  /** Boards from ideal pocket */
  pocketOffset: number;
  /** Predicted leave if not strike */
  predictedLeave: string;
  /** Is angle in optimal range (4-7 degrees) */
  isOptimalAngle: boolean;
  /** Suggestion for adjustment */
  suggestion: string;
}

/**
 * Analyze strike probability and provide suggestions
 */
export function analyzeStrike(
  entryAngle: number,
  pocketOffset: number,
  isRightHanded: boolean = true
): StrikeAnalysis {
  const probability = calculateStrikeProbability(entryAngle, pocketOffset);
  const angleDeviation = Math.abs(entryAngle - OPTIMAL_ENTRY_ANGLE);
  const isOptimalAngle = entryAngle >= 4 && entryAngle <= 7;
  const predictedLeaveResult = predictLeave(entryAngle, pocketOffset, isRightHanded);

  // Generate suggestion
  let suggestion = '';

  if (probability >= 0.8) {
    suggestion = 'Great shot! Keep this line.';
  } else if (entryAngle < 4) {
    suggestion = 'Entry angle too shallow. Move feet left or increase speed.';
  } else if (entryAngle > 7) {
    suggestion = 'Entry angle too steep. Move feet right or decrease speed.';
  } else if (Math.abs(pocketOffset) > 2) {
    const direction = pocketOffset > 0 ? 'right' : 'left';
    suggestion = `Ball hitting ${direction} of pocket. Adjust target.`;
  } else {
    suggestion = 'Good angle, fine-tune your target line.';
  }

  return {
    probability,
    entryAngle,
    angleDeviation,
    pocketOffset,
    predictedLeave: predictedLeaveResult,
    isOptimalAngle,
    suggestion,
  };
}

/**
 * Format metrics for display
 */
export const formatters = {
  speed: (mph: number) => `${mph.toFixed(1)} mph`,
  angle: (degrees: number) => `${degrees.toFixed(1)}°`,
  board: (board: number) => `${board.toFixed(1)}`,
  rpm: (rpm: number) => `${Math.round(rpm)} RPM`,
  probability: (p: number) => `${Math.round(p * 100)}%`,
  distance: (feet: number) => `${feet.toFixed(1)} ft`,
};
