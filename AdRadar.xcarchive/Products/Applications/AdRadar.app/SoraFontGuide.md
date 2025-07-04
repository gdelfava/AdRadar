# Sora Font Implementation Guide

## Overview

Your AdRadar iOS app now uses the **Sora** font family throughout the entire interface. Sora is a modern, geometric sans-serif typeface that provides excellent readability and a professional, technical appearance perfect for fintech apps.

## What's Been Implemented

### 1. Font Files Added
- `Sora-Light.ttf` - For delicate text
- `Sora-Regular.ttf` - Default body text
- `Sora-Medium.ttf` - Emphasized text
- `Sora-SemiBold.ttf` - Headings and buttons
- `Sora-Bold.ttf` - Strong emphasis and large titles

### 2. Info.plist Configuration
The fonts are registered in `Info.plist` under the `UIAppFonts` key, making them available throughout the app.

### 3. Font Extensions & Utilities
Two main files provide the font system:

- **`SoraFont.swift`** - Core font definitions and extensions
- **`GlobalFontModifier.swift`** - Global application and UI component styling

## How to Use Sora Fonts in Your App

### 1. Basic Font Application

```swift
// Using direct font modifiers
Text("Welcome to AdRadar")
    .soraLargeTitle()

Text("Your earnings overview")
    .soraBody()

Text("Last updated")
    .soraCaption()
```

### 2. Using the Style System

```swift
// Using the style enum system
Text("Revenue Dashboard")
    .soraStyle(.title)

Text("$1,234.56")
    .soraStyle(.metricValue)

Text("This month")
    .soraStyle(.cardSubtitle)
```

### 3. Custom Sizes

```swift
// Using custom weights and sizes
Text("Custom Text")
    .soraFont(.semibold, size: 18)
```

## Predefined Text Styles

### Display & Titles
- `.soraLargeTitle()` - 34pt, Bold - For main headings
- `.soraTitle()` - 28pt, SemiBold - For section titles
- `.soraTitle2()` - 22pt, SemiBold - For subsection titles
- `.soraTitle3()` - 20pt, SemiBold - For smaller headings

### Body & Content
- `.soraHeadline()` - 17pt, SemiBold - For emphasized content
- `.soraBody()` - 17pt, Regular - Default body text
- `.soraCallout()` - 16pt, Regular - For callouts
- `.soraSubheadline()` - 15pt, Regular - For subtitles

### Small Text
- `.soraFootnote()` - 13pt, Regular - For fine print
- `.soraCaption()` - 12pt, Regular - For captions
- `.soraCaption2()` - 11pt, Regular - For very small text

### Specialized Styles
- `.soraNavigationTitle()` - 20pt, SemiBold - Navigation bars
- `.soraButtonTitle()` - 17pt, SemiBold - Button text
- `.soraCardTitle()` - 16pt, SemiBold - Card headers
- `.soraCardSubtitle()` - 14pt, Regular - Card descriptions
- `.soraMetricValue()` - 28pt, Bold - Large numbers/values
- `.soraMetricLabel()` - 12pt, Medium - Metric labels

## Global Configuration

The app automatically configures Sora fonts for:

### Navigation Bars
- Navigation titles use Sora-SemiBold
- Large titles use Sora-Bold

### Tab Bars
- Tab item titles use Sora-Medium

### Global Application
Applied via `.applySoraFonts()` modifier in the main app file.

## Custom Components

### SoraButton
```swift
SoraButton("Continue", style: .primary) {
    // Action
}

SoraButton("Cancel", style: .secondary) {
    // Action  
}
```

### SoraMetricCard
```swift
SoraMetricCard(
    title: "Total Revenue", 
    value: "$1,234.56",
    subtitle: "This month",
    icon: "dollarsign.circle"
)
```

### SoraCard
```swift
SoraCard {
    VStack {
        Text("Card Title").soraCardTitle()
        Text("Card content").soraBody()
    }
}
```

## Typography Scale Reference

### Display Scale (Large Marketing Text)
- `SoraTypography.display1` - 48pt, Bold
- `SoraTypography.display2` - 40pt, Bold
- `SoraTypography.display3` - 36pt, Bold

### Heading Scale
- `SoraTypography.h1` - 32pt, Bold
- `SoraTypography.h2` - 28pt, Bold
- `SoraTypography.h3` - 24pt, SemiBold
- `SoraTypography.h4` - 20pt, SemiBold
- `SoraTypography.h5` - 18pt, SemiBold
- `SoraTypography.h6` - 16pt, SemiBold

### Body Scale
- `SoraTypography.bodyLarge` - 18pt, Regular
- `SoraTypography.bodyMedium` - 16pt, Regular
- `SoraTypography.bodySmall` - 14pt, Regular
- `SoraTypography.bodyXSmall` - 12pt, Regular

## Best Practices

### 1. Consistency
- Use predefined styles whenever possible
- Stick to the established type scale
- Maintain consistent spacing between text elements

### 2. Hierarchy
- Use font weights to establish clear information hierarchy
- Large titles (Bold) > Headings (SemiBold) > Body (Regular)
- Use color and spacing to support the typographic hierarchy

### 3. Accessibility
- Sora provides excellent legibility at all sizes
- The large x-height makes it ideal for smaller UI text
- Ensure sufficient contrast ratios for all text

### 4. Performance
- Fonts are loaded once at app startup
- Avoid creating custom font instances repeatedly
- Use the provided extensions for optimal performance

## Migration Guide

To convert existing text to use Sora fonts:

### Before:
```swift
Text("Hello World")
    .font(.title)
    .fontWeight(.bold)
```

### After:
```swift
Text("Hello World")
    .soraTitle()
    
// Or using the style system:
Text("Hello World")
    .soraStyle(.title)
```

## Troubleshooting

### Font Not Loading?
1. Verify font files are in `AdRadar/Resources/Fonts/`
2. Check `Info.plist` includes all font file names under `UIAppFonts`
3. Clean build folder and rebuild

### Font Appears Incorrect?
1. Ensure you're using the correct font name (case-sensitive)
2. Check that the font weight exists in your bundle
3. Use `SoraFontLoader.printAvailableFonts()` to debug

## Examples in Your App

The PaymentsView has been updated to demonstrate Sora font usage:

- Payment amounts use `.soraLargeTitle()`
- Card titles use `.soraHeadline()`
- Descriptions use `.soraCaption()`
- Loading text uses `.soraBody()`

## Future Enhancements

Consider implementing:
- Dark mode optimizations
- Dynamic type support
- Additional font weights (ExtraLight, ExtraBold)
- Variable font support
- Custom letter spacing for specific use cases

---

**Note**: Sora is an open-source font under the SIL Open Font License, making it free for commercial use in your AdRadar app. 