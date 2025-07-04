//
//  AdRadarWidget.swift
//  AdRadarWidget
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import WidgetKit
import SwiftUI
import Intents

// MARK: - Sora Font System for Widget
extension Font {
    // MARK: - Sora Font Family with Fallback
    static func sora(_ weight: SoraWeight, size: CGFloat) -> Font {
        let fontName = weight.fontName
        // Try to create UIFont first to verify availability
        if let _ = UIFont(name: fontName, size: size) {
            return .custom(fontName, size: size)
        } else {
            // If Sora font fails, use system font with matching weight
            print("[AdRadarWidget] Font \(fontName) not available, using system fallback")
            return .system(size: size, weight: weight.systemWeight, design: .rounded)
        }
    }
    
    // MARK: - Widget-Specific Sora Fonts
    static var soraWidgetTitle: Font { .sora(.semibold, size: 20) }
    static var soraWidgetValue: Font { .sora(.bold, size: 46) }
    static var soraWidgetMetric: Font { .sora(.regular, size: 16) }
    static var soraWidgetMetricValue: Font { .sora(.regular, size: 14) }
    static var soraWidgetCaption: Font { .sora(.regular, size: 10) }
    static var soraWidgetBrand: Font { .sora(.regular, size: 11) }
    static var soraWidgetCellTitle: Font { .sora(.regular, size: 11) }
    static var soraWidgetCellValue: Font { .sora(.bold, size: 22) }
}

enum SoraWeight: String, CaseIterable {
    case light = "Light"
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "SemiBold"
    case bold = "Bold"
    
    var fontName: String {
        return "Sora-\(self.rawValue)"
    }
    
    var systemWeight: Font.Weight {
        switch self {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

// MARK: - Font Loading and Registration
class SoraFontManager {
    static let shared = SoraFontManager()
    private var fontsRegistered = false
    
    private init() {}
    
    func registerFonts() {
        guard !fontsRegistered else { return }
        
        let fontNames: [String] = [
            "Sora-Light",
            "Sora-Regular", 
            "Sora-Medium",
            "Sora-SemiBold",
            "Sora-Bold"
        ]
        
        // Try to register fonts from bundle
        for fontName in fontNames {
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                    print("[AdRadarWidget] ✅ Successfully registered: \(fontName)")
                } else {
                    print("[AdRadarWidget] ❌ Failed to register: \(fontName)")
                }
            } else {
                print("[AdRadarWidget] ❌ Font file not found: \(fontName).ttf")
            }
        }
        
        fontsRegistered = true
        verifyFontAvailability()
    }
    
    private func verifyFontAvailability() {
        let fontNames = SoraWeight.allCases.map { $0.fontName }
        
        print("[AdRadarWidget] Verifying font availability:")
        for fontName in fontNames {
            if UIFont.fontNames(forFamilyName: "Sora").contains(fontName) ||
               UIFont(name: fontName, size: 12) != nil {
                print("[AdRadarWidget] ✅ \(fontName) - Available")
            } else {
                print("[AdRadarWidget] ❌ \(fontName) - Not available")
            }
        }
        
        // List all available Sora fonts
        let soraFonts = UIFont.fontNames(forFamilyName: "Sora")
        print("[AdRadarWidget] Available Sora fonts: \(soraFonts)")
    }
}

extension View {
    func soraFont(_ weight: SoraWeight, size: CGFloat) -> some View {
        self.font(.sora(weight, size: size))
    }
    
    // Widget-specific Sora font modifiers
    func soraWidgetTitle() -> some View {
        self.font(.soraWidgetTitle)
    }
    
    func soraWidgetValue() -> some View {
        self.font(.soraWidgetValue)
    }
    
    func soraWidgetMetric() -> some View {
        self.font(.soraWidgetMetric)
    }
    
    func soraWidgetMetricValue() -> some View {
        self.font(.soraWidgetMetricValue)
    }
    
    func soraWidgetCaption() -> some View {
        self.font(.soraWidgetCaption)
    }
    
    func soraWidgetBrand() -> some View {
        self.font(.soraWidgetBrand)
    }
    
    func soraWidgetCellTitle() -> some View {
        self.font(.soraWidgetCellTitle)
    }
    
