import Foundation
import CoreData

/// Temporary User class for migration period
/// This will be replaced by Supabase Profile model
@objc(User)
public class User: NSManagedObject {
    
    // MARK: - Properties
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var email: String?
    @NSManaged public var isParent: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // MARK: - Convenience Initializer
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: User.entity(), insertInto: context)
        self.id = UUID()
        self.name = ""
        self.email = nil
        self.isParent = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Core Data Entity
extension User {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }
} 