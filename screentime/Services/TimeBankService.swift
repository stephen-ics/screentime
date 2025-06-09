import Foundation
import Combine
import Network
import UIKit
#if canImport(Supabase)
import Supabase
#endif

/// Central service for managing the Time Bank system with offline capabilities
@MainActor
final class TimeBankService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = TimeBankService()
    
    // MARK: - Published Properties
    @Published private(set) var currentBalance: TimeBank?
    @Published private(set) var activeSession: UnlockedSession?
    @Published private(set) var isOnline: Bool = false
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var pendingTransactionCount: Int = 0
    @Published private(set) var recentTransactions: [TimeLedgerEntry] = []
    @Published private(set) var availableTasks: [TimeBankTask] = []
    
    // MARK: - Private Properties
    private let supabaseManager = SupabaseManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    private var cancellables = Set<AnyCancellable>()
    private var sessionTimer: Timer?
    
    // Offline storage
    private var pendingTransactions: [PendingTransaction] = []
    private let pendingTransactionsKey = "TimeBankPendingTransactions"
    private let cachedBalanceKey = "TimeBankCachedBalance"
    
    // MARK: - Error Types
    enum TimeBankError: LocalizedError {
        case insufficientBalance(required: Int, available: Int)
        case activeSessionExists
        case noActiveSession
        case networkUnavailable
        case syncFailed(String)
        case invalidTransaction
        
        var errorDescription: String? {
            switch self {
            case .insufficientBalance(let required, let available):
                return NSLocalizedString("Insufficient time balance. Required: \(required)m, Available: \(available)m", comment: "")
            case .activeSessionExists:
                return NSLocalizedString("An active session is already running", comment: "")
            case .noActiveSession:
                return NSLocalizedString("No active session found", comment: "")
            case .networkUnavailable:
                return NSLocalizedString("Network connection unavailable", comment: "")
            case .syncFailed(let message):
                return NSLocalizedString("Sync failed: \(message)", comment: "")
            case .invalidTransaction:
                return NSLocalizedString("Invalid transaction", comment: "")
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        setupNetworkMonitoring()
        loadCachedData()
        setupTimers()
        
        // Load initial data
        Task {
            await refreshData()
        }
    }
    
    // MARK: - Public API
    
    /// Start an unlocked session, spending time from the bank
    func startUnlockedSession(durationMinutes: Int) async throws -> UnlockedSession {
        print("🔓 Starting unlocked session for \(durationMinutes) minutes")
        
        // Check for existing active session
        if let existing = activeSession, existing.isActive {
            throw TimeBankError.activeSessionExists
        }
        
        // Check balance
        guard let balance = currentBalance else {
            throw TimeBankError.networkUnavailable
        }
        
        let requiredSeconds = Int64(durationMinutes * 60)
        if balance.currentBalanceSeconds < requiredSeconds {
            throw TimeBankError.insufficientBalance(
                required: durationMinutes,
                available: balance.currentBalanceMinutes
            )
        }
        
        // If online, attempt immediate server transaction
        if isOnline {
            return try await startUnlockedSessionOnline(durationMinutes: durationMinutes)
        } else {
            return try await startUnlockedSessionOffline(durationMinutes: durationMinutes)
        }
    }
    
    /// Get current balance (cached or live)
    func getCurrentBalance() async -> TimeBank? {
        if isOnline {
            await refreshBalance()
        }
        return currentBalance
    }
    
    /// Manually trigger a sync with the server
    func forceSyncWithServer() async throws {
        guard isOnline else {
            throw TimeBankError.networkUnavailable
        }
        
        await performSync()
    }
    
    /// Check if the user can afford a specific duration
    func canAfford(minutes: Int) -> Bool {
        guard let balance = currentBalance else { return false }
        return balance.canAfford(minutes)
    }
    
    /// Get time remaining in current session
    func getTimeRemainingInSession() -> TimeInterval {
        activeSession?.timeRemaining ?? 0
    }
    
    /// Cancel active session (returns unused time to bank)
    func cancelActiveSession() async throws {
        guard let session = activeSession, session.isActive else {
            throw TimeBankError.noActiveSession
        }
        
        let remainingMinutes = Int(session.timeRemaining / 60)
        
        if isOnline {
            try await cancelSessionOnline(session: session, remainingMinutes: remainingMinutes)
        } else {
            try await cancelSessionOffline(session: session, remainingMinutes: remainingMinutes)
        }
    }
    
    /// Complete a task (marks it as completed, pending parent approval)
    func completeTask(_ task: TimeBankTask) async throws {
        print("✅ Completing task: \(task.title)")
        
        if isOnline {
            try await completeTaskOnline(task)
        } else {
            // Tasks require parent approval, so we can't complete them offline
            // Just show a message to the user
            throw TimeBankError.networkUnavailable
        }
    }
    
    /// Load tasks available for completion
    func loadAvailableTasks() async {
        guard isOnline else { return }
        
        do {
            await refreshTasks()
        } catch {
            print("❌ Failed to load tasks: \(error)")
        }
    }
    
    /// Get transaction history
    func getTransactionHistory(limit: Int = 50) async -> [TimeLedgerEntry] {
        if isOnline {
            await refreshTransactionHistory(limit: limit)
        }
        return recentTransactions
    }
}

// MARK: - Private Implementation
private extension TimeBankService {
    
    // MARK: - Network Monitoring
    func setupNetworkMonitoring() {
        networkMonitor.isConnectedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOnline = isConnected
                if isConnected {
                    Task { @MainActor in
                        await self?.onNetworkReconnected()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func onNetworkReconnected() async {
        print("🌐 Network reconnected - triggering sync")
        await performSync()
    }
    
    // MARK: - Data Loading and Caching
    func loadCachedData() {
        // Load cached balance
        if let data = UserDefaults.standard.data(forKey: cachedBalanceKey),
           let balance = try? JSONDecoder().decode(TimeBank.self, from: data) {
            currentBalance = balance
        }
        
        // Load pending transactions
        loadPendingTransactionsFromDisk()
        pendingTransactionCount = pendingTransactions.count
    }
    
    func cacheBalance(_ balance: TimeBank) {
        currentBalance = balance
        if let data = try? JSONEncoder().encode(balance) {
            UserDefaults.standard.set(data, forKey: cachedBalanceKey)
        }
    }
    
    // MARK: - Offline Transaction Queue Management
    func loadPendingTransactionsFromDisk() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let queueURL = documentsPath.appendingPathComponent("pending_transactions.json")
        
        do {
            let data = try Data(contentsOf: queueURL)
            pendingTransactions = try JSONDecoder().decode([PendingTransaction].self, from: data)
            print("📱 Loaded \(pendingTransactions.count) pending transactions from disk")
        } catch {
            print("📱 No pending transactions file found or failed to load: \(error)")
            pendingTransactions = []
        }
    }
    
    func savePendingTransactionsToDisk() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let queueURL = documentsPath.appendingPathComponent("pending_transactions.json")
        
        do {
            let data = try JSONEncoder().encode(pendingTransactions)
            try data.write(to: queueURL)
            pendingTransactionCount = pendingTransactions.count
            print("💾 Saved \(pendingTransactions.count) pending transactions to disk")
        } catch {
            print("❌ Failed to save pending transactions: \(error)")
        }
    }
    
    func addPendingTransaction(_ transaction: PendingTransaction) {
        pendingTransactions.append(transaction)
        savePendingTransactionsToDisk()
        
        // Update local cache immediately for UI responsiveness
        updateLocalBalanceForTransaction(transaction)
    }
    
    func updateLocalBalanceForTransaction(_ transaction: PendingTransaction) {
        guard var balance = currentBalance else { return }
        
        // Apply the transaction to local cache
        balance.currentBalanceSeconds += transaction.secondsDelta
        
        if transaction.secondsDelta > 0 {
            balance.lifetimeEarnedSeconds += transaction.secondsDelta
        } else {
            balance.lifetimeSpentSeconds += abs(transaction.secondsDelta)
        }
        
        balance.updatedAt = Date()
        cacheBalance(balance)
    }
    
    // MARK: - Sync Operations
    func performSync() async {
        guard isOnline else { return }
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        print("🔄 Starting sync with server...")
        
        do {
            // First, process offline transactions
            try await processOfflineTransactions()
            
            // Then refresh all data
            await refreshData()
            
            print("✅ Sync completed successfully")
        } catch {
            print("❌ Sync failed: \(error)")
        }
    }
    
    func processOfflineTransactions() async throws {
        guard !pendingTransactions.isEmpty else { return }
        
        #if canImport(Supabase)
        guard let supabase = supabaseManager.client else {
            throw TimeBankError.syncFailed("Supabase client unavailable")
        }
        
        print("📤 Processing \(pendingTransactions.count) offline transactions")
        
        for transaction in pendingTransactions {
            do {
                // Add to server queue for processing
                try await supabase
                    .from("offline_transaction_queue")
                    .insert(transaction)
                    .execute()
                    
                print("✅ Queued transaction: \(transaction.description)")
            } catch {
                print("❌ Failed to queue transaction: \(error)")
                // Continue with other transactions
            }
        }
        
        // Clear local queue after successful upload
        pendingTransactions.removeAll()
        savePendingTransactionsToDisk()
        
        // Trigger server-side processing
        guard let currentUserId = try? await supabase.auth.session.user.id else { return }
        
        let result = try await supabase.rpc(
            "process_offline_transactions", 
            params: ["p_user_id": currentUserId.uuidString]
        ).execute()
        
        print("🔄 Server processed transactions: \(result)")
        #endif
    }
    
    // MARK: - Online Operations
    func startUnlockedSessionOnline(durationMinutes: Int) async throws -> UnlockedSession {
        #if canImport(Supabase)
        guard let supabase = supabaseManager.client else {
            throw TimeBankError.networkUnavailable
        }
        
        guard let currentUserId = try? await supabase.auth.session.user.id else {
            throw TimeBankError.networkUnavailable
        }
        
        let result = try await supabase.rpc(
            "start_unlocked_session",
            params: [
                "p_user_id": currentUserId.uuidString,
                "p_duration_minutes": "\(durationMinutes)",
                "p_device_identifier": deviceId
            ]
        ).execute()
        
        // Parse the returned session data
        // For now, create session locally - would need to parse actual response in production
        let sessionId = UUID()
        let endsAt = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        
        // Create session object
        let session = UnlockedSession(
            id: sessionId,
            userId: currentUserId,
            durationSeconds: durationMinutes * 60,
            costSeconds: durationMinutes * 60,
            startedAt: Date(),
            endsAt: endsAt,
            status: .active,
            deviceIdentifier: deviceId,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        activeSession = session
        
        // Update cached balance - deduct the spent time
        if var balance = currentBalance {
            balance.currentBalanceSeconds -= Int64(durationMinutes * 60)
            cacheBalance(balance)
        }
        
        // Start session monitoring
        startSessionTimer()
        
        return session
        #else
        throw TimeBankError.networkUnavailable
        #endif
    }
    
    func startUnlockedSessionOffline(durationMinutes: Int) async throws -> UnlockedSession {
        guard let currentUserId = currentBalance?.userId else {
            throw TimeBankError.invalidTransaction
        }
        
        let sessionId = UUID()
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
        
        // Create offline session
        let session = UnlockedSession(
            id: sessionId,
            userId: currentUserId,
            durationSeconds: durationMinutes * 60,
            costSeconds: durationMinutes * 60,
            startedAt: startTime,
            endsAt: endTime,
            status: .active,
            deviceIdentifier: deviceId,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        activeSession = session
        
        // Create pending transaction
        let transaction = PendingTransaction(
            userId: currentUserId,
            transactionType: .spend,
            secondsDelta: -Int64(durationMinutes * 60),
            description: "Started \(durationMinutes) minute unlocked session (offline)",
            metadata: [
                "session_id": sessionId.uuidString,
                "duration_minutes": "\(durationMinutes)",
                "device_identifier": deviceId
            ],
            source: .unlockedSession,
            deviceIdentifier: deviceId
        )
        
        addPendingTransaction(transaction)
        startSessionTimer()
        
        return session
    }
    
    func cancelSessionOnline(session: UnlockedSession, remainingMinutes: Int) async throws {
        // Implementation for online session cancellation with refund
        // This would involve calling a server function to cancel the session
        // and refund the unused time
    }
    
    func cancelSessionOffline(session: UnlockedSession, remainingMinutes: Int) async throws {
        guard let currentUserId = currentBalance?.userId else { return }
        
        // Create refund transaction
        let refundTransaction = PendingTransaction(
            userId: currentUserId,
            transactionType: .earn,
            secondsDelta: Int64(remainingMinutes * 60),
            description: "Refund from cancelled session (\(remainingMinutes)m remaining)",
            metadata: [
                "session_id": session.id.uuidString,
                "refund_minutes": "\(remainingMinutes)"
            ],
            source: .adminAdjustment,
            deviceIdentifier: deviceId
        )
        
        addPendingTransaction(refundTransaction)
        
        // Mark session as cancelled
        activeSession = nil
        stopSessionTimer()
    }
    
    func completeTaskOnline(_ task: TimeBankTask) async throws {
        #if canImport(Supabase)
        guard let supabase = supabaseManager.client else {
            throw TimeBankError.networkUnavailable
        }
        
        // Mark task as completed
        try await supabase
            .from("tasks")
            .update(["completed_at": Date().ISO8601Format()])
            .eq("id", value: task.id)
            .execute()
        
        await refreshTasks()
        #endif
    }
    
    // MARK: - Data Refresh Operations
    func refreshData() async {
        async let balanceTask = refreshBalance()
        async let sessionTask = refreshActiveSession()
        async let transactionTask = refreshTransactionHistory()
        async let taskTask = refreshTasks()
        
        await balanceTask
        await sessionTask
        await transactionTask
        await taskTask
    }
    
    func refreshBalance() async {
        #if canImport(Supabase)
        guard let supabase = supabaseManager.client else { return }
        
        do {
            guard let currentUserId = try? await supabase.auth.session.user.id else { return }
            
            let result: [TimeBank] = try await supabase
                .from("time_banks")
                .select()
                .eq("user_id", value: currentUserId)
                .execute()
                .value
            
            if let balance = result.first {
                cacheBalance(balance)
            }
        } catch {
            print("❌ Failed to refresh balance: \(error)")
        }
        #endif
    }
    
    func refreshActiveSession() async {
        #if canImport(Supabase)
        guard let supabase = supabaseManager.client else { return }
        
        do {
            guard let currentUserId = try? await supabase.auth.session.user.id else { return }
            
            let result: [UnlockedSession] = try await supabase
                .from("unlocked_sessions")
                .select()
                .eq("user_id", value: currentUserId)
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            activeSession = result.first
            
            if activeSession?.isActive == true {
                startSessionTimer()
            }
        } catch {
            print("❌ Failed to refresh active session: \(error)")
        }
        #endif
    }
    
    func refreshTransactionHistory(limit: Int = 50) async {
        #if canImport(Supabase)
        guard let supabase = supabaseManager.client else { return }
        
        do {
            guard let currentUserId = try? await supabase.auth.session.user.id else { return }
            
            let result: [TimeLedgerEntry] = try await supabase
                .from("time_ledger_entries")
                .select()
                .eq("user_id", value: currentUserId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            recentTransactions = result
        } catch {
            print("❌ Failed to refresh transaction history: \(error)")
        }
        #endif
    }
    
    func refreshTasks() async {
        #if canImport(Supabase)
        guard let supabase = supabaseManager.client else { return }
        
        do {
            guard let currentUserId = try? await supabase.auth.session.user.id else { return }
            
            let result: [TimeBankTask] = try await supabase
                .from("tasks")
                .select()
                .eq("assigned_to", value: currentUserId)
                .eq("is_approved", value: false)
                .is("completed_at", value: nil)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            availableTasks = result
        } catch {
            print("❌ Failed to refresh tasks: \(error)")
        }
        #endif
    }
    
    // MARK: - Session Timer Management
    func setupTimers() {
        // Set up any recurring timers needed
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkSessionExpiry()
            }
        }
    }
    
    func startSessionTimer() {
        stopSessionTimer()
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateSessionProgress()
            }
        }
    }
    
    func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    func updateSessionProgress() async {
        guard let session = activeSession else {
            stopSessionTimer()
            return
        }
        
        if !session.isActive {
            activeSession = nil
            stopSessionTimer()
        }
    }
    
    func checkSessionExpiry() async {
        guard let session = activeSession else { return }
        
        if !session.isActive {
            activeSession = nil
            stopSessionTimer()
            
            // Notify FamilyControls to re-enable restrictions
            await notifySessionEnded()
        }
    }
    
    func notifySessionEnded() async {
        // This would integrate with FamilyControls to re-enable app restrictions
        NotificationCenter.default.post(name: .sessionEnded, object: nil)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let sessionStarted = Notification.Name("TimeBankSessionStarted")
    static let sessionEnded = Notification.Name("TimeBankSessionEnded")
    static let balanceUpdated = Notification.Name("TimeBankBalanceUpdated")
} 