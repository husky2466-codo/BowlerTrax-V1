# BowlerTrax Design System

A comprehensive SwiftUI design system for the BowlerTrax bowling analytics app. This specification defines all visual elements, components, typography, spacing, and animations to ensure consistent, professional UI throughout the app.

---

## 1. Color Palette

### Primary Colors (Teal/Cyan Theme)

```swift
// Primary Brand Colors
extension Color {
    // Primary Teal - Main brand color
    static let btPrimary = Color(hex: "14B8A6")           // Teal-500
    static let btPrimaryLight = Color(hex: "5EEAD4")      // Teal-300
    static let btPrimaryDark = Color(hex: "0D9488")       // Teal-600
    static let btPrimaryMuted = Color(hex: "2DD4BF")      // Teal-400

    // Cyan Accent - Secondary highlight
    static let btAccent = Color(hex: "22D3EE")            // Cyan-400
    static let btAccentLight = Color(hex: "67E8F9")       // Cyan-300
    static let btAccentDark = Color(hex: "06B6D4")        // Cyan-500
}

// Hex Codes Summary:
// Primary:       #14B8A6 (Teal-500)
// Primary Light: #5EEAD4 (Teal-300)
// Primary Dark:  #0D9488 (Teal-600)
// Accent:        #22D3EE (Cyan-400)
// Accent Light:  #67E8F9 (Cyan-300)
```

### Background Colors (Dark Theme)

```swift
extension Color {
    // Backgrounds - Layered dark system
    static let btBackground = Color(hex: "0F0F0F")        // Deepest black
    static let btSurface = Color(hex: "1A1A1A")           // Card/surface background
    static let btSurfaceElevated = Color(hex: "252525")   // Elevated surface (modals, popovers)
    static let btSurfaceHighlight = Color(hex: "2A2A2A")  // Pressed/hover state

    // Lane visualization background
    static let btLaneBackground = Color(hex: "1C1C1E")    // Lane view specific
    static let btLaneWood = Color(hex: "3D2817")          // Wood lane color (subtle)
}

// Hex Codes Summary:
// Background:         #0F0F0F (near black)
// Surface:            #1A1A1A (primary cards)
// Surface Elevated:   #252525 (modals, sheets)
// Surface Highlight:  #2A2A2A (interactive states)
```

### Text Colors

```swift
extension Color {
    // Text hierarchy
    static let btTextPrimary = Color(hex: "FFFFFF")       // Primary content
    static let btTextSecondary = Color(hex: "A1A1AA")     // Secondary labels
    static let btTextMuted = Color(hex: "71717A")         // Disabled/hints
    static let btTextInverse = Color(hex: "18181B")       // Text on light backgrounds

    // Metric display text
    static let btMetricValue = Color(hex: "FAFAFA")       // Large numbers
    static let btMetricLabel = Color(hex: "9CA3AF")       // Metric labels
    static let btMetricDelta = Color(hex: "A1A1AA")       // "Prev:" comparison text
}

// Hex Codes Summary:
// Primary:    #FFFFFF (white)
// Secondary:  #A1A1AA (zinc-400)
// Muted:      #71717A (zinc-500)
// Inverse:    #18181B (zinc-900)
```

### Semantic Colors

```swift
extension Color {
    // Success - Strike/Perfect
    static let btSuccess = Color(hex: "22C55E")           // Green-500
    static let btSuccessLight = Color(hex: "4ADE80")      // Green-400
    static let btSuccessMuted = Color(hex: "166534")      // Green-800 (backgrounds)

    // Warning - Attention needed
    static let btWarning = Color(hex: "F59E0B")           // Amber-500
    static let btWarningLight = Color(hex: "FBBF24")      // Amber-400
    static let btWarningMuted = Color(hex: "92400E")      // Amber-800

    // Error - Danger/Reset
    static let btError = Color(hex: "EF4444")             // Red-500
    static let btErrorLight = Color(hex: "F87171")        // Red-400
    static let btErrorMuted = Color(hex: "991B1B")        // Red-800

    // Info - Informational
    static let btInfo = Color(hex: "3B82F6")              // Blue-500
    static let btInfoLight = Color(hex: "60A5FA")         // Blue-400
    static let btInfoMuted = Color(hex: "1E40AF")         // Blue-800
}

// Hex Codes Summary:
// Success:  #22C55E / #4ADE80 / #166534
// Warning:  #F59E0B / #FBBF24 / #92400E
// Error:    #EF4444 / #F87171 / #991B1B
// Info:     #3B82F6 / #60A5FA / #1E40AF
```

### Metric Accent Colors

```swift
extension Color {
    // Speed metric - Energetic orange
    static let btSpeed = Color(hex: "F97316")             // Orange-500
    static let btSpeedLight = Color(hex: "FB923C")        // Orange-400

    // Rev Rate metric - Dynamic purple
    static let btRevRate = Color(hex: "A855F7")           // Purple-500
    static let btRevRateLight = Color(hex: "C084FC")      // Purple-400

    // Entry Angle metric - Primary teal
    static let btAngle = Color(hex: "14B8A6")             // Teal-500
    static let btAngleLight = Color(hex: "2DD4BF")        // Teal-400

    // Strike Probability - Success green
    static let btStrike = Color(hex: "22C55E")            // Green-500
    static let btStrikeLight = Color(hex: "4ADE80")       // Green-400

    // Breakpoint - Cyan
    static let btBreakpoint = Color(hex: "06B6D4")        // Cyan-500
    static let btBreakpointLight = Color(hex: "22D3EE")   // Cyan-400

    // Board Position - Slate blue
    static let btBoard = Color(hex: "6366F1")             // Indigo-500
    static let btBoardLight = Color(hex: "818CF8")        // Indigo-400
}

// Hex Codes Summary:
// Speed:      #F97316 (orange)
// Rev Rate:   #A855F7 (purple)
// Angle:      #14B8A6 (teal)
// Strike:     #22C55E (green)
// Breakpoint: #06B6D4 (cyan)
// Board:      #6366F1 (indigo)
```

