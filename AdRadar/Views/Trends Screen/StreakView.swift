import SwiftUI
import Charts
import UIKit

struct StreakView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: StreakViewModel
    @State private var selectedDay: StreakDayData?
    @State private var calendarAppeared = false
    @State private var overviewAppeared = false
    @State private var detailsAppeared = false
    @State private var animateFloatingElements = false
    @State private var showDatePicker = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: StreakViewModel(accessToken: nil))
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
    }
    
    private var displayDay: StreakDayData? {
        selectedDay ?? currentDay ?? viewModel.streakData.first
    }
    
    private var currentDay: StreakDayData? {
        let today = Date()
        return viewModel.streakData.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background with dynamic colors
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color.accentColor.opacity(0.08),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.showEmptyState {
                            emptyStateView
                        } else {
                            content
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationTitle("Trends")
            .toolbar {
                leadingToolbarItems
                trailingToolbarItems
            }
        }
        .onAppear {
            setupInitialData()
            animateContent()
        }
        .onChange(of: viewModel.streakData) { _, newData in
            handleDataChange(newData)
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
    }
    
    // MARK: - Content Views
    
    private var content: some View {
        VStack(spacing: 24) {
            // Header with last update time and date selection
            headerSection
                .padding(.horizontal, 20)
            
            // Streak calendar
            calendarSection
                .padding(.horizontal, 20)
            
            // Selected day metrics card
            if let displayDay = displayDay {
                selectedDayCard(displayDay)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Performance overview
            performanceSection
                .padding(.horizontal, 20)
            
            // Insights section
            insightsSection
                .padding(.horizontal, 20)
        }
    }
    
    private var headerSection: some View {
        Group {
            if !viewModel.isLoading && !viewModel.streakData.isEmpty {
                StreakHeaderView(lastUpdateTime: viewModel.lastUpdateTime)
                    .opacity(calendarAppeared ? 1 : 0)
                    .offset(y: calendarAppeared ? 0 : 10)
            } else {
                EmptyView()
            }
        }
    }
    
    private func selectedDayCard(_ day: StreakDayData) -> some View {
        SelectedDayMetricsView(day: day, viewModel: viewModel, showCloseButton: false)
            .opacity(detailsAppeared ? 1 : 0)
            .offset(y: detailsAppeared ? 0 : 20)
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month name
            Text(formatMonth(displayDay?.date ?? Date()))
                .soraTitle2()
                .foregroundColor(.primary)
            
//            Text("Activity Calendar")
//                .soraTitle3()
//                .foregroundColor(.primary)
            
            HorizontalDatePickerView(selectedDay: $selectedDay, streakData: viewModel.streakData)
                .opacity(calendarAppeared ? 1 : 0)
                .offset(y: calendarAppeared ? 0 : 20)
        }
    }
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            OverviewCardsView(streakData: viewModel.streakData, viewModel: viewModel)
                .opacity(overviewAppeared ? 1 : 0)
                .offset(y: overviewAppeared ? 0 : 20)
        }
    }
    
    private var insightsSection: some View {
        PerformanceInsightsView(streakData: viewModel.streakData, viewModel: viewModel)
            .opacity(overviewAppeared ? 1 : 0)
            .offset(y: overviewAppeared ? 0 : 20)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading trends...")
                .soraBody()
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 100)
    }
    
    private var emptyStateView: some View {
        StreakEmptyStateView(message: viewModel.emptyStateMessage ?? "")
            .padding(.horizontal, 20)
            .padding(.vertical, 100)
    }
    
    private var datePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { displayDay?.date ?? Date() },
                        set: { newDate in
                            selectedDay = viewModel.streakData.first {
                                Calendar.current.isDate($0.date, inSameDayAs: newDate)
                            }
                        }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showDatePicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Toolbar Items
    
    private var leadingToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSlideOverMenu = true
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var trailingToolbarItems: some ToolbarContent {
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
    
    // MARK: - Helper Methods
    
    private func setupInitialData() {
        if let token = authViewModel.accessToken, !viewModel.hasLoaded {
            viewModel.accessToken = token
            viewModel.authViewModel = authViewModel
            Task { await viewModel.fetchStreakData() }
        }
    }
    
    private func animateContent() {
        withAnimation(.easeOut(duration: 0.5)) {
            calendarAppeared = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            overviewAppeared = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            detailsAppeared = true
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            animateFloatingElements = true
        }
    }
    
    private func handleDataChange(_ newData: [StreakDayData]) {
        if selectedDay == nil && !newData.isEmpty {
            let today = Date()
            selectedDay = newData.first { Calendar.current.isDate($0.date, inSameDayAs: today) } ?? newData.first
        }
    }
    
    private func refreshData() async {
        if let token = authViewModel.accessToken {
            viewModel.accessToken = token
            viewModel.authViewModel = authViewModel
            selectedDay = nil
            await viewModel.fetchStreakData()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func errorSymbol(for error: String) -> String {
        if error.localizedCaseInsensitiveContains("internet") || error.localizedCaseInsensitiveContains("offline") {
            return "wifi.slash"
        } else if error.localizedCaseInsensitiveContains("unauthorized") || error.localizedCaseInsensitiveContains("session") {
            return "person.crop.circle.badge.exclamationmark"
        } else {
            return "exclamationmark.triangle"
        }
    }
} 
