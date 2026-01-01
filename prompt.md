# BowlerTrax iOS Asset Creation Prompt

---

## Quick Reference - Copy-Paste Prompts

### App Icon (Use This First)

```
A modern iOS app icon for a bowling analytics app. Features a stylized dark bowling ball with a glowing teal (#14B8A6) curved trajectory line showing the ball's hook path down the lane. The trajectory has a subtle glow effect and data points along the curve suggesting motion tracking. Dark charcoal background (#0F0F0F) with very subtle lane board lines. The bowling ball has a sleek matte finish with a subtle teal highlight reflection. Clean geometric design, minimal details, professional sports tech aesthetic. Slight 3D depth with soft shadows. No text, no bowling pins, no busy patterns. Premium app icon style, instantly recognizable at small sizes.

Style: Modern minimal app icon, clean vector-like graphics, subtle gradients
Aspect ratio: 1:1 square
Output: 1024x1024 pixels
```

### Logo Mark (Symbol Only)

```
A standalone logo mark/symbol for "BowlerTrax" bowling analytics brand. Abstract geometric design combining a stylized bowling ball with a curved trajectory arc. The ball is suggested through a circle with subtle lane arrow detail inside. A sweeping teal (#14B8A6) arc curves around or through the ball representing motion tracking. Clean vector style, works at small sizes. Design on transparent background. Modern sports tech brand aesthetic, similar to Whoop or Garmin. Minimal, memorable, professional.

Style: Vector logo mark, geometric, brand identity design
Background: Transparent
Output: 512x512 pixels, PNG with transparency
```

### Full Logo with Text

```
A horizontal logo lockup for "BowlerTrax" bowling analytics app. Left side features the logo mark: a stylized bowling ball with curved teal trajectory arc. Right side shows "BowlerTrax" in a modern sans-serif typeface (similar to Inter, SF Pro, or Montserrat). The word "Bowler" in white, "Trax" with subtle teal (#14B8A6) accent or the 'x' highlighted in teal. Clean kerning, professional sports brand feel. Transparent background, suitable for both dark and light backgrounds. Balanced proportions between mark and wordmark.

Style: Brand identity, horizontal logo lockup
Background: Transparent
Output: 800x200 pixels, PNG with transparency
```

---

## Project Overview

**BowlerTrax** is a personal bowling analytics app that uses computer vision to track bowling shots in real-time. The app provides metrics including ball speed, trajectory, entry angle, rev rate, and strike probability.

**Target Audience**: Serious amateur and semi-professional bowlers who want data-driven insights to improve their game.

**App Personality**: Professional, precise, high-tech, athletic, trustworthy.

---

## Brand Identity

### Primary Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary Teal** | `#14B8A6` | Main brand color, CTAs, highlights |
| Primary Light | `#5EEAD4` | Hover states, gradients |
| Primary Dark | `#0D9488` | Pressed states, depth |
| **Cyan Accent** | `#22D3EE` | Secondary highlights, trajectory lines |
| Accent Light | `#67E8F9` | Glow effects |

### Semantic Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Success Green | `#22C55E` | Strikes, good metrics |
| Warning Amber | `#F59E0B` | Attention needed |
| Speed Orange | `#F97316` | Speed metric visualization |
| Rev Purple | `#A855F7` | Rev rate metric |

### Background (Dark Theme)

The app uses a dark theme optimized for bowling alley environments:
- Background: `#0F0F0F` (deep black)
- Surface: `#1A1A1A` (cards, panels)
- Lane Wood accent: `#3D2817` (subtle wood tone)

---

## Icon Concept Requirements

### Visual Elements to Incorporate

1. **Bowling Ball** - The core subject
   - Should show motion/trajectory (curved path suggesting hook)
   - Can include lane board lines or arrows
   - Consider showing tracking visualization (trajectory path, data points)

2. **Lane/Arrows** - Context and precision
   - Stylized lane arrows are iconic to bowling
   - Board lines suggest precision tracking

3. **Analytics/Tech Feel** - Differentiation
   - Trajectory visualization (curved path line)
   - Data overlay feel (without being cluttered)
   - Modern, app-like aesthetic

4. **Motion/Speed** - Dynamic energy
   - Suggest ball movement down the lane
   - Gradient trails or motion lines

### Icon Style Direction

- **Modern & Minimal** - Clean shapes, not overly detailed
- **Dark Background** - Matches app theme, stands out on home screen
- **Teal Accent** - Primary brand color should feature prominently
- **Depth/Dimension** - Subtle gradients, not flat
- **Professional** - Not cartoonish, appeals to serious bowlers

