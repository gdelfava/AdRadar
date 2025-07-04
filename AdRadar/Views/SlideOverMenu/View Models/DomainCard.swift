import SwiftUI

struct DomainCard: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let domain: DomainData
    @State private var isPressed = false
    @State private var showDetailedMetrics = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            headerSection
            
            // Divider
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // Main Metrics Section
            mainMetricsSection
            
            // Detailed Metrics Section (expandable)
            if showDetailedMetrics {
                detailedMetricsSection
            }
            
            // Expand/Collapse Button
            expandButton
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: showDetailedMetrics)
        .onTapGesture {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetailedMetrics.toggle()
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Domain icon and name
                HStack(spacing: 12) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(domain.domainName)
                            .soraHeadline()
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text("Domain Performance")
                            .soraCaption()
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Earnings badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedCurrency(domain.earnings))
                        .soraTitle2()
                        .foregroundColor(.green)
                    
                    Text("Earnings")
                        .soraCaption2()
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var mainMetricsSection: some View {
        HStack(spacing: 0) {
            MetricPill(
                icon: "eye.fill",
                title: "Impressions",
                value: domain.impressions,
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            MetricPill(
                icon: "cursorarrow.click.2",
                title: "Clicks",
                value: domain.clicks,
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
            
            MetricPill(
                icon: "percent",
                title: "CTR",
                value: domain.formattedCTR,
                color: .purple
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var detailedMetricsSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DetailedMetricRow(
                    icon: "doc.text.fill",
                    title: "Requests",
                    value: domain.requests,
                    color: .indigo
                )
                
                DetailedMetricRow(
                    icon: "newspaper.fill",
                    title: "Page Views",
                    value: domain.pageViews,
                    color: .teal
                )
                
                DetailedMetricRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "RPM",
                    value: formattedCurrency(domain.rpm),
                    color: .pink
                )
                
//                DetailedMetricRow(
//                    icon: "dollarsign.circle.fill",
//                    title: "Revenue",
//                    value: formattedCurrency(domain.earnings),
//                    color: .green
//                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
    }
    
    private var expandButton: some View {
        HStack {
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetailedMetrics.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Text(showDetailedMetrics ? "Less Details" : "More Details")
                        .soraCaption()
                    
                    Image(systemName: showDetailedMetrics ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(.bottom, 16)
    }
    
    private func formattedCurrency(_ valueString: String) -> String {
        guard let value = Double(valueString) else { return valueString }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if authViewModel.isDemoMode {
            formatter.currencySymbol = "$"
        } else {
            formatter.locale = Locale.current
        }
        
        return formatter.string(from: NSNumber(value: value)) ?? valueString
    }
}

struct MetricPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 2) {
                Text(value)
                    .soraBody()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(title)
                    .soraCaption2()
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailedMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .soraCaption()
                    .foregroundColor(.secondary)
                
                Text(value)
                    .soraSubheadline()
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    DomainCard(domain: DomainData(
        domainName: "example.com",
        earnings: "1234.56",
        requests: "50,000",
        pageViews: "25,000",
        impressions: "100,000",
        clicks: "1,500",
        ctr: "0.015",
        rpm: "24.69"
    ))
    .environmentObject(AuthViewModel())
    .padding()
} 
