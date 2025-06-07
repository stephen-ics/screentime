import Foundation
import Combine

/// Screen time balance model for Supabase backend
struct SupabaseScreenTimeBalance: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    var availableSeconds: Double
    var dailyLimitSeconds: Double
    var weeklyLimitSeconds: Double
    var lastUpdated: Date
    var isTimerActive: Bool
    var lastTimerStart: Date?
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case availableSeconds = "available_seconds"
        case dailyLimitSeconds = "daily_limit_seconds"
        case weeklyLimitSeconds = "weekly_limit_seconds"
        case lastUpdated = "last_updated"
        case isTimerActive = "is_timer_active"
        case lastTimerStart = "last_timer_start"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    var availableMinutes: Int32 {
        Int32(availableSeconds / 60)
    }
    
    var dailyLimitMinutes: Int32 {
        Int32(dailyLimitSeconds / 60)
    }
    
    var weeklyLimitMinutes: Int32 {
        Int32(weeklyLimitSeconds / 60)
    }
    
    var hasTimeRemaining: Bool {
        availableSeconds > 0
    }
    
    var formattedTimeRemaining: String {
        let totalMinutes = Int(availableSeconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return String(format: NSLocalizedString("%dh %dm remaining", comment: ""), hours, minutes)
        } else {
            return String(format: NSLocalizedString("%dm remaining", comment: ""), minutes)
        }
    }
    
    var formattedDailyLimit: String {
        let totalMinutes = Int(dailyLimitSeconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return String(format: NSLocalizedString("%dh %dm daily limit", comment: ""), hours, minutes)
        } else {
            return String(format: NSLocalizedString("%dm daily limit", comment: ""), minutes)
        }
    }
    
    var progressPercentage: Double {
        guard dailyLimitSeconds > 0 else { return 0 }
        let usedSeconds = dailyLimitSeconds - availableSeconds
        return max(0, min(1, usedSeconds / dailyLimitSeconds))
    }
    
    // MARK: - Initializers
    init(
        id: UUID = UUID(),
        userId: UUID,
        availableSeconds: Double = 0,
        dailyLimitSeconds: Double = 7200, // 2 hours default
        weeklyLimitSeconds: Double = 50400, // 14 hours default
        lastUpdated: Date = Date(),
        isTimerActive: Bool = false,
        lastTimerStart: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.availableSeconds = availableSeconds
        self.dailyLimitSeconds = dailyLimitSeconds
        self.weeklyLimitSeconds = weeklyLimitSeconds
        self.lastUpdated = lastUpdated
        self.isTimerActive = isTimerActive
        self.lastTimerStart = lastTimerStart
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        availableSeconds = try container.decode(Double.self, forKey: .availableSeconds)
        dailyLimitSeconds = try container.decode(Double.self, forKey: .dailyLimitSeconds)
        weeklyLimitSeconds = try container.decode(Double.self, forKey: .weeklyLimitSeconds)
        lastUpdated = try container.decodeDate(forKey: .lastUpdated)
        isTimerActive = try container.decode(Bool.self, forKey: .isTimerActive)
        lastTimerStart = try container.decodeDateIfPresent(forKey: .lastTimerStart)
        createdAt = try container.decodeDate(forKey: .createdAt)
        updatedAt = try container.decodeDate(forKey: .updatedAt)
    }
    
    // MARK: - Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(availableSeconds, forKey: .availableSeconds)
        try container.encode(dailyLimitSeconds, forKey: .dailyLimitSeconds)
        try container.encode(weeklyLimitSeconds, forKey: .weeklyLimitSeconds)
        try container.encodeDate(lastUpdated, forKey: .lastUpdated)
        try container.encode(isTimerActive, forKey: .isTimerActive)
        try container.encodeDateIfPresent(lastTimerStart, forKey: .lastTimerStart)
        try container.encodeDate(createdAt, forKey: .createdAt)
        try container.encodeDate(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Validation
    func validate() throws {
        guard availableSeconds >= 0 else {
            throw ValidationError.negativeBalance
        }
        
        guard dailyLimitSeconds > 0 else {
            throw ValidationError.invalidDailyLimit
        }
        
        guard weeklyLimitSeconds > 0 else {
            throw ValidationError.invalidWeeklyLimit
        }
        
        guard weeklyLimitSeconds >= dailyLimitSeconds else {
            throw ValidationError.weeklyLimitTooLow
        }
    }
    
    enum ValidationError: LocalizedError {
        case negativeBalance
        case invalidDailyLimit
        case invalidWeeklyLimit
        case weeklyLimitTooLow
        
        var errorDescription: String? {
            switch self {
            case .negativeBalance:
                return NSLocalizedString("Screen time balance cannot be negative", comment: "")
            case .invalidDailyLimit:
                return NSLocalizedString("Daily limit must be greater than 0", comment: "")
            case .invalidWeeklyLimit:
                return NSLocalizedString("Weekly limit must be greater than 0", comment: "")
            case .weeklyLimitTooLow:
                return NSLocalizedString("Weekly limit must be at least as large as daily limit", comment: "")
            }
        }
    }
    
    // MARK: - Time Management Methods
    mutating func addTime(_ seconds: Double) {
        availableSeconds += seconds
        lastUpdated = Date()
        updatedAt = Date()
    }
    
    mutating func addMinutes(_ minutes: Int32) {
        addTime(Double(minutes * 60))
    }
    
    mutating func decrementTime(_ seconds: Double) {
        availableSeconds = max(0, availableSeconds - seconds)
        lastUpdated = Date()
        updatedAt = Date()
    }
    
    mutating func resetDaily() {
        availableSeconds = dailyLimitSeconds
        lastUpdated = Date()
        updatedAt = Date()
    }
    
    mutating func startTimer() {
        guard !isTimerActive else { return }
        isTimerActive = true
        lastTimerStart = Date()
        updatedAt = Date()
    }
    
    mutating func stopTimer() {
        isTimerActive = false
        lastTimerStart = nil
        updatedAt = Date()
    }
    
    mutating func setDailyLimit(minutes: Int32) {
        dailyLimitSeconds = Double(minutes * 60)
        updatedAt = Date()
    }
    
    mutating func setWeeklyLimit(minutes: Int32) {
        weeklyLimitSeconds = Double(minutes * 60)
        updatedAt = Date()
    }
}

