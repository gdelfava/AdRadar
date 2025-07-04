import SwiftUI

struct SelectedDayMetricsView: View {
    let day: StreakDayData
    let viewModel: StreakViewModel
    let showCloseButton: Bool
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day.date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(formattedDate)
                            .soraTitle3()
                            .foregroundColor(.primary)
                        if isToday {
                            Text("Today")
                                .soraCaption()
                                .bold()
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor)
                                .cornerRadius(8)
                        }
                    }
                    Text("Daily Performance")
                        .soraSubheadline()
                        .foregroundColor(.secondary)
                }
                Spacer()
                if showCloseButton {
                    Button(action: {
                        // Handle close action
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                }
            }
            
            // Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Earnings",
                    value: viewModel.formatCurrency(day.earnings),
                    icon: "dollarsign.circle.fill",
                    color: .green,
                    trend: day.earningsTrend
                )
                MetricCard(
                    title: "Impressions",
                    value: viewModel.formatNumber(day.impressions),
                    icon: "eye.fill",
                    color: .blue,
                    trend: day.impressionsTrend
                )
                MetricCard(
                    title: "Clicks",
                    value: viewModel.formatNumber(day.clicks),
                    icon: "hand.tap.fill",
                    color: .orange,
                    trend: day.clicksTrend
                )
                MetricCard(
                    title: "CTR",
                    value: viewModel.formatPercentage(day.impressionCTR),
                    icon: "percent",
                    color: .purple,
                    trend: day.ctrTrend
                )
            }
        }
        .padding(24)
    }
}

// MARK: - Metric Card
private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Double?
    
    private var trendIcon: String {
        guard let trend = trend else { return "minus" }
        return trend > 0 ? "arrow.up.right" : "arrow.down.right"
    }
    
    private var trendColor: Color {
        guard let trend = trend else { return .secondary }
        return trend > 0 ? .green : .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .medium))
                Text(title)
                    .soraSubheadline()
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(value)
                    .soraTitle3()
                    .foregroundColor(.primary)
                
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon)
                            .font(.caption)
                        Text(String(format: "%.1f%%", abs(trend)))
                            .soraCaption()
                    }
                    .foregroundColor(trendColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
} 
