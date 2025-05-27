import Foundation
import CoreData
import CloudKit

/// Represents a user in the system, either a parent or child
@objc(User)
public class User: NSManagedObject, Identifiable {
    // MARK: - Core Data Properties
    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var userType: String
    @NSManaged public var email: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var tasks: Set<Task>
    @NSManaged public var createdTasks: Set<Task>
    @NSManaged public var screenTimeBalance: ScreenTimeBalance?
    @NSManaged public var children: Set<User>
    @NSManaged public var parent: User?
    
    // MARK: - Computed Properties
    var type: UserType {
        get { UserType(rawValue: userType) ?? .child }
        set { userType = newValue.rawValue }
    }
    
    var isParent: Bool {
        type == .parent
    }
    
    // MARK: - CloudKit Support
    var cloudKitRecord: CKRecord {
        let record = CKRecord(recordType: "User")
        record["id"] = id?.uuidString
        record["name"] = name
        record["userType"] = userType
        record["email"] = email
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        return record
    }
}

// MARK: - User Type
extension User {
    public enum UserType: String {
        case parent = "parent"
        case child = "child"
    }
}

// MARK: - Core Data Support
extension User {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
}

// MARK: - Validation
extension User {
    /// Validates user data before saving
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyName
        }
        
        if let email = email {
            guard email.contains("@") else {
                throw ValidationError.invalidEmail
            }
        }
    }
    
    enum ValidationError: LocalizedError {
        case emptyName
        case invalidEmail
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return NSLocalizedString("Name cannot be empty", comment: "")
            case .invalidEmail:
                return NSLocalizedString("Invalid email format", comment: "")
            }
        }
    }
}

// MARK: - Hashable & Equatable
extension User {
    // NSManagedObject already conforms to Hashable and Equatable
    // We cannot override isEqual: or hash for NSManagedObject subclasses
} 