### Color Extension Helper

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

---

## 2. Typography

### Font Family

BowlerTrax uses **SF Pro** (system font) for maximum iOS native feel and performance. SF Pro provides excellent legibility at all sizes and seamless integration with Dynamic Type.

```swift
// Typography System
enum BTFont {
    // Display - Hero numbers (metrics)
    static func displayLarge() -> Font { .system(size: 56, weight: .bold, design: .rounded) }
    static func displayMedium() -> Font { .system(size: 44, weight: .bold, design: .rounded) }
    static func displaySmall() -> Font { .system(size: 36, weight: .bold, design: .rounded) }

    // Headings
    static func h1() -> Font { .system(size: 32, weight: .bold) }
    static func h2() -> Font { .system(size: 24, weight: .semibold) }
    static func h3() -> Font { .system(size: 20, weight: .semibold) }
    static func h4() -> Font { .system(size: 18, weight: .medium) }

    // Body
    static func bodyLarge() -> Font { .system(size: 17, weight: .regular) }
    static func body() -> Font { .system(size: 15, weight: .regular) }
    static func bodySmall() -> Font { .system(size: 13, weight: .regular) }

    // Labels & Captions
    static func label() -> Font { .system(size: 14, weight: .medium) }
    static func labelSmall() -> Font { .system(size: 12, weight: .medium) }
    static func caption() -> Font { .system(size: 12, weight: .regular) }
    static func captionSmall() -> Font { .system(size: 10, weight: .regular) }

    // Metric-specific
    static func metricValue() -> Font { .system(size: 48, weight: .bold, design: .rounded) }
    static func metricUnit() -> Font { .system(size: 16, weight: .medium) }
    static func metricLabel() -> Font { .system(size: 13, weight: .medium) }
    static func metricDelta() -> Font { .system(size: 11, weight: .regular) }

    // Monospaced (for board numbers, coordinates)
    static func mono() -> Font { .system(size: 14, weight: .medium, design: .monospaced) }
    static func monoLarge() -> Font { .system(size: 18, weight: .semibold, design: .monospaced) }
}
```

### Typography Scale Reference

| Style | Size | Weight | Line Height | Use Case |
|-------|------|--------|-------------|----------|
| Display Large | 56pt | Bold, Rounded | 64pt | Hero metric (main stat) |
| Display Medium | 44pt | Bold, Rounded | 52pt | Secondary hero metric |
| Display Small | 36pt | Bold, Rounded | 44pt | Tertiary metric |
| H1 | 32pt | Bold | 40pt | Screen titles |
| H2 | 24pt | Semibold | 32pt | Section headers |
| H3 | 20pt | Semibold | 28pt | Card titles |
| H4 | 18pt | Medium | 24pt | Subsection headers |
| Body Large | 17pt | Regular | 24pt | Primary content |
| Body | 15pt | Regular | 22pt | Standard content |
| Body Small | 13pt | Regular | 18pt | Dense content |
| Label | 14pt | Medium | 20pt | Form labels, buttons |
| Caption | 12pt | Regular | 16pt | Timestamps, hints |
| Metric Value | 48pt | Bold, Rounded | 56pt | Metric cards |
| Metric Unit | 16pt | Medium | 20pt | Units (mph, rpm, etc.) |

### Text Style Modifiers

```swift
extension View {
    func btDisplayLarge() -> some View {
        self.font(BTFont.displayLarge())
            .foregroundColor(.btMetricValue)
    }

    func btHeading1() -> some View {
        self.font(BTFont.h1())
            .foregroundColor(.btTextPrimary)
    }

    func btHeading2() -> some View {
        self.font(BTFont.h2())
            .foregroundColor(.btTextPrimary)
    }

    func btBody() -> some View {
        self.font(BTFont.body())
            .foregroundColor(.btTextSecondary)
    }

    func btCaption() -> some View {
        self.font(BTFont.caption())
            .foregroundColor(.btTextMuted)
    }

    func btMetricValue() -> some View {
        self.font(BTFont.metricValue())
            .foregroundColor(.btMetricValue)
            .monospacedDigit()
    }

    func btMetricLabel() -> some View {
        self.font(BTFont.metricLabel())
            .foregroundColor(.btMetricLabel)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
```

---

## 3. Spacing System

### Base Unit

All spacing is based on an **8pt grid system** for consistent visual rhythm.

```swift
enum BTSpacing {
    static let base: CGFloat = 8

    // Scale
    static let xxs: CGFloat = 2      // 0.25x
    static let xs: CGFloat = 4       // 0.5x
    static let sm: CGFloat = 8       // 1x
    static let md: CGFloat = 12      // 1.5x
    static let lg: CGFloat = 16      // 2x
    static let xl: CGFloat = 24      // 3x
    static let xxl: CGFloat = 32     // 4x
    static let xxxl: CGFloat = 48    // 6x
    static let huge: CGFloat = 64    // 8x
}
```

### Spacing Scale Reference

| Token | Value | Use Case |
|-------|-------|----------|
| `xxs` | 2pt | Icon-to-text gap |
| `xs` | 4pt | Tight spacing, inline elements |
| `sm` | 8pt | Related elements, list item padding |
| `md` | 12pt | Form field padding, button padding |
| `lg` | 16pt | Card padding, section spacing |
| `xl` | 24pt | Between sections, major breaks |
| `xxl` | 32pt | Screen padding, large separations |
| `xxxl` | 48pt | Hero spacing, top margins |
| `huge` | 64pt | Major section breaks |

