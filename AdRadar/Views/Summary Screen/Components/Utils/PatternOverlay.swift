import SwiftUI

/// A utility view that creates a dotted pattern overlay using SwiftUI Canvas.
/// Used to add visual texture to card backgrounds and other UI elements.
struct PatternOverlay: View {
    let color: Color
    
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 20
            let dotSize: CGFloat = 2
            
            for x in stride(from: 0, through: size.width, by: spacing) {
                for y in stride(from: 0, through: size.height, by: spacing) {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.accentColor.opacity(0.1)
        PatternOverlay(color: .accentColor.opacity(0.1))
    }
} 