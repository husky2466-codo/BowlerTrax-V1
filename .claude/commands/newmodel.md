# /newmodel - Create New Data Model

Create a new data model following BowlerTrax project conventions.

## Arguments

Required: Model name (e.g., `Shot`, `Session`, `BallPosition`, `CalibrationData`)

## Instructions

1. Parse the model name from arguments
   - Use PascalCase for type/struct name
   - Generate appropriate filename

2. Determine project type and create appropriate file:

### For TypeScript (React Native)

Create file at `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/types/[modelName].ts`:

```typescript
/**
 * [ModelName] - [Brief description]
 *
 * @description [Detailed description of what this model represents]
 */

export interface [ModelName] {
  /** Unique identifier */
  id: string;

  /** Creation timestamp */
  createdAt: Date;

  /** Last update timestamp */
  updatedAt: Date;

  // TODO: Add model-specific fields
}

/**
 * Input type for creating a new [ModelName]
 */
export type Create[ModelName]Input = Omit<[ModelName], 'id' | 'createdAt' | 'updatedAt'>;

/**
 * Input type for updating an existing [ModelName]
 */
export type Update[ModelName]Input = Partial<Create[ModelName]Input>;

/**
 * Default values for [ModelName]
 */
export const default[ModelName]: [ModelName] = {
  id: '',
  createdAt: new Date(),
  updatedAt: new Date(),
  // TODO: Add default values for model-specific fields
};
```

3. Update the types index file:
   - Add export to `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/types/index.ts`

### For Swift (Native iOS)

Create file at `/Volumes/DevDrive/Projects/BowlerTrax-V1/ios/BowlerTrax/Models/[ModelName].swift`:

```swift
import Foundation

/// [ModelName] - [Brief description]
///
/// [Detailed description of what this model represents]
struct [ModelName]: Identifiable, Codable, Hashable {
    // MARK: - Properties

    /// Unique identifier
    let id: UUID

    /// Creation timestamp
    let createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    // TODO: Add model-specific properties

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
        // TODO: Add parameters for model-specific properties
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties

extension [ModelName] {
    // TODO: Add computed properties
}

// MARK: - Static Properties

extension [ModelName] {
    /// Default instance for previews and testing
    static let preview = [ModelName]()
}
```

4. If model needs persistence, create corresponding:
   - Zustand store action (TypeScript)
   - SwiftData model or CoreData entity (Swift)

5. Report what was created

## Usage

```
/newmodel Shot
/newmodel Session
/newmodel BallPosition
/newmodel CalibrationData
```

## Output Format

```
Creating new model: [ModelName]

File created: /Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/types/[filename].ts

Model Details:
- Type: [ModelName]
- Create Input: Create[ModelName]Input
- Update Input: Update[ModelName]Input
- Default: default[ModelName]

Exports added to: types/index.ts

Next steps:
1. Add model-specific fields
2. Create Zustand store if state management needed
3. Add validation if required
4. Consider adding to SQLite schema
```

## Bowling-Specific Model Templates

For bowling-specific models, include relevant fields:

### Shot Model
```typescript
export interface Shot {
  id: string;
  sessionId: string;
  frameNumber: number;
  ballNumber: 1 | 2 | 3;
  startBoard: number;
  targetBoard: number;
  entryBoard: number;
  entryAngle: number;
  speed: number;
  revRate?: number;
  pinsLeft: number[];
  result: 'strike' | 'spare' | 'open' | 'split';
  trajectoryPoints: Point[];
  createdAt: Date;
}
```

### Session Model
```typescript
export interface Session {
  id: string;
  date: Date;
  location: string;
  laneNumbers: number[];
  oilPattern?: string;
  shots: Shot[];
  totalScore: number;
  strikePercentage: number;
  averageSpeed: number;
  averageEntryAngle: number;
}
```

## Notes

- Follow existing project type conventions
- Include JSDoc/Swift documentation comments
- Add Codable conformance for Swift (persistence)
- Consider relationships to other models