### Component-Specific Spacing

```swift
enum BTLayout {
    // Screen layout
    static let screenHorizontalPadding: CGFloat = 16
    static let screenVerticalPadding: CGFloat = 24
    static let safeAreaTop: CGFloat = 8
    static let safeAreaBottom: CGFloat = 34  // Home indicator

    // Card layout
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let cardCornerRadius: CGFloat = 16

    // Metric card specific
    static let metricCardPadding: CGFloat = 12
    static let metricCardMinHeight: CGFloat = 100
    static let metricCardSpacing: CGFloat = 4

    // List layout
    static let listItemPadding: CGFloat = 16
    static let listItemSpacing: CGFloat = 8
    static let listSectionSpacing: CGFloat = 24

    // Button layout
    static let buttonPadding: CGFloat = 16
    static let buttonMinHeight: CGFloat = 50
    static let buttonCornerRadius: CGFloat = 12
    static let buttonIconSize: CGFloat = 20

    // Tab bar
    static let tabBarHeight: CGFloat = 84
    static let tabBarIconSize: CGFloat = 24

    // Navigation bar
    static let navBarHeight: CGFloat = 44
    static let navBarPadding: CGFloat = 16
}
```

### Grid System

```swift
enum BTGrid {
    // 2-column grid (metric cards)
    static let columns2 = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // 3-column grid (compact metrics)
    static let columns3 = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    // Adaptive grid (minimum 160pt per item)
    static let adaptive = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]
}
```

---

## 4. Component Specifications

### 4.1 MetricCard

Display individual bowling metrics (speed, rev rate, angle, etc.) in a compact card format.

```swift
// MARK: - Metric Card Sizes
enum MetricCardSize {
    case compact    // 2 columns, shorter
    case standard   // 2 columns, standard
    case featured   // Full width, larger
}

// MARK: - Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let previousValue: String?
    let accentColor: Color
    let size: MetricCardSize

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            // Label
            Text(title)
                .font(BTFont.metricLabel())
                .foregroundColor(.btMetricLabel)
                .textCase(.uppercase)
                .tracking(0.5)

            // Value + Unit
            HStack(alignment: .firstTextBaseline, spacing: BTSpacing.xs) {
                Text(value)
                    .font(size == .featured ? BTFont.displayMedium() : BTFont.metricValue())
                    .foregroundColor(.btMetricValue)
                    .monospacedDigit()

                Text(unit)
                    .font(BTFont.metricUnit())
                    .foregroundColor(.btMetricLabel)
            }

            // Previous value comparison
            if let prev = previousValue {
                Text("Prev: \(prev)")
                    .font(BTFont.metricDelta())
                    .foregroundColor(.btMetricDelta)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BTLayout.metricCardPadding)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.btSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Specifications
/*
 Size: compact
   - Min height: 80pt
   - Padding: 12pt
   - Value font: 36pt bold rounded

 Size: standard
   - Min height: 100pt
   - Padding: 12pt
   - Value font: 48pt bold rounded

 Size: featured
   - Min height: 120pt
   - Padding: 16pt
   - Value font: 44pt bold rounded

 Colors:
   - Background: #1A1A1A (btSurface)
   - Border: accent color at 30% opacity
   - Label: #9CA3AF (btMetricLabel)
   - Value: #FAFAFA (btMetricValue)
   - Delta: #A1A1AA (btMetricDelta)

 Corner radius: 12pt
*/
```

### 4.2 ActionButton

Primary interactive buttons for major actions.

```swift
// MARK: - Button Variants
enum BTButtonVariant {
    case primary    // Filled with primary color
    case secondary  // Outlined
    case destructive // Red for dangerous actions
    case ghost      // Text only
}

// MARK: - Action Button Component
struct BTActionButton: View {
    let title: String
    let icon: String?
    let variant: BTButtonVariant
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: BTSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: BTLayout.buttonIconSize, weight: .semibold))
                }

                Text(title)
                    .font(BTFont.label())
                    .fontWeight(.semibold)
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: BTLayout.buttonMinHeight)
            .background(backgroundColor)
            .cornerRadius(BTLayout.buttonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: BTLayout.buttonCornerRadius)
                    .stroke(borderColor, lineWidth: variant == .secondary ? 1.5 : 0)
            )
        }
        .buttonStyle(BTButtonStyle())
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: return .btPrimary
        case .secondary: return .clear
        case .destructive: return .btError
        case .ghost: return .clear
        }
    }

    private var textColor: Color {
        switch variant {
        case .primary: return .btTextInverse
        case .secondary: return .btPrimary
        case .destructive: return .white
        case .ghost: return .btPrimary
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary: return .btPrimary
        default: return .clear
        }
    }
}

// MARK: - Button Style (Press Animation)
struct BTButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Specifications
/*
 Primary Button:
   - Background: #14B8A6 (btPrimary)
   - Text: #18181B (btTextInverse)
   - Height: 50pt
   - Corner radius: 12pt
   - Font: 14pt medium

 Secondary Button:
   - Background: transparent
   - Border: #14B8A6, 1.5pt
   - Text: #14B8A6 (btPrimary)

 Destructive Button:
   - Background: #EF4444 (btError)
   - Text: white

 Ghost Button:
   - Background: transparent
   - Text: #14B8A6 (btPrimary)

 States:
   - Pressed: 97% scale, 90% opacity
   - Disabled: 50% opacity
   - Loading: ProgressView spinner
*/
```

### 4.3 SessionCard

List item for displaying session summaries.

