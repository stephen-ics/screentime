import Foundation
import CoreData
import Combine

/// Simulates a backend service for sharing data between devices
final class SharedDataManager: @unchecked Sendable {
    static let shared = SharedDataManager()
    
    // MARK: - Properties
    private var users: [String: Profile] = [:] // Email -> Profile mapping
    private var parentChildLinks: [String: String] = [:] // Child email -> Parent email
    
    // Note: Temporarily using a simple storage approach for time requests during transition to Supabase
    private var pendingTimeRequests: [String: [String: Any]] = [:] // Simplified storage during migration
    private let updateSubject = PassthroughSubject<DataUpdateEvent, Never>()
    
    // Use standard UserDefaults for now (in production, use app groups)
    private let defaults = UserDefaults.standard
    
    // MARK: - Constants
    private enum Constants {
        static let parentChildLinksKey = "parentChildLinks"
        static let pendingRequestsKey = "pendingTimeRequests"
        static let registeredUsersKey = "registeredUsers"
    }
    
    var updatePublisher: AnyPublisher<DataUpdateEvent, Never> {
        updateSubject.eraseToAnyPublisher()
    }
    
    private init() {
        // Disable legacy data loading during Supabase migration
        print("🔄 SharedDataManager: Legacy features disabled during Supabase migration")
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
            registeredUsers[email] = user.isParent ? "parent" : "child"
        }
        defaults.set(registeredUsers, forKey: Constants.registeredUsersKey)
        defaults.synchronize()
        print("Saved registered users: \(registeredUsers)")
    }
    
    // MARK: - User Management
    func registerUser(_ user: Profile, email: String) {
        let normalizedEmail = email.lowercased()
        users[normalizedEmail] = user
        
        // Save to UserDefaults for cross-device discovery
        var registeredUsers = defaults.object(forKey: Constants.registeredUsersKey) as? [String: String] ?? [:]
        registeredUsers[normalizedEmail] = user.isParent ? "parent" : "child"
        defaults.set(registeredUsers, forKey: Constants.registeredUsersKey)
        defaults.synchronize()
        
        print("Registered user: \(user.name) with email: \(normalizedEmail) (isParent: \(user.isParent))")
        
        updateSubject.send(.userRegistered(email: normalizedEmail))
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
    
    func findUser(byEmail email: String) -> Profile? {
        let normalizedEmail = email.lowercased()
        
        // First check in-memory cache
        if let user = users[normalizedEmail] {
            print("Found user in cache: \(user.name)")
            return user
        }
        
        // During transition: simplified user lookup
        // In production: use SupabaseDataRepository
        
        // Check if user is registered on another device
        if let registeredUsers = defaults.object(forKey: Constants.registeredUsersKey) as? [String: String],
           let userType = registeredUsers[normalizedEmail] {
            print("User \(email) is registered as \(userType) but not found locally - they may be on another device")
            
            // In a real app, we would fetch from a backend here
            // For now, return nil but log that they exist
            return nil
        }
        
        print("User not found: \(email)")
        return nil
    }
    
    // MARK: - Parent-Child Linking
    func linkChildToParent(childEmail: String, parentEmail: String) -> Bool {
        let normalizedChildEmail = childEmail.lowercased()
        let normalizedParentEmail = parentEmail.lowercased()
        
        print("Attempting to link child \(normalizedChildEmail) to parent \(normalizedParentEmail)")
        
        // Check if both users exist
        guard let parent = findUser(byEmail: normalizedParentEmail),
              parent.isParent else {
            print("Parent not found or not a parent account: \(normalizedParentEmail)")
            return false
        }
        
        // For the child, check if they're registered even if not in local CoreData
        if let registeredUsers = defaults.object(forKey: Constants.registeredUsersKey) as? [String: String],
           let userType = registeredUsers[normalizedChildEmail],
           userType == "child" {
            // Child is registered, proceed with linking
            parentChildLinks[normalizedChildEmail] = normalizedParentEmail
            saveParentChildLinks()
            
            print("Successfully linked child \(normalizedChildEmail) to parent \(normalizedParentEmail)")
            
            // During transition: skip Core Data relationship updates
            // In production: use SupabaseDataRepository
            
            updateSubject.send(.childLinked(childEmail: normalizedChildEmail, parentEmail: normalizedParentEmail))
            return true
        }
        
        print("Child not found or not a child account: \(normalizedChildEmail)")
        return false
    }
    
    func getParentEmail(forChildEmail childEmail: String) -> String? {
        return parentChildLinks[childEmail.lowercased()]
    }
    
    func getChildren(forParentEmail parentEmail: String) -> [Profile] {
        let normalizedParentEmail = parentEmail.lowercased()
        var children: [Profile] = []
        
        for (childEmail, linkedParentEmail) in parentChildLinks {
            if linkedParentEmail == normalizedParentEmail {
                if let child = findUser(byEmail: childEmail) {
                    children.append(child)
                } else {
                    print("Linked child \(childEmail) not found locally")
                }
            }
        }
        
        return children
    }
    
    // MARK: - Task Management
    func notifyTaskAssigned(_ task: SupabaseTask, toChildEmail childEmail: String) {
        updateSubject.send(.taskAssigned(task: task, childEmail: childEmail))
    }
    
    func notifyTaskCompleted(_ task: SupabaseTask, byChildEmail childEmail: String) {
        if let parentEmail = getParentEmail(forChildEmail: childEmail) {
            updateSubject.send(.taskCompleted(task: task, childEmail: childEmail, parentEmail: parentEmail))
        }
    }
    
    // MARK: - Time Management (Simplified during migration to Supabase)
    func requestMoreTime(fromChildEmail childEmail: String, minutes: Int32) -> String? {
        guard let parentEmail = getParentEmail(forChildEmail: childEmail) else {
            print("No parent linked for child: \(childEmail)")
            return nil
        }
        
        let requestId = UUID().uuidString
        let requestData: [String: Any] = [
            "id": requestId,
            "childEmail": childEmail,
            "parentEmail": parentEmail,
            "requestedMinutes": minutes,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        pendingTimeRequests[requestId] = requestData
        savePendingRequests()
        
        // Create a simplified event for backwards compatibility
        updateSubject.send(.timeRequested(requestId: requestId, childEmail: childEmail, parentEmail: parentEmail, minutes: minutes))
        
        print("Created time request from \(childEmail) to \(parentEmail)")
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
        updateSubject.send(.timeApproved(requestId: requestId, childEmail: childEmail, minutes: minutes))
        
        return true
    }
    
    func denyTimeRequest(_ requestId: String) -> Bool {
        guard let requestData = pendingTimeRequests.removeValue(forKey: requestId),
              let childEmail = requestData["childEmail"] as? String,
              let minutes = requestData["requestedMinutes"] as? Int32 else {
            return false
        }
        
        savePendingRequests()
        updateSubject.send(.timeDenied(requestId: requestId, childEmail: childEmail, minutes: minutes))
        return true
    }
    
    func updateScreenTime(forChildEmail childEmail: String, minutes: Int32) {
        updateSubject.send(.screenTimeUpdated(childEmail: childEmail, minutes: minutes))
    }
}

// MARK: - Data Update Events
enum DataUpdateEvent {
    case userRegistered(email: String)
    case childLinked(childEmail: String, parentEmail: String)
    case taskAssigned(task: SupabaseTask, childEmail: String)
    case taskCompleted(task: SupabaseTask, childEmail: String, parentEmail: String)
    case timeRequested(requestId: String, childEmail: String, parentEmail: String, minutes: Int32)
    case timeApproved(requestId: String, childEmail: String, minutes: Int32)
    case timeDenied(requestId: String, childEmail: String, minutes: Int32)
    case screenTimeUpdated(childEmail: String, minutes: Int32)
} 