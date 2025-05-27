import Foundation
import CoreData
import CloudKit

/// Represents a task that can be completed to earn screen time
@objc(Task)
public class Task: NSManagedObject, Identifiable {
    // MARK: - Core Data Properties
    @NSManaged public var id: UUID?
    @NSManaged public var title: String
    @NSManaged public var taskDescription: String?
    @NSManaged public var rewardMinutes: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var isApproved: Bool
    @NSManaged public var isRecurring: Bool
    @NSManaged public var recurringFrequency: String?
    @NSManaged public var assignedTo: User?
    @NSManaged public var createdBy: User?
    
    // MARK: - Computed Properties
    var isCompleted: Bool {
        completedAt != nil
    }
    
    var recurringType: RecurringFrequency? {
        get { RecurringFrequency(rawValue: recurringFrequency ?? "") }
        set { recurringFrequency = newValue?.rawValue }
    }
    
    // MARK: - CloudKit Support
    var cloudKitRecord: CKRecord {
        let record = CKRecord(recordType: "Task")
        record["id"] = id?.uuidString
        record["title"] = title
        record["taskDescription"] = taskDescription
        record["rewardMinutes"] = rewardMinutes
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        record["completedAt"] = completedAt
        record["isApproved"] = isApproved
        record["isRecurring"] = isRecurring
        record["recurringFrequency"] = recurringFrequency
        return record
    }
}

// MARK: - Recurring Frequency
extension Task {
    public enum RecurringFrequency: String {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        
        var localizedDescription: String {
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
}

// MARK: - Core Data Support
extension Task {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }
}

// MARK: - Validation
extension Task {
    /// Validates task data before saving
    func validate() throws {
        guard !title.isEmpty else {
            throw ValidationError.emptyTitle
        }
        
        guard rewardMinutes > 0 else {
            throw ValidationError.invalidRewardTime
        }
    }
    
    enum ValidationError: LocalizedError {
        case emptyTitle
        case invalidRewardTime
        
        var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return NSLocalizedString("Task title cannot be empty", comment: "")
            case .invalidRewardTime:
                return NSLocalizedString("Reward time must be greater than 0", comment: "")
            }
        }
    }
}

// MARK: - Hashable & Equatable
extension Task {
    // NSManagedObject already conforms to Hashable and Equatable
    // We cannot override isEqual: or hash for NSManagedObject subclasses
} 