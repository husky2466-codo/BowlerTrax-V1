import { create } from 'zustand';
import { Session, Shot, SessionStats } from '../types';

interface SessionState {
  // Current active session
  currentSession: Session | null;
  currentShots: Shot[];
  isRecording: boolean;

  // Actions
  startSession: (session: Omit<Session, 'id' | 'createdAt'>) => void;
  endSession: () => void;
  addShot: (shot: Omit<Shot, 'id' | 'sessionId' | 'createdAt'>) => void;
  clearCurrentSession: () => void;

  // Stats
  getSessionStats: () => SessionStats;
}

const generateId = () => Math.random().toString(36).substring(2, 15);

export const useSessionStore = create<SessionState>((set, get) => ({
  currentSession: null,
  currentShots: [],
  isRecording: false,

  startSession: (sessionData) => {
    const session: Session = {
      ...sessionData,
      id: generateId(),
      startTime: new Date().toISOString(),
    };
    set({
      currentSession: session,
      currentShots: [],
      isRecording: true,
    });
  },

  endSession: () => {
    const { currentSession, currentShots } = get();
    if (currentSession) {
      // TODO: Save to SQLite database
      console.log('Saving session:', currentSession, 'with', currentShots.length, 'shots');
    }
    set({ isRecording: false });
  },

  addShot: (shotData) => {
    const { currentSession, currentShots } = get();
    if (!currentSession) return;

    const shot: Shot = {
      ...shotData,
      id: generateId(),
      sessionId: currentSession.id,
      shotNumber: currentShots.length + 1,
      timestamp: new Date().toISOString(),
    };

    set({ currentShots: [...currentShots, shot] });
  },

  clearCurrentSession: () => {
    set({
      currentSession: null,
      currentShots: [],
      isRecording: false,
    });
  },

  getSessionStats: () => {
    const { currentShots } = get();

    if (currentShots.length === 0) {
      return {
        totalShots: 0,
        strikes: 0,
        spares: 0,
        opens: 0,
        avgSpeedMph: 0,
        avgRevRateRpm: 0,
        avgEntryAngle: 0,
        consistencyScore: 0,
      };
    }

    const strikes = currentShots.filter((s) => s.result === 'strike').length;
    const spares = currentShots.filter((s) => s.result === 'spare').length;
    const opens = currentShots.filter((s) => s.result === 'open').length;

    const speeds = currentShots.filter((s) => s.launchSpeed).map((s) => s.launchSpeed!);
    const revRates = currentShots.filter((s) => s.revRate).map((s) => s.revRate!);
    const entryAngles = currentShots.filter((s) => s.entryAngle).map((s) => s.entryAngle!);

    const avgSpeedMph = speeds.length > 0
      ? speeds.reduce((a, b) => a + b, 0) / speeds.length
      : 0;
    const avgRevRateRpm = revRates.length > 0
      ? revRates.reduce((a, b) => a + b, 0) / revRates.length
      : 0;
    const avgEntryAngle = entryAngles.length > 0
      ? entryAngles.reduce((a, b) => a + b, 0) / entryAngles.length
      : 0;

    // Calculate consistency score based on standard deviation of speeds
    let consistencyScore = 100;
    if (speeds.length > 1) {
      const variance = speeds.reduce((sum, speed) => sum + Math.pow(speed - avgSpeedMph, 2), 0) / speeds.length;
      const stdDev = Math.sqrt(variance);
      consistencyScore = Math.max(0, 100 - (stdDev * 10));
    }

    return {
      totalShots: currentShots.length,
      strikes,
      spares,
      opens,
      avgSpeedMph: Math.round(avgSpeedMph * 10) / 10,
      avgRevRateRpm: Math.round(avgRevRateRpm),
      avgEntryAngle: Math.round(avgEntryAngle * 10) / 10,
      consistencyScore: Math.round(consistencyScore),
    };
  },
}));
