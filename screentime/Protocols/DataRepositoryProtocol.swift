import Foundation
import CoreData
import Combine

/// Protocol defining data repository operations for parent-child relationships and time requests
protocol DataRepositoryProtocol {
    /// Publisher that emits data update events
    var dataUpdatePublisher: AnyPublisher<DataUpdateEvent, Never> { get }
    
    /// Gets all children linked to a parent account
    /// - Parameter parentEmail: The email address of the parent account
    /// - Returns: Array of child users linked to the parent
    /// - Throws: DataRepositoryError if operation fails
    func getChildren(for parentEmail: String) async throws -> [User]
    
    /// Gets pending time requests for a parent
    /// - Parameter parentEmail: The email address of the parent account
    /// - Returns: Array of pending time requests
    /// - Throws: DataRepositoryError if operation fails
    func getTimeRequests(for parentEmail: String) async throws -> [TimeRequest]
    
    /// Links a child account to a parent account
    /// - Parameters:
    ///   - childEmail: The email address of the child account
    ///   - parentEmail: The email address of the parent account
    /// - Returns: `true` if linking was successful, `false` otherwise
    /// - Throws: DataRepositoryError if operation fails
    func linkChild(email childEmail: String, to parentEmail: String) async throws -> Bool
    
    /// Approves a time request
    /// - Parameter requestId: The ID of the time request to approve
    /// - Returns: `true` if approval was successful, `false` otherwise
    /// - Throws: DataRepositoryError if operation fails
    func approveTimeRequest(_ requestId: String) async throws -> Bool
    
    /// Denies a time request
    /// - Parameter requestId: The ID of the time request to deny
    /// - Returns: `true` if denial was successful, `false` otherwise
    /// - Throws: DataRepositoryError if operation fails
    func denyTimeRequest(_ requestId: String) async throws -> Bool
    
    /// Creates a new time request
    /// - Parameters:
    ///   - childEmail: The email of the child making the request
    ///   - parentEmail: The email of the parent to request from
    ///   - minutes: The number of minutes requested
    /// - Returns: The created time request
    /// - Throws: DataRepositoryError if operation fails
    func createTimeRequest(childEmail: String, parentEmail: String, minutes: Int32) async throws -> TimeRequest
    
    /// Refreshes the user cache
    func refreshUserCache() async
    
    /// Finds a user by email
    /// - Parameter email: The email address to search for
    /// - Returns: The user if found, nil otherwise
    func findUser(byEmail email: String) async -> User?
}

/// Errors that can occur during data repository operations
enum DataRepositoryError: LocalizedError, Equatable {
    case userNotFound
    case childNotFound
    case parentNotFound
    case linkingFailed
    case requestNotFound
    case timeRequestFailed
    case networkError
    case dataCorruption
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .childNotFound:
            return "Child account not found"
        case .parentNotFound:
            return "Parent account not found"
        case .linkingFailed:
            return "Failed to link child account"
        case .requestNotFound:
            return "Time request not found"
        case .timeRequestFailed:
            return "Failed to process time request"
        case .networkError:
            return "Network error occurred"
        case .dataCorruption:
            return "Data corruption detected"
        }
    }
} 