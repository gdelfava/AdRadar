import SwiftUI

// MARK: - Accessibility Extensions for AdRadar

// MARK: - Text Accessibility Extensions
extension Text {
    /// Adds accessibility support for metric values with proper formatting
    func accessibleMetric(
        label: String,
        value: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "Double tap to view details")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
    
    /// Adds accessibility for currency values with proper pronunciation
    func accessibleCurrency(
        label: String,
        amount: String,
        hint: String? = nil
    ) -> some View {
        let spokenAmount = formatCurrencyForSpeech(amount)
        return self
            .accessibilityLabel(label)
            .accessibilityValue(spokenAmount)
            .accessibilityHint(hint ?? "Double tap to view breakdown")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
    
    /// Adds accessibility for percentage values
    func accessiblePercentage(
        label: String,
        percentage: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue("\(percentage) percent")
            .accessibilityHint(hint ?? "Double tap for details")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

// MARK: - Button Accessibility Extensions
extension Button {
    /// Creates an accessible button with proper labels and hints
    static func accessible(
        _ title: String,
        hint: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .accessibilityLabel(title)
            .accessibilityHint(hint ?? "Double tap to activate")
            .accessibilityAddTraits(.button)
    }
    
    /// Creates an accessible icon button
    static func accessibleIcon(
        icon: String,
        label: String,
        hint: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
        }
        .accessibilityLabel(label)
        .accessibilityHint(hint ?? "Double tap to activate")
        .accessibilityAddTraits(.button)
    }
}

// MARK: - View Accessibility Extensions
extension View {
    /// Makes a view accessible as a card with combined children
    func accessibleCard(
        label: String,
        value: String? = nil,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "Double tap to view details")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
    
    /// Makes a view accessible as a button
    func accessibleButton(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double tap to activate")
            .accessibilityAddTraits(.button)
    }
    
    /// Adds accessibility for data visualization
    func accessibleChart(
        label: String,
        description: String
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(description)
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
    
    /// Adds accessibility for navigation elements
    func accessibleNavigation(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double tap to navigate")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

// MARK: - Dynamic Type Support
extension View {
    /// Adds Dynamic Type support with minimum scale factor
    func dynamicTypeSupport(minimumScaleFactor: CGFloat = 0.8) -> some View {
        self
            .minimumScaleFactor(minimumScaleFactor)
            .lineLimit(nil)
    }
    
    /// Adds responsive font sizing
    func responsiveFont() -> some View {
        self
            .environment(\.sizeCategory, .accessibility1)
    }
}

// MARK: - Color Accessibility
extension Color {
    /// Returns accessible color based on contrast setting
    static var accessibleAccent: Color {
        @Environment(\.colorSchemeContrast) var contrast
        return contrast == .increased ? .blue : .accentColor
    }
    
    /// Returns accessible text color
    static var accessibleText: Color {
        @Environment(\.colorSchemeContrast) var contrast
        return contrast == .increased ? .primary : .primary
    }
}

// MARK: - Accessibility Utilities
struct AccessibilityUtilities {
    /// Formats currency for speech synthesis
    static func formatCurrencyForSpeech(_ amount: String) -> String {
        guard let value = Double(amount.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) else {
            return amount
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        
        let wholePart = Int(value)
        let decimalPart = Int((value - Double(wholePart)) * 100)
        
        var result = formatter.string(from: NSNumber(value: wholePart)) ?? ""
        result += " dollars"
        
        if decimalPart > 0 {
            result += " and "
            result += formatter.string(from: NSNumber(value: decimalPart)) ?? ""
            result += " cents"
        }
        
        return result
    }
    
    /// Formats numbers for speech synthesis
    static func formatNumberForSpeech(_ number: String) -> String {
        guard let value = Double(number.replacingOccurrences(of: ",", with: "")) else {
            return number
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        
        if value >= 1_000_000 {
            let millions = value / 1_000_000
            return "\(formatter.string(from: NSNumber(value: millions)) ?? "") million"
        } else if value >= 1_000 {
            let thousands = value / 1_000
            return "\(formatter.string(from: NSNumber(value: thousands)) ?? "") thousand"
        } else {
            return formatter.string(from: NSNumber(value: value)) ?? number
        }
    }
    
    /// Creates accessibility description for metric data
    static func metricDescription(
        title: String,
        value: String,
        delta: String? = nil,
        period: String? = nil
    ) -> String {
        var description = "\(title): \(value)"
        
        if let delta = delta {
            description += ". Change: \(delta)"
        }
        
        if let period = period {
            description += ". Period: \(period)"
        }
        
        return description
    }
}

// MARK: - Accessible Components

/// Accessible metric card component
struct AccessibleMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let delta: String?
    let icon: String?
    let color: Color
    let onTap: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .soraHeadline()
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(value)
                .soraMetricValue()
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .soraCaption()
                    .foregroundColor(.secondary)
            }
            
            if let delta = delta {
                Text(delta)
                    .soraCaption()
                    .foregroundColor(delta.hasPrefix("+") ? .green : .red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture {
            onTap?()
        }
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

/// Accessible button component
struct AccessibleButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to activate")
        .accessibilityAddTraits(.button)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .accentColor
        case .secondary:
            return Color(.systemGray5)
        case .destructive:
            return .red
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return .white
        }
    }
}

/// Accessible navigation link
struct AccessibleNavigationLink<Label: View>: View {
    let destination: AnyView
    let label: Label
    let accessibilityLabel: String
    let accessibilityHint: String?
    
    init<Destination: View>(
        destination: Destination,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.destination = AnyView(destination)
        self.label = label()
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            label
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "Double tap to navigate")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

// MARK: - Accessibility Testing Helpers
struct AccessibilityTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Accessibility Test")
                .soraTitle()
            
            AccessibleMetricCard(
                title: "Today's Earnings",
                value: "$123.45",
                subtitle: "vs yesterday",
                delta: "+12.5%",
                icon: "dollarsign.circle",
                color: .green,
                onTap: { print("Tapped") }
            )
            
            AccessibleButton(
                title: "Refresh Data",
                icon: "arrow.clockwise",
                style: .primary
            ) {
                print("Refresh tapped")
            }
            
            Text("$1,234.56")
                .soraMetricValue()
                .accessibleCurrency(
                    label: "Total earnings",
                    amount: "$1,234.56",
                    hint: "Double tap to view breakdown"
                )
        }
        .padding()
    }
}

#Preview {
    AccessibilityTestView()
} 