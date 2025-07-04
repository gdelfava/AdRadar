import SwiftUI

/// A modern button style that provides a smooth press animation effect.
/// This style scales down the button slightly when pressed and reduces its opacity,
/// creating a natural and responsive feel.
struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
} 