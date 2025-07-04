import SwiftUI

// MARK: - Font Extension
extension Font {
    
    // MARK: - Sora Font Family
    static func sora(_ weight: SoraWeight, size: CGFloat) -> Font {
        // Use memory manager for optimized font loading
        if let optimizedFont = MemoryManager.shared.optimizedFont(name: weight.fontName, size: size) {
            return Font(optimizedFont)
        }
        return .custom(weight.fontName, size: size)
    }
    
    // MARK: - Predefined Sora Sizes
    static var soraLargeTitle: Font { .sora(.bold, size: 34) }
    static var soraTitle: Font { .sora(.semibold, size: 28) }
    static var soraTitle2: Font { .sora(.semibold, size: 22) }
    static var soraTitle3: Font { .sora(.semibold, size: 20) }
    static var soraHeadline: Font { .sora(.semibold, size: 17) }
    static var soraBody: Font { .sora(.regular, size: 17) }
    static var soraCallout: Font { .sora(.regular, size: 16) }
    static var soraSubheadline: Font { .sora(.regular, size: 15) }
    static var soraFootnote: Font { .sora(.regular, size: 13) }
    static var soraCaption: Font { .sora(.regular, size: 12) }
    static var soraCaption2: Font { .sora(.regular, size: 11) }
    
    // MARK: - Specialized Sora Fonts
    static var soraNavigationTitle: Font { .sora(.semibold, size: 20) }
    static var soraTabBarTitle: Font { .sora(.medium, size: 10) }
    static var soraButtonTitle: Font { .sora(.semibold, size: 17) }
    static var soraCardTitle: Font { .sora(.semibold, size: 16) }
    static var soraCardSubtitle: Font { .sora(.regular, size: 14) }
    static var soraMetricValue: Font { .sora(.bold, size: 28) }
    static var soraMetricLabel: Font { .sora(.medium, size: 12) }
}

// MARK: - Sora Font Weights
enum SoraWeight: String, CaseIterable {
    case light = "Light"
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "SemiBold"
    case bold = "Bold"
    
    var fontName: String {
        return "Sora-\(self.rawValue)"
    }
    
    var weight: Font.Weight {
        switch self {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

// MARK: - Sora Font Modifier
struct SoraFontModifier: ViewModifier {
    let weight: SoraWeight
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.sora(weight, size: size))
    }
}

// MARK: - View Extension for Sora Font
extension View {
    func soraFont(_ weight: SoraWeight, size: CGFloat) -> some View {
        self.modifier(SoraFontModifier(weight: weight, size: size))
    }
    
    // MARK: - Predefined Sora Font Modifiers
    func soraLargeTitle() -> some View {
        self.font(.soraLargeTitle)
    }
    
    func soraTitle() -> some View {
        self.font(.soraTitle)
    }
    
    func soraTitle2() -> some View {
        self.font(.soraTitle2)
    }
    
    func soraTitle3() -> some View {
        self.font(.soraTitle3)
    }
    
    func soraHeadline() -> some View {
        self.font(.soraHeadline)
    }
    
    func soraBody() -> some View {
        self.font(.soraBody)
    }
    
    func soraCallout() -> some View {
        self.font(.soraCallout)
    }
    
    func soraSubheadline() -> some View {
        self.font(.soraSubheadline)
    }
    
    func soraFootnote() -> some View {
        self.font(.soraFootnote)
    }
    
    func soraCaption() -> some View {
        self.font(.soraCaption)
    }
    
    func soraCaption2() -> some View {
        self.font(.soraCaption2)
    }
    
    // MARK: - Specialized Sora Font Modifiers
    func soraNavigationTitle() -> some View {
        self.font(.soraNavigationTitle)
    }
    
    func soraTabBarTitle() -> some View {
        self.font(.soraTabBarTitle)
    }
    
    func soraButtonTitle() -> some View {
        self.font(.soraButtonTitle)
    }
    
    func soraCardTitle() -> some View {
        self.font(.soraCardTitle)
    }
    
    func soraCardSubtitle() -> some View {
        self.font(.soraCardSubtitle)
    }
    
    func soraMetricValue() -> some View {
        self.font(.soraMetricValue)
    }
    
