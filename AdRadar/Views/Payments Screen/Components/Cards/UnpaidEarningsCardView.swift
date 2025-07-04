import SwiftUI
import UIKit

struct UnpaidEarningsCardView: View {
    let amount: String
    let unpaidValue: Double
    let paymentThreshold: Double
    let date: String
    let isPaid: Bool
    
    @State private var isExpanded = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Earnings icon and status
                    HStack(spacing: 12) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.orange)
                            .frame(width: 32, height: 32)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unpaid Earnings")
                                .soraHeadline()
                                .foregroundColor(.primary)
                            
                            Text("Current Period")
                                .soraCaption()
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text(isPaid ? "Paid" : "Pending")
                        .soraCaption()
                        .textCase(.uppercase)
                        .foregroundColor(isPaid ? .green : .orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background((isPaid ? Color.green : Color.orange).opacity(0.1))
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
                        icon: "clock.fill",
                        title: "Status",
                        value: isPaid ? "Paid" : "Pending",
                        color: isPaid ? .green : .orange
                    )
                    
                    PaymentMetricPill(
                        icon: "calendar.circle.fill",
                        title: "Period",
                        value: "Current",
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
                            icon: "calendar.badge.plus",
                            title: "Earnings Date",
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
                            icon: "info.circle.fill",
                            title: "Payment Info",
                            value: isPaid ? "Completed" : "Processing on next payment date",
                            color: .secondary
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