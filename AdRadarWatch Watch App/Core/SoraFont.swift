import SwiftUI

// MARK: - Font Extensions for Watch
extension Font {
    // Display fonts - for hero numbers and large text
    static func soraDisplayLarge() -> Font {
        return Font.custom("Sora-Bold", size: 24)
    }
    
    static func soraDisplayMedium() -> Font {
        return Font.custom("Sora-SemiBold", size: 20)
    }
    
    static func soraDisplaySmall() -> Font {
        return Font.custom("Sora-Medium", size: 18)
    }
    
    // Headline fonts - for section headers
    static func soraHeadlineLarge() -> Font {
        return Font.custom("Sora-SemiBold", size: 16)
    }
    
    static func soraHeadline() -> Font {
        return Font.custom("Sora-Medium", size: 14)
    }
    
    // Body fonts - for regular content
    static func soraBody() -> Font {
        return Font.custom("Sora-Regular", size: 12)
    }
    
    static func soraBodyMedium() -> Font {
        return Font.custom("Sora-Medium", size: 12)
    }
    
    // Caption fonts - for small text and labels
    static func soraCaption() -> Font {
        return Font.custom("Sora-Regular", size: 10)
    }
    
    static func soraCaptionMedium() -> Font {
        return Font.custom("Sora-Medium", size: 10)
    }
    
    // Footnote fonts - for very small text
    static func soraFootnote() -> Font {
        return Font.custom("Sora-Light", size: 9)
    }
}

// MARK: - Text Modifiers for Watch
extension Text {
    func soraDisplayLarge() -> Text {
        self.font(.custom("Sora-Bold", size: 24))
    }
    
    func soraDisplayMedium() -> Text {
        self.font(.custom("Sora-SemiBold", size: 20))
    }
    
    func soraDisplaySmall() -> Text {
        self.font(.custom("Sora-Medium", size: 18))
    }
    
    func soraHeadlineLarge() -> Text {
        self.font(.custom("Sora-SemiBold", size: 16))
    }
    
    func soraHeadline() -> Text {
        self.font(.custom("Sora-Medium", size: 14))
    }
    
    func soraBody() -> Text {
        self.font(.custom("Sora-Regular", size: 12))
    }
    
    func soraBodyMedium() -> Text {
        self.font(.custom("Sora-Medium", size: 12))
    }
    
    func soraCaption() -> Text {
        self.font(.custom("Sora-Regular", size: 10))
    }
    
    func soraCaptionMedium() -> Text {
        self.font(.custom("Sora-Medium", size: 10))
    }
    
    func soraFootnote() -> Text {
        self.font(.custom("Sora-Light", size: 9))
    }
} 