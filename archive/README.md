# BowlerTrax Archive

This directory contains archived code from previous implementation attempts.

## Contents

### react-native-build/

**React Native / Expo implementation (Phase 1)**

- **Framework**: React Native with Expo SDK 54
- **Navigation**: Expo Router (file-based routing)
- **State Management**: Zustand stores
- **Styling**: NativeWind v4 (Tailwind CSS)
- **Status**: Completed scaffold with UI screens, navigation, type definitions, and stores

#### Why Archived

Moving to native Swift/SwiftUI for the following reasons:

1. **Better CV Performance**: Native Swift provides direct access to Apple's Vision framework and Metal for GPU-accelerated image processing, essential for real-time ball tracking at 60+ FPS
2. **Lower Latency**: Eliminating the JavaScript bridge reduces frame processing latency significantly
3. **Better Camera Integration**: Native AVFoundation gives more control over camera capture, focus, and exposure
4. **Core ML Integration**: Direct access to Core ML for future ML-based ball detection improvements
5. **Smaller App Size**: Native Swift apps are significantly smaller than React Native bundles

#### Reusable Code for Swift Port

The following can be ported to Swift:

- **Type definitions** (`types/`): Domain models for shots, sessions, calibration can be converted to Swift structs
- **Physics calculations** (`lib/physics/`): Ball speed, rev rate, and trajectory formulas
- **Lane constants** (`lib/constants/laneDimensions.ts`): USBC-standard dimensions
- **UI/UX patterns**: Screen layouts and user flows from the tab navigation

---

**Date Archived**: 2025-12-31

**Archived By**: Claude Code during project reorganization for Swift rebuild
