/**
 * useBallTracking Hook
 * Ball detection and trajectory tracking state management
 */

import { useState, useCallback, useRef } from 'react';
import { ColorTracker, createColorTracker } from '@/lib/cv/colorTracker';
import { TrajectoryPoint, BallDetection, HSVColor } from '@/types';

export interface UseBallTrackingReturn {
  /** Is tracking active */
  isTracking: boolean;
  /** Start tracking */
  startTracking: () => void;
  /** Stop tracking */
  stopTracking: () => void;
  /** Current ball detection */
  currentDetection: BallDetection | null;
  /** Full trajectory */
  trajectory: TrajectoryPoint[];
  /** Clear trajectory */
  clearTrajectory: () => void;
  /** Set target ball color from tap */
  setTargetColor: (rgb: { r: number; g: number; b: number }) => void;
  /** Current target color */
  targetColor: HSVColor | null;
  /** Has target color been set */
  hasTargetColor: boolean;
  /** Frame count processed */
  frameCount: number;
}

export function useBallTracking(): UseBallTrackingReturn {
  const [isTracking, setIsTracking] = useState(false);
  const [currentDetection, setCurrentDetection] = useState<BallDetection | null>(null);
  const [trajectory, setTrajectory] = useState<TrajectoryPoint[]>([]);
  const [targetColor, setTargetColorState] = useState<HSVColor | null>(null);
  const [frameCount, setFrameCount] = useState(0);

  const trackerRef = useRef<ColorTracker>(createColorTracker());

  const startTracking = useCallback(() => {
    trackerRef.current.clearTrajectory();
    setTrajectory([]);
    setCurrentDetection(null);
    setFrameCount(0);
    setIsTracking(true);
  }, []);

  const stopTracking = useCallback(() => {
    setIsTracking(false);
    setTrajectory(trackerRef.current.getTrajectory());
    setFrameCount(trackerRef.current.getFrameCount());
  }, []);

  const clearTrajectory = useCallback(() => {
    trackerRef.current.clearTrajectory();
    setTrajectory([]);
    setCurrentDetection(null);
    setFrameCount(0);
  }, []);

  const setTargetColor = useCallback((rgb: { r: number; g: number; b: number }) => {
    trackerRef.current.setTargetColor(rgb);
    setTargetColorState(trackerRef.current.getTargetColor());
  }, []);

  return {
    isTracking,
    startTracking,
    stopTracking,
    currentDetection,
    trajectory,
    clearTrajectory,
    setTargetColor,
    targetColor,
    hasTargetColor: targetColor !== null,
    frameCount,
  };
}
