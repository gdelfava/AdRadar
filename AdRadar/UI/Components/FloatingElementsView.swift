import SwiftUI

/// A base view that creates an animated floating elements effect using circles.
/// This view is typically used as a background decoration to add visual interest to the UI.
/// The circles animate in with a scaling effect and different delays for a dynamic appearance.
struct FloatingElementsView: View {
    @Binding var animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Floating circles
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.0).delay(0.5), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.5).delay(1.0), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 40, height: 40)
                    .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.7)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.2).delay(1.5), value: animate)
            }
        }
    }
}

/// A variant of FloatingElementsView specifically designed for the Summary screen
struct SummaryFloatingElementsView: View {
    @Binding var animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Floating circles positioned for summary content
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 40, height: 40)
                    .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.2)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.0).delay(0.3), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 60, height: 60)
                    .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.15)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.5).delay(0.8), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.06))
                    .frame(width: 35, height: 35)
                    .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.6)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.2).delay(1.2), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.04))
                    .frame(width: 50, height: 50)
                    .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.7)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.8).delay(1.6), value: animate)
            }
        }
    }
}

/// A variant of FloatingElementsView specifically designed for the Settings screen
struct SettingsFloatingElementsView: View {
    @Binding var animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Floating circles positioned for settings content
                Circle()
                    .fill(Color.accentColor.opacity(0.04))
                    .frame(width: 55, height: 55)
                    .position(x: geometry.size.width * 0.18, y: geometry.size.height * 0.2)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.0).delay(0.6), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.06))
                    .frame(width: 40, height: 40)
                    .position(x: geometry.size.width * 0.82, y: geometry.size.height * 0.15)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.4).delay(1.1), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 30, height: 30)
                    .position(x: geometry.size.width * 0.12, y: geometry.size.height * 0.45)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.2).delay(1.5), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.03))
                    .frame(width: 60, height: 60)
                    .position(x: geometry.size.width * 0.88, y: geometry.size.height * 0.65)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.3).delay(1.9), value: animate)
            }
        }
    }
}

/// A variant of FloatingElementsView specifically designed for the Payments screen
struct PaymentsFloatingElementsView: View {
    @Binding var animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Floating circles positioned for payments content
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 50, height: 50)
                    .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.22)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.1).delay(0.5), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.03))
                    .frame(width: 70, height: 70)
                    .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.16)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.6).delay(1.0), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.06))
                    .frame(width: 35, height: 35)
                    .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.58)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.3).delay(1.4), value: animate)
            }
        }
    }
}

/// A variant of FloatingElementsView specifically designed for the Streak screen
struct StreakFloatingElementsView: View {
    @Binding var animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Floating circles positioned for streak content
                Circle()
                    .fill(Color.accentColor.opacity(0.06))
                    .frame(width: 45, height: 45)
                    .position(x: geometry.size.width * 0.12, y: geometry.size.height * 0.25)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.2).delay(0.4), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.04))
                    .frame(width: 65, height: 65)
                    .position(x: geometry.size.width * 0.88, y: geometry.size.height * 0.18)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.7).delay(0.9), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 30, height: 30)
                    .position(x: geometry.size.width * 0.08, y: geometry.size.height * 0.55)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.1).delay(1.3), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.03))
                    .frame(width: 55, height: 55)
                    .position(x: geometry.size.width * 0.92, y: geometry.size.height * 0.72)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.5).delay(1.7), value: animate)
            }
        }
    }
} 