import Foundation
import Combine

/// ⚠️ **DEPRECATED** ⚠️
/// This service is part of the old Core Data architecture and should not be used.
/// Please migrate to `SupabaseAuthService` and `SupabaseDataRepository`.
class UserService: UserServiceProtocol {
    var currentUserPublisher: AnyPublisher<User?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> User? {
        return nil
    }
    
    func getChildren(for parentEmail: String) -> [User] {
        return []
    }
    
    func getPendingRequestsCount(for parentEmail: String) -> Int {
        return 0
    }
    
    func signIn(email: String, password: String) async throws -> User {
        throw UserServiceError.networkError
    }
    
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws -> User {
        throw UserServiceError.networkError
    }
    
    func signOut() {
        // No-op
    }
} 