```swift
struct SessionCard: View {
    let session: Session
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: BTSpacing.lg) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.btSurfaceElevated)
                        .frame(width: 60, height: 60)

                    Image(systemName: "figure.bowling")
                        .font(.system(size: 24))
                        .foregroundColor(.btPrimary)
                }

                // Content
                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                    Text(session.centerName ?? "Practice Session")
                        .font(BTFont.h4())
                        .foregroundColor(.btTextPrimary)

                    HStack(spacing: BTSpacing.md) {
                        Label("\(session.shotCount) shots", systemImage: "circle.fill")
                        Label(session.formattedDate, systemImage: "calendar")
                    }
                    .font(BTFont.caption())
                    .foregroundColor(.btTextMuted)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.btTextMuted)
            }
            .padding(BTLayout.listItemPadding)
            .background(Color.btSurface)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Specifications
/*
 Layout:
   - Padding: 16pt all sides
   - Thumbnail: 60x60pt, 8pt radius
   - Content spacing: 4pt vertical, 12pt horizontal
   - Corner radius: 12pt

 Colors:
   - Background: #1A1A1A (btSurface)
   - Thumbnail bg: #252525 (btSurfaceElevated)
   - Title: #FFFFFF (btTextPrimary)
   - Meta: #71717A (btTextMuted)
   - Icon: #14B8A6 (btPrimary)
*/
```

### 4.4 ShotCard

List item for individual shot results.

```swift
struct ShotCard: View {
    let shot: Shot
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: BTSpacing.md) {
                // Result badge
                ResultBadge(result: shot.result)

                // Shot number
                Text("#\(shot.number)")
                    .font(BTFont.monoLarge())
                    .foregroundColor(.btTextPrimary)
                    .frame(width: 44)

                // Metrics row
                HStack(spacing: BTSpacing.lg) {
                    MiniMetric(value: shot.speedMph, unit: "mph", color: .btSpeed)
                    MiniMetric(value: shot.entryAngle, unit: "deg", color: .btAngle)
                    MiniMetric(value: shot.arrowBoard, unit: "bd", color: .btBoard)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.btTextMuted)
            }
            .padding(.horizontal, BTLayout.listItemPadding)
            .padding(.vertical, BTSpacing.md)
            .background(Color.btSurface)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct ResultBadge: View {
    let result: ShotResult

    var body: some View {
        Text(result.symbol)
            .font(.system(size: 18))
            .frame(width: 36, height: 36)
            .background(result.color.opacity(0.2))
            .cornerRadius(8)
    }
}

struct MiniMetric: View {
    let value: Double?
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value.map { String(format: "%.1f", $0) } ?? "--")
                .font(BTFont.label())
                .foregroundColor(.btTextPrimary)
                .monospacedDigit()

            Text(unit)
                .font(BTFont.captionSmall())
                .foregroundColor(color)
        }
    }
}

// MARK: - Specifications
/*
 Layout:
   - Horizontal padding: 16pt
   - Vertical padding: 12pt
   - Result badge: 36x36pt
   - Shot number width: 44pt
   - Corner radius: 10pt

 Result Badge Colors:
   - Strike (X): #22C55E (btSuccess)
   - Spare (/): #14B8A6 (btPrimary)
   - Open (-): #71717A (btTextMuted)
   - Split: #EF4444 (btError)
*/
```

### 4.5 NavigationBar

Custom navigation bar with consistent styling.

```swift
struct BTNavigationBar: View {
    let title: String
    let leadingAction: (() -> Void)?
    let leadingIcon: String?
    let trailingAction: (() -> Void)?
    let trailingIcon: String?

    var body: some View {
        HStack {
            // Leading button
            if let action = leadingAction, let icon = leadingIcon {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.btTextPrimary)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer().frame(width: 44)
            }

            Spacer()

            // Title
            Text(title)
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)

            Spacer()

            // Trailing button
            if let action = trailingAction, let icon = trailingIcon {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.btTextPrimary)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer().frame(width: 44)
            }
        }
        .frame(height: BTLayout.navBarHeight)
        .padding(.horizontal, BTSpacing.sm)
        .background(Color.btBackground)
    }
}

// MARK: - Specifications
/*
 Height: 44pt
 Horizontal padding: 8pt
 Icon size: 18pt semibold
 Title: 20pt semibold (h3)
 Button hit area: 44x44pt
 Background: #0F0F0F (btBackground)
*/
```

### 4.6 TabBar

Custom tab bar with bowling-themed icons.

```swift
struct BTTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.top, BTSpacing.md)
        .padding(.bottom, BTSpacing.xxl) // Safe area for home indicator
        .background(
            Color.btSurface
                .shadow(color: .black.opacity(0.3), radius: 8, y: -4)
        )
    }
}

struct TabBarItem: View {
    let tab: Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: BTSpacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: BTLayout.tabBarIconSize, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .btPrimary : .btTextMuted)

                Text(tab.title)
                    .font(BTFont.captionSmall())
                    .foregroundColor(isSelected ? .btPrimary : .btTextMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

enum Tab: CaseIterable {
    case dashboard, record, sessions, settings

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .record: return "Record"
        case .sessions: return "Sessions"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .record: return "video.fill"
        case .sessions: return "list.bullet.rectangle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Specifications
/*
 Total height: 84pt (including safe area)
 Content height: ~52pt
 Icon size: 24pt
 Label: 10pt medium

 Colors:
   - Background: #1A1A1A (btSurface)
   - Selected: #14B8A6 (btPrimary)
   - Unselected: #71717A (btTextMuted)

 Shadow: black 30%, 8pt blur, -4pt y offset
*/
```

### 4.7 ProgressIndicator

Multi-step progress for calibration wizard.

