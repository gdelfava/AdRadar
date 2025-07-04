//
//  ContentView.swift
//  AdRadarWatch Watch App
//
//  Created by Guilio Del Fava on 2025/06/24.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var connectivityService = WatchConnectivityService.shared
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 6)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.accentColor.opacity(0.05),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                if connectivityService.isLoading {
                    WatchLoadingView()
                } else if let errorMessage = connectivityService.errorMessage {
                    WatchErrorView(message: errorMessage) {
                        connectivityService.refreshData()
                    }
                } else if let data = connectivityService.summaryData {
                    UnifiedSummaryView(data: data, lastUpdate: connectivityService.lastUpdateTime)
                        .onAppear {
                            animateCards()
                        }
                        .onDisappear {
                            resetAnimations()
                        }
                } else {
                    WatchNoDataView {
                        connectivityService.refreshData()
                    }
                }
            }
            .navigationTitle("AdRadar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        print("⌚ [Watch] Refresh button tapped")
                        
                        // Provide haptic feedback
                        WKInterfaceDevice.current().play(.click)
                        
                        connectivityService.refreshData()
                    }) {
                        Image(systemName: connectivityService.isLoading ? "arrow.clockwise.circle" : "arrow.clockwise")
                            .foregroundColor(.accentColor)
                            .font(.soraBody())
                            .rotationEffect(.degrees(connectivityService.isLoading ? 360 : 0))
                            .animation(connectivityService.isLoading ? 
                                .linear(duration: 1).repeatForever(autoreverses: false) : 
                                .default, value: connectivityService.isLoading)
                    }
                    .disabled(connectivityService.isLoading)
                }
            }
        }
        .environmentObject(connectivityService)
    }
    
    private func animateCards() {
        for i in 0..<cardAppearances.count {
            withAnimation(.easeOut(duration: 0.5).delay(Double(i) * 0.08)) {
                cardAppearances[i] = true
            }
        }
    }
    
    private func resetAnimations() {
        cardAppearances = Array(repeating: false, count: 6)
    }
}

struct UnifiedSummaryView: View {
    let data: WatchSummaryData
    let lastUpdate: Date?
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 6)
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                // HERO SECTION - Today's Performance
                VStack(spacing: 8) {
                    HeroCard(
                        title: "Today So Far",
                        value: data.todayEarnings,
                        subtitle: "vs yesterday",
                        delta: data.todayDelta,
                        deltaPositive: data.todayDeltaPositive
                    )
                    .opacity(cardAppearances[0] ? 1 : 0)
                    .offset(y: cardAppearances[0] ? 0 : 15)
                    
                    // Today's Metrics (if available)
                    if data.todayClicks != nil || data.todayPageViews != nil {
                        TodayMetricsCard(
                            clicks: data.todayClicks,
                            pageViews: data.todayPageViews,
                            impressions: data.todayImpressions
                        )
                        .opacity(cardAppearances[1] ? 1 : 0)
                        .offset(y: cardAppearances[1] ? 0 : 15)
                    }
                }
                
                // RECENT SECTION
                VStack(spacing: 6) {
                    SectionDivider(title: "Recent Performance", icon: "clock.fill", color: .orange)
                        .opacity(cardAppearances[2] ? 1 : 0)
                        .offset(y: cardAppearances[2] ? 0 : 10)
                    
                    VStack(spacing: 6) {
                        CompactCard(
                            title: "Yesterday",
                            value: data.yesterdayEarnings,
                            delta: data.yesterdayDelta,
                            deltaPositive: data.yesterdayDeltaPositive,
                            icon: "calendar.badge.clock",
                            color: .orange
                        )
                        .opacity(cardAppearances[3] ? 1 : 0)
                        .offset(y: cardAppearances[3] ? 0 : 10)
                        
                        CompactCard(
                            title: "Last 7 Days",
                            value: data.last7DaysEarnings,
                            delta: data.last7DaysDelta,
                            deltaPositive: data.last7DaysDeltaPositive,
                            icon: "calendar.badge.plus",
                            color: .blue
                        )
                        .opacity(cardAppearances[4] ? 1 : 0)
                        .offset(y: cardAppearances[4] ? 0 : 10)
                    }
                }
                
                // MONTHLY SECTION
                VStack(spacing: 6) {
                    SectionDivider(title: "Monthly Overview", icon: "calendar.circle.fill", color: .purple)
                        .opacity(cardAppearances[5] ? 1 : 0)
                        .offset(y: cardAppearances[5] ? 0 : 10)
                    
                    HStack(spacing: 6) {
                        MiniCard(
                            title: "This Month",
                            value: data.thisMonthEarnings,
                            delta: data.thisMonthDelta,
                            deltaPositive: data.thisMonthDeltaPositive,
                            icon: "calendar",
                            color: .purple
                        )
                        
                        MiniCard(
                            title: "Last Month",
                            value: data.lastMonthEarnings,
                            delta: data.lastMonthDelta,
                            deltaPositive: data.lastMonthDeltaPositive,
                            icon: "calendar.badge.minus",
                            color: .pink
                        )
                    }
                    .opacity(cardAppearances[5] ? 1 : 0)
                    .offset(y: cardAppearances[5] ? 0 : 10)
                }
                
                // Footer with last update
                if let lastUpdate = lastUpdate {
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 0.3)
                            .padding(.horizontal, 16)
                        
                        Text("Updated \(formatRelativeTime(lastUpdate))")
                            .soraFootnote()
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 4)
        }
        .onAppear {
            animateCards()
        }
    }
    
    private func animateCards() {
        for i in 0..<cardAppearances.count {
            withAnimation(.easeOut(duration: 0.5).delay(Double(i) * 0.08)) {
                cardAppearances[i] = true
            }
        }
    }
}

