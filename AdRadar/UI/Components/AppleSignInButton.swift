import SwiftUI
import AuthenticationServices

/// A modern Apple Sign In button that matches the app's design language.
/// Features consistent styling with the Google Sign In button.
struct AppleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Apple Sign In icon
                Image(systemName: "applelogo")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Continue with Apple")
                    .font(.sora(.semibold, size: 17))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.primary.opacity(0.1), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(ModernButtonStyle())
    }
}

/// Alternative Apple Sign In button using the native ASAuthorizationAppleIDButton
/// This provides the official Apple-styled button
struct NativeAppleSignInButton: UIViewRepresentable {
    let action: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(
            authorizationButtonType: .continue,
            authorizationButtonStyle: UITraitCollection.current.userInterfaceStyle == .dark ? .whiteOutline : .black
        )
        
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.buttonPressed),
            for: .touchUpInside
        )
        
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor.label.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        // The style is set during creation and doesn't need updating
        // ASAuthorizationAppleIDButton doesn't support dynamic style changes
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonPressed() {
            action()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AppleSignInButton(action: {})
        
        NativeAppleSignInButton(action: {})
            .frame(height: 56)
        
        GoogleSignInButtonView(action: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 