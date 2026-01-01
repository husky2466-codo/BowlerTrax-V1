# /newscreen - Scaffold New Screen

Create a new screen/view following BowlerTrax project conventions.

## Arguments

Required: Screen name (e.g., `Settings`, `ShotDetail`, `CalibrationWizard`)

## Instructions

1. Parse the screen name from arguments
   - Convert to appropriate casing (PascalCase for component name)
   - Generate kebab-case filename for Expo Router

2. Determine project type and create appropriate file:

### For React Native (Expo Router)

Create file at `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/app/[name].tsx`:

```tsx
import { View, Text, StyleSheet } from 'react-native';
import { Stack } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function [ScreenName]Screen() {
  return (
    <SafeAreaView style={styles.container}>
      <Stack.Screen
        options={{
          title: '[Screen Title]',
          headerShown: true,
        }}
      />
      <View style={styles.content}>
        <Text style={styles.title}>[Screen Name]</Text>
        {/* TODO: Implement screen content */}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a0a0a',
  },
  content: {
    flex: 1,
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#ffffff',
    marginBottom: 16,
  },
});
```

### For Native SwiftUI

Create file at `/Volumes/DevDrive/Projects/BowlerTrax-V1/ios/BowlerTrax/Views/[ScreenName]View.swift`:

```swift
import SwiftUI

struct [ScreenName]View: View {
    // MARK: - Properties

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                Text("[Screen Name]")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                // TODO: Implement screen content
            }
            .padding()
            .navigationTitle("[Screen Title]")
            .background(Color.black)
        }
    }
}

// MARK: - Preview
#Preview {
    [ScreenName]View()
        .preferredColorScheme(.dark)
}
```

3. If screen is a tab, update tab navigation:
   - For Expo: Update `/Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/app/(tabs)/_layout.tsx`
   - For SwiftUI: Update main TabView

4. Report what was created:
   - File path
   - Screen name
   - Navigation integration status

## Usage

```
/newscreen Settings
/newscreen ShotDetail
/newscreen CalibrationWizard
/newscreen session/[id]    # Dynamic route
```

## Output Format

```
Creating new screen: [ScreenName]

File created: /Volumes/DevDrive/Projects/BowlerTrax-V1/mobile/app/[filename].tsx

Screen Details:
- Component: [ScreenName]Screen
- Route: /[route-path]
- Navigation: [Added to tabs / Standalone screen]

Next steps:
1. Implement screen content
2. Add navigation links from other screens
3. Connect to relevant stores if needed
```

## Notes

- Follow existing project styling conventions
- Use dark theme by default (matches BowlerTrax design)
- Import relevant stores and types as needed
- For tab screens, include icon selection