    func soraWidgetCellValue() -> some View {
        self.font(.soraWidgetCellValue)
    }
}

// Copy of AdSenseSummaryData for widget use (should match the main app)
struct AdSenseSummaryData: Codable {
    let today: String
    let yesterday: String
    let last7Days: String
    let thisMonth: String
    let lastMonth: String
    let lifetime: String
    let todayDelta: String?
    let todayDeltaPositive: Bool?
    let yesterdayDelta: String?
    let yesterdayDeltaPositive: Bool?
    let last7DaysDelta: String?
    let last7DaysDeltaPositive: Bool?
    let thisMonthDelta: String?
    let thisMonthDeltaPositive: Bool?
    let lastMonthDelta: String?
    let lastMonthDeltaPositive: Bool?
}

// MARK: - Shared Data Models (copied from main app for widget use)
struct SharedSummaryData: Codable, Equatable {
    let todayEarnings: String
    let yesterdayEarnings: String
    let last7DaysEarnings: String
    let thisMonthEarnings: String
    let lastMonthEarnings: String
    let lifetimeEarnings: String
    
    // Delta information
    let todayDelta: String?
    let todayDeltaPositive: Bool?
    let yesterdayDelta: String?
    let yesterdayDeltaPositive: Bool?
    let last7DaysDelta: String?
    let last7DaysDeltaPositive: Bool?
    let thisMonthDelta: String?
    let thisMonthDeltaPositive: Bool?
    let lastMonthDelta: String?
    let lastMonthDeltaPositive: Bool?
    
    // Metadata
    let lastUpdated: Date
    let dataVersion: Int
    
    init(from adSenseData: AdSenseSummaryData) {
        self.todayEarnings = adSenseData.today
        self.yesterdayEarnings = adSenseData.yesterday
        self.last7DaysEarnings = adSenseData.last7Days
        self.thisMonthEarnings = adSenseData.thisMonth
        self.lastMonthEarnings = adSenseData.lastMonth
        self.lifetimeEarnings = adSenseData.lifetime
        
        self.todayDelta = adSenseData.todayDelta
        self.todayDeltaPositive = adSenseData.todayDeltaPositive
        self.yesterdayDelta = adSenseData.yesterdayDelta
        self.yesterdayDeltaPositive = adSenseData.yesterdayDeltaPositive
        self.last7DaysDelta = adSenseData.last7DaysDelta
        self.last7DaysDeltaPositive = adSenseData.last7DaysDeltaPositive
        self.thisMonthDelta = adSenseData.thisMonthDelta
        self.thisMonthDeltaPositive = adSenseData.thisMonthDeltaPositive
        self.lastMonthDelta = adSenseData.lastMonthDelta
        self.lastMonthDeltaPositive = adSenseData.lastMonthDeltaPositive
        
        self.lastUpdated = Date()
        self.dataVersion = 1
    }
}

struct AdRadarWidgetEntry: TimelineEntry {
    let date: Date
    let summary: SharedSummaryData?
    let lastUpdate: String
    let dataFreshness: String
}

// Enhanced data loading for widget using shared data models
struct WidgetDataLoader {
    static let appGroupID = "group.com.delteqis.AdRadar" // Must match main app
    
    private static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupID)
    }
    
    // Load using new shared data model
    static func loadSharedSummaryData() -> SharedSummaryData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "shared_summary_data") else {
            print("[AdRadarWidget] No shared summary data found")
            return loadLegacySummaryData() // Fallback to legacy data
        }
        
        do {
            let summary = try JSONDecoder().decode(SharedSummaryData.self, from: data)
            print("[AdRadarWidget] Successfully loaded shared summary data")
            return summary
        } catch {
            print("[AdRadarWidget] Failed to decode shared summary data: \(error)")
            return loadLegacySummaryData() // Fallback to legacy data
        }
    }
    
    // Fallback to legacy data format for backward compatibility
    private static func loadLegacySummaryData() -> SharedSummaryData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: "summaryData") else {
            print("[AdRadarWidget] No legacy summary data found")
            return nil
        }
        
        do {
            let legacySummary = try JSONDecoder().decode(AdSenseSummaryData.self, from: data)
            let sharedData = SharedSummaryData(from: legacySummary)
            print("[AdRadarWidget] Successfully converted legacy data to shared format")
            return sharedData
        } catch {
            print("[AdRadarWidget] Failed to decode legacy summary data: \(error)")
            return nil
        }
    }

    static func loadLastUpdateDate() -> Date? {
        guard let defaults = sharedDefaults,
              let date = defaults.object(forKey: "summaryLastUpdate") as? Date else {
            print("[AdRadarWidget] No last update date found in shared container")
            return nil
        }
        print("[AdRadarWidget] Successfully loaded last update date: \(date)")
        return date
    }
}

struct Provider: TimelineProvider {
    init() {
        // Register fonts when provider initializes
        SoraFontManager.shared.registerFonts()
    }
    
