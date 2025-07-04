import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .utility)
    @Published var isConnected: Bool = true
    @Published var showNetworkErrorModal: Bool = false
    @Published var connectionType: NWInterface.InterfaceType = .other
    @Published var connectionState: NWPath.Status = .satisfied
    
    private init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.showNetworkErrorModal = path.status != .satisfied
                self?.connectionState = path.status
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = .other
                }
                
                print("[NetworkMonitor] Connection status: \(path.status), Type: \(self?.connectionType.description ?? "unknown")")
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - Network Connection Utilities
extension NetworkMonitor {
    
    /// Creates a properly configured URLSession for network requests
    static func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }
    
    /// Validates if a network request should proceed
    func shouldProceedWithRequest() -> Bool {
        return isConnected && connectionState == .satisfied
    }
    
    /// Validates if endpoints can be accessed
    func canAccessEndpoints() -> Bool {
        return connectionState == .satisfied
    }
    
    /// Gets a descriptive string for the current connection type
    var connectionTypeDescription: String {
        switch connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Gets a descriptive string for the current connection state
    var connectionStateDescription: String {
        switch connectionState {
        case .satisfied:
            return "Connected"
        case .unsatisfied:
            return "Not Connected"
        case .requiresConnection:
            return "Requires Connection"
        @unknown default:
            return "Unknown"
        }
    }
}

// Extension to provide a description for NWInterface.InterfaceType
extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Wired Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
} 