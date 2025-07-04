import SwiftUI

struct CountryAdFilterView: View {
    @Binding var selectedFilter: CountryAdMetricFilter
    let onFilterChanged: (CountryAdMetricFilter) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CountryAdMetricFilter.allCases, id: \.self) { filter in
                    CountryFilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        onFilterChanged(filter)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct CountryFilterButton: View {
    let filter: CountryAdMetricFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 14, weight: .medium))
                
                Text(filter.rawValue)
                    .soraCaption()
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 