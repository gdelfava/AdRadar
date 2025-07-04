import SwiftUI

struct CountryAdCard: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let country: CountryAdData
    let selectedFilter: CountryAdMetricFilter
    
    var body: some View {
        HStack(spacing: 16) {
            // Country Flag and Info
            HStack(spacing: 12) {
                countryIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(country.countryName)
                        .soraHeadline()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(displayDescription)
                        .soraCaption()
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Metric Value
            VStack(alignment: .trailing, spacing: 4) {
                Text(country.getValue(for: selectedFilter, isDemoMode: authViewModel.isDemoMode))
                    .soraTitle2()
                    .foregroundColor(selectedFilter.color)
                    .lineLimit(1)
                
                Text(selectedFilter.rawValue)
                    .soraCaption2()
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
    
    private var countryIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(width: 32, height: 32)
            
            Text(country.flagEmoji)
                .font(.system(size: 18))
        }
    }
    
    private var displayDescription: String {
        switch selectedFilter {
        case .earnings:
            return "Revenue generated"
        case .clicks:
            return "Ad clicks recorded"
        case .impressions:
            return "Ad views delivered"
        case .requests:
            return "Ad requests made"
        case .eCPM:
            return "Effective cost per mille"
        }
    }
} 