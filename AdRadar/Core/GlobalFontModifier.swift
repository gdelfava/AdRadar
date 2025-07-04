import SwiftUI

// MARK: - Global Font Modifier
struct GlobalSoraFontModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .environment(\.font, .soraBody) // Set default body font
    }
}

// MARK: - App-Wide Font Application
extension View {
    func applySoraFonts() -> some View {
        self.modifier(GlobalSoraFontModifier())
    }
}

// MARK: - Navigation Appearance Configuration
struct SoraNavigationAppearance {
    static func configure() {
        // Configure UINavigationBar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Set Sora font for navigation titles
        if let soraFont = UIFont(name: "Sora-SemiBold", size: 20) {
            appearance.titleTextAttributes = [
                .font: soraFont,
                .foregroundColor: UIColor.label
            ]
            appearance.largeTitleTextAttributes = [
                .font: UIFont(name: "Sora-Bold", size: 32) ?? soraFont,
                .foregroundColor: UIColor.label
            ]
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure UITabBar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        if let soraTabFont = UIFont(name: "Sora-Medium", size: 10) {
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .font: soraTabFont
            ]
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .font: soraTabFont
            ]
        }
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

// MARK: - SwiftUI Component Extensions with Sora Defaults
extension Text {
    func soraStyle(_ style: SoraTextStyle) -> AnyView {
        switch style {
        case .largeTitle:
            return AnyView(self.soraLargeTitle())
        case .title:
            return AnyView(self.soraTitle())
        case .title2:
            return AnyView(self.soraTitle2())
        case .title3:
            return AnyView(self.soraTitle3())
        case .headline:
            return AnyView(self.soraHeadline())
        case .body:
            return AnyView(self.soraBody())
        case .callout:
            return AnyView(self.soraCallout())
        case .subheadline:
            return AnyView(self.soraSubheadline())
        case .footnote:
            return AnyView(self.soraFootnote())
        case .caption:
            return AnyView(self.soraCaption())
        case .caption2:
            return AnyView(self.soraCaption2())
        case .navigationTitle:
            return AnyView(self.soraNavigationTitle())
        case .buttonTitle:
            return AnyView(self.soraButtonTitle())
        case .cardTitle:
            return AnyView(self.soraCardTitle())
        case .cardSubtitle:
            return AnyView(self.soraCardSubtitle())
        case .metricValue:
            return AnyView(self.soraMetricValue())
        case .metricLabel:
            return AnyView(self.soraMetricLabel())
        }
    }
}

// MARK: - Text Style Enum
enum SoraTextStyle {
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
    case caption2
    case navigationTitle
    case buttonTitle
    case cardTitle
    case cardSubtitle
    case metricValue
    case metricLabel
}

// MARK: - Auto-Apply Sora to Common UI Elements
struct SoraButton: View {
    let title: String
    let action: () -> Void
    let style: SoraButtonStyle
    
    init(_ title: String, style: SoraButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .soraButtonTitle()
                .foregroundColor(style.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(style.backgroundColor)
                .cornerRadius(8)
        }
    }
}

enum SoraButtonStyle {
    case primary
    case secondary
    case tertiary
    
    var backgroundColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return .gray.opacity(0.2)
        case .tertiary: return .clear
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return .primary
        case .tertiary: return .blue
        }
    }
}

// MARK: - Sora Card Components
struct SoraCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct SoraMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String?
    
    init(title: String, value: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        SoraCard {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .soraHeadline()
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .soraCardTitle()
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .soraMetricValue()
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .soraCardSubtitle()
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("Sora Font Demo")
            .soraStyle(.largeTitle)
        
        SoraButton("Primary Button") {
            print("Tapped")
        }
        
        SoraMetricCard(
            title: "Revenue",
            value: "$1,234.56",
            subtitle: "This month",
            icon: "dollarsign.circle"
        )
        
        Text("Body text using Sora font family for excellent readability and modern look.")
            .soraStyle(.body)
            .multilineTextAlignment(.center)
    }
    .padding()
} 