    func soraMetricLabel() -> some View {
        self.font(.soraMetricLabel)
    }
}

// MARK: - Typography Scale
struct SoraTypography {
    
    // MARK: - Display Scale
    static let display1 = Font.sora(.bold, size: 48)
    static let display2 = Font.sora(.bold, size: 40)
    static let display3 = Font.sora(.bold, size: 36)
    
    // MARK: - Heading Scale
    static let h1 = Font.sora(.bold, size: 32)
    static let h2 = Font.sora(.bold, size: 28)
    static let h3 = Font.sora(.semibold, size: 24)
    static let h4 = Font.sora(.semibold, size: 20)
    static let h5 = Font.sora(.semibold, size: 18)
    static let h6 = Font.sora(.semibold, size: 16)
    
    // MARK: - Body Scale
    static let bodyLarge = Font.sora(.regular, size: 18)
    static let bodyMedium = Font.sora(.regular, size: 16)
    static let bodySmall = Font.sora(.regular, size: 14)
    static let bodyXSmall = Font.sora(.regular, size: 12)
    
    // MARK: - Label Scale
    static let labelLarge = Font.sora(.medium, size: 16)
    static let labelMedium = Font.sora(.medium, size: 14)
    static let labelSmall = Font.sora(.medium, size: 12)
    static let labelXSmall = Font.sora(.medium, size: 10)
    
    // MARK: - Utility Scale
    static let overline = Font.sora(.medium, size: 10)
    static let caption = Font.sora(.regular, size: 12)
    static let button = Font.sora(.semibold, size: 16)
    static let link = Font.sora(.medium, size: 16)
}

// MARK: - Font Loading Helper
struct SoraFontLoader {
    static func loadFonts() {
        // This function validates that fonts are available in the system
        
        let fontNames = [
            "Sora-Light",
            "Sora-Regular", 
            "Sora-Medium",
            "Sora-SemiBold",
            "Sora-Bold"
        ]
        
        for fontName in fontNames {
            // Use UIFont to properly validate font availability
            if UIFont(name: fontName, size: 12) != nil {
                print("✅ Font loaded: \(fontName)")
            } else {
                print("❌ Failed to load font: \(fontName)")
            }
        }
    }
    
    static func printAvailableFonts() {
        print("📝 Available Sora fonts:")
        for weight in SoraWeight.allCases {
            print("  - \(weight.fontName)")
        }
    }
    
    static func validateSoraFonts() -> Bool {
        let fontNames = [
            "Sora-Light",
            "Sora-Regular", 
            "Sora-Medium",
            "Sora-SemiBold",
            "Sora-Bold"
        ]
        
        return fontNames.allSatisfy { fontName in
            UIFont(name: fontName, size: 12) != nil
        }
    }
}

// MARK: - Preview Helper
struct SoraFontPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("Sora Display 1")
                        .font(SoraTypography.display1)
                    
                    Text("Sora Display 2")
                        .font(SoraTypography.display2)
                    
                    Text("Sora Heading 1")
                        .font(SoraTypography.h1)
                    
                    Text("Sora Heading 2")
                        .font(SoraTypography.h2)
                    
                    Text("Sora Heading 3")
                        .font(SoraTypography.h3)
                    
                    Text("Sora Body Large - This is a sample text to show how the Sora font looks in body text.")
                        .font(SoraTypography.bodyLarge)
                    
                    Text("Sora Body Medium - This is a sample text to show how the Sora font looks in body text.")
                        .font(SoraTypography.bodyMedium)
                    
                    Text("Sora Label Large")
                        .font(SoraTypography.labelLarge)
                    
                    Text("Sora Caption")
                        .font(SoraTypography.caption)
                }
                
                Group {
                    Text("Using Extensions:")
                        .soraHeadline()
                    
                    Text("This text uses the Sora headline modifier")
                        .soraBody()
                    
                    Text("This text uses the Sora caption modifier")
                        .soraCaption()
                }
            }
            .padding()
        }
        .onAppear {
            SoraFontLoader.printAvailableFonts()
        }
    }
}

#Preview {
    SoraFontPreview()
} 