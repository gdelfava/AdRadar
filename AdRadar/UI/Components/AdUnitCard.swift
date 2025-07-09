import SwiftUI

struct AdUnitCard: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let adUnit: AdUnitData
    let selectedFilter: AdUnitMetricFilter
    
    var body: some View {
        HStack(spacing: 16) {
            // Ad Unit Icon and Info
            HStack(spacing: 12) {
                adUnitIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(adUnit.adUnitName)
                        .soraHeadline()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(adUnit.displayDescription)
                        .soraCaption()
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Primary Metric (based on selected filter)
            VStack(alignment: .trailing, spacing: 4) {
                Text(adUnit.getValue(for: selectedFilter, isDemoMode: authViewModel.isDemoMode))
                    .soraTitle2()
                    .foregroundColor(colorForFilter(selectedFilter))
                    .lineLimit(1)
                
                Text(secondaryValueText)
                    .soraCaption2()
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .accessibleCard(
            label: "\(adUnit.adUnitName) ad unit",
            value: AccessibilityUtilities.metricDescription(
                title: selectedFilter.rawValue,
                value: adUnit.getValue(for: selectedFilter, isDemoMode: authViewModel.isDemoMode),
                period: adUnit.displayDescription
            ),
            hint: "Double tap to view detailed metrics for this ad unit"
        )
    }
    
    private var adUnitIcon: some View {
        Image(systemName: iconForAdUnitFormat(adUnit.adUnitFormat))
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.accentColor)
            .frame(width: 32, height: 32)
            .background(Color.accentColor.opacity(0.1))
            .clipShape(Circle())
    }
    
    private var secondaryValueText: String {
        switch selectedFilter {
        case .earnings:
            return "CTR: \(adUnit.formattedCTR)"
        case .clicks:
            return "CTR: \(adUnit.formattedCTR)"
        case .impressions:
            return "Requests: \(formattedNumber(adUnit.requests))"
        case .requests:
            return "Impressions: \(formattedNumber(adUnit.impressions))"
        case .eCPM:
            return "Earnings: \(adUnit.formattedEarnings(isDemoMode: authViewModel.isDemoMode))"
        }
    }
    
    private func iconForAdUnitFormat(_ format: String) -> String {
        switch format.lowercased() {
        case "banner":
            return "rectangle.fill"
        case "interstitial":
            return "square.fill"
        case "rewarded", "video":
            return "play.rectangle.fill"
        case "native":
            return "doc.richtext.fill"
        default:
            return "rectangle.fill"
        }
    }
    
    private func colorForFilter(_ filter: AdUnitMetricFilter) -> Color {
        switch filter {
        case .earnings:
            return .green
        case .clicks:
            return .orange
        case .impressions:
            return .blue
        case .requests:
            return .indigo
        case .eCPM:
            return .pink
        }
    }
    
    private func formattedNumber(_ numberString: String) -> String {
        guard let number = Double(numberString) else { return numberString }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if number >= 1_000_000 {
            return String(format: "%.1fM", number / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", number / 1_000)
        } else {
            return formatter.string(from: NSNumber(value: number)) ?? numberString
        }
    }
}

#Preview {
    AdUnitCard(
        adUnit: AdUnitData(
            adUnitName: "Banner Ad",
            adUnitId: "ca-app-pub-1234567890123456/1234567890",
            adUnitFormat: "Banner",
            adType: "Banner",
            earnings: "10.50",
            impressions: "5000",
            clicks: "50",
            ctr: "0.01",
            eCPM: "2.10",
            requests: "5500"
        ),
        selectedFilter: .earnings
    )
    .environmentObject(AuthViewModel())
    .padding()
} 