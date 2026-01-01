import { create } from 'zustand';
import { CalibrationProfile, CalibrationWizardState } from '../types';

interface CalibrationState {
  // Saved calibrations
  calibrations: CalibrationProfile[];
  activeCalibration: CalibrationProfile | null;

  // Wizard state
  wizardState: CalibrationWizardState;

  // Actions
  saveCalibration: (calibration: Omit<CalibrationProfile, 'id' | 'createdAt'>) => void;
  setActiveCalibration: (id: string | null) => void;
  deleteCalibration: (id: string) => void;

  // Wizard actions
  setWizardStep: (step: CalibrationWizardState['step']) => void;
  setFoulLineY: (y: number) => void;
  addArrowPoint: (point: { arrowNumber: number; pixelX: number; pixelY: number; boardNumber: number }) => void;
  clearArrowPoints: () => void;
  calculateCalibration: () => void;
  resetWizard: () => void;
}

const generateId = () => Math.random().toString(36).substring(2, 15);

const initialWizardState: CalibrationWizardState = {
  step: 'position',
  foulLineY: undefined,
  arrowPoints: [],
  pixelsPerFoot: undefined,
  pixelsPerBoard: undefined,
  isValid: false,
  errorMessage: undefined,
};

export const useCalibrationStore = create<CalibrationState>((set, get) => ({
  calibrations: [],
  activeCalibration: null,
  wizardState: { ...initialWizardState },

  saveCalibration: (calibrationData) => {
    const calibration: CalibrationProfile = {
      ...calibrationData,
      id: generateId(),
      createdAt: new Date().toISOString(),
    };

    set((state) => ({
      calibrations: [...state.calibrations, calibration],
      activeCalibration: calibration,
    }));

    // TODO: Save to SQLite
  },

  setActiveCalibration: (id) => {
    const { calibrations } = get();
    const calibration = id ? calibrations.find((c) => c.id === id) : null;
    set({ activeCalibration: calibration || null });
  },

  deleteCalibration: (id) => {
    set((state) => ({
      calibrations: state.calibrations.filter((c) => c.id !== id),
      activeCalibration: state.activeCalibration?.id === id ? null : state.activeCalibration,
    }));
    // TODO: Delete from SQLite
  },

  setWizardStep: (step) => {
    set((state) => ({
      wizardState: { ...state.wizardState, step },
    }));
  },

  setFoulLineY: (y) => {
    set((state) => ({
      wizardState: { ...state.wizardState, foulLineY: y },
    }));
  },

  addArrowPoint: (point) => {
    set((state) => ({
      wizardState: {
        ...state.wizardState,
        arrowPoints: [...state.wizardState.arrowPoints, point],
      },
    }));
  },

  clearArrowPoints: () => {
    set((state) => ({
      wizardState: { ...state.wizardState, arrowPoints: [] },
    }));
  },

  calculateCalibration: () => {
    const { wizardState } = get();
    const { foulLineY, arrowPoints } = wizardState;

    if (!foulLineY || arrowPoints.length < 2) {
      set((state) => ({
        wizardState: {
          ...state.wizardState,
          isValid: false,
          errorMessage: 'Need foul line and at least 2 arrows marked',
        },
      }));
      return;
    }

    // Calculate pixels per board from arrow spacing
    const arrow1 = arrowPoints[0];
    const arrow2 = arrowPoints[1];
    const pixelDistance = Math.abs(arrow2.pixelX - arrow1.pixelX);
    const boardDistance = Math.abs(arrow2.boardNumber - arrow1.boardNumber);
    const pixelsPerBoard = pixelDistance / boardDistance;

    // Calculate pixels per foot from foul line to arrows
    // Arrows are 15 feet from foul line
    const arrowY = (arrow1.pixelY + arrow2.pixelY) / 2;
    const foulToArrowPixels = Math.abs(foulLineY - arrowY);
    const pixelsPerFoot = foulToArrowPixels / 15;

    set((state) => ({
      wizardState: {
        ...state.wizardState,
        pixelsPerFoot,
        pixelsPerBoard,
        isValid: true,
        errorMessage: undefined,
      },
    }));
  },

  resetWizard: () => {
    set({ wizardState: { ...initialWizardState } });
  },
}));
