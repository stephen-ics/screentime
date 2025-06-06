import Foundation
import Combine
import _Concurrency

/// Concrete implementation of DataRepositoryProtocol that wraps SharedDataManager
final class DataRepository: DataRepositoryProtocol, @unchecked Sendable {
    
    // MARK: - Dependencies
    private let sharedDataManager: SharedDataManager
    private let coreDataManager: CoreDataManager
    
    // MARK: - Protocol Properties
    var dataUpdatePublisher: AnyPublisher<DataUpdateEvent, Never> {
        sharedDataManager.updatePublisher
    }
    
    // MARK: - Initialization
    
    init(
        sharedDataManager: SharedDataManager = .shared,
        coreDataManager: CoreDataManager = .shared
    ) {
        self.sharedDataManager = sharedDataManager
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - DataRepositoryProtocol Implementation
    
    func getChildren(for parentEmail: String) async throws -> [User] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [sharedDataManager] in
                let children = sharedDataManager.getChildren(forParentEmail: parentEmail)
                continuation.resume(returning: children)
            }
        }
    }
    
    func getTimeRequests(for parentEmail: String) async throws -> [TimeRequest] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [sharedDataManager] in
                let requests = sharedDataManager.getPendingRequests(forParentEmail: parentEmail)
                continuation.resume(returning: requests)
            }
        }
    }
    
    func linkChild(email childEmail: String, to parentEmail: String) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [sharedDataManager] in
                let success = sharedDataManager.linkChildToParent(
                    childEmail: childEmail,
                    parentEmail: parentEmail
                )
                continuation.resume(returning: success)
            }
        }
    }
    
    func approveTimeRequest(_ requestId: String) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [sharedDataManager] in
                let success = sharedDataManager.approveTimeRequest(requestId)
                continuation.resume(returning: success)
            }
        }
    }
    
    func denyTimeRequest(_ requestId: String) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [sharedDataManager] in
                let success = sharedDataManager.denyTimeRequest(requestId)
                continuation.resume(returning: success)
            }
        }
    }
    
    func createTimeRequest(childEmail: String, parentEmail: String, minutes: Int32) async throws -> TimeRequest {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [sharedDataManager] in
                if let requestId = sharedDataManager.requestMoreTime(
                    fromChildEmail: childEmail,
                    minutes: minutes
                ) {
                    let request = TimeRequest(
                        id: requestId,
                        childEmail: childEmail,
                        parentEmail: parentEmail,
                        requestedMinutes: minutes,
                        timestamp: Date()
                    )
                    continuation.resume(returning: request)
                } else {
                    // Create a failed request with empty ID to indicate failure
                    let failedRequest = TimeRequest(
                        id: "",
                        childEmail: childEmail,
                        parentEmail: parentEmail,
                        requestedMinutes: minutes,
                        timestamp: Date()
                    )
                    continuation.resume(returning: failedRequest)
                }
            }
        }
    }
    
    func refreshUserCache() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [sharedDataManager] in
                sharedDataManager.refreshUserCache()
                continuation.resume()
            }
        }
    }
    
    func findUser(byEmail email: String) async -> User? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [sharedDataManager] in
                let user = sharedDataManager.findUser(byEmail: email)
                continuation.resume(returning: user)
            }
        }
    }
}

// MARK: - Singleton Support

extension DataRepository {
    /// Shared instance for global access
    static let shared = DataRepository()
} 