// MARK: - Enhanced Components

struct HeroCard: View {
    let title: String
    let value: String
    let subtitle: String
    let delta: String?
    let deltaPositive: Bool?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            VStack(spacing: 2) {
                Text(title)
                    .soraHeadline()
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .soraCaption()
                    .foregroundColor(.secondary)
            }
            
            // Main value
            Text(value)
                .soraDisplayLarge()
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            // Delta indicator
            if let delta = delta, let positive = deltaPositive {
                HStack(spacing: 3) {
                    Image(systemName: positive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.soraCaption())
                        .foregroundColor(positive ? Color.green : Color.red)
                    
                    Text(delta)
                        .soraCaptionMedium()
                        .foregroundColor(positive ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill((positive ? Color.green : Color.red).opacity(0.15))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            ZStack {
                // Main gradient
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.green.opacity(0.12), location: 0),
                        .init(color: Color.green.opacity(0.06), location: 0.7),
                        .init(color: Color.green.opacity(0.02), location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle pattern overlay
                PatternOverlay(color: .green.opacity(0.03), spacing: 12, dotSize: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.green.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.3),
                            Color.clear,
                            Color.green.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
    }
}

struct TodayMetricsCard: View {
    let clicks: String?
    let pageViews: String?
    let impressions: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.soraCaption())
                    .foregroundColor(Color.blue)
                
                Text("Today's Stats")
                    .soraCaption()
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: 3) {
                if let clicks = clicks {
                    MetricRow(icon: "cursorarrow.click", label: "Clicks", value: clicks, color: .orange)
                }
                
                if let pageViews = pageViews {
                    MetricRow(icon: "doc.text.fill", label: "Views", value: pageViews, color: .blue)
                }
                
                if let impressions = impressions {
                    MetricRow(icon: "eye.fill", label: "Impressions", value: impressions, color: .green)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CompactCard: View {
    let title: String
    let value: String
    let delta: String?
    let deltaPositive: Bool?
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.soraCaption())
                .foregroundColor(color)
                .frame(width: 16, height: 16)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .soraCaption()
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Value and delta
            VStack(alignment: .trailing, spacing: 1) {
                Text(value)
                    .soraBodyMedium()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if let delta = delta, let positive = deltaPositive {
                    HStack(spacing: 2) {
                        Image(systemName: positive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(positive ? .green : .red)
                        
                        Text(delta)
                            .soraFootnote()
                            .foregroundColor(positive ? .green : .red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct MiniCard: View {
    let title: String
    let value: String
    let delta: String?
    let deltaPositive: Bool?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 14, height: 14)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .soraFootnote()
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(value)
                    .soraBodyMedium()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                if let delta = delta, let positive = deltaPositive {
                    HStack(spacing: 2) {
                        Image(systemName: positive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(positive ? .green : .red)
                        
                        Text(delta)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(positive ? .green : .red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                } else {
                    // Spacer to maintain consistent height
                    Text(" ")
                        .font(.system(size: 8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: color.opacity(0.1), location: 0),
                    .init(color: color.opacity(0.05), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SectionDivider: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.soraFootnote())
                .foregroundColor(color)
                .frame(width: 12, height: 12)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .soraCaptionMedium()
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer(minLength: 4)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.3)
                .frame(maxWidth: 60)
        }
        .padding(.horizontal, 4)
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(color)
                .frame(width: 10)
            
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

struct PatternOverlay: View {
    let color: Color
    let spacing: CGFloat
    let dotSize: CGFloat
    
    var body: some View {
        Canvas { context, size in
            for x in stride(from: 0, through: size.width, by: spacing) {
                for y in stride(from: 0, through: size.height, by: spacing) {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
    }
}

// MARK: - Helper Functions
private func formatRelativeTime(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}

#Preview {
    ContentView()
}
