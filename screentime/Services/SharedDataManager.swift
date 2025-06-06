import Foundation
import CoreData
import Combine

/// Simulates a backend service for sharing data between devices
final class SharedDataManager: @unchecked Sendable {
    static let shared = SharedDataManager()
    
    // MARK: - Properties
    private var users: [String: User] = [:] // Email -> User mapping
    private var parentChildLinks: [String: String] = [:] // Child email -> Parent email
    private var pendingTimeRequests: [String: TimeRequest] = [:] // Request ID -> TimeRequest
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
        loadPersistedData()
        loadUsersFromCoreData()
    }
    
    // MARK: - Persistence
    private func loadPersistedData() {
        // Load parent-child links
        if let linksData = defaults.object(forKey: Constants.parentChildLinksKey) as? [String: String] {
            parentChildLinks = linksData
            print("Loaded parent-child links: \(parentChildLinks)")
        }
        
        // Load pending requests
        if let requestsData = defaults.data(forKey: Constants.pendingRequestsKey),
           let requests = try? JSONDecoder().decode([String: TimeRequest].self, from: requestsData) {
            pendingTimeRequests = requests
        }
        
        // Load registered users
        if let usersData = defaults.object(forKey: Constants.registeredUsersKey) as? [String: String] {
            print("Loaded registered users from defaults: \(usersData)")
        }
    }
    
    private func loadUsersFromCoreData() {
        // Load all users from Core Data
        let request = User.fetchRequest()
        if let allUsers = try? CoreDataManager.shared.fetch(request) {
            for user in allUsers {
                if let email = user.email {
                    users[email.lowercased()] = user
                    print("Loaded user from CoreData: \(user.name) with email: \(email) (isParent: \(user.isParent))")
                }
            }
        }
        print("Total users loaded from CoreData: \(users.count)")
        
        // Also check UserDefaults for registered users
        if let registeredEmails = defaults.object(forKey: Constants.registeredUsersKey) as? [String: String] {
            print("Registered emails in UserDefaults: \(registeredEmails)")
        }
    }
    
    private func saveParentChildLinks() {
        defaults.set(parentChildLinks, forKey: Constants.parentChildLinksKey)
        defaults.synchronize()
        print("Saved parent-child links: \(parentChildLinks)")
    }
    
    private func savePendingRequests() {
        if let data = try? JSONEncoder().encode(pendingTimeRequests) {
            defaults.set(data, forKey: Constants.pendingRequestsKey)
            defaults.synchronize()
        }
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
    func registerUser(_ user: User, email: String) {
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
        loadUsersFromCoreData()
        
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
    
    func findUser(byEmail email: String) -> User? {
        let normalizedEmail = email.lowercased()
        
        // First check in-memory cache
        if let user = users[normalizedEmail] {
            print("Found user in cache: \(user.name)")
            return user
        }
        
        // If not found, try to fetch from Core Data with case-insensitive search
        let request = User.fetchRequest()
        request.predicate = NSPredicate(format: "email ==[c] %@", email)
        
        if let user = try? CoreDataManager.shared.fetch(request).first {
            users[normalizedEmail] = user
            print("Found user in CoreData: \(user.name)")
            return user
        }
        
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
            
            // Update Core Data relationships if child is available locally
            if let child = findUser(byEmail: normalizedChildEmail) {
                child.parent = parent
                parent.children.insert(child)
                try? CoreDataManager.shared.save()
            }
            
            updateSubject.send(.childLinked(childEmail: normalizedChildEmail, parentEmail: normalizedParentEmail))
            return true
        }
        
        print("Child not found or not a child account: \(normalizedChildEmail)")
        return false
    }
    
    func getParentEmail(forChildEmail childEmail: String) -> String? {
        return parentChildLinks[childEmail.lowercased()]
    }
    
    func getChildren(forParentEmail parentEmail: String) -> [User] {
        let normalizedParentEmail = parentEmail.lowercased()
        var children: [User] = []
        
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
    func notifyTaskAssigned(_ task: Task, toChildEmail childEmail: String) {
        updateSubject.send(.taskAssigned(task: task, childEmail: childEmail))
    }
    
    func notifyTaskCompleted(_ task: Task, byChildEmail childEmail: String) {
        if let parentEmail = getParentEmail(forChildEmail: childEmail) {
            updateSubject.send(.taskCompleted(task: task, childEmail: childEmail, parentEmail: parentEmail))
        }
    }
    
    // MARK: - Time Management
    func requestMoreTime(fromChildEmail childEmail: String, minutes: Int32) -> String? {
        guard let parentEmail = getParentEmail(forChildEmail: childEmail) else {
            print("No parent linked for child: \(childEmail)")
            return nil
        }
        
        let requestId = UUID().uuidString
        let request = TimeRequest(
            id: requestId,
            childEmail: childEmail,
            parentEmail: parentEmail,
            requestedMinutes: minutes,
            timestamp: Date()
        )
        
        pendingTimeRequests[requestId] = request
        savePendingRequests()
        updateSubject.send(.timeRequested(request: request))
        
        print("Created time request from \(childEmail) to \(parentEmail)")
        return requestId
    }
    
    func getPendingRequests(forParentEmail parentEmail: String) -> [TimeRequest] {
        return pendingTimeRequests.values.filter { $0.parentEmail.lowercased() == parentEmail.lowercased() }
    }
    
    func approveTimeRequest(_ requestId: String) -> Bool {
        guard let request = pendingTimeRequests[requestId],
              let child = findUser(byEmail: request.childEmail) else {
            return false
        }
        
        child.screenTimeBalance?.addTime(request.requestedMinutes)
        try? CoreDataManager.shared.save()
        
        pendingTimeRequests.removeValue(forKey: requestId)
        savePendingRequests()
        updateSubject.send(.timeApproved(request: request))
        
        return true
    }
    
    func denyTimeRequest(_ requestId: String) -> Bool {
        guard let request = pendingTimeRequests.removeValue(forKey: requestId) else {
            return false
        }
        
        savePendingRequests()
        updateSubject.send(.timeDenied(request: request))
        return true
    }
    
    func updateScreenTime(forChildEmail childEmail: String, minutes: Int32) {
        updateSubject.send(.screenTimeUpdated(childEmail: childEmail, minutes: minutes))
    }
}

// MARK: - Data Models
struct TimeRequest: Codable, Hashable, Equatable {
    let id: String
    let childEmail: String
    let parentEmail: String
    let requestedMinutes: Int32
    let timestamp: Date
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    static func == (lhs: TimeRequest, rhs: TimeRequest) -> Bool {
        return lhs.id == rhs.id
    }
}

enum DataUpdateEvent {
    case userRegistered(email: String)
    case childLinked(childEmail: String, parentEmail: String)
    case taskAssigned(task: Task, childEmail: String)
    case taskCompleted(task: Task, childEmail: String, parentEmail: String)
    case timeRequested(request: TimeRequest)
    case timeApproved(request: TimeRequest)
    case timeDenied(request: TimeRequest)
    case screenTimeUpdated(childEmail: String, minutes: Int32)
} 