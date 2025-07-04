import Foundation

/// Provides static demo data for all views when the app is in demo mode
class DemoDataProvider {
    static let shared = DemoDataProvider()
    
    // Base date for all demo data
    private let baseDate = Calendar.current.date(from: DateComponents(year: 2025, month: 5, day: 11))!
    
    // Mock user profile data
    let demoUser = (
        name: "Demo User",
        email: "demo@example.com",
        profileImage: nil as URL?
    )
    
    // Mock summary data
    let summaryData = AdSenseSummaryData(
        today: "$25.45",
        yesterday: "$23.67",
        last7Days: "$158.32",
        thisMonth: "$758.32",
        lastMonth: "$845.67",
        lifetime: "$12,456.78",
        todayDelta: "7.5%",
        todayDeltaPositive: true,
        yesterdayDelta: "-2.3%",
        yesterdayDeltaPositive: false,
        last7DaysDelta: "5.2%",
        last7DaysDeltaPositive: true,
        thisMonthDelta: "12.4%",
        thisMonthDeltaPositive: true,
        lastMonthDelta: "8.9%",
        lastMonthDeltaPositive: true
    )
    
    // Mock payments data
    let paymentsData = PaymentsData(
        unpaidEarnings: "$758.32",
        unpaidEarningsValue: 758.32,
        previousPaymentDate: "March 21, 2024",
        previousPaymentAmount: "$1,245.67",
        currentMonthEarnings: "$758.32",
        currentMonthEarningsValue: 758.32
    )
    
    // Function to generate mock data based on date range
    func generateMockDataForRange(startDate: Date, endDate: Date) -> (
        domains: [DomainData],
        platforms: [PlatformData],
        countries: [CountryData],
        adNetworks: [AdNetworkData],
        targeting: [TargetingData]
    ) {
        let daysBetween = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let multiplier = Double(daysBetween) / 7.0  // Scale data based on date range
        
        // Helper function to scale numeric string values
        func scaleValue(_ value: String, multiplier: Double) -> String {
            if let number = Double(value.replacingOccurrences(of: ",", with: "")) {
                return String(format: "%.2f", number * multiplier)
            }
            return value
        }
        
        // Generate domain data
        let scaledDomains = [
            DomainData(
                domainName: "example.com",
                earnings: scaleValue("345.67", multiplier: multiplier),
                requests: scaleValue("30000", multiplier: multiplier),
                pageViews: scaleValue("25400", multiplier: multiplier),
                impressions: scaleValue("28500", multiplier: multiplier),
                clicks: scaleValue("856", multiplier: multiplier),
                ctr: "3.37",
                rpm: "12.40"
            ),
            DomainData(
                domainName: "myblog.com",
                earnings: scaleValue("234.56", multiplier: multiplier),
                requests: scaleValue("25000", multiplier: multiplier),
                pageViews: scaleValue("18900", multiplier: multiplier),
                impressions: scaleValue("20500", multiplier: multiplier),
                clicks: scaleValue("634", multiplier: multiplier),
                ctr: "3.35",
                rpm: "11.80"
            ),
            DomainData(
                domainName: "techsite.net",
                earnings: scaleValue("178.09", multiplier: multiplier),
                requests: scaleValue("20000", multiplier: multiplier),
                pageViews: scaleValue("15300", multiplier: multiplier),
                impressions: scaleValue("17800", multiplier: multiplier),
                clicks: scaleValue("512", multiplier: multiplier),
                ctr: "3.34",
                rpm: "11.20"
            )
        ]
        
        // Generate platform data
        let scaledPlatforms = [
            PlatformData(
                platform: "Mobile",
                earnings: scaleValue("456.78", multiplier: multiplier),
                pageViews: scaleValue("28900", multiplier: multiplier),
                pageRPM: "15.80",
                impressions: scaleValue("32400", multiplier: multiplier),
                impressionsRPM: "14.10",
                activeViewViewable: "92.5",
                clicks: scaleValue("967", multiplier: multiplier),
                requests: scaleValue("35000", multiplier: multiplier),
                ctr: "2.98"
            ),
            PlatformData(
                platform: "Desktop",
                earnings: scaleValue("234.56", multiplier: multiplier),
                pageViews: scaleValue("15600", multiplier: multiplier),
                pageRPM: "15.20",
                impressions: scaleValue("18900", multiplier: multiplier),
                impressionsRPM: "13.80",
                activeViewViewable: "91.8",
                clicks: scaleValue("523", multiplier: multiplier),
                requests: scaleValue("20000", multiplier: multiplier),
                ctr: "2.77"
            ),
            PlatformData(
                platform: "Tablet",
                earnings: scaleValue("66.98", multiplier: multiplier),
                pageViews: scaleValue("4500", multiplier: multiplier),
                pageRPM: "14.90",
                impressions: scaleValue("5800", multiplier: multiplier),
                impressionsRPM: "13.50",
                activeViewViewable: "90.5",
                clicks: scaleValue("151", multiplier: multiplier),
                requests: scaleValue("6500", multiplier: multiplier),
                ctr: "2.60"
            )
        ]
        
        // Generate country data
        let scaledCountries = [
            CountryData(
                countryCode: "US",
                countryName: "United States",
                earnings: scaleValue("456.78", multiplier: multiplier),
                requests: scaleValue("35000", multiplier: multiplier),
                pageViews: scaleValue("28900", multiplier: multiplier),
                impressions: scaleValue("32400", multiplier: multiplier),
                clicks: scaleValue("967", multiplier: multiplier),
                ctr: "3.35",
                rpm: "14.70"
            ),
            CountryData(
                countryCode: "GB",
                countryName: "United Kingdom",
                earnings: scaleValue("134.56", multiplier: multiplier),
                requests: scaleValue("12000", multiplier: multiplier),
                pageViews: scaleValue("8900", multiplier: multiplier),
                impressions: scaleValue("10500", multiplier: multiplier),
                clicks: scaleValue("298", multiplier: multiplier),
                ctr: "3.35",
                rpm: "14.50"
            ),
            CountryData(
                countryCode: "CA",
                countryName: "Canada",
                earnings: scaleValue("89.67", multiplier: multiplier),
                requests: scaleValue("8000", multiplier: multiplier),
                pageViews: scaleValue("5900", multiplier: multiplier),
                impressions: scaleValue("7200", multiplier: multiplier),
                clicks: scaleValue("198", multiplier: multiplier),
                ctr: "3.36",
                rpm: "14.45"
            )
        ]
        
        // Generate ad network data
        let scaledAdNetworks = [
            AdNetworkData(
                adNetworkType: "Google AdSense",
                earnings: scaleValue("458.32", multiplier: multiplier),
                requests: scaleValue("45000", multiplier: multiplier),
                pageViews: scaleValue("35600", multiplier: multiplier),
                impressions: scaleValue("42300", multiplier: multiplier),
                clicks: scaleValue("1200", multiplier: multiplier),
                ctr: "3.37",
                rpm: "14.70"
            ),
            AdNetworkData(
                adNetworkType: "Google AdMob",
                earnings: scaleValue("245.67", multiplier: multiplier),
                requests: scaleValue("25000", multiplier: multiplier),
                pageViews: scaleValue("18900", multiplier: multiplier),
                impressions: scaleValue("20500", multiplier: multiplier),
                clicks: scaleValue("856", multiplier: multiplier),
                ctr: "3.35",
                rpm: "14.60"
            )
        ]
        
        // Generate targeting data
        let scaledTargeting = [
            TargetingData(
                targetingType: "Display",
                earnings: scaleValue("456.78", multiplier: multiplier),
                impressions: scaleValue("28900", multiplier: multiplier),
                clicks: scaleValue("967", multiplier: multiplier),
                ctr: "3.35",
                rpm: "14.70",
                requests: scaleValue("35000", multiplier: multiplier),
                pageViews: scaleValue("30000", multiplier: multiplier)
            ),
            TargetingData(
                targetingType: "Search",
                earnings: scaleValue("301.54", multiplier: multiplier),
                impressions: scaleValue("19200", multiplier: multiplier),
                clicks: scaleValue("643", multiplier: multiplier),
                ctr: "3.35",
                rpm: "14.70",
                requests: scaleValue("25000", multiplier: multiplier),
                pageViews: scaleValue("22000", multiplier: multiplier)
            )
        ]
        
        return (
            domains: scaledDomains,
            platforms: scaledPlatforms,
            countries: scaledCountries,
            adNetworks: scaledAdNetworks,
            targeting: scaledTargeting
        )
    }
    
