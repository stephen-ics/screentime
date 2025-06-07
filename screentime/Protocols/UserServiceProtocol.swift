import Foundation
import Combine
import CoreData

/// Protocol defining user-related operations including authentication and user data management
protocol UserServiceProtocol: ObservableObject {
    /// Publisher that emits the current user when it changes
    var currentUserPublisher: AnyPublisher<User?, Never> { get }
    
    /// Retrieves the currently authenticated user
    /// - Returns: The current user if authenticated, nil otherwise
    func getCurrentUser() -> User?
    
    /// Gets all children linked to a parent account
    /// - Parameter parentEmail: The email address of the parent account
    /// - Returns: Array of child users linked to the parent
    func getChildren(for parentEmail: String) -> [User]
    
    /// Gets the count of pending time requests for a parent
    /// - Parameter parentEmail: The email address of the parent account
    /// - Returns: Number of pending time requests
    func getPendingRequestsCount(for parentEmail: String) -> Int
    
    /// Signs in a user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated user
    /// - Throws: UserServiceError if authentication fails
    func signIn(email: String, password: String) async throws -> User
    
    /// Signs up a new user
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - name: User's full name
    ///   - isParent: Whether the user is a parent or child
    /// - Returns: The newly created user
    /// - Throws: UserServiceError if signup fails
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws -> User
    
    /// Signs out the current user
    func signOut()
}

/// Errors that can occur during user service operations
enum UserServiceError: LocalizedError, Equatable {
    case notAuthenticated
    case invalidCredentials
    case userAlreadyExists
    case userNotFound
    case linkingFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userAlreadyExists:
            return "An account with this email already exists"
        case .userNotFound:
            return "User not found"
        case .linkingFailed:
            return "Failed to link accounts"
        case .networkError:
            return "Network error occurred"
        }
    }
} 