import Foundation
import Combine

struct PaymentsData {
    let unpaidEarnings: String
    let unpaidEarningsValue: Double // Raw value for calculations
    let previousPaymentDate: String
    let previousPaymentAmount: String
    let currentMonthEarnings: String
    let currentMonthEarningsValue: Double // Raw value for progress calculations
}

@MainActor
class PaymentsViewModel: ObservableObject {
    @Published var paymentsData: PaymentsData? = nil
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var hasLoaded: Bool = false
    @Published var lastUpdateTime: Date? = nil
    @Published var showEmptyState: Bool = false
    @Published var emptyStateMessage: String = "No payments data available"
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    private var accountID: String?
    private var currentTask: Task<Void, Never>?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    @MainActor
    func fetchPayments() async {
        guard let currentToken = accessToken else { 
            self.showEmptyState = true
            self.emptyStateMessage = "Please sign in to view your payments"
            return 
        }
        
        // Cancel any existing task to prevent conflicts
        currentTask?.cancel()
        
        // Create new task
        currentTask = Task {
            await performFetchPayments(with: currentToken)
        }
        
        await currentTask?.value
    }
    
    private func performFetchPayments(with workingToken: String) async {
        if !NetworkMonitor.shared.isConnected {
            self.showEmptyState = true
            self.emptyStateMessage = "Unable to load payments data. Please check your connection."
            self.isLoading = false
            return
        }
        
        // If in demo mode, use demo data
        if let authVM = authViewModel, authVM.isDemoMode {
            self.paymentsData = DemoDataProvider.shared.paymentsData
            self.isLoading = false
            self.error = nil
            return
        }
        
        let maxRetries = 3
        var retryCount = 0
        
        while retryCount < maxRetries && !Task.isCancelled {
            self.isLoading = true
            self.error = nil
            
            // Get account ID if not already available
            if accountID == nil {
                let accountResult = await AdSenseAPI.fetchAccountID(accessToken: workingToken)
                switch accountResult {
                case .success(let id):
                    self.accountID = id
                case .failure(let err):
                    switch err {
                    case .unauthorized:
                        if let authVM = authViewModel {
                            let refreshed = await authVM.refreshTokenIfNeeded()
                            if refreshed && !Task.isCancelled {
                                retryCount += 1
                                continue
                            }
                        }
                        if !Task.isCancelled {
                            self.showEmptyState = true
                            self.emptyStateMessage = "Please sign in to view your payments data"
                        }
                        self.isLoading = false
                        return
                    case .noAccountID:
                        if !Task.isCancelled {
                            self.showEmptyState = true
                            self.emptyStateMessage = "No AdSense account found"
                        }
                        self.isLoading = false
                        return
                    case .requestFailed(_):
                        if !Task.isCancelled {
                            self.showEmptyState = true
                            self.emptyStateMessage = "Unable to load payments data. Please try again later."
                        }
                        self.isLoading = false
                        return
                    case .invalidURL, .invalidResponse, .decodingError:
                        if !Task.isCancelled {
                            self.showEmptyState = true
                            self.emptyStateMessage = "Unable to load payments data. Please try again later."
                        }
                        self.isLoading = false
                        return
                    }
                }
            }
            
            // 2. Fetch unpaid earnings, previous payment, and current month earnings in parallel
            // Capture the token value to avoid concurrency warnings
            let currentWorkingToken = workingToken
            
            // Calculate current month date range
            let calendar = Calendar.current
            let now = Date()
            let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentMonthStartStr = dateFormatter.string(from: currentMonthStart)
            let currentMonthEndStr = dateFormatter.string(from: now)
            
            async let unpaidResult = AdSenseAPI.shared.fetchUnpaidEarnings(accessToken: currentWorkingToken, accountID: accountID ?? "")
            async let prevPaymentResult = AdSenseAPI.shared.fetchPreviousPayment(accessToken: currentWorkingToken, accountID: accountID ?? "")
            async let currentMonthResult = AdSenseAPI.shared.fetchReport(accessToken: currentWorkingToken, accountID: accountID ?? "", startDate: currentMonthStartStr, endDate: currentMonthEndStr)
            
            let unpaid = await unpaidResult
            let prev = await prevPaymentResult
            let currentMonth = await currentMonthResult
            
            // Check for cancellation after async operations
            if Task.isCancelled {
                self.isLoading = false
                return
            }
            
            // Check for 401 errors in any request
            var needsRetry = false
            if case .failure(let error) = unpaid, case .unauthorized = error {
                needsRetry = true
            }
            if case .failure(let error) = prev, case .unauthorized = error {
                needsRetry = true
            }
            if case .failure(let error) = currentMonth, case .unauthorized = error {
                needsRetry = true
            }
            
            if needsRetry && !Task.isCancelled {
                if let authVM = authViewModel {
                    let refreshed = await authVM.refreshTokenIfNeeded()
                    if refreshed && !Task.isCancelled {
                        retryCount += 1
                        continue
                    }
                }
                if !Task.isCancelled {
                    self.showEmptyState = true
                    self.emptyStateMessage = "Please sign in to view your payments data"
                }
                self.isLoading = false
                return
            }
            
            // 3. Format and assign
            func formatCurrency(_ value: Double) -> String {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = Locale.current
                formatter.minimumFractionDigits = 2
                formatter.maximumFractionDigits = 2
                return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
            }
            func formatDate(_ date: Date) -> String {
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMM yyyy"
                return formatter.string(from: date)
            }
            
            if case .success(let unpaidEarnings) = unpaid, !Task.isCancelled {
                let currentMonthEarnings = (try? currentMonth.get()) ?? 0.0
                
                switch prev {
                case .success(let prevPayment?):
                    // Normal case: payment exists
                    let data = PaymentsData(
                        unpaidEarnings: formatCurrency(unpaidEarnings),
                        unpaidEarningsValue: unpaidEarnings,
                        previousPaymentDate: formatDate(prevPayment.date),
                        previousPaymentAmount: formatCurrency(prevPayment.amount),
                        currentMonthEarnings: formatCurrency(currentMonthEarnings),
                        currentMonthEarningsValue: currentMonthEarnings
                    )
                    if !Task.isCancelled {
                        self.paymentsData = data
                        self.lastUpdateTime = Date()
                        self.error = nil
                        self.hasLoaded = true
                    }
                case .success(nil):
                    // No previous payment exists
                    let data = PaymentsData(
                        unpaidEarnings: formatCurrency(unpaidEarnings),
                        unpaidEarningsValue: unpaidEarnings,
                        previousPaymentDate: "No payments yet",
                        previousPaymentAmount: "-",
                        currentMonthEarnings: formatCurrency(currentMonthEarnings),
                        currentMonthEarningsValue: currentMonthEarnings
                    )
                    if !Task.isCancelled {
                        self.paymentsData = data
                        self.lastUpdateTime = Date()
                        self.error = nil
                        self.hasLoaded = true
                    }
                case .failure(let err):
                    switch err {
                    case .unauthorized:
                        // This case is already handled above
                        break
                    case .requestFailed(_):
                        // Handle cancellation more gracefully
                        if Task.isCancelled {
                            // Silently ignore cancellation errors during refresh
                            break
                        }
                        if !Task.isCancelled {
                            self.showEmptyState = true
                            self.emptyStateMessage = "Failed to load previous payment data"
                        }
                    default:
                        if !Task.isCancelled {
                            self.showEmptyState = true
                            self.emptyStateMessage = "Failed to load payment data"
                        }
                    }
                }
            } else if case .failure(let err) = unpaid, !Task.isCancelled {
                switch err {
                case .unauthorized:
                    // This case is already handled above
                    break
                case .requestFailed(_):
                    // Handle cancellation more gracefully
                    if Task.isCancelled {
                        // Silently ignore cancellation errors during refresh
                        break
                    }
                    if !Task.isCancelled {
                        self.showEmptyState = true
                        self.emptyStateMessage = "Failed to load unpaid earnings data"
                    }
                default:
                    if !Task.isCancelled {
                        self.showEmptyState = true
                        self.emptyStateMessage = "Failed to load earnings data"
                    }
                }
            }
            
            if !Task.isCancelled {
                self.isLoading = false
            }
            break // Exit the retry loop
        }
        
        if retryCount >= maxRetries && !Task.isCancelled {
            self.showEmptyState = true
            self.emptyStateMessage = "Failed to refresh authentication. Please sign in again."
            self.isLoading = false
        } else if !Task.isCancelled {
            self.isLoading = false
        }
    }
} 
