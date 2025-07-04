import SwiftUI

struct AdUnitsSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var adUnitViewModel: AdUnitViewModel
    let appData: AppData
    let accountID: String
    let dateRange: (start: Date, end: Date)
    
    init(appData: AppData, accountID: String, dateRange: (start: Date, end: Date)) {
        self.appData = appData
        self.accountID = accountID
        self.dateRange = dateRange
        self._adUnitViewModel = StateObject(wrappedValue: AdUnitViewModel(accessToken: nil))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Ad Units")
                    .soraTitle2()
                    .foregroundColor(.primary)
                
                Spacer()
                
                if adUnitViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 20)
            
            // Filter View
            AdUnitFilterView(selectedFilter: $adUnitViewModel.selectedFilter) { filter in
                adUnitViewModel.setFilter(filter)
            }
            
            // Content
            Group {
                if adUnitViewModel.isLoading && adUnitViewModel.filteredAdUnits.isEmpty {
                    loadingView
                } else if let errorMessage = adUnitViewModel.errorMessage {
                    errorView(message: errorMessage)
                } else if adUnitViewModel.filteredAdUnits.isEmpty && adUnitViewModel.hasLoaded {
                    emptyStateView
                } else {
                    adUnitsListView
                }
            }
        }
        .onAppear {
            if let token = authViewModel.accessToken, !adUnitViewModel.hasLoaded {
                adUnitViewModel.accessToken = token
                adUnitViewModel.authViewModel = authViewModel
                Task {
                    await adUnitViewModel.fetchAdUnitsData(
                        for: appData.appId,
                        accountID: accountID,
                        dateRange: dateRange
                    )
                }
            }
        }
        .onChange(of: authViewModel.accessToken) { oldToken, newToken in
            if let token = newToken {
                adUnitViewModel.accessToken = token
                adUnitViewModel.authViewModel = authViewModel
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading ad units...")
                .soraBody()
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("Error Loading Ad Units")
                .soraHeadline()
                .foregroundColor(.primary)
            
            Text(message)
                .soraBody()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await adUnitViewModel.fetchAdUnitsData(
                        for: appData.appId,
                        accountID: accountID,
                        dateRange: dateRange
                    )
                }
            }
            .soraBody()
            .foregroundColor(.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 32))
                .foregroundColor(.gray)
            
            Text("No Ad Units")
                .soraHeadline()
                .foregroundColor(.primary)
            
            VStack(spacing: 4) {
                Text("No ad unit data available for this app.")
                    .soraBody()
                    .foregroundColor(.secondary)
                
                Text("Create ad units in AdMob to start earning revenue.")
                    .soraCaption()
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
    
    private var adUnitsListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(adUnitViewModel.filteredAdUnits) { adUnit in
                AdUnitCard(
                    adUnit: adUnit,
                    selectedFilter: adUnitViewModel.selectedFilter
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    AdUnitsSection(
        appData: AppData(
            appName: "Demo App",
            appId: "com.example.demo",
            earnings: "100.50",
            impressions: "10000",
            clicks: "150",
            ctr: "1.5",
            rpm: "10.05",
            requests: "11000"
        ),
        accountID: "pub-1234567890123456",
        dateRange: (start: Date().addingTimeInterval(-7*24*60*60), end: Date())
    )
    .environmentObject(AuthViewModel())
} 