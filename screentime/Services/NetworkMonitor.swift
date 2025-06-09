import Foundation
import Network
import Combine

/// Network connectivity monitor using Apple's NWPathMonitor
/// Provides real-time connectivity status and triggers sync events
final class NetworkMonitor: ObservableObject {
    
    // MARK: - Singleton
    static let shared = NetworkMonitor()
    
    // MARK: - Published Properties
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isExpensive: Bool = false
    @Published private(set) var isConstrained: Bool = false
    
    // MARK: - Combine Publishers
    private let isConnectedSubject = CurrentValueSubject<Bool, Never>(false)
    private let connectionTypeSubject = CurrentValueSubject<ConnectionType, Never>(.unknown)
    
    /// Publisher for connection status changes
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        isConnectedSubject.eraseToAnyPublisher()
    }
    
    /// Publisher for connection type changes
    var connectionTypePublisher: AnyPublisher<ConnectionType, Never> {
        connectionTypeSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .background)
    private var isMonitoring = false
    
    // Connection history for intelligent syncing
    private var connectionHistory: [ConnectionEvent] = []
    private var lastConnectionChange: Date = Date()
    
    // MARK: - Connection Types
    enum ConnectionType: String, CaseIterable {
        case wifi = "wifi"
        case cellular = "cellular"
        case ethernet = "ethernet"
        case other = "other"
        case unknown = "unknown"
        
        var displayName: String {
            switch self {
            case .wifi: return NSLocalizedString("Wi-Fi", comment: "")
            case .cellular: return NSLocalizedString("Cellular", comment: "")
            case .ethernet: return NSLocalizedString("Ethernet", comment: "")
            case .other: return NSLocalizedString("Other", comment: "")
            case .unknown: return NSLocalizedString("Unknown", comment: "")
            }
        }
        
        var systemImageName: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .other: return "network"
            case .unknown: return "questionmark.circle"
            }
        }
        
        /// Whether this connection type is suitable for large data syncing
        var isSuitableForSync: Bool {
            switch self {
            case .wifi, .ethernet: return true
            case .cellular, .other, .unknown: return false
            }
        }
    }
    
    // MARK: - Connection Events
    private struct ConnectionEvent {
        let timestamp: Date
        let isConnected: Bool
        let connectionType: ConnectionType
        let wasExpensive: Bool
        let wasConstrained: Bool
    }
    
    // MARK: - Initialization
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public API
    
    /// Start monitoring network connectivity
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handlePathUpdate(path)
            }
        }
        
        monitor.start(queue: queue)
        isMonitoring = true
        
        print("🌐 NetworkMonitor: Started monitoring network connectivity")
    }
    
    /// Stop monitoring network connectivity
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        monitor.cancel()
        isMonitoring = false
        
        print("🌐 NetworkMonitor: Stopped monitoring network connectivity")
    }
    
    /// Check if the current connection is suitable for syncing
    func isSuitableForSyncing() -> Bool {
        return isConnected && 
               connectionType.isSuitableForSync && 
               !isConstrained &&
               !hasFrequentConnectionChanges()
    }
    
    /// Get connection quality score (0.0 to 1.0)
    func getConnectionQuality() -> Double {
        guard isConnected else { return 0.0 }
        
        var quality = 0.5 // Base quality for being connected
        
        // Connection type bonus
        switch connectionType {
        case .wifi, .ethernet:
            quality += 0.3
        case .cellular:
            quality += 0.1
        case .other:
            quality += 0.05
        case .unknown:
            break
        }
        
        // Penalties
        if isExpensive {
            quality -= 0.2
        }
        
        if isConstrained {
            quality -= 0.3
        }
        
        if hasFrequentConnectionChanges() {
            quality -= 0.1
        }
        
        return max(0.0, min(1.0, quality))
    }
    
    /// Get a delay suggestion for sync operations based on connection stability
    func getSyncDelay() -> TimeInterval {
        let timeSinceLastChange = Date().timeIntervalSince(lastConnectionChange)
        
        // If connection just changed, wait a bit for it to stabilize
        if timeSinceLastChange < 5.0 {
            return 5.0 - timeSinceLastChange
        }
        
        // If we have frequent changes, wait longer
        if hasFrequentConnectionChanges() {
            return 10.0
        }
        
        // If connection quality is poor, wait a bit
        if getConnectionQuality() < 0.5 {
            return 3.0
        }
        
        return 0.0 // Sync immediately
    }
    
    /// Get network statistics for debugging
    func getNetworkStats() -> NetworkStats {
        let recentEvents = connectionHistory.suffix(10)
        let recentChanges = recentEvents.count
        let averageQuality = getConnectionQuality()
        
        return NetworkStats(
            isConnected: isConnected,
            connectionType: connectionType,
            isExpensive: isExpensive,
            isConstrained: isConstrained,
            quality: averageQuality,
            recentChanges: recentChanges,
            isSuitableForSync: isSuitableForSyncing(),
            suggestedDelay: getSyncDelay()
        )
    }
}

// MARK: - Private Implementation
private extension NetworkMonitor {
    
