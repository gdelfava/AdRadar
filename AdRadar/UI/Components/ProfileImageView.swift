import SwiftUI

actor ImageCache {
    static let shared = ImageCache()
    private var cache: [URL: Image] = [:]
    
    func image(for url: URL) -> Image? {
        return cache[url]
    }
    
    func setImage(_ image: Image, for url: URL) {
        cache[url] = image
    }
}

struct ProfileImageView: View {
    let url: URL?
    @State private var cachedImage: Image?
    @State private var isPressed = false
    @Environment(\.authViewModel) private var authViewModel
    
    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                cachedImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.primary.opacity(0.1),
                                        Color.primary.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    )
                    .onAppear {
                        if let url = url {
                            Task {
                                await ImageCache.shared.setImage(cachedImage, for: url)
                            }
                        }
                    }
            } else if let url = url {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.primary.opacity(0.1),
                                            Color.primary.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                        .background(
                            Circle()
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                        )
                        .onAppear {
                            Task {
                                await ImageCache.shared.setImage(image, for: url)
                                cachedImage = image
                            }
                        }
                } placeholder: {
                    ZStack {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.primary.opacity(0.1),
                                                Color.primary.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                        
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.secondary)
                    }
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    )
                }
            } else if authViewModel?.isDemoMode == true {
                // Use local asset for demo mode
                Image("user-profile-image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.primary.opacity(0.1),
                                        Color.primary.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.tertiarySystemBackground),
                                    Color(.quaternarySystemFill)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.primary.opacity(0.1),
                                            Color.primary.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.secondary.opacity(0.8),
                                    Color.secondary.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                )
            }
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
        .task {
            if let url = url {
                cachedImage = await ImageCache.shared.image(for: url)
            }
        }
    }
}

private struct AuthViewModelKey: EnvironmentKey {
    static let defaultValue: AuthViewModel? = nil
}

extension EnvironmentValues {
    var authViewModel: AuthViewModel? {
        get { self[AuthViewModelKey.self] }
        set { self[AuthViewModelKey.self] = newValue }
    }
} 