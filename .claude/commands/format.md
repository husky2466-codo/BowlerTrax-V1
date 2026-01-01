# /format - Format Code

Run code formatters on the BowlerTrax project.

## Instructions

1. Detect project type and available formatters:

### For React Native/TypeScript

Check for Prettier:
```bash
cd /Volumes/DevDrive/Projects/BowlerTrax-V1/mobile

# Check if prettier is available
if [ -f "node_modules/.bin/prettier" ] || command -v prettier &> /dev/null; then
  npx prettier --write "**/*.{ts,tsx,js,jsx,json}" --ignore-path .gitignore
fi
```

Check for ESLint with fix:
```bash
npx eslint --fix "**/*.{ts,tsx}" 2>/dev/null || true
```

### For Swift

Check for SwiftFormat:
```bash
# Check if swiftformat is installed
if command -v swiftformat &> /dev/null; then
  swiftformat /Volumes/DevDrive/Projects/BowlerTrax-V1/ios --config .swiftformat 2>/dev/null || \
  swiftformat /Volumes/DevDrive/Projects/BowlerTrax-V1/ios
fi
```

Check for swift-format (Apple's formatter):
```bash
if command -v swift-format &> /dev/null; then
  swift-format format --in-place --recursive /Volumes/DevDrive/Projects/BowlerTrax-V1/ios/
fi
```

2. If no formatter is configured, offer to set one up:
   - For TypeScript: Suggest adding Prettier config
   - For Swift: Suggest installing SwiftFormat via Homebrew

3. Report results:
   - Number of files checked
   - Number of files modified
   - List modified files
   - Any errors encountered

## Output Format

```
Formatting BowlerTrax codebase...

Formatter: Prettier
Config: .prettierrc

Checking files...

Modified files:
- app/(tabs)/index.tsx
- stores/sessionStore.ts
- types/bowling.ts

Summary:
- Files checked: 45
- Files modified: 3
- Errors: 0

Formatting complete!
```

## Arguments

- `--check` or `-c`: Check formatting without modifying files
- `--swift`: Format only Swift files
- `--ts`: Format only TypeScript files
- `--verbose` or `-v`: Show all files being processed

## Usage

```
/format           # Format all files
/format --check   # Check without modifying
/format --swift   # Format only Swift
/format --ts      # Format only TypeScript
```

## Formatter Configs

### Prettier (.prettierrc)
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
```

### SwiftFormat (.swiftformat)
```
--indent 4
--indentcase false
--trimwhitespace always
--voidtype tuple
--wraparguments before-first
--wrapparameters before-first
--maxwidth 120
```

## Notes

- Always run before committing code
- Format command respects .gitignore
- Consider adding format check to pre-commit hook
- If formatter not installed, provide installation instructions
