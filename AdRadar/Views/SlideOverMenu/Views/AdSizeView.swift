import SwiftUI

struct AdSizeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: AdSizeViewModel
    @State private var showingDateFilter = false
    @State private var showTotalEarningsCard = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: AdSizeViewModel(accessToken: nil))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                mainContent
            }
            .navigationTitle("Ad Sizes")
            .toolbar {
                leadingToolbarItem
                trailingToolbarItem
            }
        }
        .sheet(isPresented: $showingDateFilter) {
            AdSizeDateFilterSheet(selectedFilter: $viewModel.selectedFilter, isPresented: $showingDateFilter) {
                // Reset total earnings card when filter changes
                showTotalEarningsCard = false
                Task {
                    await viewModel.fetchAdSizeData()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            filterButton
        }
        .onAppear {
            if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                Task { await viewModel.fetchAdSizeData() }
            }
            
            // Reset total earnings card visibility
            showTotalEarningsCard = false
        }
        .onChange(of: viewModel.adSizes) { oldAdSizes, newAdSizes in
            // Show total earnings card after ad sizes have loaded
            if !newAdSizes.isEmpty && viewModel.hasLoaded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTotalEarningsCard = true
                }
            } else {
                showTotalEarningsCard = false
            }
        }
        .onChange(of: viewModel.hasLoaded) { oldValue, newValue in
            // Reset total earnings card when loading state changes
            if newValue && !viewModel.adSizes.isEmpty {
                showTotalEarningsCard = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showTotalEarningsCard = true
                }
            } else {
                showTotalEarningsCard = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var mainContent: some View {
        Group {
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading ad sizes...")
                    .soraBody()
                    .padding()
                Spacer()
            } else if viewModel.adSizes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Ad Size Data")
                        .soraHeadline()
                        .foregroundColor(.gray)
                    
                    Text("No ad size data available for the selected time period.")
                        .soraBody()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                adSizesScrollView
            }
        }
    }
    
    private var adSizesScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                totalEarningsCard
                adSizeCardsList
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 100)
        }
        .refreshable {
            if let token = authViewModel.accessToken {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                await viewModel.fetchAdSizeData()
            }
        }
    }
    
    private var totalEarningsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Total Earnings")
                    .soraHeadline()
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(calculateTotalEarnings())
                    .soraLargeTitle()
                    .foregroundColor(.accentColor)
            }
            
            HStack {
                Image(systemName: "rectangle.3.group")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.adSizes.count) adSize\(viewModel.adSizes.count == 1 ? "" : "s")")
                    .soraCaption()
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Period: \(viewModel.selectedFilter.rawValue)")
                    .soraCaption()
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(showTotalEarningsCard ? 1 : 0)
        .offset(y: showTotalEarningsCard ? 0 : 20)
        .animation(.easeOut(duration: 0.4), value: showTotalEarningsCard)
    }
    
    private var adSizeCardsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(viewModel.adSizes.enumerated()), id: \.element.id) { index, adSize in
                AdSizeCard(adSize: adSize)
            }
        }
    }
    
    private var leadingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Done") {
                dismiss()
            }
            .soraBody()
            .foregroundColor(.accentColor)
        }
    }
    
    private var trailingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            ProfileImageView(url: authViewModel.userProfileImageURL)
                .contextMenu {
                    Button(role: .destructive) {
                        authViewModel.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    Button("Cancel", role: .cancel) { }
                }
        }
    }
    
    private var filterButton: some View {
        Button(action: {
            showingDateFilter = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.body)
                    .foregroundColor(.white)
                Text(viewModel.selectedFilter.rawValue)
                    .soraBody()
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func calculateTotalEarnings() -> String {
        let totalEarnings = viewModel.adSizes.reduce(0.0) { sum, adSize in
            sum + (Double(adSize.earnings) ?? 0.0)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current // Use user's locale for currency
        
        return formatter.string(from: NSNumber(value: totalEarnings)) ?? formatter.string(from: NSNumber(value: 0.0)) ?? "0.00"
    }
}

struct AdSizeDateFilterSheet: View {
    @Binding var selectedFilter: AdSizeDateFilter
    @Binding var isPresented: Bool
    var onFilterSelected: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    // Grouping filters by type for better organization
    private var quickFilters: [AdSizeDateFilter] {
        [.today, .yesterday]
    }
    
    private var periodFilters: [AdSizeDateFilter] {
        [.last7Days, .thisMonth, .lastMonth]
    }
    
    private var extendedFilters: [AdSizeDateFilter] {
        [.lifetime]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator and header
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                
                HStack {
                    Text("Filter by Date")
                        .soraTitle2()
                        .foregroundColor(.primary)
                    Spacer()
                    Button("Done") {
                        isPresented = false
                    }
                    .soraBody()
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 24)
            }
            .background(Color(.systemGroupedBackground))
            
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Access Section
                    AdSizeFilterSection(title: "Quick Access") {
                        VStack(spacing: 0) {
                            ForEach(Array(quickFilters.enumerated()), id: \.element) { index, filter in
                                AdSizeFilterRow(
                                    filter: filter,
                                    isSelected: selectedFilter == filter,
                                    action: {
                                        selectFilter(filter)
                                    }
                                )
                                
                                if index < quickFilters.count - 1 {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                    }
                    
                    // Time Periods Section
                    AdSizeFilterSection(title: "Time Periods") {
                        VStack(spacing: 0) {
                            ForEach(Array(periodFilters.enumerated()), id: \.element) { index, filter in
                                AdSizeFilterRow(
                                    filter: filter,
                                    isSelected: selectedFilter == filter,
                                    action: {
                                        selectFilter(filter)
                                    }
                                )
                                
                                if index < periodFilters.count - 1 {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                    }
                    
                    // Extended Range Section
                    AdSizeFilterSection(title: "Extended Range") {
                        VStack(spacing: 0) {
                            ForEach(extendedFilters, id: \.self) { filter in
                                AdSizeFilterRow(
                                    filter: filter,
                                    isSelected: selectedFilter == filter,
                                    action: {
                                        selectFilter(filter)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Current Selection Summary
                    if let summary = getFilterSummary() {
                        VStack(spacing: 8) {
                            Text("Current Selection")
                                .soraFootnote()
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                Text(summary)
                                    .soraCaption()
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
        }
        .presentationDetents([.height(650), .large])
        .presentationDragIndicator(.hidden)
    }
    
    private func selectFilter(_ filter: AdSizeDateFilter) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        selectedFilter = filter
        onFilterSelected()
        
        // Delay dismissal slightly for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPresented = false
        }
    }
    
    private func getFilterSummary() -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let range = selectedFilter.dateRange
        
        switch selectedFilter {
        case .today:
            return "Today only"
        case .yesterday:
            return "Yesterday only"
        case .last7Days:
            return "Last 7 days including today"
        case .thisMonth:
            return "From \(formatter.string(from: range.start)) to today"
        case .lastMonth:
            return "Previous month period"
        case .lifetime:
            return "Last 3 years of data"
        }
    }
}

struct AdSizeFilterSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .soraSubheadline()
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
            
            content
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 24)
        }
    }
}

struct AdSizeFilterRow: View {
    let filter: AdSizeDateFilter
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var filterIcon: String {
        switch filter {
        case .today:
            return "calendar.circle.fill"
        case .yesterday:
            return "calendar.badge.clock"
        case .last7Days:
            return "calendar.badge.exclamationmark"
        case .thisMonth:
            return "calendar"
        case .lastMonth:
            return "calendar.badge.minus"
        case .lifetime:
            return "infinity.circle.fill"
        }
    }
    
    private var filterColor: Color {
        switch filter {
        case .today:
            return .green
        case .yesterday:
            return .orange
        case .last7Days:
            return .blue
        case .thisMonth:
            return .purple
        case .lastMonth:
            return .red
        case .lifetime:
            return .indigo
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: filterIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : filterColor)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(isSelected ? filterColor : filterColor.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(filter.rawValue)
                        .soraBody()
                        .foregroundColor(.primary)
                    
                    if let description = getFilterDescription() {
                        Text(description)
                            .soraCaption()
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private func getFilterDescription() -> String? {
        switch filter {
        case .today:
            return "Current day data"
        case .yesterday:
            return "Previous day data"
        case .last7Days:
            return "Week overview"
        case .thisMonth:
            return "Month to date"
        case .lastMonth:
            return "Previous month"
        case .lifetime:
            return "All available data"
        }
    }
} 