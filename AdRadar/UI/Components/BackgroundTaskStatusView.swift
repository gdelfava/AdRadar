import SwiftUI

struct BackgroundTaskStatusView: View {
    @EnvironmentObject var backgroundDataManager: BackgroundDataManager
    @State private var showingDataDetails = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Background Task Status") {
                    backgroundTaskStatusSection
                }
                
                Section("Data Information") {
                    dataInfoSection
                }
                
                #if DEBUG
                Section("Debug Controls") {
                    debugControlsSection
                }
                #endif
                
                Section("Actions") {
                    actionButtonsSection
                }
            }
            .navigationTitle("Background Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await refreshData()
            }
        }
    }
    
    private var backgroundTaskStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: backgroundDataManager.isBackgroundRefreshEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(backgroundDataManager.isBackgroundRefreshEnabled ? .green : .red)
                
                Text("Background App Refresh")
                    .font(.headline)
                
                Spacer()
                
                Text(backgroundDataManager.isBackgroundRefreshEnabled ? "Enabled" : "Disabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                
                Text("Scheduled Tasks")
                
                Spacer()
                
                Text("\(backgroundDataManager.backgroundTasksScheduled)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let lastUpdate = backgroundDataManager.lastBackgroundUpdate {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.orange)
                    
                    Text("Last Background Update")
                    
                    Spacer()
                    
                    Text(lastUpdate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var dataInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let sharedData = CrossPlatformDataBridge.shared.loadSharedSummaryData() {
                HStack {
                    Image(systemName: "database.fill")
                        .foregroundColor(.green)
                    
                    Text("Shared Data Available")
                    
                    Spacer()
                    
                    Button("View Details") {
                        showingDataDetails = true
                    }
                    .font(.caption)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    
                    Text("Data Version")
                    
                    Spacer()
                    
                    Text("v\(sharedData.dataVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                    
                    Text("Last Updated")
                    
                    Spacer()
                    
                    Text(sharedData.lastUpdated, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text("No Shared Data Available")
                        .foregroundColor(.secondary)
                }
            }
            
            if let freshness = CrossPlatformDataBridge.shared.getDataFreshness() {
                HStack {
                    Image(systemName: freshness.isStale ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(freshness.isStale ? .orange : .green)
                    
                    Text("Data Freshness")
                    
                    Spacer()
                    
                    Text(freshness.ageDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    #if DEBUG
    private var debugControlsSection: some View {
        VStack(spacing: 8) {
            Button("Simulate Background Task") {
                Task {
                    backgroundDataManager.simulateBackgroundTask()
                }
            }
            .buttonStyle(.bordered)
            
            Button("Check Background Refresh Permission") {
                let status = UIApplication.shared.backgroundRefreshStatus
                print("Background Refresh Status: \(status.rawValue)")
            }
            .buttonStyle(.bordered)
            
            Button("View Debug Info") {
                print(backgroundDataManager.getDebugInfo())
            }
            .buttonStyle(.bordered)
        }
    }
    #endif
    
    private var actionButtonsSection: some View {
        VStack(spacing: 8) {
            Button("Refresh Data Now") {
                Task {
                    await refreshData()
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func refreshData() async {
        let success = await backgroundDataManager.performDataRefresh()
        print("Manual refresh result: \(success)")
    }
}

struct DataDetailsView: View {
    let data: SharedSummaryData
    
    var body: some View {
        NavigationView {
            List {
                Section("Earnings Data") {
                    DataRow(title: "Today", value: data.todayEarnings, delta: data.todayDelta, isPositive: data.todayDeltaPositive)
                    DataRow(title: "Yesterday", value: data.yesterdayEarnings, delta: data.yesterdayDelta, isPositive: data.yesterdayDeltaPositive)
                    DataRow(title: "Last 7 Days", value: data.last7DaysEarnings, delta: data.last7DaysDelta, isPositive: data.last7DaysDeltaPositive)
                    DataRow(title: "This Month", value: data.thisMonthEarnings, delta: data.thisMonthDelta, isPositive: data.thisMonthDeltaPositive)
                    DataRow(title: "Last Month", value: data.lastMonthEarnings, delta: data.lastMonthDelta, isPositive: data.lastMonthDeltaPositive)
                    DataRow(title: "Lifetime", value: data.lifetimeEarnings)
                }
                
                Section("Metadata") {
                    HStack {
                        Text("Data Version")
                        Spacer()
                        Text("v\(data.dataVersion)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(data.lastUpdated.formatted())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Data Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DataRow: View {
    let title: String
    let value: String
    let delta: String?
    let isPositive: Bool?
    
    init(title: String, value: String, delta: String? = nil, isPositive: Bool? = nil) {
        self.title = title
        self.value = value
        self.delta = delta
        self.isPositive = isPositive
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            if let delta = delta {
                HStack {
                    Image(systemName: isPositive == true ? "arrow.up" : "arrow.down")
                        .foregroundColor(isPositive == true ? .green : .red)
                    Text(delta)
                        .foregroundColor(isPositive == true ? .green : .red)
                    Spacer()
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    BackgroundTaskStatusView()
        .environmentObject(BackgroundDataManager.shared)
} 