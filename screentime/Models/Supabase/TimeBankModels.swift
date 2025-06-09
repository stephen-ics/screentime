import Foundation

// MARK: - Time Bank Models

/// Central time balance for each user - the core of the system
struct TimeBank: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    var currentBalanceSeconds: Int64
    var lifetimeEarnedSeconds: Int64
    var lifetimeSpentSeconds: Int64
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentBalanceSeconds = "current_balance_seconds"
        case lifetimeEarnedSeconds = "lifetime_earned_seconds"
        case lifetimeSpentSeconds = "lifetime_spent_seconds"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    var currentBalanceMinutes: Int {
        Int(currentBalanceSeconds / 60)
    }
    
    var lifetimeEarnedMinutes: Int {
        Int(lifetimeEarnedSeconds / 60)
    }
    
    var lifetimeSpentMinutes: Int {
        Int(lifetimeSpentSeconds / 60)
    }
    
    var formattedBalance: String {
        TimeFormatter.shared.formatDuration(seconds: currentBalanceSeconds)
    }
    
    var formattedLifetimeEarned: String {
        TimeFormatter.shared.formatDuration(seconds: lifetimeEarnedSeconds)
    }
    
    var formattedLifetimeSpent: String {
        TimeFormatter.shared.formatDuration(seconds: lifetimeSpentSeconds)
    }
    
    var canAfford: (Int) -> Bool {
        { minutes in currentBalanceSeconds >= Int64(minutes * 60) }
    }
    
    // MARK: - Static Factory Methods
    static func empty(userId: UUID) -> TimeBank {
        TimeBank(
            id: UUID(),
            userId: userId,
            currentBalanceSeconds: 0,
            lifetimeEarnedSeconds: 0,
            lifetimeSpentSeconds: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

/// Immutable audit log of all time bank transactions
struct TimeLedgerEntry: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let transactionType: TransactionType
    let secondsDelta: Int64 // Positive for earning, negative for spending
    let balanceAfterSeconds: Int64
    let description: String
    let metadata: [String: String]
    let source: TransactionSource
    let createdAt: Date
    let createdBy: UUID?
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case transactionType = "transaction_type"
        case secondsDelta = "seconds_delta"
        case balanceAfterSeconds = "balance_after_seconds"
        case description
        case metadata
        case source
        case createdAt = "created_at"
        case createdBy = "created_by"
    }
    
    // MARK: - Enums
    enum TransactionType: String, Codable, CaseIterable {
        case earn = "earn"
        case spend = "spend"
        case adjustment = "adjustment"
        
        var displayName: String {
            switch self {
            case .earn: return NSLocalizedString("Earned", comment: "")
            case .spend: return NSLocalizedString("Spent", comment: "")
            case .adjustment: return NSLocalizedString("Adjustment", comment: "")
            }
        }
        
        var systemImageName: String {
            switch self {
            case .earn: return "plus.circle.fill"
            case .spend: return "minus.circle.fill"
            case .adjustment: return "slider.horizontal.3"
            }
        }
        
        var color: String {
            switch self {
            case .earn: return "green"
            case .spend: return "red"
            case .adjustment: return "blue"
            }
        }
    }
    
    enum TransactionSource: String, Codable, CaseIterable {
        case taskCompletion = "task_completion"
        case unlockedSession = "unlocked_session"
        case parentGrant = "parent_grant"
        case adminAdjustment = "admin_adjustment"
        
        var displayName: String {
            switch self {
            case .taskCompletion: return NSLocalizedString("Task Completed", comment: "")
            case .unlockedSession: return NSLocalizedString("Unlocked Session", comment: "")
            case .parentGrant: return NSLocalizedString("Parent Grant", comment: "")
            case .adminAdjustment: return NSLocalizedString("Adjustment", comment: "")
            }
        }
    }
    
    // MARK: - Computed Properties
    var formattedAmount: String {
        let absSeconds = abs(secondsDelta)
        let sign = secondsDelta >= 0 ? "+" : "-"
        return "\(sign)\(TimeFormatter.shared.formatDuration(seconds: absSeconds))"
    }
    
    var balanceAfterFormatted: String {
        TimeFormatter.shared.formatDuration(seconds: balanceAfterSeconds)
    }
    
    var isPositive: Bool {
        secondsDelta > 0
    }
    
    // MARK: - Custom Decoder for Metadata
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        transactionType = try container.decode(TransactionType.self, forKey: .transactionType)
        secondsDelta = try container.decode(Int64.self, forKey: .secondsDelta)
        balanceAfterSeconds = try container.decode(Int64.self, forKey: .balanceAfterSeconds)
        description = try container.decode(String.self, forKey: .description)
        source = try container.decode(TransactionSource.self, forKey: .source)
        createdAt = try container.decodeDate(forKey: .createdAt)
        createdBy = try container.decodeIfPresent(UUID.self, forKey: .createdBy)
        
        // Handle JSONB metadata - simplified to String values
        if let metadataDict = try container.decodeIfPresent([String: String].self, forKey: .metadata) {
            self.metadata = metadataDict
        } else {
            self.metadata = [:]
        }
    }
}

