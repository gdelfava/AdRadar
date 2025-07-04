import SwiftUI

struct HorizontalDatePickerView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var selectedDay: StreakDayData?
    let streakData: [StreakDayData]
    
    private var sortedData: [StreakDayData] {
        streakData.sorted { $0.date < $1.date }  // Sort oldest to newest
    }
    
    private var mostRecentDayId: UUID? {
        // Get the most recent date (the last one in the sorted array)
        sortedData.last?.id
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 8) {
                    ForEach(sortedData) { day in
                        DateCell(day: day, isSelected: day.id == selectedDay?.id)
                            .environmentObject(authViewModel)
                            .id(day.id)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDay = day
                                }
                            }
                    }
                }
                .padding(.horizontal, 4)
                .onAppear {
                    // Scroll to the most recent date immediately and again after a delay
                    if let recentId = mostRecentDayId {
                        proxy.scrollTo(recentId, anchor: .trailing)
                        // Also do it after a delay to ensure it works even if layout isn't ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(recentId, anchor: .trailing)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Date Cell
private struct DateCell: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let day: StreakDayData
    let isSelected: Bool
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: day.date)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: day.date)
    }
    
    private var formattedEarnings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if authViewModel.isDemoMode {
            formatter.currencySymbol = "$"
        } else {
            formatter.locale = Locale.current // Use user's locale for currency
        }
        
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        // For very small amounts, show more decimal places
        if day.earnings < 1.0 && day.earnings > 0 {
            formatter.minimumFractionDigits = 3
            formatter.maximumFractionDigits = 3
        }
        
        return formatter.string(from: NSNumber(value: day.earnings)) ?? "0.00"
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(dayName)
                .soraCaption()
                .foregroundColor(isSelected ? .white : .secondary)
            
            Text(dayNumber)
                .soraTitle3()
                .foregroundColor(isSelected ? .white : .primary)
            
            Text(formattedEarnings)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Circle()
                .fill(isToday ? Color.accentColor : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(width: 52, height: 95)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
    }
} 
