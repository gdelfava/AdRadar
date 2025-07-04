import SwiftUI

struct WatchLoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Enhanced loading indicator with scaling animation
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.6)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(Angle(degrees: rotationAngle))
                    .scaleEffect(scale)
                    .animation(
                        Animation.linear(duration: 1.2).repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
                    .animation(
                        Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: scale
                    )
            }
            
            VStack(spacing: 4) {
                Text("Syncing...")
                    .soraBodyMedium()
                    .foregroundColor(.primary)
                
                Text("Fetching latest data")
                    .soraCaption()
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            rotationAngle = 360
            scale = 1.1
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct WatchErrorView: View {
    let message: String
    let onRetry: () -> Void
    @State private var bounceAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Enhanced error icon with bounce animation
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .scaleEffect(bounceAnimation ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: bounceAnimation
                    )
                
                Image(systemName: "wifi.exclamationmark")
                    .font(.soraHeadline())
                    .foregroundColor(Color.orange)
            }
            
            VStack(spacing: 8) {
                Text("Connection Issue")
                    .soraHeadline()
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .soraCaption()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Enhanced retry button
            Button(action: onRetry) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.soraCaption())
                    Text("Retry")
                        .soraCaption()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.accentColor,
                            Color.accentColor.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            bounceAnimation = true
        }
    }
}

struct WatchNoDataView: View {
    let onRefresh: () -> Void
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Enhanced no data icon with pulse animation
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.3 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.soraHeadline())
                    .foregroundColor(Color.blue)
            }
            
            VStack(spacing: 8) {
                Text("No Data Available")
                    .soraHeadline()
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Open the iPhone app to sync your AdSense performance data")
                    .soraCaption()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }
            
            // Enhanced refresh button
            Button(action: onRefresh) {
                HStack(spacing: 6) {
                    Image(systemName: "iphone")
                        .font(.soraCaption())
                    Text("Sync Now")
                        .soraCaption()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue,
                            Color.blue.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            pulseAnimation = true
        }
    }
}

#Preview("Loading") {
    WatchLoadingView()
}

#Preview("Error") {
    WatchErrorView(message: "Unable to connect to iPhone. Please ensure both devices are nearby and connected.") {
        print("Retry tapped")
    }
}

#Preview("No Data") {
    WatchNoDataView {
        print("Refresh tapped")
    }
} 