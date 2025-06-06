import Foundation
import Combine

/// Concrete implementation of UserServiceProtocol that wraps AuthenticationService
final class UserService: UserServiceProtocol {
    
    // MARK: - Published Properties
    @Published private var currentUser: User?
    
    // MARK: - Protocol Properties
    var currentUserPublisher: AnyPublisher<User?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
    
    // MARK: - Dependencies
    private let authService: AuthenticationService
    private let sharedDataManager: SharedDataManager
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        authService: AuthenticationService = .shared,
        sharedDataManager: SharedDataManager = .shared
    ) {
        self.authService = authService
        self.sharedDataManager = sharedDataManager
        
        // Initialize current user
        self.currentUser = authService.currentUser
        
        setupBindings()
    }
    
    // MARK: - UserServiceProtocol Implementation
    
    func getCurrentUser() -> User? {
        return authService.currentUser
    }
    
    func getChildren(for parentEmail: String) -> [User] {
        return sharedDataManager.getChildren(forParentEmail: parentEmail)
    }
    
    func getPendingRequestsCount(for parentEmail: String) -> Int {
        return sharedDataManager.getPendingRequests(forParentEmail: parentEmail).count
    }
    
    func signIn(email: String, password: String) async throws -> User {
        do {
            let user = try await authService.signIn(email: email, password: password)
            await MainActor.run {
                self.currentUser = user
            }
            return user
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws -> User {
        do {
            let user = try await authService.signUp(
                email: email,
                password: password,
                name: name,
                isParent: isParent
            )
            await MainActor.run {
                self.currentUser = user
            }
            return user
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func signOut() {
        authService.signOut()
        currentUser = nil
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Subscribe to authentication service changes
        authService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.currentUser = self?.authService.currentUser
            }
            .store(in: &cancellables)
    }
    
    private func mapAuthError(_ error: Error) -> UserServiceError {
        if let authError = error as? AuthenticationService.AuthError {
            switch authError {
            case .invalidCredentials:
                return .invalidCredentials
            case .userAlreadyExists:
                return .userAlreadyExists
            case .unauthorized:
                return .notAuthenticated
            default:
                return .networkError
            }
        }
        
        return .networkError
    }
}

// MARK: - Singleton Support

extension UserService {
    /// Shared instance for global access
    static let shared = UserService()
} 