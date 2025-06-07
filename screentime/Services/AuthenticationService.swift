import Foundation
import LocalAuthentication
import Combine

/// ⚠️ **DEPRECATED** ⚠️
/// This service is part of the old Core Data architecture and should not be used.
/// Please migrate to `SupabaseAuthService` and `SupabaseDataRepository`.
final class AuthenticationService: ObservableObject {
    
    enum DeprecatedError: LocalizedError {
        case serviceDeprecated
        
        var errorDescription: String? {
            "This service is deprecated. Please migrate to SupabaseAuthService."
        }
    }
    
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws -> User {
        throw DeprecatedError.serviceDeprecated
    }
    
    func signIn(email: String, password: String) async throws -> User {
        throw DeprecatedError.serviceDeprecated
    }
} 