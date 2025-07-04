import SwiftUI

struct PaymentMetricPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color.opacity(0.8))
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .soraCaption()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(getSubtitle())
                        .soraCaption2()
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            Text(value)
                .soraTitle3()
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: color.opacity(0.08), location: 0),
                    .init(color: color.opacity(0.04), location: 0.7),
                    .init(color: color.opacity(0.02), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
    
    private func getSubtitle() -> String {
        switch title.lowercased() {
        case "status":
            return value == "Paid" ? "Payment Complete" : "Awaiting Payment"
        case "period":
            return "Earnings Cycle"
        case "date":
            return "Payment Date"
        default:
            return "Payment Info"
        }
    }
} 