import Foundation
import CoreData
import Combine

/// Manages shared data between app extensions and main app
@MainActor
final class SharedDataManager: ObservableObject {
    static let shared = SharedDataManager()
    
    private let defaults = UserDefaults(suiteName: "group.com.screentime.app")!
    private let updateSubject = PassthroughSubject<UpdateType, Never>()
    
    // MARK: - Properties
    private var users: [String: FamilyProfile] = [:] // Email -> Profile mapping
    private var parentChildLinks: [String: String] = [:] // Child email -> Parent email
    
    // Note: Temporarily using a simple storage approach for time requests during transition to Supabase
    private var pendingTimeRequests: [String: [String: Any]] = [:] // Simplified storage during migration
    private var registeredUsers: [String: String] = [:] // Email -> Role mapping
    
    // MARK: - Published Properties
    @Published private(set) var lastUpdate: UpdateType?
    
    // MARK: - Constants
    private enum Constants {
        static let parentChildLinksKey = "parentChildLinks"
        static let pendingRequestsKey = "pendingTimeRequests"
        static let registeredUsersKey = "registeredUsers"
    }
    
    var updatePublisher: AnyPublisher<UpdateType, Never> {
        updateSubject.eraseToAnyPublisher()
    }
    
    private init() {
        loadData()
        // Disable legacy data loading during Supabase migration
        print("🔄 SharedDataManager: Legacy features disabled during Supabase migration")
    }
    
    // MARK: - Data Loading
    private func loadData() {
        // Load registered users from UserDefaults
        registeredUsers = defaults.object(forKey: Constants.registeredUsersKey) as? [String: String] ?? [:]
    }
    
    // MARK: - Persistence
    private func saveParentChildLinks() {
        defaults.set(parentChildLinks, forKey: Constants.parentChildLinksKey)
        defaults.synchronize()
        print("Saved parent-child links: \(parentChildLinks)")
    }
    
    private func savePendingRequests() {
        defaults.set(pendingTimeRequests, forKey: Constants.pendingRequestsKey)
        defaults.synchronize()
    }
    
    private func saveRegisteredUsers() {
        // Save a simple mapping of emails to user types for cross-device discovery
        var registeredUsers: [String: String] = [:]
        for (email, user) in users {
            registeredUsers[email] = user.role == .parent ? "parent" : "child"
        }
        defaults.set(registeredUsers, forKey: Constants.registeredUsersKey)
        defaults.synchronize()
        print("Saved registered users: \(registeredUsers)")
    }
    
    // MARK: - User Management
    func registerUser(_ user: FamilyProfile) {
        let key = user.id.uuidString
        users[key] = user
        // Save to UserDefaults for cross-device discovery
        var registeredUsers = defaults.object(forKey: Constants.registeredUsersKey) as? [String: String] ?? [:]
        registeredUsers[key] = user.role == .parent ? "parent" : "child"
        defaults.set(registeredUsers, forKey: Constants.registeredUsersKey)
        defaults.synchronize()
        print("Registered user: \(user.name) with id: \(key) (role: \(user.role))")
        updateSubject.send(.userRegistered(id: user.id))
    }
    
    func registerUser(id: UUID, role: FamilyProfile.ProfileRole) {
        let key = id.uuidString
        users[key] = FamilyProfile(id: id, authUserId: UUID(), name: "", role: role)
        // Save to UserDefaults for cross-device discovery
        var registeredUsers = defaults.object(forKey: Constants.registeredUsersKey) as? [String: String] ?? [:]
        registeredUsers[key] = role == .parent ? "parent" : "child"
        defaults.set(registeredUsers, forKey: Constants.registeredUsersKey)
        defaults.synchronize()
        print("Registered user with id: \(key) (role: \(role))")
        updateSubject.send(.userRegistered(id: id))
    }
    
    func refreshUserCache() {
        print("Refreshing user cache...")
        
        // Also check UserDefaults for any users registered on other devices
        if let registeredUsers = defaults.object(forKey: Constants.registeredUsersKey) as? [String: String] {
            print("Found registered users in UserDefaults: \(registeredUsers)")
            
            // For each registered user not in our cache, try to create a placeholder
            for (email, _) in registeredUsers {
                if users[email] == nil {
                    print("User \(email) is registered but not in cache - they may be on another device")
                }
            }
        }
    }
    
    func findUser(byId id: UUID) -> FamilyProfile? {
        let key = id.uuidString
        return users[key]
    }
    
    // MARK: - Parent-Child Linking
    // Use UUIDs for linking
    func linkChildToParent(childId: UUID, parentId: UUID) -> Bool {
        print("Attempting to link child \(childId) to parent \(parentId)")
        guard let parent = findUser(byId: parentId), parent.role == .parent else {
            print("Parent not found or not a parent account: \(parentId)")
            return false
        }
        // Link child to parent
        parentChildLinks[childId.uuidString] = parentId.uuidString
        saveParentChildLinks()
        print("Successfully linked child \(childId) to parent \(parentId)")
        updateSubject.send(.userUpdated(id: childId))
        return true
    }
    