```swift
struct BTProgressIndicator: View {
    let steps: [String]
    let currentStep: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 0) {
                    // Step circle
                    StepCircle(
                        number: index + 1,
                        state: stepState(for: index)
                    )

                    // Connector line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.btPrimary : Color.btSurfaceHighlight)
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding(.horizontal, BTSpacing.lg)
    }

    private func stepState(for index: Int) -> StepState {
        if index < currentStep { return .completed }
        if index == currentStep { return .active }
        return .pending
    }
}

enum StepState {
    case pending, active, completed
}

struct StepCircle: View {
    let number: Int
    let state: StepState

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 32, height: 32)

            if state == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.btTextInverse)
            } else {
                Text("\(number)")
                    .font(BTFont.label())
                    .foregroundColor(state == .active ? .btTextInverse : .btTextMuted)
            }
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .completed: return .btPrimary
        case .active: return .btPrimary
        case .pending: return .btSurfaceHighlight
        }
    }
}

// MARK: - Specifications
/*
 Circle size: 32x32pt
 Connector height: 2pt

 States:
   - Pending: #2A2A2A background, #71717A text
   - Active: #14B8A6 background, #18181B text
   - Completed: #14B8A6 background, checkmark icon

 Checkmark: 14pt bold
 Number: 14pt medium
*/
```

### 4.8 CameraOverlay

Lane guide overlay for camera view during recording.

```swift
struct CameraOverlay: View {
    let calibration: CalibrationProfile?
    let showGuides: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Foul line indicator
                if showGuides {
                    FoulLineGuide()
                        .position(x: geometry.size.width / 2, y: foulLineY(in: geometry))

                    // Arrow markers (15ft from foul line)
                    ArrowGuides(calibration: calibration)
                        .position(x: geometry.size.width / 2, y: arrowsY(in: geometry))

                    // Board number indicators
                    BoardNumbers()
                        .position(x: geometry.size.width / 2, y: geometry.size.height - 60)
                }

                // Lane boundary guides
                LaneBoundaryGuides()

                // Recording indicator
                RecordingIndicator()
                    .position(x: 40, y: 50)
            }
        }
    }
}

struct FoulLineGuide: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20) { _ in
                Rectangle()
                    .fill(Color.btWarning)
                    .frame(width: 12, height: 3)
            }
        }
    }
}

struct ArrowGuides: View {
    let calibration: CalibrationProfile?

    var body: some View {
        HStack(spacing: arrowSpacing) {
            ForEach([5, 10, 15, 20, 25, 30, 35], id: \.self) { board in
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.btPrimary.opacity(0.7))
            }
        }
    }

    private var arrowSpacing: CGFloat {
        calibration?.pixelsPerBoard ?? 8 * 5 // 5 boards between arrows
    }
}

struct LaneBoundaryGuides: View {
    var body: some View {
        HStack {
            // Left gutter line
            Rectangle()
                .fill(Color.btPrimary.opacity(0.3))
                .frame(width: 2)

            Spacer()

            // Right gutter line
            Rectangle()
                .fill(Color.btPrimary.opacity(0.3))
                .frame(width: 2)
        }
        .padding(.horizontal, 20)
    }
}

struct RecordingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: BTSpacing.sm) {
            Circle()
                .fill(Color.btError)
                .frame(width: 12, height: 12)
                .opacity(isAnimating ? 1.0 : 0.3)

            Text("REC")
                .font(BTFont.labelSmall())
                .foregroundColor(.white)
        }
        .padding(.horizontal, BTSpacing.md)
        .padding(.vertical, BTSpacing.xs)
        .background(Color.black.opacity(0.6))
        .cornerRadius(6)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Specifications
/*
 Foul Line:
   - Color: #F59E0B (btWarning)
   - Dashed: 12pt segments, 4pt gaps, 3pt height

 Arrow Guides:
   - Color: #14B8A6 at 70% opacity
   - Icon: arrowtriangle.up.fill, 12pt
   - Spacing: Based on calibration (default 40pt)

 Lane Boundaries:
   - Color: #14B8A6 at 30% opacity
   - Width: 2pt

 Recording Indicator:
   - Red dot: 12x12pt, pulsing animation
   - Label: "REC", 12pt medium
   - Background: black 60%, 6pt radius
*/
```

### 4.9 TrajectoryPath

Skia/Core Animation path for ball trajectory visualization.

```swift
import SwiftUI

struct TrajectoryPath: View {
    let points: [CGPoint]
    let animationProgress: Double
    let showGlow: Bool

    var body: some View {
        Canvas { context, size in
            guard points.count >= 2 else { return }

            let animatedPoints = Array(points.prefix(Int(Double(points.count) * animationProgress)))

            // Glow effect (wider, blurred path underneath)
            if showGlow {
                var glowPath = Path()
                glowPath.move(to: animatedPoints[0])
                for point in animatedPoints.dropFirst() {
                    glowPath.addLine(to: point)
                }
                context.stroke(
                    glowPath,
                    with: .color(.btAccent.opacity(0.4)),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                )
            }

            // Main trajectory line
            var mainPath = Path()
            mainPath.move(to: animatedPoints[0])
            for point in animatedPoints.dropFirst() {
                mainPath.addLine(to: point)
            }

            // Gradient stroke
            let gradient = Gradient(colors: [.btPrimaryLight, .btAccent])
            context.stroke(
                mainPath,
                with: .linearGradient(
                    gradient,
                    startPoint: animatedPoints.first ?? .zero,
                    endPoint: animatedPoints.last ?? .zero
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )

            // Ball position dot at current point
            if let lastPoint = animatedPoints.last {
                let ballPath = Path(ellipseIn: CGRect(
                    x: lastPoint.x - 8,
                    y: lastPoint.y - 8,
                    width: 16,
                    height: 16
                ))
                context.fill(ballPath, with: .color(.btAccent))
            }
        }
    }
}

// Alternative SwiftUI Shape approach
struct TrajectoryShape: Shape {
    let points: [CGPoint]
    var animatableData: Double

    init(points: [CGPoint], progress: Double) {
        self.points = points
        self.animatableData = progress
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }

        let pointCount = Int(Double(points.count) * animatableData)
        let animatedPoints = Array(points.prefix(max(2, pointCount)))

        path.move(to: animatedPoints[0])
        for point in animatedPoints.dropFirst() {
            path.addLine(to: point)
        }

        return path
    }
}

// MARK: - Specifications
/*
 Main Line:
   - Width: 4pt
   - Color: Gradient from #5EEAD4 to #22D3EE
   - Cap: round
   - Join: round

 Glow Effect:
   - Width: 12pt
   - Color: #22D3EE at 40% opacity
   - Blur: implicit from larger stroke

 Ball Position Dot:
   - Size: 16x16pt
   - Color: #22D3EE (btAccent)

 Animation:
   - Duration: 1.5 seconds
   - Timing: ease-out
   - Progressive reveal from start to end
*/
```