### What to Avoid

- Cartoony or childish bowling imagery
- Clip-art style pins or generic bowling icons
- Overly complex details (icons render at small sizes)
- Pure white backgrounds (app is dark-themed)
- Red/generic sports colors (teal is the brand)

---

## iOS App Icon Specifications

### Master Icon Requirements

| Property | Requirement |
|----------|-------------|
| **Size** | 1024 x 1024 pixels |
| **Format** | PNG |
| **Color Space** | sRGB |
| **Transparency** | NOT allowed (must be fully opaque) |
| **Corners** | Square (iOS applies squircle mask automatically) |
| **Safe Zone** | Keep important content within center ~80% |

### How iOS Uses the Master Icon

Apple's Xcode automatically generates all required sizes from the 1024px master:

| Context | Size (pt) | Scale | Pixels |
|---------|-----------|-------|--------|
| App Store | 1024 | @1x | 1024x1024 |
| iPhone App | 60 | @2x | 120x120 |
| iPhone App | 60 | @3x | 180x180 |
| iPad App | 76 | @1x | 76x76 |
| iPad App | 76 | @2x | 152x152 |
| iPad Pro App | 83.5 | @2x | 167x167 |
| Spotlight | 40 | @2x | 80x80 |
| Spotlight | 40 | @3x | 120x120 |
| Settings | 29 | @2x | 58x58 |
| Settings | 29 | @3x | 87x87 |
| Notification | 20 | @2x | 40x40 |
| Notification | 20 | @3x | 60x60 |

### Icon Appearance Modes (iOS 18+)

Apple now supports three icon appearance modes. Design the master icon considering:

1. **Light Mode** - Standard appearance
2. **Dark Mode** - Darker variant for dark home screens
3. **Tinted Mode** - Monochrome tinted version

**Recommendation**: Design the primary icon with a dark background so it works well across all modes. The teal accent on dark background will translate well to tinted mode.

### Design Best Practices

- **Simplicity**: Icon should be instantly recognizable at 29x29pt
- **Single focal point**: One clear subject, not multiple competing elements
- **No text**: Avoid text in the icon (unreadable at small sizes)
- **No photos**: Use illustrated/graphic style
- **Brand consistency**: Icon should match app's visual language
- **Edge bleeding**: Avoid important content at edges (squircle crops corners)

---

## Logo Specifications

### Primary Logo (Horizontal)

- App icon mark + "BowlerTrax" wordmark
- Use on splash screens, marketing, documentation
- Provide in both dark and light background versions

### Logo Mark Only

- The icon without wordmark
- For small spaces, favicons, watermarks

### Wordmark

- "BowlerTrax" text treatment
- Font suggestion: Modern sans-serif, tech/sporty feel
- Consider subtle kerning adjustment for "Trax"

### Logo Files Needed

| File | Format | Background | Size |
|------|--------|------------|------|
| logo-horizontal-dark.png | PNG | Transparent (for dark BG) | 400px height |
| logo-horizontal-light.png | PNG | Transparent (for light BG) | 400px height |
| logo-mark.png | PNG | Transparent | 512x512 |
| logo-mark.svg | SVG | Transparent | Vector |
| logo-horizontal.svg | SVG | Transparent | Vector |

---

## Deliverables Checklist

### Required Assets

- [ ] **App Icon Master** - 1024x1024px PNG, sRGB, no transparency
- [ ] **App Icon Dark Variant** - For iOS dark mode (optional but recommended)
- [ ] **Logo Horizontal** - PNG + SVG, transparent background
- [ ] **Logo Mark** - PNG 512x512 + SVG vector
- [ ] **Wordmark** - PNG + SVG

### Bonus Assets (If Provided)

- [ ] App Store Preview Banner (1920x1080)
- [ ] Social media avatar (400x400)
- [ ] Launch screen logo variant

---

## AI Image Generation Prompts

### PROMPT 1: App Icon - Primary (Dark Background)

```
A modern iOS app icon for a bowling analytics app. Features a stylized dark bowling ball with a glowing teal (#14B8A6) curved trajectory line showing the ball's hook path down the lane. The trajectory has a subtle glow effect and data points along the curve suggesting motion tracking. Dark charcoal background (#0F0F0F) with very subtle lane board lines. The bowling ball has a sleek matte finish with a subtle teal highlight reflection. Clean geometric design, minimal details, professional sports tech aesthetic. Slight 3D depth with soft shadows. No text, no bowling pins, no busy patterns. Premium app icon style, instantly recognizable at small sizes.

Style: Modern minimal app icon, clean vector-like graphics, subtle gradients
Aspect ratio: 1:1 square
Output: 1024x1024 pixels
```

