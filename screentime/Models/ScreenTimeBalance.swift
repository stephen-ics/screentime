import Foundation
import CoreData
import CloudKit
import Combine

/// Represents a user's screen time balance and usage tracking
@objc(ScreenTimeBalance)
public class ScreenTimeBalance: NSManagedObject {
    // MARK: - Core Data Properties
    @NSManaged public var id: UUID?
    @NSManaged public var availableMinutes: Int32
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var dailyLimit: Int32
    @NSManaged public var weeklyLimit: Int32
    @NSManaged public var isTimerActive: Bool
    @NSManaged public var lastTimerStart: Date?
    @NSManaged public var user: User?
    @NSManaged public var approvedApps: Set<ApprovedApp>
    
    // MARK: - Transient Properties
    private var timerCancellable: AnyCancellable?
    
    // MARK: - Computed Properties
    var formattedTimeRemaining: String {
        let hours = availableMinutes / 60
        let minutes = availableMinutes % 60
        
        if hours > 0 {
            return String(format: NSLocalizedString("%dh %dm remaining", comment: ""), hours, minutes)
        } else {
            return String(format: NSLocalizedString("%dm remaining", comment: ""), minutes)
        }
    }
    
    var hasTimeRemaining: Bool {
        availableMinutes > 0
    }
    
    // MARK: - Timer Management
    func startTimer() {
        guard !isTimerActive else { return }
        
        isTimerActive = true
        lastTimerStart = Date()
        
        // Create a timer that fires every minute
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.decrementTime()
            }
    }
    
    func stopTimer() {
        isTimerActive = false
        lastTimerStart = nil
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func decrementTime() {
        guard availableMinutes > 0 else {
            stopTimer()
            NotificationCenter.default.post(name: .screenTimeExhausted, object: self)
            return
        }
        
        availableMinutes -= 1
        lastUpdated = Date()
        
        // Post notification when time is running low (5 minutes)
        if availableMinutes == 5 {
            NotificationCenter.default.post(name: .screenTimeLow, object: self)
        }
    }
    
    // MARK: - Time Management
    func addTime(_ minutes: Int32) {
        availableMinutes += minutes
        lastUpdated = Date()
    }
    
    func resetDaily() {
        availableMinutes = dailyLimit
        lastUpdated = Date()
    }
    
    // MARK: - CloudKit Support
    var cloudKitRecord: CKRecord {
        let record = CKRecord(recordType: "ScreenTimeBalance")
        record["id"] = id?.uuidString
        record["availableMinutes"] = availableMinutes
        record["lastUpdated"] = lastUpdated
        record["dailyLimit"] = dailyLimit
        record["weeklyLimit"] = weeklyLimit
        record["isTimerActive"] = isTimerActive
        record["lastTimerStart"] = lastTimerStart
        return record
    }
}

// MARK: - Core Data Support
extension ScreenTimeBalance {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScreenTimeBalance> {
        return NSFetchRequest<ScreenTimeBalance>(entityName: "ScreenTimeBalance")
    }
}

// MARK: - Validation
extension ScreenTimeBalance {
    /// Validates screen time balance data before saving
    func validate() throws {
        guard availableMinutes >= 0 else {
            throw ValidationError.negativeBalance
        }
    }
    
    enum ValidationError: LocalizedError {
        case negativeBalance
        case invalidDailyLimit
        case invalidWeeklyLimit
        
        var errorDescription: String? {
            switch self {
            case .negativeBalance:
                return NSLocalizedString("Screen time balance cannot be negative", comment: "")
            case .invalidDailyLimit:
                return NSLocalizedString("Daily limit must be greater than 0", comment: "")
            case .invalidWeeklyLimit:
                return NSLocalizedString("Weekly limit must be greater than 0", comment: "")
            }
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let screenTimeExhausted = Notification.Name("screenTimeExhausted")
    static let screenTimeLow = Notification.Name("screenTimeLow")
}

// MARK: - Hashable & Equatable
extension ScreenTimeBalance {
    // NSManagedObject already conforms to Hashable and Equatable
    // We cannot override isEqual: or hash for NSManagedObject subclasses
} 