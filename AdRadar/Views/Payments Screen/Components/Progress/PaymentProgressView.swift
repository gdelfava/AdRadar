import SwiftUI

struct PaymentProgressView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let currentMonthEarnings: Double
    let paymentThreshold: Double
    
    @State private var animatedProgress: CGFloat = 0
    
    private var progress: Double {
        min(currentMonthEarnings / paymentThreshold, 1.0)
    }
    
    private var progressPercentage: Int {
        Int(progress * 100)
    }
    
    private var remainingAmount: Double {
        max(paymentThreshold - currentMonthEarnings, 0)
    }
    
    private var nextMonthName: String {
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: nextMonth)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress header
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("\(nextMonthName) Threshold Progress")
                    .soraSubheadline()
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(progressPercentage)%")
                    .soraSubheadline()
                    .foregroundColor(progress >= 1.0 ? .green : .blue)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: progress >= 1.0 ? .green : .blue, location: 0),
                                    .init(color: progress >= 1.0 ? .green.opacity(0.8) : .blue.opacity(0.8), location: 0.5),
                                    .init(color: progress >= 1.0 ? .green : .blue, location: 1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animatedProgress * geometry.size.width, height: 8)
                        .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                }
            }
            .frame(height: 8)
            
            // Progress details
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Month Earnings")
                        .soraCaption2()
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(currentMonthEarnings))
                        .soraCaption()
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if progress < 1.0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Needed for \(nextMonthName) Payment")
                            .soraCaption2()
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(remainingAmount))
                            .soraCaption()
                            .foregroundColor(.orange)
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Ready for \(nextMonthName) Payment!")
                            .soraCaption2()
                            .foregroundColor(.green)
                        
                        Text("Threshold Met")
                            .soraCaption()
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = CGFloat(progress)
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if authViewModel.isDemoMode {
            formatter.currencySymbol = "$"
            formatter.locale = Locale(identifier: "en_US")
        } else {
            formatter.locale = Locale.current // Use user's locale for currency
        }
        
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }
} 