/// Active unlocked sessions where all apps are accessible
struct UnlockedSession: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let durationSeconds: Int
    let costSeconds: Int
    let startedAt: Date
    let endsAt: Date
    var status: SessionStatus
    let deviceIdentifier: String?
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case durationSeconds = "duration_seconds"
        case costSeconds = "cost_seconds"
        case startedAt = "started_at"
        case endsAt = "ends_at"
        case status
        case deviceIdentifier = "device_identifier"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    enum SessionStatus: String, Codable, CaseIterable {
        case active = "active"
        case expired = "expired"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .active: return NSLocalizedString("Active", comment: "")
            case .expired: return NSLocalizedString("Expired", comment: "")
            case .cancelled: return NSLocalizedString("Cancelled", comment: "")
            }
        }
        
        var systemImageName: String {
            switch self {
            case .active: return "play.circle.fill"
            case .expired: return "clock.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
    }
    
    // MARK: - Computed Properties
    var isActive: Bool {
        status == .active && endsAt > Date()
    }
    
    var timeRemaining: TimeInterval {
        max(0, endsAt.timeIntervalSinceNow)
    }
    
    var timeRemainingFormatted: String {
        guard isActive else { return "00:00" }
        let remaining = Int(timeRemaining)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var durationMinutes: Int {
        durationSeconds / 60
    }
    
    var formattedDuration: String {
        TimeFormatter.shared.formatDuration(seconds: Int64(durationSeconds))
    }
    
    var progressPercentage: Double {
        let totalDuration = endsAt.timeIntervalSince(startedAt)
        let elapsed = Date().timeIntervalSince(startedAt)
        return min(1.0, max(0.0, elapsed / totalDuration))
    }
    
    // MARK: - Initializers
    init(
        id: UUID,
        userId: UUID,
        durationSeconds: Int,
        costSeconds: Int,
        startedAt: Date,
        endsAt: Date,
        status: SessionStatus,
        deviceIdentifier: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.durationSeconds = durationSeconds
        self.costSeconds = costSeconds
        self.startedAt = startedAt
        self.endsAt = endsAt
        self.status = status
        self.deviceIdentifier = deviceIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        costSeconds = try container.decode(Int.self, forKey: .costSeconds)
        startedAt = try container.decodeDate(forKey: .startedAt)
        endsAt = try container.decodeDate(forKey: .endsAt)
        status = try container.decode(SessionStatus.self, forKey: .status)
        deviceIdentifier = try container.decodeIfPresent(String.self, forKey: .deviceIdentifier)
        createdAt = try container.decodeDate(forKey: .createdAt)
        updatedAt = try container.decodeDate(forKey: .updatedAt)
    }
}

/// Task that can be completed to earn time
struct TimeBankTask: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    var title: String
    var taskDescription: String?
    var rewardSeconds: Int
    var completedAt: Date?
    var isApproved: Bool
    var isRecurring: Bool
    var recurringFrequency: RecurringFrequency?
    let assignedTo: UUID
    let createdBy: UUID
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case title
        case taskDescription = "task_description"
        case rewardSeconds = "reward_seconds"
        case completedAt = "completed_at"
        case isApproved = "is_approved"
        case isRecurring = "is_recurring"
        case recurringFrequency = "recurring_frequency"
        case assignedTo = "assigned_to"
        case createdBy = "created_by"
    }
    
    enum RecurringFrequency: String, Codable, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        
        var displayName: String {
            switch self {
            case .daily: return NSLocalizedString("Daily", comment: "")
            case .weekly: return NSLocalizedString("Weekly", comment: "")
            case .monthly: return NSLocalizedString("Monthly", comment: "")
            }
        }
    }
    
    // MARK: - Computed Properties
    var rewardMinutes: Int {
        rewardSeconds / 60
    }
    
    var formattedReward: String {
        TimeFormatter.shared.formatDuration(seconds: Int64(rewardSeconds))
    }
    
    var isCompleted: Bool {
        completedAt != nil
    }
    
    var isPendingApproval: Bool {
        isCompleted && !isApproved
    }
    
    var canBeCompleted: Bool {
        !isCompleted
    }
    
    var statusDescription: String {
        if !isCompleted {
            return NSLocalizedString("Pending", comment: "")
        } else if !isApproved {
            return NSLocalizedString("Awaiting Approval", comment: "")
        } else {
            return NSLocalizedString("Completed", comment: "")
        }
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decodeDate(forKey: .createdAt)
        updatedAt = try container.decodeDate(forKey: .updatedAt)
        title = try container.decode(String.self, forKey: .title)
        taskDescription = try container.decodeIfPresent(String.self, forKey: .taskDescription)
        rewardSeconds = try container.decode(Int.self, forKey: .rewardSeconds)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        isApproved = try container.decode(Bool.self, forKey: .isApproved)
        isRecurring = try container.decode(Bool.self, forKey: .isRecurring)
        recurringFrequency = try container.decodeIfPresent(RecurringFrequency.self, forKey: .recurringFrequency)
        assignedTo = try container.decode(UUID.self, forKey: .assignedTo)
        createdBy = try container.decode(UUID.self, forKey: .createdBy)
    }
}

