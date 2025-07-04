import SwiftUI
import Charts

struct OverviewCardsView: View {
    let streakData: [StreakDayData]
    let viewModel: StreakViewModel
    
    private var weeklyRevenue: Double {
        streakData.prefix(7).reduce(into: 0.0) { sum, day in
            sum += day.earnings
        }
    }
    
    private var weeklyImpressions: Int {
        streakData.prefix(7).reduce(into: 0) { sum, day in
            sum += day.impressions
        }
    }
    
    private var weeklyClicks: Int {
        streakData.prefix(7).reduce(into: 0) { sum, day in
            sum += day.clicks
        }
    }
    
    private var weeklyAverageCTR: Double {
        let clicks = Double(weeklyClicks)
        let impressions = Double(weeklyImpressions)
        return impressions > 0 ? (clicks / impressions) * 100 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Modern header with large icon
            HStack(spacing: 16) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("7-Day Overview")
                        .soraTitle2()
                        .foregroundColor(.primary)
                    Text("Your weekly performance at a glance")
                        .soraSubheadline()
                        .foregroundColor(.secondary)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                OverviewCard(
                    title: "Total Earnings",
                    value: viewModel.formatCurrency(weeklyRevenue),
                    icon: "dollarsign.circle.fill",
                    color: .green,
                    data: streakData.prefix(7).map { $0.earnings }
                )
                
                OverviewCard(
                    title: "Total Impress.",
                    value: viewModel.formatNumber(weeklyImpressions),
                    icon: "eye.fill",
                    color: .blue,
                    data: streakData.prefix(7).map { Double($0.impressions) }
                )
                
                OverviewCard(
                    title: "Total Clicks",
                    value: viewModel.formatNumber(weeklyClicks),
                    icon: "hand.tap.fill",
                    color: .orange,
                    data: streakData.prefix(7).map { Double($0.clicks) }
                )
                
                OverviewCard(
                    title: "Average CTR",
                    value: viewModel.formatPercentage(weeklyAverageCTR),
                    icon: "percent",
                    color: .purple,
                    data: streakData.prefix(7).map { $0.impressionCTR }
                )
            }
        }
    }
}

// MARK: - Overview Card
private struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let data: [Double]
    
    private var trend: Double {
        guard data.count >= 2 else { return 0 }
        let current = data[0]
        let previous = data[1]
        return previous != 0 ? ((current - previous) / previous) * 100 : 0
    }
    
    private var trendIcon: String {
        trend > 0 ? "arrow.up.right" : (trend < 0 ? "arrow.down.right" : "minus")
    }
    
    private var trendColor: Color {
        trend > 0 ? .green : (trend < 0 ? .red : .secondary)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                Text(title)
                    .soraSubheadline()
                    .foregroundColor(.secondary)
            }
            
            // Value and Trend
            VStack(alignment: .leading, spacing: 8) {
                Text(value)
                    .soraTitle3()
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: trendIcon)
                        .font(.caption)
                    Text(String(format: "%.1f%%", abs(trend)))
                        .soraCaption()
                }
                .foregroundColor(trendColor)
            }
            
            // Mini Sparkline Chart
            Chart(Array(data.enumerated()), id: \.0) { index, value in
                LineMark(
                    x: .value("Day", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(color.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("Day", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [color.opacity(0.2), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                if index == 0 {
                    PointMark(
                        x: .value("Day", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(color)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 50)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: color.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
} 