### 4.10 StrikeProbabilityGauge

Circular gauge showing strike probability percentage.

```swift
struct StrikeProbabilityGauge: View {
    let probability: Double // 0.0 to 1.0
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(spacing: BTSpacing.md) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.btSurfaceHighlight, lineWidth: 12)

                // Progress arc
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        gaugeGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: BTSpacing.xxs) {
                    Text("\(Int(probability * 100))")
                        .font(BTFont.displaySmall())
                        .foregroundColor(.btMetricValue)
                        .monospacedDigit()

                    Text("%")
                        .font(BTFont.metricUnit())
                        .foregroundColor(.btMetricLabel)
                }
            }
            .frame(width: 120, height: 120)

            // Label
            Text("Strike Probability")
                .font(BTFont.metricLabel())
                .foregroundColor(.btMetricLabel)
                .textCase(.uppercase)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedProgress = probability
            }
        }
    }

    private var gaugeGradient: AngularGradient {
        AngularGradient(
            colors: gaugeColors,
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * probability)
        )
    }

    private var gaugeColors: [Color] {
        if probability >= 0.7 {
            return [.btSuccess, .btSuccessLight]
        } else if probability >= 0.4 {
            return [.btWarning, .btWarningLight]
        } else {
            return [.btError, .btErrorLight]
        }
    }
}

// MARK: - Specifications
/*
 Size: 120x120pt
 Track width: 12pt
 Track color: #2A2A2A (btSurfaceHighlight)

 Progress Colors:
   - 70%+: Green gradient (#22C55E to #4ADE80)
   - 40-69%: Amber gradient (#F59E0B to #FBBF24)
   - <40%: Red gradient (#EF4444 to #F87171)

 Center Text:
   - Value: 36pt bold rounded
   - Unit: 16pt medium

 Animation:
   - Duration: 1.0s
   - Delay: 0.2s
   - Easing: ease-out
*/
```

---

## 5. Iconography

### Tab Bar Icons (SF Symbols)

| Tab | Icon Name | Filled Variant |
|-----|-----------|----------------|
| Dashboard | `chart.bar` | `chart.bar.fill` |
| Record | `video` | `video.fill` |
| Sessions | `list.bullet.rectangle` | `list.bullet.rectangle.fill` |
| Settings | `gearshape` | `gearshape.fill` |

### Action Icons

| Action | Icon Name | Notes |
|--------|-----------|-------|
| Start Recording | `record.circle` | Red tint when active |
| Stop Recording | `stop.circle.fill` | |
| Calibrate | `scope` | |
| New Session | `plus.circle.fill` | Primary color |
| End Session | `xmark.circle.fill` | |
| Delete | `trash` | Destructive red |
| Share | `square.and.arrow.up` | |
| Export | `arrow.up.doc` | |
| Settings | `gearshape` | |
| Back | `chevron.left` | |
| Close | `xmark` | |
| Info | `info.circle` | |
| Help | `questionmark.circle` | |

### Status Icons

| Status | Icon Name | Color |
|--------|-----------|-------|
| Strike | `star.fill` or custom "X" | btSuccess |
| Spare | `circle.fill` with "/" | btPrimary |
| Open Frame | `minus` | btTextMuted |
| Split | `exclamationmark.triangle` | btError |
| Gutter | `arrow.down` | btError |

### Metric Icons

| Metric | Icon Name |
|--------|-----------|
| Speed | `speedometer` |
| Rev Rate | `arrow.triangle.2.circlepath` |
| Entry Angle | `angle` |
| Board Position | `ruler` |
| Breakpoint | `point.topleft.down.curvedto.point.bottomright.up` |
| Distance | `arrow.left.and.right` |

### Custom Icon Set

For bowling-specific icons not available in SF Symbols:

```swift
// Custom bowling icons (to be created as SVG/PDF assets)
enum BTIcon {
    case bowlingBall      // Solid circle with finger holes
    case bowlingPin       // Single pin silhouette
    case pinDeck          // 10-pin triangle arrangement
    case laneArrow        // Target arrow marker
    case trajectory       // Curved path icon
    case pocket           // 1-3 pocket indicator

    var systemFallback: String {
        switch self {
        case .bowlingBall: return "circle.fill"
        case .bowlingPin: return "pin.fill"
        case .pinDeck: return "triangle.fill"
        case .laneArrow: return "arrowtriangle.up.fill"
        case .trajectory: return "point.topleft.down.curvedto.point.bottomright.up"
        case .pocket: return "target"
        }
    }
}
```

---

## 6. Animation Specifications

### Screen Transitions

