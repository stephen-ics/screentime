import Foundation
import Combine
import LocalAuthentication
#if canImport(Supabase)
import Supabase
#endif

/// Family authentication service implementing single-auth-per-family architecture
@MainActor
final class FamilyAuthService: ObservableObject {
    static let shared = FamilyAuthService()
    
    // MARK: - Published Properties
    @Published private(set) var authenticationState: AuthenticationState = .unauthenticated
    @Published private(set) var availableProfiles: [FamilyProfile] = []
    @Published private(set) var selectedProfile: FamilyProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var error: FamilyAuthError?
    
    // MARK: - Private Properties
    private let supabase = SupabaseManager.shared
    private let logger = Logger.shared
    private var cancellables = Set<AnyCancellable>()
    private let biometricContext = LAContext()
    
    // MARK: - Authentication State
    enum AuthenticationState: Equatable {
        case unauthenticated
        case authenticatedAwaitingProfile
        case fullyAuthenticated(profile: FamilyProfile)
        
        var isAuthenticated: Bool {
            switch self {
            case .unauthenticated:
                return false
            case .authenticatedAwaitingProfile, .fullyAuthenticated:
                return true
            }
        }
        
        var requiresProfileSelection: Bool {
            switch self {
            case .authenticatedAwaitingProfile:
                return true
            case .unauthenticated, .fullyAuthenticated:
                return false
            }
        }
        
        var currentProfile: FamilyProfile? {
            switch self {
            case .fullyAuthenticated(let profile):
                return profile
            case .unauthenticated, .authenticatedAwaitingProfile:
                return nil
            }
        }
        
