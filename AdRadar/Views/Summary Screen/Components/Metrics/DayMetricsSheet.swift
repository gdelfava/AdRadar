import SwiftUI
import UIKit
import Combine

/// A sheet view that displays detailed metrics for a specific day.
/// Features animated cards and comprehensive performance data.
struct DayMetricsSheet: View {
    let metrics: AdSenseDayMetrics
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 4)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header section with enhanced styling
                        headerSection
                        
                        // Enhanced metric cards
                        VStack(spacing: 20) {
                            // Grand Total Card
                            EnhancedMetricCard(
                                title: "Revenue Overview",
                                icon: "dollarsign.circle.fill",
                                iconColor: .green,
                                metrics: [
                                    MetricData(
                                        icon: "banknote.fill",
                                        title: "Total Earnings",
                                        value: metrics.formattedEstimatedEarnings(isDemoMode: authViewModel.isDemoMode),
                                        subtitle: "Revenue Generated",
                                        color: .green
                                    )
                                ]
                            )
                            .opacity(cardAppearances[0] ? 1 : 0)
                            .offset(y: cardAppearances[0] ? 0 : 30)
                            
                            // Performance Card
                            EnhancedMetricCard(
                                title: "Engagement Metrics",
                                icon: "chart.bar.xaxis.ascending.badge.clock",
                                iconColor: .blue,
                                metrics: [
                                    MetricData(
                                        icon: "cursorarrow.click",
                                        title: "Clicks",
                                        value: metrics.clicks,
                                        subtitle: "User Interactions",
                                        color: .blue
                                    ),
                                    MetricData(
                                        icon: "eye.fill",
                                        title: "Impressions",
                                        value: metrics.impressions,
                                        subtitle: "Ad Views",
                                        color: .cyan
                                    ),
                                    MetricData(
                                        icon: "percent",
                                        title: "CTR",
                                        value: metrics.formattedImpressionsCTR,
                                        subtitle: "Click Rate",
                                        color: .indigo
                                    )
                                ]
                            )
                            .opacity(cardAppearances[1] ? 1 : 0)
                            .offset(y: cardAppearances[1] ? 0 : 30)
                            
                            // Traffic Card
                            EnhancedMetricCard(
                                title: "Traffic Analytics",
                                icon: "network.badge.shield.half.filled",
                                iconColor: .orange,
                                metrics: [
                                    MetricData(
                                        icon: "doc.text.fill",
                                        title: "Page Views",
                                        value: metrics.requests,
                                        subtitle: "Site Traffic",
                                        color: .orange
                                    ),
                                    MetricData(
                                        icon: "checkmark.circle.fill",
                                        title: "Matched Requests",
                                        value: metrics.matchedRequests,
                                        subtitle: "Ad Requests",
                                        color: .mint
                                    )
                                ]
                            )
                            .opacity(cardAppearances[2] ? 1 : 0)
                            .offset(y: cardAppearances[2] ? 0 : 30)
                            
                            // Cost Analysis Card
                            EnhancedMetricCard(
                                title: "Cost Analysis",
                                icon: "chart.pie.fill",
                                iconColor: .purple,
                                metrics: [
                                    MetricData(
                                        icon: "creditcard.fill",
                                        title: "Cost Per Click",
                                        value: metrics.formattedCostPerClick(isDemoMode: authViewModel.isDemoMode),
                                        subtitle: "Average CPC",
                                        color: .purple
                                    )
                                ]
                            )
                            .opacity(cardAppearances[3] ? 1 : 0)
                            .offset(y: cardAppearances[3] ? 0 : 30)
                        }
                        .padding(.horizontal, 20)
                        
                        // Footer disclaimer
                        Text("AdRadar is not affiliated with Google or Google AdSense.")
                            .soraFootnote()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .soraBody()
                    .foregroundColor(.accentColor)
                }
            }
        }
        .onAppear {
            // Stagger the card animations
            for index in 0..<cardAppearances.count {
                withAnimation(.easeOut(duration: 0.6).delay(Double(index) * 0.1)) {
                    cardAppearances[index] = true
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon or Branding Element
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.8),
                                Color.accentColor
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(title.capitalized)
                    .soraTitle2()
                    .foregroundColor(.primary)
                
                Text("Comprehensive performance overview")
                    .soraSubheadline()
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }
}

/// A data structure for metric information.
struct MetricData {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
}

#Preview {
    DayMetricsSheet(
        metrics: AdSenseDayMetrics(
            estimatedEarnings: "123.45",
            clicks: "1,234",
            pageViews: "23,456",
            impressions: "12,345",
            adRequests: "23,456",
            matchedAdRequests: "22,345",
            costPerClick: "0.25",
            impressionsCTR: "10.5",
            impressionsRPM: "5.67",
            pageViewsCTR: "8.9",
            pageViewsRPM: "4.32"
        ),
        title: "Today's Performance"
    )
    .environmentObject(AuthViewModel())
} 