import Foundation

/// Task model for Supabase backend
struct SupabaseTask: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    var title: String
    var taskDescription: String?
    var rewardSeconds: Double
    var completedAt: Date?
    var isApproved: Bool
    var isRecurring: Bool
    var recurringFrequency: RecurringFrequency?
    var assignedTo: UUID?
    var createdBy: UUID?
    
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
    
    // MARK: - Recurring Frequency
    enum RecurringFrequency: String, Codable, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        
        var displayName: String {
            switch self {
            case .daily:
                return NSLocalizedString("Daily", comment: "")
            case .weekly:
                return NSLocalizedString("Weekly", comment: "")
            case .monthly:
                return NSLocalizedString("Monthly", comment: "")
            }
        }
    }
    
    // MARK: - Computed Properties
    var isCompleted: Bool {
        completedAt != nil
    }
    
    var rewardMinutes: Int32 {
        Int32(rewardSeconds / 60)
    }
    
    var formattedReward: String {
        let minutes = Int(rewardSeconds / 60)
        let seconds = Int(rewardSeconds.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return String(format: NSLocalizedString("%dm %ds", comment: ""), minutes, seconds)
        } else {
            return String(format: NSLocalizedString("%ds", comment: ""), seconds)
        }
    }
    
    var statusDescription: String {
        if isCompleted {
            return isApproved ? "Completed & Approved" : "Completed (Pending Approval)"
        } else {
            return "In Progress"
        }
    }
    
    // MARK: - Initializers
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        title: String,
        taskDescription: String? = nil,
        rewardSeconds: Double = 0,
        completedAt: Date? = nil,
        isApproved: Bool = false,
        isRecurring: Bool = false,
        recurringFrequency: RecurringFrequency? = nil,
        assignedTo: UUID? = nil,
        createdBy: UUID? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.taskDescription = taskDescription
        self.rewardSeconds = rewardSeconds
        self.completedAt = completedAt
        self.isApproved = isApproved
        self.isRecurring = isRecurring
        self.recurringFrequency = recurringFrequency
        self.assignedTo = assignedTo
        self.createdBy = createdBy
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decodeDate(forKey: .createdAt)
        updatedAt = try container.decodeDate(forKey: .updatedAt)
        title = try container.decode(String.self, forKey: .title)
        
        // Handle optional string that might be empty
        let taskDescriptionString = try container.decodeIfPresent(String.self, forKey: .taskDescription)
        taskDescription = taskDescriptionString?.isEmpty == true ? nil : taskDescriptionString
        
        rewardSeconds = try container.decode(Double.self, forKey: .rewardSeconds)
        completedAt = try container.decodeDateIfPresent(forKey: .completedAt)
        isApproved = try container.decode(Bool.self, forKey: .isApproved)
        isRecurring = try container.decode(Bool.self, forKey: .isRecurring)
        
        // Handle optional enum that might be empty string
        let recurringFrequencyString = try container.decodeIfPresent(String.self, forKey: .recurringFrequency)
        if let freqString = recurringFrequencyString, !freqString.isEmpty {
            recurringFrequency = RecurringFrequency(rawValue: freqString)
        } else {
            recurringFrequency = nil
        }
        
        assignedTo = try container.decodeIfPresent(UUID.self, forKey: .assignedTo)
        createdBy = try container.decodeIfPresent(UUID.self, forKey: .createdBy)
    }
    
    // MARK: - Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeDate(createdAt, forKey: .createdAt)
        try container.encodeDate(updatedAt, forKey: .updatedAt)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(taskDescription, forKey: .taskDescription)
        try container.encode(rewardSeconds, forKey: .rewardSeconds)
        try container.encodeDateIfPresent(completedAt, forKey: .completedAt)
        try container.encode(isApproved, forKey: .isApproved)
        try container.encode(isRecurring, forKey: .isRecurring)
        try container.encodeIfPresent(recurringFrequency, forKey: .recurringFrequency)
        try container.encodeIfPresent(assignedTo, forKey: .assignedTo)
        try container.encodeIfPresent(createdBy, forKey: .createdBy)
    }
    
    // MARK: - Validation
    func validate() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyTitle
        }
        
        guard title.count <= 200 else {
            throw ValidationError.titleTooLong
        }
        
        guard rewardSeconds >= 0 else {
            throw ValidationError.invalidRewardTime
        }
        
        if isRecurring && recurringFrequency == nil {
            throw ValidationError.missingRecurringFrequency
        }
    }
    
    enum ValidationError: LocalizedError {
        case emptyTitle
        case titleTooLong
        case invalidRewardTime
        case missingRecurringFrequency
        
        var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return NSLocalizedString("Task title cannot be empty", comment: "")
            case .titleTooLong:
                return NSLocalizedString("Task title cannot exceed 200 characters", comment: "")
            case .invalidRewardTime:
                return NSLocalizedString("Reward time must be greater than or equal to 0", comment: "")
            case .missingRecurringFrequency:
                return NSLocalizedString("Recurring tasks must have a frequency", comment: "")
            }
        }
    }
    
    // MARK: - Task Actions
    mutating func complete() {
        completedAt = Date()
        updatedAt = Date()
    }
    
    mutating func approve() {
        isApproved = true
        updatedAt = Date()
    }
    
    mutating func completeAndApprove() {
        completedAt = Date()
        isApproved = true
        updatedAt = Date()
    }

    mutating func setRewardMinutes(_ minutes: Int32) {
        rewardSeconds = Double(minutes * 60)
        updatedAt = Date()
    }
}

// MARK: - Hashable
extension SupabaseTask {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Equatable
extension SupabaseTask {
    static func == (lhs: SupabaseTask, rhs: SupabaseTask) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Mock Data
extension SupabaseTask {
    static func mock(
        title: String = "Clean Room",
        rewardMinutes: Int32 = 30,
        isCompleted: Bool = false,
        isApproved: Bool = false
    ) -> SupabaseTask {
        SupabaseTask(
            title: title,
            taskDescription: "Clean and organize your bedroom",
            rewardSeconds: Double(rewardMinutes * 60),
            completedAt: isCompleted ? Date() : nil,
            isApproved: isApproved
        )
    }
    
    static let mockTasks: [SupabaseTask] = [
        .mock(title: "Make Bed", rewardMinutes: 15),
        .mock(title: "Homework", rewardMinutes: 60, isCompleted: true),
        .mock(title: "Walk Dog", rewardMinutes: 30, isCompleted: true, isApproved: true)
    ]
}

// MARK: - Date Coding Helpers
private extension KeyedDecodingContainer {
    func decodeDate(forKey key: Key) throws -> Date {
        if let dateString = try? decode(String.self, forKey: key) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            let customFormatter = DateFormatter()
            customFormatter.locale = Locale(identifier: "en_US_POSIX")
            customFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
            if let date = customFormatter.date(from: dateString) {
                return date
            }
            customFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
            if let date = customFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Date string does not match expected format.")
        }
        
        let date = try decode(Date.self, forKey: key)
        return date
    }
    
    func decodeDateIfPresent(forKey key: Key) throws -> Date? {
        if let dateString = try? decodeIfPresent(String.self, forKey: key) {
            guard !dateString.isEmpty else {
                return nil
            }
            
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            let customFormatter = DateFormatter()
            customFormatter.locale = Locale(identifier: "en_US_POSIX")
            customFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
            if let date = customFormatter.date(from: dateString) {
                return date
            }
            customFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
            if let date = customFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Date string does not match expected format.")
        }
        
        let date = try decodeIfPresent(Date.self, forKey: key)
        if let date = date {
            return date
        }
        return nil
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