        // MARK: - Equatable
        static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
            switch (lhs, rhs) {
            case (.unauthenticated, .unauthenticated):
                return true
            case (.authenticatedAwaitingProfile, .authenticatedAwaitingProfile):
                return true
            case (.fullyAuthenticated(let lhsProfile), .fullyAuthenticated(let rhsProfile)):
                return lhsProfile.id == rhsProfile.id
            default:
                return false
            }
        }
    }
    
    // MARK: - Errors
    enum FamilyAuthError: LocalizedError, Equatable {
        case configurationMissing
        case signUpFailed(String)
        case signInFailed(String)
        case profileCreationFailed(String)
        case profileLoadingFailed(String)
        case noProfilesFound
        case biometricsNotAvailable
        case biometricsAuthFailed
        case parentAuthRequired
        case networkError(String)
        case invalidInput(String)
        
        var errorDescription: String? {
            switch self {
            case .configurationMissing:
                return "Supabase configuration is missing"
            case .signUpFailed(let message):
                return "Sign up failed: \(message)"
            case .signInFailed(let message):
                return "Sign in failed: \(message)"
            case .profileCreationFailed(let message):
                return "Profile creation failed: \(message)"
            case .profileLoadingFailed(let message):
                return "Profile loading failed: \(message)"
            case .noProfilesFound:
                return "No profiles found for this account"
            case .biometricsNotAvailable:
                return "Biometric authentication is not available"
            case .biometricsAuthFailed:
                return "Biometric authentication failed"
            case .parentAuthRequired:
                return "Parent authorization required"
            case .networkError(let message):
                return "Network error: \(message)"
            case .invalidInput(let message):
                return "Invalid input: \(message)"
            }
        }
        
        static func == (lhs: FamilyAuthError, rhs: FamilyAuthError) -> Bool {
            switch (lhs, rhs) {
            case (.configurationMissing, .configurationMissing),
                 (.noProfilesFound, .noProfilesFound),
                 (.biometricsNotAvailable, .biometricsNotAvailable),
                 (.biometricsAuthFailed, .biometricsAuthFailed),
                 (.parentAuthRequired, .parentAuthRequired):
                return true
            case (.signUpFailed(let lhsMsg), .signUpFailed(let rhsMsg)),
                 (.signInFailed(let lhsMsg), .signInFailed(let rhsMsg)),
                 (.profileCreationFailed(let lhsMsg), .profileCreationFailed(let rhsMsg)),
                 (.profileLoadingFailed(let lhsMsg), .profileLoadingFailed(let rhsMsg)),
                 (.networkError(let lhsMsg), .networkError(let rhsMsg)),
                 (.invalidInput(let lhsMsg), .invalidInput(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }
    
    // MARK: - Computed Properties
    var isUnauthenticated: Bool {
        return authenticationState == .unauthenticated
    }
    
    var isFullyAuthenticated: Bool {
        if case .fullyAuthenticated = authenticationState {
            return true
        }
        return false
    }
    
    var currentProfile: FamilyProfile? {
        return authenticationState.currentProfile
    }
    
    var requiresProfileSelection: Bool {
        return authenticationState.requiresProfileSelection
    }
    
    var canManageFamily: Bool {
        return currentProfile?.canManageFamily ?? false
    }
    
    // MARK: - Initialization
    init() {
        #if canImport(Supabase)
        if supabase.client != nil {
            logger.authSuccess("Supabase client available for family auth")
            Task {
                await setupAuthStateListener()
                await restoreSession()
            }
        } else {
            logger.authError("Supabase client is nil - family auth disabled")
        }
        #else
        logger.authWarning("Supabase package not available. Family authentication disabled.")
        #endif
    }
    
    #if canImport(Supabase)
    // MARK: - Authentication State Management
    private func setupAuthStateListener() async {
        guard let auth = supabase.auth else { 
            logger.authError("Auth client not available")
            return 
        }
        
        logger.info(.auth, "🔄 Setting up family auth state listener...")
        
        Task {
            for await (event, session) in auth.authStateChanges {
                logger.info(.auth, "🔄 Family auth state changed: \(event)")
                await handleAuthStateChange(event: event, session: session)
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        logger.info(.auth, "🔄 Handling family auth state change: \(event)")
        
        switch event {
        case .signedIn:
            if let session = session {
                logger.authSuccess("Family auth: User signed in: \(session.user.email ?? "no email")")
                await loadFamilyProfiles(for: session.user.id)
            }
        case .signedOut:
            logger.info(.auth, "👋 Family auth: User signed out")
            authenticationState = .unauthenticated
            availableProfiles = []
            selectedProfile = nil
        case .tokenRefreshed:
            logger.info(.auth, "🔄 Family auth: Token refreshed")
            // Keep current state
            break
        default:
            logger.info(.auth, "🔄 Family auth: Other event: \(event)")
            break
        }
    }
    
    private func restoreSession() async {
        guard let auth = supabase.auth else { return }
        
        do {
            let session = try await auth.session
            logger.authSuccess("Family auth: Restored session for: \(session.user.email ?? "no email")")
            await loadFamilyProfiles(for: session.user.id)
        } catch {
            logger.info(.auth, "ℹ️ Family auth: No existing session found")
            authenticationState = .unauthenticated
        }
    }
    
    // MARK: - Email Verification
    func resendVerificationEmail(email: String) async throws {
        guard let auth = supabase.auth else {
            throw FamilyAuthError.configurationMissing
        }
        
        logger.info(.auth, "📧 Resending verification email to: \(email)")
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        do {
            try await auth.resend(email: email, type: .signup)
            logger.authSuccess("✅ Verification email resent successfully")
        } catch {
            logger.authError("Failed to resend verification email", error: error)
            let familyError = FamilyAuthError.networkError(error.localizedDescription)
            self.error = familyError
            throw familyError
        }
    }
    
    func checkVerification(email: String) async throws -> Bool {
        guard let auth = supabase.auth else {
            throw FamilyAuthError.configurationMissing
        }
        
        logger.info(.auth, "🔍 Checking email verification status for: \(email)")
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        do {
            // Supabase Swift does not have getUserByEmail; use listUsers and filter
            let response = try await auth.admin.listUsers()
            if let user = response.users.first(where: { $0.email?.lowercased() == email.lowercased() }) {
                logger.authSuccess("✅ Email verification status checked")
                return user.emailConfirmedAt != nil
            } else {
                logger.authWarning("No user found for email: \(email)")
                return false
            }
        } catch {
            logger.authError("Failed to check email verification", error: error)
            let familyError = FamilyAuthError.networkError(error.localizedDescription)
            self.error = familyError
            throw familyError
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign up new family (creates auth account + parent profile)
    func signUpFamily(email: String, password: String, parentName: String) async throws {
        guard let auth = supabase.auth else {
            throw FamilyAuthError.configurationMissing
        }
        
        // Validate input
        try validateSignUpInput(email: email, password: password, parentName: parentName)
        
        logger.info(.auth, "🚀 Starting family signup for: \(email)")
        isLoading = true
        error = nil
        
        do {
            // Sign up with parent name in metadata
            let authResponse = try await auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(parentName)]
            )
            
            logger.authSuccess("✅ Family account created successfully!")
            
            // Check if immediately authenticated or needs email verification
            if let session = authResponse.session {
                logger.authSuccess("✅ Family immediately authenticated")
                await loadFamilyProfiles(for: session.user.id)
            } else {
                logger.info(.auth, "📧 Email verification required")
                authenticationState = .unauthenticated
            }
            
        } catch {
            logger.authError("Family signup failed", error: error)
            let familyError = FamilyAuthError.signUpFailed(error.localizedDescription)
            self.error = familyError
            throw familyError
        }
        
        isLoading = false
    }
    
    /// Sign in to family account
    func signInFamily(email: String, password: String) async throws {
        guard let auth = supabase.auth else {
            throw FamilyAuthError.configurationMissing
        }
        
        logger.info(.auth, "🔑 Starting family sign in for: \(email)")
        isLoading = true
        error = nil
        
        do {
            let session = try await auth.signIn(email: email, password: password)
            logger.authSuccess("Family sign in successful for: \(session.user.email ?? email)")
            await loadFamilyProfiles(for: session.user.id)
        } catch {
            logger.authError("Family sign in failed", error: error)
            let familyError = FamilyAuthError.signInFailed(error.localizedDescription)
            self.error = familyError
            throw familyError
        }
        
        isLoading = false
    }
    
    /// Sign out of family account
    func signOut() async throws {
        guard let auth = supabase.auth else {
            throw FamilyAuthError.configurationMissing
        }
        
        logger.info(.auth, "👋 Signing out of family account")
        isLoading = true
        error = nil
        
        do {
            try await auth.signOut()
            authenticationState = .unauthenticated
            availableProfiles = []
            selectedProfile = nil
            logger.authSuccess("Family sign out successful")
        } catch {
            logger.authError("Family sign out failed", error: error)
            let familyError = FamilyAuthError.networkError(error.localizedDescription)
            self.error = familyError
            throw familyError
        }
        
        isLoading = false
    }
    
    // MARK: - Profile Management
    
    private func loadFamilyProfiles(for authUserId: UUID) async {
        guard let client = supabase.client else {
            logger.authError("Database client not available")
            authenticationState = .unauthenticated
            return
        }
        
        logger.info(.auth, "🔄 Loading family profiles for user: \(authUserId)")
        
        // Give database trigger time to complete if this is a new signup
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Try up to 3 times with increasing delays (for race conditions with triggers)
        for attempt in 1...3 {
            do {
                logger.info(.auth, "🔍 Attempt \(attempt): Querying family_profiles table...")
                
                let profiles: [FamilyProfile] = try await client
                    .from("family_profiles")
                    .select()
                    .eq("auth_user_id", value: authUserId)
                    .order("role") // Parent first
                    .execute()
                    .value
                
                logger.info(.auth, "📊 Loaded \(profiles.count) family profiles on attempt \(attempt)")
                
                if !profiles.isEmpty {
                    // Success - we found profiles
                    availableProfiles = profiles
                    authenticationState = .authenticatedAwaitingProfile
                    logger.authSuccess("✅ Family profiles loaded, awaiting selection")
                    return
                }
                
                // No profiles found, but this might be normal for new users
                logger.info(.auth, "⚠️ No profiles found on attempt \(attempt)")
                
                // For new signups, the trigger might need more time
                if attempt < 3 {
                    let delay = TimeInterval(attempt) // 1s, 2s delays
                    logger.info(.auth, "⏳ Waiting \(delay)s before retry...")
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
            } catch {
                logger.authError("Attempt \(attempt) - Failed to load family profiles", error: error)
                
                if attempt == 3 {
                    // Final attempt failed
                    let familyError = FamilyAuthError.profileLoadingFailed(error.localizedDescription)
                    self.error = familyError
                    authenticationState = .unauthenticated
                    return
                }
            }
        }
        
        // If we get here, no profiles were found after all attempts
        logger.authWarning("⚠️ No profiles found after 3 attempts - this suggests the database trigger didn't fire")
        logger.authWarning("💡 Check that the handle_new_family_user() trigger is properly installed")
        logger.authWarning("💡 User metadata should contain 'name' field for trigger to activate")
        
        // Check what metadata we actually have
        if let auth = supabase.auth {
            do {
                let session = try await auth.session
                let metadata = session.user.userMetadata
                logger.info(.auth, "🔍 User metadata: \(metadata)")
            } catch {
                logger.authError("Could not retrieve session to check metadata", error: error)
            }
        }
        
        let familyError = FamilyAuthError.noProfilesFound
        self.error = familyError
        authenticationState = .unauthenticated
    }
    
    /// Select a profile to use for this session
    func selectProfile(_ profile: FamilyProfile) async {
        logger.info(.auth, "👤 Selecting profile: \(profile.name) (\(profile.role.displayName))")
        
        selectedProfile = profile
        authenticationState = .fullyAuthenticated(profile: profile)
        
        logger.authSuccess("✅ Profile selected: \(profile.name)")
    }
    
    /// Create a new child profile
    func createChildProfile(name: String) async throws {
        guard let client = supabase.client else {
            throw FamilyAuthError.configurationMissing
        }
        
        guard let auth = supabase.auth else {
            throw FamilyAuthError.configurationMissing
        }
        
        // Ensure we have parent permissions
        guard canManageFamily else {
            throw FamilyAuthError.parentAuthRequired
        }
        
        // Validate name
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FamilyAuthError.invalidInput("Child name cannot be empty")
        }
        
        logger.info(.auth, "👶 Creating child profile: \(name)")
        isLoading = true
        error = nil
        
        do {
            let session = try await auth.session
            let childProfile = FamilyProfile(
                authUserId: session.user.id,
                name: name,
                role: .child
            )
            
            let createdProfile: FamilyProfile = try await client
                .from("family_profiles")
                .insert(childProfile)
                .select()
                .single()
                .execute()
                .value
            
            // Add to available profiles
            availableProfiles.append(createdProfile)
            
            logger.authSuccess("✅ Child profile created: \(name)")
            
        } catch {
            logger.authError("Failed to create child profile", error: error)
            let familyError = FamilyAuthError.profileCreationFailed(error.localizedDescription)
            self.error = familyError
            throw familyError
        }
        
        isLoading = false
    }
    
    /// Update a profile name
    func updateProfile(_ profile: FamilyProfile, newName: String) async throws {
        guard let client = supabase.client else {
            throw FamilyAuthError.configurationMissing
        }
        
        // Ensure we have parent permissions or we're updating our own profile
        guard canManageFamily || profile.id == currentProfile?.id else {
            throw FamilyAuthError.parentAuthRequired
        }
        
        // Validate name
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FamilyAuthError.invalidInput("Profile name cannot be empty")
        }
        
        logger.info(.auth, "✏️ Updating profile \(profile.name) to \(newName)")
        isLoading = true
        error = nil
        
        do {
            let updatedProfile = profile.updatingName(newName)
            
            let returnedProfile: FamilyProfile = try await client
                .from("family_profiles")
                .update(updatedProfile)
                .eq("id", value: profile.id)
                .select()
                .single()
                .execute()
                .value
            
            // Update in available profiles
            if let index = availableProfiles.firstIndex(where: { $0.id == profile.id }) {
                availableProfiles[index] = returnedProfile
            }
            
            // Update selected profile if it's the one we updated
            if selectedProfile?.id == profile.id {
                selectedProfile = returnedProfile
                authenticationState = .fullyAuthenticated(profile: returnedProfile)
            }
            
            logger.authSuccess("✅ Profile updated: \(newName)")
            
        } catch {
            logger.authError("Failed to update profile", error: error)
            let familyError = FamilyAuthError.profileCreationFailed(error.localizedDescription)
            self.error = familyError
            throw familyError
        }
        
        isLoading = false
    }
    
    /// Delete a child profile (parent only)
    func deleteChildProfile(_ profile: FamilyProfile) async throws {
        guard let client = supabase.client else {
            throw FamilyAuthError.configurationMissing
        }
        
        // Ensure we have parent permissions and it's not a parent profile
        guard canManageFamily else {
            throw FamilyAuthError.parentAuthRequired
        }
        
        guard profile.role == .child else {
            throw FamilyAuthError.invalidInput("Cannot delete parent profile")
        }
        
        logger.info(.auth, "🗑️ Deleting child profile: \(profile.name)")
        isLoading = true
        error = nil
        
        do {
            try await client
                .from("family_profiles")
                .delete()
                .eq("id", value: profile.id)
                .execute()
            
            // Remove from available profiles
            availableProfiles.removeAll { $0.id == profile.id }
            
            // If this was the selected profile, clear selection
            if selectedProfile?.id == profile.id {
                selectedProfile = nil
                authenticationState = .authenticatedAwaitingProfile
            }
            
            logger.authSuccess("✅ Child profile deleted: \(profile.name)")
            
        } catch {
            logger.authError("Failed to delete child profile", error: error)
            let familyError = FamilyAuthError.profileCreationFailed(error.localizedDescription)
            self.error = familyError
            throw familyError
        }
        
        isLoading = false
    }
    
    // MARK: - Security & Parent Authorization
    
    /// Require parent authentication using biometrics or password
    func requireParentAuthorization() async throws {
        guard let currentProfile = currentProfile else {
            throw FamilyAuthError.parentAuthRequired
        }
        
        // If already parent, just require biometric
        if currentProfile.isParent {
            try await authenticateWithBiometrics()
            return
        }
        
        // For child profiles, require parent auth
        throw FamilyAuthError.parentAuthRequired
    }
    
    /// Authenticate using biometrics
    func authenticateWithBiometrics() async throws {
        guard biometricContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            throw FamilyAuthError.biometricsNotAvailable
        }
        
        logger.info(.auth, "🔐 Requesting biometric authentication")
        
        do {
            let reason = "Authenticate to access family controls"
            let success = try await biometricContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            
            if !success {
                throw FamilyAuthError.biometricsAuthFailed
            }
            
            logger.authSuccess("✅ Biometric authentication successful")
            
        } catch {
            logger.authError("Biometric authentication failed", error: error)
            throw FamilyAuthError.biometricsAuthFailed
        }
    }
    
    /// Check if profile switching should be restricted (for child profiles)
    var isProfileSwitchingRestricted: Bool {
        return currentProfile?.role == .child
    }
    
    /// Attempt to switch profiles (may require parent auth for child profiles)
    func switchToProfileSelectionWithSecurity() async throws {
        guard let currentProfile = currentProfile else { return }
        
        // If current profile is child, require parent authorization
        if currentProfile.role == .child {
            try await requireParentAuthorization()
        }
        
        // Switch to profile selection
        selectedProfile = nil
        authenticationState = .authenticatedAwaitingProfile
        
        logger.info(.auth, "🔄 Switched to profile selection")
    }
    
    #else
    // MARK: - Stub Methods for Non-Supabase Builds
    func signUpFamily(email: String, password: String, parentName: String) async throws {
        throw FamilyAuthError.configurationMissing
    }
    
    func signInFamily(email: String, password: String) async throws {
        throw FamilyAuthError.configurationMissing
    }
    
    func signOut() async throws {
        throw FamilyAuthError.configurationMissing
    }
    
    func selectProfile(_ profile: FamilyProfile) async { }
    
    func createChildProfile(name: String) async throws {
        throw FamilyAuthError.configurationMissing
    }
    
    func updateProfile(_ profile: FamilyProfile, newName: String) async throws {
        throw FamilyAuthError.configurationMissing
    }
    
    func deleteChildProfile(_ profile: FamilyProfile) async throws {
        throw FamilyAuthError.configurationMissing
    }
    
    func requireParentAuthorization() async throws {
        throw FamilyAuthError.configurationMissing
    }
    
    func authenticateWithBiometrics() async throws {
        throw FamilyAuthError.configurationMissing
    }
    
    func switchToProfileSelectionWithSecurity() async throws {
        throw FamilyAuthError.configurationMissing
    }
    #endif
    
    // MARK: - Utility Methods
    
    func clearError() {
        error = nil
    }
    
    private func validateSignUpInput(email: String, password: String, parentName: String) throws {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FamilyAuthError.invalidInput("Email cannot be empty")
        }
        
        guard email.contains("@") && email.contains(".") else {
            throw FamilyAuthError.invalidInput("Please enter a valid email address")
        }
        
        guard password.count >= 6 else {
            throw FamilyAuthError.invalidInput("Password must be at least 6 characters")
        }
        
        guard !parentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FamilyAuthError.invalidInput("Parent name cannot be empty")
        }
        
        guard parentName.count <= 100 else {
            throw FamilyAuthError.invalidInput("Parent name cannot exceed 100 characters")
        }
    }
} 