---

### PROMPT 2: App Icon - Alternate (Teal Dominant)

```
A sleek iOS app icon for "BowlerTrax" bowling tracking app. Center focus on a minimalist bowling ball silhouette with an elegant curved arc trajectory sweeping behind it. Primary teal color (#14B8A6) gradient from light (#5EEAD4) to dark (#0D9488). Deep black background (#0F0F0F). The trajectory line has subtle speed lines and small tracking dots suggesting real-time data capture. Modern tech aesthetic like Strava or Nike Training Club apps. Clean geometry, no clutter, professional athletic feel. The ball should have subtle dimension with a soft highlight. No text, no pins, square format.

Style: Premium sports analytics app icon, geometric, tech-forward
Aspect ratio: 1:1 square
Output: 1024x1024 pixels
```

---

### PROMPT 3: App Icon - Motion Focus

```
Minimalist iOS app icon showing a bowling ball in motion. The ball is rendered in dark gray (#2A2A2A) with a subtle metallic sheen, positioned lower-left of frame. A dynamic curved trajectory path in glowing teal (#14B8A6) with cyan highlights (#22D3EE) sweeps from the ball toward upper-right, representing the ball's hook motion. Small velocity vectors or tracking markers along the path. Pure black background (#0F0F0F). The trajectory should feel like real-time motion tracking visualization. Ultra-clean design, no extra elements. Premium quality, suitable for App Store featuring.

Style: Dark mode app icon, motion graphics aesthetic, data visualization feel
Aspect ratio: 1:1 square
Output: 1024x1024 pixels
```

---

### PROMPT 4: Logo Mark (Standalone Symbol)

```
A standalone logo mark/symbol for "BowlerTrax" bowling analytics brand. Abstract geometric design combining a stylized bowling ball with a curved trajectory arc. The ball is suggested through a circle with subtle lane arrow detail inside. A sweeping teal (#14B8A6) arc curves around or through the ball representing motion tracking. Clean vector style, works at small sizes. Design on transparent background. Modern sports tech brand aesthetic, similar to Whoop or Garmin. Minimal, memorable, professional.

Style: Vector logo mark, geometric, brand identity design
Background: Transparent
Output: 512x512 pixels, PNG with transparency
```

---

### PROMPT 5: Horizontal Logo with Wordmark

```
A horizontal logo lockup for "BowlerTrax" bowling analytics app. Left side features the logo mark: a stylized bowling ball with curved teal trajectory arc. Right side shows "BowlerTrax" in a modern sans-serif typeface (similar to Inter, SF Pro, or Montserrat). The word "Bowler" in white, "Trax" with subtle teal (#14B8A6) accent or the 'x' highlighted in teal. Clean kerning, professional sports brand feel. Transparent background, suitable for both dark and light backgrounds. Balanced proportions between mark and wordmark.

Style: Brand identity, horizontal logo lockup
Background: Transparent
Output: 800x200 pixels, PNG with transparency
```

---

### PROMPT 6: Logo on Dark Background (Marketing Use)

```
The BowlerTrax logo displayed on a dark gradient background. Logo features a bowling ball with glowing teal (#14B8A6) trajectory path, next to "BowlerTrax" wordmark in clean white sans-serif text. Background is a subtle gradient from deep black (#0F0F0F) to dark charcoal (#1A1A1A). Slight atmospheric glow around the teal elements. Professional app marketing style, suitable for App Store screenshots, social media, or website hero. Premium quality, high contrast, legible.

Style: Marketing asset, brand presentation
Output: 1920x1080 pixels (16:9)
```

---

### PROMPT 7: Logo on Light Background (Documentation Use)

```
The BowlerTrax logo on a clean white or light gray background. Logo mark is the bowling ball with teal trajectory. Wordmark "BowlerTrax" in dark charcoal (#18181B) text. The teal (#14B8A6) trajectory arc provides the color accent. Minimal, professional, suitable for documentation, invoices, or light-mode contexts. Clean vector look.

Style: Brand identity, light background variant
Background: White or light gray (#FAFAFA)
Output: 800x200 pixels
```

---

### PROMPT 8: App Store Feature Banner

```
A cinematic App Store promotional banner for BowlerTrax bowling analytics app. Dark atmospheric background with subtle bowling lane wood texture. Large BowlerTrax logo glowing in the center. Multiple teal (#14B8A6) trajectory arcs sweeping across the frame suggesting ball tracking paths. Subtle data visualization elements: small tracking dots, velocity indicators. Professional sports tech aesthetic. Text overlay space on right side. Dramatic lighting, premium quality.

Style: App Store marketing, cinematic, sports tech
Output: 1920x1080 pixels
```