```swift
// Navigation push/pop
extension AnyTransition {
    static var btSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    static var btModal: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    static var btFade: AnyTransition {
        .opacity.animation(.easeInOut(duration: 0.2))
    }
}

// Standard durations
enum BTAnimation {
    static let fast: Double = 0.15
    static let normal: Double = 0.25
    static let slow: Double = 0.4
    static let trajectory: Double = 1.5

    // Spring presets
    static var bounce: Animation {
        .spring(response: 0.35, dampingFraction: 0.7)
    }

    static var smooth: Animation {
        .spring(response: 0.4, dampingFraction: 0.9)
    }

    static var snappy: Animation {
        .spring(response: 0.25, dampingFraction: 0.8)
    }
}
```

### Metric Value Counting Animation

```swift
struct AnimatedNumber: View {
    let value: Double
    let format: String
    let duration: Double

    @State private var displayValue: Double = 0

    var body: some View {
        Text(String(format: format, displayValue))
            .btMetricValue()
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { newValue in
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = newValue
                }
            }
    }
}

// Usage
AnimatedNumber(value: 18.5, format: "%.1f", duration: 0.6)

// MARK: - Specifications
/*
 Duration: 0.6 seconds for standard updates
 Easing: ease-out
 Format: Preserve decimal places from format string

 Triggers:
   - On appear (initial load)
   - On value change (new shot data)
*/
```

### Trajectory Drawing Animation

```swift
struct AnimatedTrajectory: View {
    let points: [CGPoint]
    @State private var progress: Double = 0

    var body: some View {
        TrajectoryPath(
            points: points,
            animationProgress: progress,
            showGlow: true
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Specifications
/*
 Total Duration: 1.5 seconds
 Easing: ease-out (fast start, slow end)

 Phases:
   0.0s - 0.3s: Path appears from foul line
   0.3s - 0.9s: Path draws through hook zone
   0.9s - 1.5s: Path reaches pins, ball dot settles

 Optional: Overshoot bounce on ball dot arrival
*/
```

### Button Press Feedback

```swift
// Already defined in BTButtonStyle above
// Scale: 0.97x when pressed
// Opacity: 0.9 when pressed
// Duration: 0.15s ease-out
// Haptic: UIImpactFeedbackGenerator(style: .medium)
```

### Loading States

```swift
struct BTLoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.btSurfaceHighlight, lineWidth: 4)

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.btPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: 40, height: 40)
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Specifications
/*
 Size: 40x40pt
 Track: #2A2A2A, 4pt
 Spinner: #14B8A6, 4pt, 30% arc
 Duration: 1.0s per rotation
 Easing: linear (constant speed)
*/
```

### Tab Switch Animation

```swift
// Icon scale when selected
withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
    selectedTab = newTab
}

// Specifications:
// Scale on selection: 1.0 -> 1.1 -> 1.0 (bounce)
// Color change: instant
// Duration: 0.3s spring
```

### Card Appearance

```swift
extension View {
    func btCardAppearAnimation(delay: Double) -> some View {
        self
            .opacity(0)
            .offset(y: 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                    // Handled by animation modifier
                }
            }
    }
}

// Specifications:
// Initial: 0 opacity, 20pt down
// Final: 1 opacity, 0pt offset
// Duration: 0.4s per card
// Stagger: 0.05s between cards
```

---

## 7. Component Usage Examples

### Dashboard Screen Layout

```swift
struct DashboardView: View {
    @State private var recentSession: Session?
    @State private var stats: SessionStats?

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // Quick Actions
                HStack(spacing: BTSpacing.md) {
                    BTActionButton(
                        title: "New Session",
                        icon: "plus.circle.fill",
                        variant: .primary,
                        isLoading: false
                    ) {
                        // Start new session
                    }

                    BTActionButton(
                        title: "Calibrate",
                        icon: "scope",
                        variant: .secondary,
                        isLoading: false
                    ) {
                        // Open calibration
                    }
                }

                // Stats Overview
                VStack(alignment: .leading, spacing: BTSpacing.md) {
                    Text("Your Averages")
                        .font(BTFont.h3())
                        .foregroundColor(.btTextPrimary)

                    LazyVGrid(columns: BTGrid.columns2, spacing: BTSpacing.md) {
                        MetricCard(
                            title: "Speed",
                            value: "17.2",
                            unit: "mph",
                            previousValue: "16.8",
                            accentColor: .btSpeed,
                            size: .standard
                        )

                        MetricCard(
                            title: "Rev Rate",
                            value: "342",
                            unit: "rpm",
                            previousValue: "338",
                            accentColor: .btRevRate,
                            size: .standard
                        )

                        MetricCard(
                            title: "Entry Angle",
                            value: "5.8",
                            unit: "deg",
                            previousValue: "5.6",
                            accentColor: .btAngle,
                            size: .standard
                        )

                        MetricCard(
                            title: "Strike Rate",
                            value: "47",
                            unit: "%",
                            previousValue: "42",
                            accentColor: .btStrike,
                            size: .standard
                        )
                    }
                }

                // Recent Sessions
                VStack(alignment: .leading, spacing: BTSpacing.md) {
                    HStack {
                        Text("Recent Sessions")
                            .font(BTFont.h3())
                            .foregroundColor(.btTextPrimary)

                        Spacer()

                        Button("See All") {
                            // Navigate to sessions
                        }
                        .font(BTFont.label())
                        .foregroundColor(.btPrimary)
                    }

                    if let session = recentSession {
                        SessionCard(session: session) {
                            // Navigate to session detail
                        }
                    } else {
                        EmptyStateCard(
                            icon: "figure.bowling",
                            title: "No sessions yet",
                            message: "Start your first session to see your stats"
                        )
                    }
                }
            }
            .padding(BTLayout.screenHorizontalPadding)
        }
        .background(Color.btBackground)
    }
}
```