    func getParentId(forChildId childId: UUID) -> UUID? {
        guard let parentIdString = parentChildLinks[childId.uuidString] else { return nil }
        return UUID(uuidString: parentIdString)
    }
    
    func getChildren(forParentId parentId: UUID) -> [FamilyProfile] {
        var children: [FamilyProfile] = []
        for (key, user) in users {
            if let userType = registeredUsers[key], userType == "child" {
                if let linkedParentId = getParentId(forChildId: user.id), linkedParentId == parentId {
                    children.append(user)
                }
            }
        }
        return children
    }
    
    // MARK: - Task Management
    func notifyTaskAssigned(_ task: SupabaseTask, toChildEmail childEmail: String) {
        updateSubject.send(.userUpdated(id: UUID(uuidString: childEmail)!))
    }
    
    func notifyTaskCompleted(_ task: SupabaseTask, byChildEmail childEmail: String) {
        if let childId = UUID(uuidString: childEmail),
           let parentId = getParentId(forChildId: childId) {
            updateSubject.send(.userUpdated(id: parentId))
        }
    }
    
    // MARK: - Time Management (Simplified during migration to Supabase)
    func requestMoreTime(fromChildEmail childEmail: String, minutes: Int32) -> String? {
        guard let childId = UUID(uuidString: childEmail),
              let parentId = getParentId(forChildId: childId) else {
            print("No parent linked for child: \(childEmail)")
            return nil
        }
        
        let requestId = UUID().uuidString
        let requestData: [String: Any] = [
            "id": requestId,
            "childEmail": childEmail,
            "parentId": parentId.uuidString,
            "requestedMinutes": minutes,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        pendingTimeRequests[requestId] = requestData
        savePendingRequests()
        
        // Create a simplified event for backwards compatibility
        updateSubject.send(.timeRequested(requestId: requestId, childId: childId, parentId: parentId, minutes: minutes))
        
        print("Created time request from \(childEmail) to parent \(parentId)")
        return requestId
    }
    
    func getPendingRequests(forParentEmail parentEmail: String) -> [[String: Any]] {
        return pendingTimeRequests.values.filter { 
            if let parentEmailFromRequest = $0["parentEmail"] as? String {
                return parentEmailFromRequest.lowercased() == parentEmail.lowercased()
            }
            return false
        }
    }
    
    func approveTimeRequest(_ requestId: String) -> Bool {
        guard let requestData = pendingTimeRequests[requestId],
              let childEmail = requestData["childEmail"] as? String,
              let minutes = requestData["requestedMinutes"] as? Int32 else {
            return false
        }
        
        // During transition: simplified time addition
        // In production: use SupabaseDataRepository to add time to balance
        print("Approving time request: \(minutes) minutes for \(childEmail)")
        
        pendingTimeRequests.removeValue(forKey: requestId)
        savePendingRequests()
        updateSubject.send(.timeApproved(requestId: requestId, childId: UUID(uuidString: childEmail)!, minutes: minutes))
        
        return true
    }
    
    func denyTimeRequest(_ requestId: String) -> Bool {
        guard let requestData = pendingTimeRequests.removeValue(forKey: requestId),
              let childEmail = requestData["childEmail"] as? String,
              let minutes = requestData["requestedMinutes"] as? Int32 else {
            return false
        }
        
        savePendingRequests()
        updateSubject.send(.timeDenied(requestId: requestId, childId: UUID(uuidString: childEmail)!, minutes: minutes))
        return true
    }
    
    func updateScreenTime(forChildEmail childEmail: String, minutes: Int32) {
        updateSubject.send(.userUpdated(id: UUID(uuidString: childEmail)!))
    }
    
    // MARK: - Update Types
    enum UpdateType {
        case userRegistered(id: UUID)
        case userUpdated(id: UUID)
        case userDeleted(id: UUID)
        case timeRequested(requestId: String, childId: UUID, parentId: UUID, minutes: Int32)
        case timeApproved(requestId: String, childId: UUID, minutes: Int32)
        case timeDenied(requestId: String, childId: UUID, minutes: Int32)
    }
}

// MARK: - Data Update Events
enum UpdateType {
    case userRegistered(id: UUID)
    case userUpdated(id: UUID)
    case userDeleted(id: UUID)
    case timeRequested(requestId: String, childId: UUID, parentId: UUID, minutes: Int32)
    case timeApproved(requestId: String, childId: UUID, minutes: Int32)
    case timeDenied(requestId: String, childId: UUID, minutes: Int32)
} 