    func handlePathUpdate(_ path: NWPath) {
        let wasConnected = isConnected
        let oldConnectionType = connectionType
        
        // Update connection status
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        connectionType = determineConnectionType(from: path)
        
        // Update subjects for Combine publishers
        isConnectedSubject.send(isConnected)
        connectionTypeSubject.send(connectionType)
        
        // Log connection changes
        let connectionChanged = wasConnected != isConnected
        let typeChanged = oldConnectionType != connectionType
        
        if connectionChanged || typeChanged {
            lastConnectionChange = Date()
            
            let event = ConnectionEvent(
                timestamp: lastConnectionChange,
                isConnected: isConnected,
                connectionType: connectionType,
                wasExpensive: isExpensive,
                wasConstrained: isConstrained
            )
            
            connectionHistory.append(event)
            
            // Keep only recent events (last 50)
            if connectionHistory.count > 50 {
                connectionHistory.removeFirst(connectionHistory.count - 50)
            }
            
            logConnectionChange(
                wasConnected: wasConnected,
                connectionChanged: connectionChanged,
                typeChanged: typeChanged
            )
        }
    }
    
    func determineConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.other) {
            return .other
        } else {
            return .unknown
        }
    }
    
    func hasFrequentConnectionChanges() -> Bool {
        let now = Date()
        let recentThreshold = now.addingTimeInterval(-60) // Last minute
        
        let recentChanges = connectionHistory.filter { $0.timestamp > recentThreshold }
        return recentChanges.count > 3 // More than 3 changes in last minute
    }
    
    func logConnectionChange(wasConnected: Bool, connectionChanged: Bool, typeChanged: Bool) {
        var logMessage = "🌐 NetworkMonitor: "
        
        if connectionChanged {
            if isConnected {
                logMessage += "Connected to \(connectionType.displayName)"
            } else {
                logMessage += "Disconnected"
            }
        } else if typeChanged {
            logMessage += "Connection type changed to \(connectionType.displayName)"
        }
        
        // Add additional info
        var details: [String] = []
        
        if isExpensive {
            details.append("expensive")
        }
        
        if isConstrained {
            details.append("constrained")
        }
        
        if !details.isEmpty {
            logMessage += " (\(details.joined(separator: ", ")))"
        }
        
        // Add quality assessment
        let quality = getConnectionQuality()
        logMessage += " - Quality: \(String(format: "%.1f", quality))"
        
        if isSuitableForSyncing() {
            logMessage += " ✅ Suitable for sync"
        } else {
            logMessage += " ❌ Not suitable for sync"
        }
        
        let suggestedDelay = getSyncDelay()
        if suggestedDelay > 0 {
            logMessage += " (delay: \(String(format: "%.1f", suggestedDelay))s)"
        }
        
        print(logMessage)
    }
}

// MARK: - Network Statistics
struct NetworkStats {
    let isConnected: Bool
    let connectionType: NetworkMonitor.ConnectionType
    let isExpensive: Bool
    let isConstrained: Bool
    let quality: Double
    let recentChanges: Int
    let isSuitableForSync: Bool
    let suggestedDelay: TimeInterval
    
    var description: String {
        var desc = "Network: "
        
        if isConnected {
            desc += "Connected via \(connectionType.displayName)"
            desc += " (Quality: \(String(format: "%.1f", quality)))"
            
            if isExpensive {
                desc += " [Expensive]"
            }
            
            if isConstrained {
                desc += " [Constrained]"
            }
            
            if recentChanges > 0 {
                desc += " [Recent changes: \(recentChanges)]"
            }
            
            if isSuitableForSync {
                desc += " ✅"
            } else {
                desc += " ⚠️"
            }
        } else {
            desc += "Disconnected ❌"
        }
        
        return desc
    }
}

// MARK: - Convenience Extensions
extension NetworkMonitor {
    
    /// Combine publisher that emits when network becomes suitable for syncing
    var syncReadyPublisher: AnyPublisher<Void, Never> {
        isConnectedPublisher
            .combineLatest(connectionTypePublisher)
            .map { [weak self] _, _ in
                self?.isSuitableForSyncing() ?? false
            }
            .removeDuplicates()
            .filter { $0 } // Only emit when suitable
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    /// Combine publisher that emits connection quality changes
    var qualityPublisher: AnyPublisher<Double, Never> {
        isConnectedPublisher
            .combineLatest(connectionTypePublisher)
            .map { [weak self] _, _ in
                self?.getConnectionQuality() ?? 0.0
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Testing Helpers
#if DEBUG
extension NetworkMonitor {
    
    /// Force a connection state for testing (DEBUG only)
    func simulateConnectionChange(isConnected: Bool, type: ConnectionType = .wifi) {
        DispatchQueue.main.async {
            self.isConnected = isConnected
            self.connectionType = type
            self.isExpensive = false
            self.isConstrained = false
            self.lastConnectionChange = Date()
            
            self.isConnectedSubject.send(isConnected)
            self.connectionTypeSubject.send(type)
            
            print("🧪 NetworkMonitor: Simulated connection change - Connected: \(isConnected), Type: \(type.displayName)")
        }
    }
    
    /// Get connection history for testing
    private var connectionEventHistory: [ConnectionEvent] {
        connectionHistory
    }
}
#endif 