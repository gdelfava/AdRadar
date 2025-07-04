import SwiftUI
import Charts

struct PerformanceInsightsView: View {
    let streakData: [StreakDayData]
    let viewModel: StreakViewModel
    @State private var selectedMetric = 0
    @State private var selectedPoint: StreakDayData?
    
    private var weeklyData: [StreakDayData] {
        Array(streakData.prefix(7))
    }
    
    private let metrics = [
        ("Earnings Trend", Color.green),
        ("Impressions Trend", Color.blue),
        ("CTR Trend", Color.purple)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Modern header with large icon and metric selector
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Performance Insights")
                            .soraTitle2()
                            .foregroundColor(.primary)
                        Text("Analyze your revenue and engagement trends")
                            .soraSubheadline()
                            .foregroundColor(.secondary)
                    }
                }
                
                // Metric selector
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(0..<metrics.count, id: \.self) { index in
                        Text(metrics[index].0.replacingOccurrences(of: " Trend", with: ""))
                            .tag(index)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Chart Card
            VStack(alignment: .leading, spacing: 20) {
                // Weekly change indicator
                HStack {
                    Text(metrics[selectedMetric].0)
                        .soraTitle3()
                        .foregroundColor(.primary)
                    
                    Spacer()
                    weeklyChangeIndicator
                }
                
                // Main Chart
                Chart(weeklyData, id: \.date) { day in
                    LineMark(
                        x: .value("Date", day.date),
                        y: .value("Value", metricValue(for: day))
                    )
                    .foregroundStyle(metrics[selectedMetric].1)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .symbol {
                        Circle()
                            .fill(metrics[selectedMetric].1)
                            .frame(width: 8, height: 8)
                    }
                    
                    AreaMark(
                        x: .value("Date", day.date),
                        y: .value("Value", metricValue(for: day))
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                metrics[selectedMetric].1.opacity(0.2),
                                metrics[selectedMetric].1.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    if let selectedPoint = selectedPoint, selectedPoint.id == day.id {
                        RuleMark(
                            x: .value("Selected Date", selectedPoint.date)
                        )
                        .foregroundStyle(metrics[selectedMetric].1.opacity(0.3))
                        
                        PointMark(
                            x: .value("Selected Date", selectedPoint.date),
                            y: .value("Selected Value", metricValue(for: selectedPoint))
                        )
                        .foregroundStyle(metrics[selectedMetric].1)
                        .annotation(position: .top) {
                            Text(formatValue(metricValue(for: selectedPoint)))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(formatDate(date))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(.label))
                            }
                        }
                        AxisTick()
                            .foregroundStyle(Color(.label))
                        AxisGridLine()
                            .foregroundStyle(Color(.separator))
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .extended) { value in
                        if let doubleValue = value.as(Double.self) {
                            AxisValueLabel {
                                Text(formatValue(doubleValue))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(.label))
                            }
                            AxisTick()
                                .foregroundStyle(Color(.label))
                            AxisGridLine()
                                .foregroundStyle(Color(.separator))
                        }
                    }
                }
                .frame(height: 250)
                .padding(.vertical, 8)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let xPosition = value.location.x
                                        guard let date = proxy.value(atX: xPosition, as: Date.self) else { return }
                                        
                                        if let nearestPoint = weeklyData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                            selectedPoint = nearestPoint
                                        }
                                    }
                                    .onEnded { _ in
                                        // Optional: Keep the selection or clear it after a delay
                                        // DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        //     selectedPoint = nil
                                        // }
                                    }
                            )
                    }
                }
                
                // Key metrics summary
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    MetricSummary(
                        title: "Highest",
                        value: formatValue(highestValue),
                        icon: "arrow.up.circle.fill",
                        color: metrics[selectedMetric].1
                    )
                    
                    MetricSummary(
                        title: "Average",
                        value: formatValue(averageValue),
                        icon: "equal.circle.fill",
                        color: metrics[selectedMetric].1
                    )
                    
                    MetricSummary(
                        title: "Lowest",
                        value: formatValue(lowestValue),
                        icon: "arrow.down.circle.fill",
                        color: metrics[selectedMetric].1
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Helper Views
    
    private var weeklyChangeIndicator: some View {
        let change = weeklyChange
        return HStack(spacing: 4) {
            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)
            Text(String(format: "%.1f%%", abs(change)))
                .soraCaption()
        }
        .foregroundColor(change >= 0 ? .green : .red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Helper Methods
    
    private func metricValue(for day: StreakDayData) -> Double {
        switch selectedMetric {
        case 0: return day.earnings
        case 1: return Double(day.impressions)
        case 2: return day.impressionCTR
        default: return 0
        }
    }
    
    private var weeklyChange: Double {
        guard weeklyData.count >= 2 else { return 0 }
        let current = metricValue(for: weeklyData[0])
        let previous = metricValue(for: weeklyData[1])
        return previous != 0 ? ((current - previous) / previous) * 100 : 0
    }
    
    private var highestValue: Double {
        weeklyData.map { metricValue(for: $0) }.max() ?? 0
    }
    
    private var lowestValue: Double {
        weeklyData.map { metricValue(for: $0) }.min() ?? 0
    }
    
    private var averageValue: Double {
        let values = weeklyData.map { metricValue(for: $0) }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatValue(_ value: Double) -> String {
        switch selectedMetric {
        case 0: return viewModel.formatCurrency(value)
        case 1: return viewModel.formatNumber(Int(value))
        case 2: return viewModel.formatPercentage(value)
        default: return ""
        }
    }
}

// MARK: - Metric Summary
private struct MetricSummary: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(title)
                .soraCaption()
                .foregroundColor(.secondary)
            
            Text(value)
                .soraSubheadline()
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
} 
