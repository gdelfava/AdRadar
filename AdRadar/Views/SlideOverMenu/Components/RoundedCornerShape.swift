import SwiftUI
import UIKit

/// Custom shape for creating rounded corners on specific corners
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    Rectangle()
        .fill(Color.blue)
        .frame(width: 200, height: 100)
        .clipShape(RoundedCornerShape(radius: 20, corners: [.topLeft, .bottomRight]))
        .padding()
} 