---

## Tool-Specific Prompt Formats

### For Midjourney

**App Icon:**
```
modern iOS app icon, bowling analytics app, dark bowling ball with glowing teal trajectory arc #14B8A6, ball hook path with tracking dots, dark background #0F0F0F, subtle lane lines, matte finish ball with teal reflection, clean geometric minimal design, sports tech aesthetic, 3D depth soft shadows, no text no pins, premium quality --ar 1:1 --v 6.1 --s 250
```

**Logo Mark:**
```
minimal logo mark, bowling ball with curved teal arc trajectory #14B8A6, abstract geometric design, sports analytics brand, clean vector style, transparent background, modern tech aesthetic like Whoop Garmin, memorable professional --ar 1:1 --v 6.1 --s 200 --style raw
```

**Full Logo:**
```
horizontal logo lockup "BowlerTrax", bowling ball mark with teal trajectory arc left side, modern sans-serif wordmark right side, "Bowler" white "Trax" teal accent #14B8A6, clean kerning, sports tech brand, transparent background --ar 4:1 --v 6.1 --s 200
```

---

### For DALL-E 3

**App Icon:**
```
Create a modern iOS app icon for a bowling analytics application. The icon should feature a stylized dark bowling ball with a glowing teal (#14B8A6) curved trajectory line that shows the ball's hook path. Include subtle data tracking points along the curve. Use a dark charcoal background (#0F0F0F). The bowling ball should have a matte finish with a teal highlight reflection. Keep the design clean, geometric, and minimal with professional sports tech aesthetic. Add slight 3D depth with soft shadows. Do not include any text or bowling pins. Make it premium quality that works at small sizes. Square format, 1024x1024 pixels.
```

**Logo Mark:**
```
Design a standalone logo symbol for "BowlerTrax" bowling analytics brand. Create an abstract geometric design that combines a stylized bowling ball shape with a curved trajectory arc in teal (#14B8A6). The arc should curve around or through the ball to represent motion tracking. Use clean vector-style graphics that work well at small sizes. Modern sports tech aesthetic similar to Whoop or Garmin branding. The design should be minimal, memorable, and professional. Transparent background, 512x512 pixels.
```

---

### For Ideogram

**App Icon:**
```
iOS app icon design, bowling analytics app, stylized dark bowling ball with glowing teal curved trajectory path showing hook motion, color #14B8A6, tracking dots along curve, dark background #0F0F0F, subtle lane board lines, matte ball with teal highlight, clean geometric minimal, professional sports tech style, 3D depth, no text, no bowling pins, premium app store quality, 1024x1024 square
```

**Logo with Text:**
```
Logo design for "BowlerTrax", horizontal layout, left side bowling ball icon with teal trajectory arc, right side text "BowlerTrax" in modern sans-serif font, "Bowler" in white "Trax" in teal #14B8A6, clean professional sports brand, transparent background, balanced proportions
```

---

### For Adobe Firefly

**App Icon:**
```
A sleek iOS application icon for a bowling tracking app. Dark bowling ball with luminous teal (#14B8A6) curved motion path. The trajectory shows the ball's hook with subtle tracking markers. Deep black background. Clean minimalist design with slight 3D dimensionality. Professional sports analytics aesthetic. No text elements. Square composition suitable for app store.
```

---

## Reference & Inspiration

### Competing Apps

- **LaneTrax** - Bowling analytics (competitor)
- **Specto** - Professional lane tracking system

### Style References

- Sports analytics apps (ESPN, Nike Training)
- Precision tracking apps (Strava, Whoop)
- Premium dark-mode apps (Apple Fitness+)

---

## Technical Notes

### File Placement

Once assets are created, place them in:

```
ios/BowlerTrax/Resources/Assets.xcassets/
├── AppIcon.appiconset/
│   ├── Contents.json
│   └── icon-1024.png          ← Master app icon
├── Logo.imageset/
│   ├── Contents.json
│   ├── logo@1x.png
│   ├── logo@2x.png
│   └── logo@3x.png
```

### Current Asset Catalog Status

The project has an empty `AppIcon.appiconset` ready for the icon. The `Contents.json` is configured to accept a single 1024x1024 icon that Xcode will auto-generate sizes from.

---

## Sources & References

- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [iOS App Icon Sizes Guide](https://splitmetrics.com/blog/guide-to-mobile-icons/)
- [Apple App Icon Guidelines](https://twinr.dev/blogs/apple-app-icon-design-guidelines/)
