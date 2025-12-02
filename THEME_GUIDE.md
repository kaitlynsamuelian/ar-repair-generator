# 🎨 Pink & White UI Theme Guide

## Overview
Professional pink-and-white theme for the AR Repair Generator app, designed to be clean, minimal, and Apple-like while maintaining excellent readability over AR camera feeds.

---

## 📐 Color Palette

### Primary Colors
- **Main Pink:** `#FF4F8B` → `.appPink`
  - Primary buttons, active elements, accent highlights
- **Secondary Pink:** `#E63E7A` → `.appPinkDark`
  - Hover states, gradients, active glows
- **Blush Pink:** `#FFF2F7` → `.appPinkLight`
  - Subtle backgrounds for cards and sections

### Neutrals
- **White:** `#FFFFFF` → `.appWhite`
  - Primary backgrounds, button text
- **Light Gray Text:** `#6E6E73` → `.appTextLight`
  - Secondary text, captions
- **Dark Text:** `#1C1C1E` → `.appTextDark`
  - Primary text, headings (high contrast)
- **Soft Border:** `#F7DCE4` → `.appBorder`
  - Card borders, dividers

### Overlays
- **Translucent Overlay:** `.appOverlay` (white @ 88% opacity)
  - Top/bottom bars over AR camera view

---

## 🔤 Typography

### Fonts
```swift
.appTitle          // 24pt bold rounded
.appHeadline       // 18pt semibold default
.appBody           // 16pt regular
.appBodyBold       // 16pt semibold
.appCaption        // 14pt medium
.appCaptionSmall   // 12pt regular
.appMeasurement    // 14pt semibold rounded
.appMeasurementLarge // 48pt bold monospaced
```

---

## 🎛️ Button Styles

### Primary Button
```swift
Button("Action") { }
    .buttonStyle(PrimaryButtonStyle())
```
- Pink gradient background (`appPink` → `appPinkDark`)
- White text
- Rounded corners (24pt radius)
- Pink shadow
- Press animation (scale 0.97)

### Secondary Button
```swift
Button("Action") { }
    .buttonStyle(SecondaryButtonStyle())
```
- White background
- Pink border (2pt)
- Pink text
- Rounded corners (24pt radius)
- Press animation

### Small Button
```swift
Button("Action") { }
    .buttonStyle(SmallButtonStyle(isDestructive: false))
```
- White background
- Pink or red border (for destructive actions)
- Smaller padding (12pt radius)
- Use for inline actions like "Clear", "Edit"

---

## 🏷️ Measurement Labels (AR Scene)

### Active Measurement
```swift
Text("42.5mm")
    .activeMeasurementStyle()
```
- Pink pill background (`appPink`)
- White text
- Rounded (999 radius = full pill)
- Shadow with pink tint

### Idle Measurement
```swift
Text("42.5mm")
    .idleMeasurementStyle()
```
- White pill background
- Pink text
- Pink border (1pt)
- Subtle shadow

---

## 📦 Card Styles

### Standard Card
```swift
VStack {
    // Content
}
.cardStyle()
```
- Light blush pink background (`appPinkLight`)
- Soft border (`appBorder`)
- 16pt rounded corners

### Overlay Bar (Camera Overlay)
```swift
HStack {
    // Top bar content
}
.overlayBar()
```
- Ultra-thin material (frosted glass effect)
- 95% opacity
- Allows AR camera to show through subtly

---

## 🎨 AR Visual Elements

### Measurement Points
- **Color:** Pink (`appPink`)
- **Glow:** Emissive pink
- **Size:** 0.005 radius sphere

### Measurement Lines
- **Color:** Pink (`appPink`)
- **Glow:** Dark pink (`appPinkDark`)
- **Width:** 0.001 radius cylinder

### Measurement Labels (3D AR Text)
- **Text:** White with white emission
- **Background:** Pink pill shape (`appPink`)
- **Billboard:** Always faces camera
- **Position:** 15mm above measurement line

---

## 🧩 Common Components

### SectionHeader
```swift
SectionHeader("Title", icon: "sparkles")
```
- Pink icon
- Dark text title
- Left-aligned with icon

### MeasurementBadge
```swift
MeasurementBadge(number: 1, isActive: true)
```
- Circular badge with number
- Pink when active, gray when idle
- 28x28 size

---

## 🔧 Usage Examples

### Top Navigation Bar
```swift
HStack {
    VStack(alignment: .leading) {
        Text("AR Tape Measure")
            .font(.appHeadline)
            .foregroundColor(.appTextDark)
        Text("Tap to start")
            .font(.appCaption)
            .foregroundColor(.appTextLight)
    }
    Spacer()
}
.padding()
.overlayBar()
```

### AI Generator Section
```swift
VStack(spacing: 16) {
    SectionHeader("AI Part Generator", icon: "sparkles")
    
    TextField("Description", text: $text)
        .tint(.appPink)
    
    Button("Generate") { }
        .buttonStyle(PrimaryButtonStyle())
}
.padding(20)
.cardStyle()
```

### Measurement List Item
```swift
HStack {
    MeasurementBadge(number: 1, isActive: true)
    Text("Width: 42.5mm")
        .font(.appBodyBold)
        .foregroundColor(.appTextDark)
}
.padding()
.background(.appWhite)
.cornerRadius(12)
```

---

## ✅ Accessibility Notes

- **Contrast Ratio:** Pink (#FF4F8B) on white meets WCAG AA for large text
- **Dark text (#1C1C1E):** High contrast for readability over light backgrounds
- **Light text (#6E6E73):** Used only for secondary/non-critical info
- **Pink-on-white buttons:** Always use bold/semibold fonts for better legibility

---

## 🎯 Design Principles

1. **Minimal & Functional:** Apple-like, tool-focused (not decorative)
2. **High Contrast:** All text must be readable over translucent overlays
3. **Consistent Pink Accent:** Pink used sparingly for primary actions & highlights
4. **Frosted Glass Overlays:** Camera view always partially visible during measurement
5. **Rounded Corners:** Everything uses rounded corners (12-24pt) for modern feel
6. **Pill Shapes:** Badges and tags use 999 radius for full pill shape
7. **Subtle Shadows:** Pink shadows for pink elements, black shadows for neutral elements

---

## 🚀 Quick Start

1. **Import Theme:** `Theme.swift` is automatically available in all SwiftUI views
2. **Use Color Extensions:** `.appPink`, `.appWhite`, `.appTextDark`, etc.
3. **Use Font Extensions:** `.appHeadline`, `.appBody`, `.appCaption`, etc.
4. **Apply Button Styles:** `.buttonStyle(PrimaryButtonStyle())`
5. **Apply Modifiers:** `.cardStyle()`, `.overlayBar()`, `.activeMeasurementStyle()`

---

## 📝 Customization

To adjust the theme globally, edit `Theme.swift`:
- Change hex values in `Color` extensions
- Adjust font sizes in `Font` extensions
- Modify button corner radii, padding, or shadow styles
- Tweak card background opacity or border width

All changes will automatically apply throughout the app! 🎉