    // Mock streak data
    let streakData: [StreakDayData] = {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2025, month: 5, day: 11))!
        
        // Generate 30 days of data, starting from May 11, 2025
        return (0..<30).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: baseDate)!
            
            // Create deterministic but realistic-looking data
            let baseEarnings = 25.0
            let dayOfWeek = calendar.component(.weekday, from: date)
            let weekendMultiplier = (dayOfWeek == 1 || dayOfWeek == 7) ? 0.7 : 1.0 // Lower earnings on weekends
            
            let earnings = baseEarnings * weekendMultiplier * (1.0 + Double(dayOfWeek) * 0.1)
            let impressions = 1000 + (dayOfWeek * 100)
            let clicks = 30 + (dayOfWeek * 2)
            let impressionCTR = Double(clicks) / Double(impressions) * 100
            let pageViews = impressions - Int.random(in: 50...100)
            let costPerClick = earnings / Double(clicks)
            let requests = pageViews + Int.random(in: 20...50)
            
            // Calculate delta based on previous day's earnings
            let delta = dayOffset == 29 ? nil : earnings - (baseEarnings * (1.0 + Double((dayOfWeek % 7 + 1)) * 0.1))
            let deltaPositive = delta.map { $0 > 0 }
            
            return StreakDayData(
                date: date,
                earnings: earnings,
                clicks: clicks,
                impressions: impressions,
                impressionCTR: impressionCTR,
                pageViews: pageViews,
                costPerClick: costPerClick,
                requests: requests,
                delta: delta,
                deltaPositive: deltaPositive
            )
        }
    }()
    
    // Mock day metrics data
    let dayMetrics = AdSenseDayMetrics(
        estimatedEarnings: "$125.45",
        clicks: "1,234",
        pageViews: "23,456",
        impressions: "12,345",
        adRequests: "23,456",
        matchedAdRequests: "21,234",
        costPerClick: "0.45",
        impressionsCTR: "3.35",
        impressionsRPM: "13.80",
        pageViewsCTR: "3.25",
        pageViewsRPM: "14.70"
    )
    
    private init() {} // Singleton
} 