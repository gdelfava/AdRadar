import SwiftUI
import UIKit

struct PreviousPaymentCardView: View {
    let amount: String
    let date: String
    
    @State private var isExpanded = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Payment icon and info
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.green)
                            .frame(width: 32, height: 32)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Previous Payment")
                                .soraHeadline()
                                .foregroundColor(.primary)
                            
                            Text("Last Completed")
                                .soraCaption()
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text("Paid")
                        .soraCaption()
                        .textCase(.uppercase)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                // Main amount
                Text(amount)
                    .soraLargeTitle()
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Main metrics pills
                HStack(spacing: 12) {
                    PaymentMetricPill(
                        icon: "checkmark.circle.fill",
                        title: "Status",
                        value: "Completed",
                        color: .green
                    )
                    
                    PaymentMetricPill(
                        icon: "calendar.badge.checkmark",
                        title: "Date",
                        value: "Last Period",
                        color: .blue
                    )
                }
            }
            .padding(20)
            
            // Expandable detailed metrics
            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        PaymentDetailedMetricRow(
                            icon: "calendar.circle.fill",
                            title: "Payment Date",
                            value: date,
                            color: .blue
                        )
                        
                        PaymentDetailedMetricRow(
                            icon: "creditcard.fill",
                            title: "Payment Method",
                            value: "Bank Transfer",
                            color: .purple
                        )
                        
                        PaymentDetailedMetricRow(
                            icon: "building.2.fill",
                            title: "Payment Source",
                            value: "Google AdSense",
                            color: .green
                        )
                        
                        PaymentDetailedMetricRow(
                            icon: "clock.badge.checkmark.fill",
                            title: "Processing Time",
                            value: "Instant Transfer",
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(.tertiarySystemBackground))
            }
            
            // Expand/Collapse button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Less Details" : "More Details")
                        .soraCaption()
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.quaternarySystemFill))
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
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
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
} 