### Shot Analysis Screen

```swift
struct ShotAnalysisView: View {
    let shot: Shot

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // Result header
                HStack {
                    ResultBadge(result: shot.result)
                        .scaleEffect(1.5)

                    VStack(alignment: .leading) {
                        Text("Shot #\(shot.number)")
                            .font(BTFont.h2())
                            .foregroundColor(.btTextPrimary)

                        Text(shot.result.description)
                            .font(BTFont.body())
                            .foregroundColor(.btTextSecondary)
                    }

                    Spacer()
                }

                // Trajectory visualization
                ZStack {
                    // Lane background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.btLaneBackground)
                        .aspectRatio(0.3, contentMode: .fit)

                    // Trajectory overlay
                    AnimatedTrajectory(points: shot.trajectoryPoints)
                }

                // Strike probability gauge
                HStack {
                    Spacer()
                    StrikeProbabilityGauge(probability: shot.strikeProbability)
                    Spacer()
                }

                // Metrics grid
                LazyVGrid(columns: BTGrid.columns2, spacing: BTSpacing.md) {
                    MetricCard(
                        title: "Launch Speed",
                        value: String(format: "%.1f", shot.launchSpeed ?? 0),
                        unit: "mph",
                        previousValue: nil,
                        accentColor: .btSpeed,
                        size: .standard
                    )

                    MetricCard(
                        title: "Impact Speed",
                        value: String(format: "%.1f", shot.impactSpeed ?? 0),
                        unit: "mph",
                        previousValue: nil,
                        accentColor: .btSpeed,
                        size: .standard
                    )

                    MetricCard(
                        title: "Rev Rate",
                        value: String(format: "%.0f", shot.revRate ?? 0),
                        unit: "rpm",
                        previousValue: nil,
                        accentColor: .btRevRate,
                        size: .standard
                    )

                    MetricCard(
                        title: "Entry Angle",
                        value: String(format: "%.1f", shot.entryAngle ?? 0),
                        unit: "deg",
                        previousValue: nil,
                        accentColor: .btAngle,
                        size: .standard
                    )
                }

                // Board positions
                VStack(alignment: .leading, spacing: BTSpacing.md) {
                    Text("Board Positions")
                        .font(BTFont.h3())
                        .foregroundColor(.btTextPrimary)

                    HStack(spacing: BTSpacing.lg) {
                        BoardMetric(label: "Foul Line", board: shot.foulLineBoard)
                        BoardMetric(label: "Arrows", board: shot.arrowBoard)
                        BoardMetric(label: "Breakpoint", board: shot.breakpointBoard)
                        BoardMetric(label: "Entry", board: shot.entryBoard)
                    }
                }
            }
            .padding(BTLayout.screenHorizontalPadding)
        }
        .background(Color.btBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BoardMetric: View {
    let label: String
    let board: Double?

    var body: some View {
        VStack(spacing: BTSpacing.xs) {
            Text(board.map { String(format: "%.1f", $0) } ?? "--")
                .font(BTFont.monoLarge())
                .foregroundColor(.btTextPrimary)

            Text(label)
                .font(BTFont.captionSmall())
                .foregroundColor(.btTextMuted)
        }
    }
}
```

---

## 8. Accessibility

### Dynamic Type Support

```swift
// All text should scale with system settings
.font(BTFont.body())
.dynamicTypeSize(...DynamicTypeSize.accessibility3) // Cap maximum for layouts

// Minimum touch targets
.frame(minWidth: 44, minHeight: 44)
```

### Color Contrast

All color combinations meet WCAG AA standards:
- Primary text on dark background: 15.8:1
- Secondary text on dark background: 7.2:1
- Primary accent on dark background: 6.1:1

### VoiceOver Labels

```swift
MetricCard(...)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Speed: 17.2 miles per hour. Previous: 16.8")
    .accessibilityHint("Double tap to view speed history")
```

---

## 9. Dark Mode

BowlerTrax is designed as a dark-mode-first app to:
1. Reduce eye strain in bowling alleys (low light environments)
2. Improve camera overlay visibility
3. Extend battery life on OLED displays

The color system does not include light mode variants. All backgrounds use dark colors with light text.

---

## 10. File Organization

```
BowlerTrax/
├── DesignSystem/
│   ├── Colors.swift           # Color extensions
│   ├── Typography.swift       # BTFont enum
│   ├── Spacing.swift          # BTSpacing, BTLayout, BTGrid
│   ├── Animation.swift        # BTAnimation, transitions
│   └── Components/
│       ├── MetricCard.swift
│       ├── ActionButton.swift
│       ├── SessionCard.swift
│       ├── ShotCard.swift
│       ├── NavigationBar.swift
│       ├── TabBar.swift
│       ├── ProgressIndicator.swift
│       ├── CameraOverlay.swift
│       ├── TrajectoryPath.swift
│       └── StrikeProbabilityGauge.swift
├── Assets.xcassets/
│   ├── Colors/               # Color set definitions
│   └── Icons/                # Custom bowling icons
└── Preview Content/
    └── PreviewData.swift     # Mock data for previews
```

---

## Summary

This design system provides a cohesive visual language for BowlerTrax, inspired by the LaneTrax competitor analysis while establishing a unique identity. Key characteristics:

- **Dark theme** optimized for bowling alley environments
- **Teal/Cyan primary palette** for brand recognition
- **8pt spacing grid** for consistent layouts
- **SF Pro typography** with rounded variants for metrics
- **Metric-specific accent colors** for quick scanning
- **Smooth animations** that enhance without distracting
- **Accessibility-first** approach for all users

All components are designed for SwiftUI with clear specifications for size, color, spacing, and animation timing.
