import Foundation
import CoreData
import CloudKit

/// Represents an app that is approved and monitored for screen time tracking
@objc(ApprovedApp)
public class ApprovedApp: NSManagedObject, Identifiable {
    // MARK: - Core Data Properties
    @NSManaged public var id: UUID?
    @NSManaged public var bundleIdentifier: String
    @NSManaged public var appName: String
    @NSManaged public var isEnabled: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var dailyLimit: Int32
    @NSManaged public var screenTimeBalance: ScreenTimeBalance?
    
    // MARK: - CloudKit Support
    var cloudKitRecord: CKRecord {
        let record = CKRecord(recordType: "ApprovedApp")
        record["id"] = id?.uuidString
        record["bundleIdentifier"] = bundleIdentifier
        record["appName"] = appName
        record["isEnabled"] = isEnabled
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        record["dailyLimit"] = dailyLimit
        return record
    }
}

// MARK: - Core Data Support
extension ApprovedApp {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ApprovedApp> {
        return NSFetchRequest<ApprovedApp>(entityName: "ApprovedApp")
    }
}

// MARK: - Validation
extension ApprovedApp {
    /// Validates approved app data before saving
    func validate() throws {
        guard !bundleIdentifier.isEmpty else {
            throw ValidationError.emptyBundleIdentifier
        }
        
        guard !appName.isEmpty else {
            throw ValidationError.emptyAppName
        }
    }
    
    enum ValidationError: LocalizedError {
        case emptyBundleIdentifier
        case emptyAppName
        case invalidDailyLimit
        
        var errorDescription: String? {
            switch self {
            case .emptyBundleIdentifier:
                return NSLocalizedString("Bundle identifier cannot be empty", comment: "")
            case .emptyAppName:
                return NSLocalizedString("App name cannot be empty", comment: "")
            case .invalidDailyLimit:
                return NSLocalizedString("Daily limit must be greater than 0", comment: "")
            }
        }
    }
}

// MARK: - Hashable & Equatable
extension ApprovedApp {
    // NSManagedObject already conforms to Hashable and Equatable
    // We cannot override isEqual: or hash for NSManagedObject subclasses
} 