    func placeholder(in context: Context) -> AdRadarWidgetEntry {
        AdRadarWidgetEntry(date: Date(), summary: nil, lastUpdate: "--:--", dataFreshness: "Loading...")
    }

    func getSnapshot(in context: Context, completion: @escaping (AdRadarWidgetEntry) -> ()) {
        let summary = WidgetDataLoader.loadSharedSummaryData()
        let lastUpdateDate = summary?.lastUpdated ?? Date()
        let dataFreshness = calculateDataFreshness(lastUpdateDate)
        let entry = AdRadarWidgetEntry(
            date: lastUpdateDate,
            summary: summary,
            lastUpdate: formattedTime(lastUpdateDate),
            dataFreshness: dataFreshness
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AdRadarWidgetEntry>) -> ()) {
        let summary = WidgetDataLoader.loadSharedSummaryData()
        let lastUpdateDate = summary?.lastUpdated ?? Date()
        let dataFreshness = calculateDataFreshness(lastUpdateDate)
        let entry = AdRadarWidgetEntry(
            date: lastUpdateDate,
            summary: summary,
            lastUpdate: formattedTime(lastUpdateDate),
            dataFreshness: dataFreshness
        )
        
        // Update every 10 minutes to sync with background refresh
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func calculateDataFreshness(_ date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        let minutes = Int(timeInterval / 60)
        
        if minutes < 1 {
            return "Just updated"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h ago"
        }
    }
}

struct EarningsCell: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Spacer()
                Text(value)
                    .soraWidgetCellValue()
            }
            Text(title)
                .soraWidgetMetric()
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

// MARK: - WidgetCellView for Large Widget
struct WidgetCellView: View {
    let iconName: String
    let iconColor: Color
    let value: String
    let title: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 36) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.18))
                        .frame(width: 24, height: 24)
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                        .font(.system(size: 12, weight: .bold))
                }
                Text(title)
                    .soraWidgetCellTitle()
                    .foregroundColor(colorScheme == .dark ? .white : .secondary)
                    .lineLimit(1)
                Spacer()
            }
            Spacer()
            HStack {
                Text(value)
                    .soraWidgetCellValue()
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                Spacer()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct AdRadarWidgetEntryView: View {
    var entry: AdRadarWidgetEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        (colorScheme == .dark ? Color.black : Color.white)
            .ignoresSafeArea()
        VStack(alignment: .leading, spacing: 2) {
            Spacer(minLength: 4)
            // Header
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                VStack(alignment: .leading){
                    Text("Today")
                        .soraWidgetTitle()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 2) {
                        Text("Last Updated: ")
                            .soraWidgetCaption()
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(entry.lastUpdate)
                            .soraWidgetCaption()
                    }
                    .foregroundColor(.secondary)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("AdRadar")
                        .soraWidgetBrand()
                }
                .foregroundColor(.secondary)
            }
            // Today value (reduce spacing)
            if let summary = entry.summary {
                Text(summary.todayEarnings)
                    .soraWidgetValue()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 2)
            } else {
                Text("--")
                    .soraFont(.bold, size: 24)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 2)
            }
            // Row for Yesterday, This Month, Last Month
            Spacer(minLength: 2)
            HStack(alignment: .top, spacing: 2) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Yesterday")
                        .soraFont(.semibold, size: 12)
                        .soraWidgetMetric()
                        .foregroundColor(.primary)
                    Text(entry.summary?.yesterdayEarnings ?? "--")
                        .soraFont(.semibold, size: 10)
                        .soraWidgetMetricValue()
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Month")
                        .soraFont(.semibold, size: 12)
                        .soraWidgetMetric()
                        .foregroundColor(.primary)
                    Text(entry.summary?.thisMonthEarnings ?? "--")
                        .soraFont(.semibold, size: 10)
                        .soraWidgetMetricValue()
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Month")
                        .soraFont(.semibold, size: 12)
                        .soraWidgetMetric()
                        .foregroundColor(.primary)
                    Text(entry.summary?.lastMonthEarnings ?? "--")
                        .soraFont(.semibold, size: 10)
                        .soraWidgetMetricValue()
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 2)
            Spacer(minLength: 0)
        }
        .padding([.leading, .trailing, .bottom, .top], 16)
        .containerBackground(colorScheme == .dark ? Color.black : Color.white, for: .widget)
        .onAppear {
            // Ensure fonts are registered when view appears
            SoraFontManager.shared.registerFonts()
        }
    }
}

// Helper for time formatting
private func formattedTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

struct AdRadarWidget: Widget {
    let kind: String = "AdRadarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AdRadarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AdRadar Summary")
        .description("Shows today's earnings and delta.")
        .supportedFamilies([.systemMedium])
    }
}
