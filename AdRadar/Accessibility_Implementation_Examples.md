# AdRadar Accessibility Implementation Examples

## Quick Start Guide

### 1. Import Accessibility Extensions
Add this import to any file where you want to use accessibility features:
```swift
import SwiftUI
// The AccessibilityExtensions.swift file is already imported
```

### 2. Basic Implementation Examples

#### Currency Values
```swift
// Before
Text("$1,234.56")
    .soraMetricValue()

// After
Text("$1,234.56")
    .soraMetricValue()
    .accessibleCurrency(
        label: "Total earnings",
        amount: "$1,234.56",
        hint: "Double tap to view breakdown"
    )
```

#### Metric Cards
```swift
// Before
VStack {
    Text("Today's Earnings")
    Text("$123.45")
    Text("+12.5%")
}
.padding()
.background(Color(.secondarySystemBackground))
.cornerRadius(12)

// After
AccessibleMetricCard(
    title: "Today's Earnings",
    value: "$123.45",
    subtitle: "vs yesterday",
    delta: "+12.5%",
    icon: "dollarsign.circle",
    color: .green,
    onTap: { /* action */ }
)
```

#### Buttons
```swift
// Before
Button("Refresh") {
    // action
}

// After
AccessibleButton(
    title: "Refresh Data",
    icon: "arrow.clockwise",
    style: .primary
) {
    // action
}
```

## Implementation by Screen

### Summary Screen

#### Hero Summary Card
```swift
// In HeroSummaryCard.swift
struct HeroSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let delta: String
    let deltaPositive: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            // ... existing content
        }
        .onTapGesture(perform: onTap)
        .accessibleCard(
            label: title,
            value: AccessibilityUtilities.metricDescription(
                title: title,
                value: value,
                delta: delta,
                period: subtitle
            ),
            hint: "Double tap to view detailed breakdown"
        )
    }
}
```

#### Compact Summary Card
```swift
// In CompactSummaryCard.swift
struct CompactSummaryCard: View {
    // ... existing properties
    
    var body: some View {
        HStack {
            // ... existing content
        }
        .onTapGesture(perform: onTap)
        .accessibleCard(
            label: "\(title) performance",
            value: AccessibilityUtilities.metricDescription(
                title: title,
                value: value,
                delta: delta,
                period: subtitle
            ),
            hint: "Double tap to view detailed metrics"
        )
    }
}
```

### Payments Screen

#### Payment Progress View
```swift
// In PaymentProgressView.swift
struct PaymentProgressView: View {
    let currentMonthEarnings: Double
    let paymentThreshold: Double
    
    var body: some View {
        VStack {
            // ... existing content
        }
        .accessibleCard(
            label: "Payment progress",
            value: "\(Int(progress * 100))% complete. \(remainingAmount) needed for next payment",
            hint: "Double tap to view payment details"
        )
    }
}
```

#### Previous Payment Card
```swift
// In PreviousPaymentCardView.swift
struct PreviousPaymentCardView: View {
    let amount: String
    let date: Date
    
    var body: some View {
        VStack {
            // ... existing content
        }
        .accessibleCard(
            label: "Previous payment",
            value: AccessibilityUtilities.metricDescription(
                title: "Payment amount",
                value: amount,
                period: "Paid on \(dateFormatter.string(from: date))"
            ),
            hint: "Double tap to view payment details"
        )
    }
}
```

### Settings Screen

#### Settings Rows
```swift
// In SettingsView.swift
struct SettingsRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                VStack(alignment: .leading) {
                    Text(title)
                    if let subtitle = subtitle {
                        Text(subtitle)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
        }
        .accessibleButton(
            label: title,
            hint: "Double tap to configure \(title.lowercased())"
        )
    }
}
```

## Dynamic Type Implementation

### Update Text Components
```swift
// In any text component
Text("Your text here")
    .soraBody()
    .dynamicTypeSupport(minimumScaleFactor: 0.8)
    .lineLimit(nil) // Allow text to wrap
```

### Update Layout Components
```swift
// In VStack or HStack
VStack(spacing: 16) {
    // content
}
.frame(maxWidth: .infinity)
.minimumScaleFactor(0.8)
```

## Color Accessibility

### Use Accessible Colors
```swift
// Instead of hardcoded colors
Text("Important text")
    .foregroundColor(.accessibleText)

// For accent colors
Button("Action") { }
    .foregroundColor(.accessibleAccent)
```

### High Contrast Support
```swift
// In your color definitions
extension Color {
    static var successGreen: Color {
        @Environment(\.colorSchemeContrast) var contrast
        return contrast == .increased ? .green : .green
    }
}
```

## Testing Your Implementation

### 1. VoiceOver Testing
```swift
// Add this to your preview for testing
#Preview {
    YourView()
        .environment(\.accessibilityEnabled, true)
}
```

### 2. Dynamic Type Testing
```swift
// Test with different text sizes
#Preview("Large Text") {
    YourView()
        .environment(\.sizeCategory, .accessibility3)
}
```

### 3. High Contrast Testing
```swift
// Test with high contrast
#Preview("High Contrast") {
    YourView()
        .environment(\.colorSchemeContrast, .increased)
}
```

## Common Patterns

### 1. Metric Display Pattern
```swift
// For any metric display
Text(value)
    .soraMetricValue()
    .accessibleMetric(
        label: title,
        value: AccessibilityUtilities.formatNumberForSpeech(value),
        hint: "Double tap for details"
    )
```

### 2. Navigation Pattern
```swift
// For navigation elements
NavigationLink(destination: destination) {
    // content
}
.accessibleNavigation(
    label: "Navigate to \(destinationName)",
    hint: "Double tap to navigate"
)
```

### 3. Action Pattern
```swift
// For action buttons
Button(action: action) {
    // content
}
.accessibleButton(
    label: actionName,
    hint: "Double tap to \(actionDescription)"
)
```

## Accessibility Checklist

### For Each Screen
- [ ] All text elements have proper labels
- [ ] Interactive elements have hints
- [ ] Buttons have proper traits
- [ ] Navigation is accessible
- [ ] Dynamic Type works properly
- [ ] High contrast mode works
- [ ] VoiceOver navigation is smooth

### For Each Component
- [ ] Currency values are properly formatted for speech
- [ ] Numbers are spelled out appropriately
- [ ] Icons have descriptive labels
- [ ] Gestures have accessibility actions
- [ ] Cards are properly grouped
- [ ] Focus management works correctly

## Performance Considerations

### Efficient Accessibility
```swift
// Use lazy loading for accessibility labels
.accessibilityLabel(lazyAccessibilityLabel)

// Cache formatted values
private var cachedAccessibilityValue: String {
    // Compute once and cache
}
```

### Memory Management
```swift
// Avoid creating accessibility strings repeatedly
private let accessibilityLabel: String = "Pre-computed label"
```

## Troubleshooting

### Common Issues
1. **VoiceOver not reading correctly**: Check accessibility labels and values
2. **Dynamic Type not working**: Ensure fonts use UIFontMetrics
3. **High contrast not applied**: Use accessible color extensions
4. **Navigation issues**: Add proper accessibility traits

### Debug Tools
```swift
// Add to your view for debugging
.accessibilityIdentifier("debug-identifier")
```

This guide provides practical examples for implementing accessibility in your AdRadar app. Start with the basic patterns and gradually implement more advanced features. 