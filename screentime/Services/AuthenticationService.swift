import Foundation
import LocalAuthentication
import Combine

/// Manages user authentication and authorization
final class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    // MARK: - Properties
    private let context = LAContext()
    private let defaults = UserDefaults.standard
    private let keychainService = "world.screentime"
    
    @Published private(set) var currentUser: User?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum Constants {
        static let currentUserIDKey = "currentUserID"
        static let biometricReason = "Authenticate to manage screen time"
    }
    
    private init() {
        // Attempt to restore the current user session
        restoreSession()
    }
    
    private func restoreSession() {
        if let userID = defaults.string(forKey: Constants.currentUserIDKey),
           let uuid = UUID(uuidString: userID) {
            loadUser(withID: uuid)
        }
    }
    
    // MARK: - Authentication Methods
    func authenticateWithBiometrics() async throws -> Bool {
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            throw AuthError.biometricsNotAvailable
        }
        
        return try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: Constants.biometricReason
        )
    }
    
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws -> User {
        // Check if user already exists
        let request = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        
        if let _ = try CoreDataManager.shared.fetch(request).first {
            throw AuthError.userAlreadyExists
        }
        
        // Create new user
        let user = try await MainActor.run {
            try CoreDataManager.shared.createUser(
                name: name,
                type: isParent ? User.UserType.parent.rawValue : User.UserType.child.rawValue,
                email: email
            )
        }
        
        // Create screen time balance for child accounts
        if !isParent {
            try await MainActor.run {
                try CoreDataManager.shared.createScreenTimeBalance(for: user)
            }
        }
        
        // Register user with SharedDataManager - this is critical!
        SharedDataManager.shared.registerUser(user, email: email)
        
        // Force refresh the user cache to ensure it's available
        SharedDataManager.shared.refreshUserCache()
        
        // Store the user ID in UserDefaults for session persistence
        if let userID = user.id {
            defaults.set(userID.uuidString, forKey: Constants.currentUserIDKey)
            defaults.synchronize()
        }
        
        currentUser = user
        
        // Subscribe to updates
        subscribeToUpdates()
        
        // Log for debugging
        print("User created successfully: \(name) with email: \(email) (isParent: \(isParent))")
        
        return user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        // In a real app, validate credentials against a backend service
        // For now, we'll just fetch the user from Core Data
        let request = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        
        guard let user = try CoreDataManager.shared.fetch(request).first else {
            throw AuthError.invalidCredentials
        }
        
        // Register user with SharedDataManager
        SharedDataManager.shared.registerUser(user, email: email)
        
        // Store the user ID in UserDefaults for session persistence
        if let userID = user.id {
            defaults.set(userID.uuidString, forKey: Constants.currentUserIDKey)
            defaults.synchronize() // Force synchronization
        }
        currentUser = user
        
        // Subscribe to updates
        subscribeToUpdates()
        
        return user
    }
    
    func signOut() {
        defaults.removeObject(forKey: Constants.currentUserIDKey)
        defaults.synchronize()
        currentUser = nil
        cancellables.removeAll()
    }
    
    // MARK: - Authorization Methods
    func authorizeParentAction() async throws -> Bool {
        guard let currentUser = currentUser, currentUser.isParent else {
            throw AuthError.unauthorized
        }
        
        return try await authenticateWithBiometrics()
    }
    
    func isAuthorizedParent(_ user: User) -> Bool {
        user.isParent
    }
    
    // MARK: - Private Methods
    private func loadUser(withID id: UUID) {
        do {
            if let user = try CoreDataManager.shared.fetchUser(withID: id) {
                currentUser = user
                
                // Register with SharedDataManager if email exists
                if let email = user.email {
                    SharedDataManager.shared.registerUser(user, email: email)
                    subscribeToUpdates()
                }
            }
        } catch {
            print("Failed to load user: \(error)")
        }
    }
    
    // MARK: - Password Management
    func setParentPassword(_ password: String) throws {
        guard let currentUser = currentUser, 
              currentUser.isParent,
              let userID = currentUser.id else {
            throw AuthError.unauthorized
        }
        
        // In a real app, hash the password before storing
        // For demo purposes, we'll just store it in the keychain
        try setKeychainPassword(password, for: userID)
    }
    
    private func setKeychainPassword(_ password: String, for userID: UUID) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userID.uuidString,
            kSecValueData as String: password.data(using: .utf8)!
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.keychainError
        }
    }
    
    private func getKeychainPassword(for userID: UUID) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userID.uuidString,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    private func subscribeToUpdates() {
        SharedDataManager.shared.updatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleDataUpdate(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleDataUpdate(_ event: DataUpdateEvent) {
        guard let currentUser = currentUser,
              let email = currentUser.email else { return }
        
        switch event {
        case .childLinked(let childEmail, let parentEmail):
            if email.lowercased() == parentEmail.lowercased() {
                // Refresh children list for parent
                objectWillChange.send()
            }
            
        case .taskAssigned(_, let childEmail):
            if email.lowercased() == childEmail.lowercased() {
                // Refresh tasks for child
                objectWillChange.send()
            }
            
        case .timeRequested(let request):
            if email.lowercased() == request.parentEmail.lowercased() {
                // Show notification to parent
                showTimeRequestNotification(request)
            }
            
        case .timeApproved(let request):
            if email.lowercased() == request.childEmail.lowercased() {
                // Refresh screen time for child
                objectWillChange.send()
            }
            
        case .screenTimeUpdated(let childEmail, _):
            if email.lowercased() == childEmail.lowercased() {
                // Refresh screen time
                objectWillChange.send()
            }
            
        default:
            break
        }
    }
    
    private func showTimeRequestNotification(_ request: TimeRequest) {
        _Concurrency.Task {
            do {
                if let child = SharedDataManager.shared.findUser(byEmail: request.childEmail) {
                    try await NotificationService.shared.scheduleTimeRequestNotification(from: child)
                }
            } catch {
                print("Failed to show time request notification: \(error)")
            }
        }
    }
}

// MARK: - Error Handling
extension AuthenticationService {
    enum AuthError: LocalizedError {
        case invalidCredentials
        case unauthorized
        case biometricsNotAvailable
        case keychainError
        case userAlreadyExists
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return NSLocalizedString("Invalid email or password", comment: "")
            case .unauthorized:
                return NSLocalizedString("You are not authorized to perform this action", comment: "")
            case .biometricsNotAvailable:
                return NSLocalizedString("Biometric authentication is not available", comment: "")
            case .keychainError:
                return NSLocalizedString("Failed to access keychain", comment: "")
            case .userAlreadyExists:
                return NSLocalizedString("An account with this email already exists", comment: "")
            }
        }
    }
} 