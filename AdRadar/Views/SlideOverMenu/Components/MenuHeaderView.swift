import SwiftUI

/// Header view for the slide over menu with user information and gradient background
struct MenuHeaderView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    let geometry: GeometryProxy
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header content with proper safe area handling
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(settingsViewModel.currentPublisherName.isEmpty ? "Publisher Name" : settingsViewModel.currentPublisherName)
                            .soraTitle2()
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "number.circle.fill")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(settingsViewModel.currentPublisherId.isEmpty ? "1234567890" : settingsViewModel.currentPublisherId)
                                .soraBody()
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                        
//                        Text("AdSense & Admob Analytics")
//                            .soraCaption()
//                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Menu close indicator
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                        .onTapGesture {
                            onDismiss()
                        }
                }
                .padding(.horizontal, 24)
                .padding(.top, max(60, geometry.safeAreaInsets.top + 40))
                .padding(.bottom, 24)
            }
            .background(headerGradient)
            .clipShape(
                RoundedCornerShape(
                    radius: 20,
                    corners: [.topLeft, .bottomLeft, .bottomRight]
                )
            )
        }
    }
    
    private var headerGradient: some View {
        ZStack {
            // Base gradient matching app's accent color and design
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: colorScheme == .dark ? 
                        Color.accentColor.opacity(0.7) : Color.accentColor.opacity(0.95), location: 0),
                    .init(color: colorScheme == .dark ? 
                        Color.accentColor.opacity(0.6) : Color.accentColor.opacity(0.85), location: 0.4),
                    .init(color: colorScheme == .dark ? 
                        Color.blue.opacity(0.5) : Color.blue.opacity(0.8), location: 0.7),
                    .init(color: colorScheme == .dark ? 
                        Color.indigo.opacity(0.4) : Color.indigo.opacity(0.75), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle overlay for depth matching app's style
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.08), location: 0.6),
                    .init(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.15), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)
        }
    }
}

#Preview {
    GeometryReader { geometry in
        MenuHeaderView(geometry: geometry) {
            print("Dismiss tapped")
        }
        .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
    }
} 