// MARK: - Hashable
extension SupabaseScreenTimeBalance {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Equatable
extension SupabaseScreenTimeBalance {
    static func == (lhs: SupabaseScreenTimeBalance, rhs: SupabaseScreenTimeBalance) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Mock Data
extension SupabaseScreenTimeBalance {
    static func mock(
        userId: UUID = UUID(),
        availableMinutes: Int32 = 60,
        dailyLimitMinutes: Int32 = 120
    ) -> SupabaseScreenTimeBalance {
        SupabaseScreenTimeBalance(
            userId: userId,
            availableSeconds: Double(availableMinutes * 60),
            dailyLimitSeconds: Double(dailyLimitMinutes * 60)
        )
    }
    
    static let mockBalance = SupabaseScreenTimeBalance(
        userId: UUID(),
        availableSeconds: 3600, // 1 hour
        dailyLimitSeconds: 7200 // 2 hours
    )
}

// MARK: - Timer Notifications (for compatibility)
extension SupabaseScreenTimeBalance {
    var screenTimeExhaustedNotification: Notification.Name {
        Notification.Name("screenTimeExhausted")
    }
    
    var screenTimeLowNotification: Notification.Name {
        Notification.Name("screenTimeLow")
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
    
    func decodeDateIfPresent(forKey key: Key) throws -> Date? {
        if let dateString = try? decodeIfPresent(String.self, forKey: key) {
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
        
        return try decodeIfPresent(Date.self, forKey: key)
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeDate(_ date: Date, forKey key: Key) throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)
        try encode(dateString, forKey: key)
    }
    
    mutating func encodeDateIfPresent(_ date: Date?, forKey key: Key) throws {
        guard let date = date else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)
        try encode(dateString, forKey: key)
    }
} 