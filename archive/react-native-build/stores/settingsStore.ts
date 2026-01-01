import { create } from 'zustand';
import { UserSettings, HandPreference, OilPatternType } from '../types';

// Note: For persistence, add zustand/middleware persist with expo-secure-store or AsyncStorage

interface SettingsState extends UserSettings {
  // Actions
  setHand: (hand: HandPreference) => void;
  setDefaultOilPattern: (pattern: OilPatternType) => void;
  setShowPreviousShot: (show: boolean) => void;
  setAutoSaveVideos: (save: boolean) => void;
  setHapticFeedback: (enabled: boolean) => void;
  resetSettings: () => void;
}

const defaultSettings: UserSettings = {
  hand: 'right',
  defaultOilPattern: 'house',
  showPreviousShot: true,
  autoSaveVideos: true,
  hapticFeedback: true,
};

// Note: AsyncStorage needs to be installed: npx expo install @react-native-async-storage/async-storage
// For now, we'll use a simple in-memory version

export const useSettingsStore = create<SettingsState>()((set) => ({
  ...defaultSettings,

  setHand: (hand) => set({ hand }),
  setDefaultOilPattern: (pattern) => set({ defaultOilPattern: pattern }),
  setShowPreviousShot: (show) => set({ showPreviousShot: show }),
  setAutoSaveVideos: (save) => set({ autoSaveVideos: save }),
  setHapticFeedback: (enabled) => set({ hapticFeedback: enabled }),
  resetSettings: () => set(defaultSettings),
}));
