import SwiftUI

/// A modern card component for displaying metric data with enhanced styling.
/// Features a header with icon, and supports both single and multiple metric layouts.
struct EnhancedMetricCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let metrics: [MetricData]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section with enhanced styling
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    // Enhanced icon design
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        iconColor.opacity(0.15),
                                        iconColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .soraHeadline()
                            .foregroundColor(.primary)
                        
                        Text("Performance insights")
                            .soraCaption()
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Metrics grid with improved layout
                if metrics.count == 1 {
                    // Single metric - full width
                    singleMetricView(metrics[0])
                } else {
                    // Multiple metrics - grid layout
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                            metricPillView(metric)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }
    
    private func singleMetricView(_ metric: MetricData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: metric.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(metric.color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.title)
                        .soraSubheadline()
                        .foregroundColor(.primary)
                    
                    Text(metric.subtitle)
                        .soraCaption()
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(metric.value)
                .soraTitle()
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func metricPillView(_ metric: MetricData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: metric.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(metric.color)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(metric.title)
                        .soraCaption()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(metric.subtitle)
                        .soraCaption2()
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Text(metric.value)
                .soraCallout()
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 20) {
        // Single metric card
        EnhancedMetricCard(
            title: "Revenue Overview",
            icon: "dollarsign.circle.fill",
            iconColor: .green,
            metrics: [
                MetricData(
                    icon: "banknote.fill",
                    title: "Total Earnings",
                    value: "$1,234.56",
                    subtitle: "Revenue Generated",
                    color: .green
                )
            ]
        )
        
        // Multiple metrics card
        EnhancedMetricCard(
            title: "Engagement Metrics",
            icon: "chart.bar.xaxis.ascending.badge.clock",
            iconColor: .blue,
            metrics: [
                MetricData(
                    icon: "cursorarrow.click",
                    title: "Clicks",
                    value: "1,234",
                    subtitle: "User Interactions",
                    color: .blue
                ),
                MetricData(
                    icon: "eye.fill",
                    title: "Impressions",
                    value: "12,345",
                    subtitle: "Ad Views",
                    color: .cyan
                ),
                MetricData(
                    icon: "percent",
                    title: "CTR",
                    value: "10.5%",
                    subtitle: "Click Rate",
                    color: .indigo
                )
            ]
        )
    }
    .padding()
    .background(Color(.systemBackground))
} 