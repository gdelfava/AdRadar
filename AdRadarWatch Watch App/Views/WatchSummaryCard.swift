import SwiftUI

// MARK: - Legacy Components (Updated for consistency)

struct WatchSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let delta: String?
    let deltaPositive: Bool?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with icon and title
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.soraCaption())
                    .frame(width: 16, height: 16)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Text(title)
                    .soraCaption()
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Main value
            Text(value)
                .soraDisplayMedium()
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Delta information
            if let delta = delta {
                HStack(spacing: 3) {
                    Image(systemName: deltaPositive == true ? "arrow.up" : "arrow.down")
                        .font(.soraFootnote())
                        .foregroundColor(deltaPositive == true ? .green : .red)
                    
                    Text(delta)
                        .soraFootnote()
                        .foregroundColor(deltaPositive == true ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            
            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .soraFootnote()
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: color.opacity(0.08), location: 0),
                    .init(color: color.opacity(0.04), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct WatchHeroCard: View {
    let title: String
    let value: String
    let subtitle: String
    let delta: String?
    let deltaPositive: Bool?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Title and subtitle
            VStack(spacing: 2) {
                Text(title)
                    .soraHeadline()
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .soraCaption()
                    .foregroundColor(.secondary)
            }
            
            // Main value - large and prominent
            Text(value)
                .soraDisplayLarge()
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            // Delta with enhanced styling
            if let delta = delta {
                HStack(spacing: 4) {
                    Image(systemName: deltaPositive == true ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.soraBodyMedium())
                        .foregroundColor(deltaPositive == true ? .green : .red)
                    
                    Text(delta)
                        .soraBodyMedium()
                        .foregroundColor(deltaPositive == true ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill((deltaPositive == true ? Color.green : Color.red).opacity(0.15))
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.accentColor.opacity(0.12), location: 0),
                        .init(color: Color.accentColor.opacity(0.06), location: 0.7),
                        .init(color: Color.accentColor.opacity(0.02), location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Use PatternOverlay from ContentView.swift to avoid duplication
                PatternOverlay(color: .accentColor.opacity(0.03), spacing: 14, dotSize: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.accentColor.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct WatchMetricsCard: View {
    let clicks: String?
    let pageViews: String?
    let impressions: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.soraCaption())
                    .frame(width: 16, height: 16)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                Text("Today's Stats")
                    .soraCaption()
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: 4) {
                if let clicks = clicks {
                    LegacyMetricRow(icon: "cursorarrow.click", label: "Clicks", value: clicks, color: .orange)
                }
                
                if let pageViews = pageViews {
                    LegacyMetricRow(icon: "doc.text.fill", label: "Page Views", value: pageViews, color: .blue)
                }
                
                if let impressions = impressions {
                    LegacyMetricRow(icon: "eye.fill", label: "Impressions", value: impressions, color: .green)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct LegacyMetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.soraFootnote())
                .frame(width: 12)
            
            Text(label)
                .soraFootnote()
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .soraCaption()
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

#Preview("Summary Card") {
    WatchSummaryCard(
        title: "Yesterday",
        value: "R 12,30",
        subtitle: "vs same day last week",
        delta: "+15%",
        deltaPositive: true,
        icon: "calendar.badge.clock",
        color: .orange
    )
}

#Preview("Hero Card") {
    WatchHeroCard(
        title: "Today So Far",
        value: "R 5,67",
        subtitle: "vs yesterday",
        delta: "+8%",
        deltaPositive: true
    )
}

#Preview("Metrics Card") {
    WatchMetricsCard(
        clicks: "142",
        pageViews: "1,234",
        impressions: "5,678"
    )
} 