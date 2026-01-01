# /specs - Load Project Specifications

Load and display relevant specification files to recall design decisions during coding.

## Instructions

1. Parse the argument to determine which spec to show:
   - `ui` - UI/UX specifications and screen designs
   - `cv` - Computer vision and ball tracking specs
   - `state` - State management and data flow
   - `physics` - Physics calculations and algorithms
   - `types` - TypeScript/Swift type definitions
   - `lane` - Lane dimensions and bowling constants
   - `all` - Show overview of all specs

2. Load relevant files based on argument:

### UI Specs
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/BowlerTrax-App-Design.md`
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/Analysis/LaneTrax-App-Analysis.md`
- Show screen layouts, navigation structure, component hierarchy

### CV (Computer Vision) Specs
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/BowlerTrax-Plan.md` (Ball Detection section)
- Show color detection algorithm, frame processing pipeline, tracking logic

### State Specs
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/stores/` - Zustand stores
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/types/` - Type definitions
- Show state shape, actions, selectors

### Physics Specs
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/BowlerTrax-Plan.md` (Physics section)
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/Bowling-Info-Ref.md`
- Show calculations for speed, rev rate, entry angle, trajectory

### Types Specs
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/types/bowling.ts`
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/types/tracking.ts`
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/types/calibration.ts`
- Show all type definitions

### Lane Specs
- `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/lib/constants/laneDimensions.ts`
- Show USBC lane dimensions, arrow positions, board numbers

3. Display the relevant content with clear section headers.

## Usage

```
/specs ui        - Show UI/UX design specs
/specs cv        - Show computer vision specs
/specs state     - Show state management specs
/specs physics   - Show physics calculation specs
/specs types     - Show type definitions
/specs lane      - Show lane dimension constants
/specs all       - Show overview of all specs
/specs           - Same as /specs all
```

## Output Format

```
=== BowlerTrax Specifications: [CATEGORY] ===

Source: [filename]
Last Updated: [date if available]

[Content of spec file with key sections highlighted]

---
Related Files:
- [list of related files for further reference]
```

## Notes

- Use this command before implementing features to ensure alignment with design decisions
- Cross-reference multiple specs when implementing complex features (e.g., CV + Physics for ball tracking)