/// Simplified approved app (no per-app limits)
struct TimeBankApprovedApp: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    var name: String
    var bundleIdentifier: String
    var isEnabled: Bool
    let userId: UUID
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case name
        case bundleIdentifier = "bundle_identifier"
        case isEnabled = "is_enabled"
        case userId = "user_id"
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        name.isEmpty ? bundleIdentifier : name
    }
    
    var statusDescription: String {
        isEnabled ? NSLocalizedString("Enabled", comment: "") : NSLocalizedString("Disabled", comment: "")
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decodeDate(forKey: .createdAt)
        updatedAt = try container.decodeDate(forKey: .updatedAt)
        name = try container.decode(String.self, forKey: .name)
        bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        userId = try container.decode(UUID.self, forKey: .userId)
    }
}

/// Offline transaction to be synced with server
struct PendingTransaction: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let transactionType: TransactionType
    let secondsDelta: Int64
    let description: String
    let metadata: [String: String]
    let source: TransactionSource
    let clientTimestamp: Date
    let deviceIdentifier: String?
    var processedAt: Date?
    let createdAt: Date
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case transactionType = "transaction_type"
        case secondsDelta = "seconds_delta"
        case description
        case metadata
        case source
        case clientTimestamp = "client_timestamp"
        case deviceIdentifier = "device_identifier"
        case processedAt = "processed_at"
        case createdAt = "created_at"
    }
    
    // MARK: - Type Aliases for Consistency
    typealias TransactionType = TimeLedgerEntry.TransactionType
    typealias TransactionSource = TimeLedgerEntry.TransactionSource
    
    // MARK: - Computed Properties
    var isProcessed: Bool {
        processedAt != nil
    }
    
    var formattedAmount: String {
        let absSeconds = abs(secondsDelta)
        let sign = secondsDelta >= 0 ? "+" : "-"
        return "\(sign)\(TimeFormatter.shared.formatDuration(seconds: absSeconds))"
    }
    
    // MARK: - Initializers
    init(
        id: UUID = UUID(),
        userId: UUID,
        transactionType: TransactionType,
        secondsDelta: Int64,
        description: String,
        metadata: [String: String] = [:],
        source: TransactionSource,
        deviceIdentifier: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.transactionType = transactionType
        self.secondsDelta = secondsDelta
        self.description = description
        self.metadata = metadata
        self.source = source
        self.clientTimestamp = Date()
        self.deviceIdentifier = deviceIdentifier
        self.processedAt = nil
        self.createdAt = Date()
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        transactionType = try container.decode(TransactionType.self, forKey: .transactionType)
        secondsDelta = try container.decode(Int64.self, forKey: .secondsDelta)
        description = try container.decode(String.self, forKey: .description)
        source = try container.decode(TransactionSource.self, forKey: .source)
        clientTimestamp = try container.decodeDate(forKey: .clientTimestamp)
        deviceIdentifier = try container.decodeIfPresent(String.self, forKey: .deviceIdentifier)
        processedAt = try container.decodeIfPresent(Date.self, forKey: .processedAt)
        createdAt = try container.decodeDate(forKey: .createdAt)
        
        // Handle metadata - simplified to String values
        if let metadataDict = try container.decodeIfPresent([String: String].self, forKey: .metadata) {
            self.metadata = metadataDict
        } else {
            self.metadata = [:]
        }
    }
}

// MARK: - Time Formatter Utility
final class TimeFormatter {
    static let shared = TimeFormatter()
    
    private init() {}
    
    func formatDuration(seconds: Int64) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return String(format: NSLocalizedString("%dh %dm", comment: ""), hours, minutes)
        } else {
            return String(format: NSLocalizedString("%dm", comment: ""), minutes)
        }
    }
    
    func formatCountdown(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Date Coding Helpers
private extension KeyedDecodingContainer {
    func decodeDate(forKey key: Key) throws -> Date {
        if let dateString = try? decode(String.self, forKey: key) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return try decode(Date.self, forKey: key)
    }
} 