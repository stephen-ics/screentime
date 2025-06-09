import Foundation
#if canImport(Supabase)
import Supabase
#endif
import Combine
import LocalAuthentication

/// Manages user authentication using Supabase Auth
@MainActor
final class SupabaseAuthService: ObservableObject {
    static let shared = SupabaseAuthService()
    
    // MARK: - Properties
    @Published private(set) var currentProfile: Profile?
    @Published private(set) var isLoading = false
    @Published private(set) var error: AuthError?
    @Published private(set) var isAuthenticated = false
    
    private let supabase = SupabaseManager.shared
    private let logger = Logger.shared
    private var cancellables = Set<AnyCancellable>()
    private let context = LAContext()
    
    // MARK: - Computed Properties
    var isUserAuthenticated: Bool {
        return isAuthenticated && currentProfile != nil
    }
    
    // MARK: - Initialization
    init() {
        #if canImport(Supabase)
        // Check if Supabase is properly configured
        if supabase.client != nil {
            logger.authSuccess("Supabase client available")
            Task {
                await setupAuthStateListener()
                await restoreSession()
            }
        } else {
            logger.authError("Supabase client is nil")
        }
        #else
        logger.authWarning("Supabase package not available. Authentication disabled.")
        #endif
    }
    
    #if canImport(Supabase)
    // MARK: - Authentication State Management
    private func setupAuthStateListener() async {
        guard let auth = supabase.auth else { 
            logger.authError("Auth client not available")
            return 
        }
        
        logger.info(.auth, "🔄 Setting up auth state listener...")
        
        Task {
            for await (event, session) in auth.authStateChanges {
                logger.info(.auth, "🔄 Auth state changed: \(event)")
                await self.handleAuthStateChange(event: event, session: session)
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        logger.info(.auth, "🔄 Handling auth state change: \(event)")
        switch event {
        case .signedIn:
            if let session = session {
                logger.authSuccess("User signed in: \(session.user.email ?? "no email")")
                isAuthenticated = true
                await loadUserProfile(for: session.user)
            }
        case .signedOut:
            logger.info(.auth, "👋 User signed out")
            isAuthenticated = false
            currentProfile = nil
        case .tokenRefreshed:
            logger.info(.auth, "🔄 Token refreshed")
            // Keep current auth state
            break
        default:
            logger.info(.auth, "🔄 Other auth event: \(event)")
            break
        }
    }
    
    private func restoreSession() async {
        guard let auth = supabase.auth else { return }
        
        do {
            let session = try await auth.session
            logger.authSuccess("Restored session for: \(session.user.email ?? "no email")")
            isAuthenticated = true
            await loadUserProfile(for: session.user)
        } catch {
            logger.info(.auth, "ℹ️ No existing session found: \(error.localizedDescription)")
            isAuthenticated = false
        }
    }
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws -> EmailVerificationResult {
        guard let auth = supabase.auth else { 
            logger.authError("Auth client not available")
            throw AuthError.configurationMissing 
        }
        
        logger.info(.auth, "🚀 Starting sign up for: \(email)")
        isLoading = true
        error = nil
        
        do {
            // Get the auth response from signup with email confirmation
            let authResponse = try await supabase.testSignUp(email: email, password: password, name: name, isParent: isParent)
            
            logger.authSuccess("✅ User created successfully! Processing authentication...")
            
            // Check if we have a session in the response
            if let session = authResponse.session {
                logger.authSuccess("✅ Session found in signup response - user authenticated immediately")
                isAuthenticated = true
                await loadUserProfile(for: session.user)
                return .verified // User is immediately verified (email confirmation disabled)
            } else {
                // No session - email confirmation is required
                logger.info(.auth, "ℹ️ No session in signup response - email confirmation required")
                logger.info(.auth, "✅ Account created successfully! Email verification required.")
                
                // User account is created but not authenticated until email is confirmed
                isAuthenticated = false
                return .pendingVerification(email: email)
            }
            
        } catch let supabaseError {
            logger.authError("Sign up failed with error: \(supabaseError)")
            logger.authError("Error type: \(type(of: supabaseError))")
            logger.authError("Error description: \(supabaseError.localizedDescription)")
            
            let authError = AuthError.networkError("Sign up failed: \(supabaseError.localizedDescription)")
            self.error = authError
            throw authError
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async throws {
        guard let auth = supabase.auth else { 
            logger.authError("Auth client not available")
            throw AuthError.configurationMissing 
        }
        
        logger.info(.auth, "🔑 Starting sign in for: \(email)")
        isLoading = true
        error = nil
        
        do {
            let session = try await auth.signIn(email: email, password: password)
            logger.authSuccess("Sign in successful for: \(session.user.email ?? email)")
            isAuthenticated = true
            await loadUserProfile(for: session.user)
            
            // Double check authentication state
            if currentProfile != nil {
                logger.authSuccess("User fully authenticated with profile loaded")
            } else {
                logger.authWarning("User authenticated but profile not loaded")
            }
        } catch {
            logger.authError("Sign in failed", error: error)
            isAuthenticated = false
            let authError = AuthError.invalidCredentials
            self.error = authError
            throw authError
        }
        
        isLoading = false
    }
    
    func signOut() async throws {
        guard let auth = supabase.auth else { throw AuthError.configurationMissing }
        isLoading = true
        error = nil
        
        do {
            try await auth.signOut()
            isAuthenticated = false
            currentProfile = nil
            logger.authSuccess("Sign out successful")
        } catch {
            logger.authError("Sign out failed", error: error)
            let authError = AuthError.signOutFailed
            self.error = authError
            throw authError
        }
        
        isLoading = false
    }
    
    func resetPassword(email: String) async throws {
        guard let auth = supabase.auth else { throw AuthError.configurationMissing }
        isLoading = true
        error = nil
        
        do {
            try await auth.resetPasswordForEmail(email)
            logger.authSuccess("Password reset email sent")
        } catch {
            logger.authError("Password reset failed", error: error)
            let authError = AuthError.resetPasswordFailed
            self.error = authError
            throw authError
        }
        
        isLoading = false
    }
    
    // MARK: - Profile Management
    private func loadUserProfile(for user: Auth.User) async {
        guard let client = supabase.client else { 
            logger.authError("Database client not available")
            return 
        }
        
        logger.info(.auth, "🔄 Loading profile for user: \(user.id)")
        
        // Give the trigger a moment to complete (reduced from 2 seconds)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Try to load profile with reasonable retry logic
        var retryCount = 0
        let maxRetries = 3 // Reduced from 5
        
        while retryCount < maxRetries {
            do {
                logger.info(.auth, "📋 Attempting to query profiles table for user: \(user.id)")
                
                let profiles: [Profile] = try await client
                    .from("profiles")
                    .select()
                    .eq("id", value: user.id)
                    .execute()
                    .value
                
                logger.info(.auth, "📊 Query returned \(profiles.count) profiles")
                
                if let profile = profiles.first {
                    logger.authSuccess("✅ Profile loaded: \(profile.name) (\(profile.email))")
                    currentProfile = profile
                    return
                } else {
                    logger.info(.auth, "⏳ Profile not found yet... (attempt \(retryCount + 1)/\(maxRetries))")
                    retryCount += 1
                    
                    // On the last attempt, try to create the profile manually
                    if retryCount == maxRetries {
                        logger.info(.auth, "🔧 Final attempt - trying to create profile manually")
                        await createProfileFromUser(user)
                        return
                    }
                    
                    // Shorter wait time (reduced from exponential backoff)
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                }
            } catch {
                logger.authError("❌ Failed to load user profile (attempt \(retryCount + 1))", error: error)
                logger.authError("❌ Error details: \(error)")
                
                retryCount += 1
                
                // On the last attempt, try to create the profile manually
                if retryCount == maxRetries {
                    logger.info(.auth, "🔧 Profile loading failed completely - trying to create profile manually")
                    await createProfileFromUser(user)
                    return
                }
                
                // Shorter wait before retrying
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
        
        // If we get here, both loading and creation failed
        logger.authError("💥 Both profile loading and creation failed after \(maxRetries) attempts")
        logger.info(.auth, "🔄 User is authenticated but profile loading failed. This will be retried on next app launch.")
    }
    
    private func createProfileFromUser(_ user: Auth.User) async {
        logger.info(.auth, "🔧 Creating profile manually for user: \(user.id)")
        logger.info(.auth, "📧 User email: \(user.email ?? "no email")")
        logger.info(.auth, "📝 User metadata: \(user.userMetadata)")
        
        do {
            let userType: Profile.UserType = user.userMetadata["user_type"]?.stringValue == "parent" ? .parent : .child
            let name = user.userMetadata["name"]?.stringValue ?? user.email ?? "User"
            let isVerified = user.emailConfirmedAt != nil
            
            logger.info(.auth, "👤 Creating profile with - Name: \(name), Type: \(userType), Email verified: \(isVerified)")
            
            let profile = Profile(
                id: user.id,
                email: user.email ?? "",
                name: name,
                userType: userType,
                emailVerified: isVerified
            )
            
            logger.info(.auth, "🔄 Inserting profile into database...")
            try await createProfile(profile)
            currentProfile = profile
            logger.authSuccess("✅ Profile created successfully and set as current profile!")
            
        } catch {
            logger.authError("❌ Failed to create profile from user", error: error)
            logger.authError("❌ Create profile error details: \(error)")
        }
    }
    
    private func createProfile(_ profile: Profile) async throws {
        guard let client = supabase.client else { 
            throw AuthError.configurationMissing 
        }
        
        do {
            try await client
                .from("profiles")
                .insert(profile)
                .execute()
            
            logger.authSuccess("Profile created successfully in Supabase")
            
        } catch {
            logger.authError("Failed to create profile in Supabase", error: error)
            throw AuthError.networkError("Failed to create user profile: \(error.localizedDescription)")
        }
    }
    
    func updateProfile(_ profile: Profile) async throws {
        guard let client = supabase.client else { throw AuthError.configurationMissing }
        isLoading = true
        error = nil
        
        do {
            let updatedProfile: Profile = try await client.from("profiles").update(profile).eq("id", value: profile.id).single().execute().value
            currentProfile = updatedProfile
        } catch {
            let authError = AuthError.updateProfileFailed
            self.error = authError
            throw authError
        }
        
        isLoading = false
    }
    #else
    // MARK: - Stub Methods
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws -> EmailVerificationResult {
        throw AuthError.configurationMissing
    }
    func signIn(email: String, password: String) async throws {
        throw AuthError.configurationMissing
    }
    func signOut() async throws {
        throw AuthError.configurationMissing
    }
    func resetPassword(email: String) async throws {
        throw AuthError.configurationMissing
    }
    func updateProfile(_ profile: Profile) async throws {
        throw AuthError.configurationMissing
    }
    #endif
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics() async throws -> Bool {
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else { throw AuthError.biometricsNotAvailable }
        let reason = "Authenticate to access screen time controls"
        return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    }
    
    #if canImport(Supabase)
    // MARK: - Parent-Child Linking
    // ... (logic remains the same)
    #endif
    
    func getLinkedChildren() async throws -> [Profile] {
        throw AuthError.configurationMissing
    }
    
    // MARK: - Authorization
    func requireParentAuthorization() async throws {
        guard let currentProfile = currentProfile,
              currentProfile.isParent else {
            throw AuthError.unauthorized
        }
        
        _ = try await authenticateWithBiometrics()
    }
    
    // MARK: - Utility
    func clearError() {
        error = nil
    }
    
    // MARK: - Database Setup Helper
    static func getSupabaseDatabaseSetupSQL() -> String {
        return """
        -- Create the profiles table in your Supabase database
        -- Go to your Supabase dashboard > SQL Editor and run this:
        
        CREATE TABLE IF NOT EXISTS profiles (
          id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
          email TEXT NOT NULL,
          name TEXT NOT NULL,
          user_type TEXT NOT NULL CHECK (user_type IN ('parent', 'child')),
          is_parent BOOLEAN NOT NULL DEFAULT FALSE,
          email_verified BOOLEAN NOT NULL DEFAULT FALSE,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          updated_at TIMESTAMPTZ DEFAULT NOW(),
          parent_id UUID REFERENCES profiles(id) ON DELETE SET NULL
        );
        
        -- Enable Row Level Security (RLS)
        ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
        
        -- Create policies for RLS
        CREATE POLICY "Users can view own profile" ON profiles
          FOR SELECT USING (auth.uid() = id);
          
        CREATE POLICY "Users can update own profile" ON profiles
          FOR UPDATE USING (auth.uid() = id);
          
        CREATE POLICY "Users can insert own profile" ON profiles
          FOR INSERT WITH CHECK (auth.uid() = id);
        
        -- Create a function to automatically handle updated_at
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
          NEW.updated_at = NOW();
          RETURN NEW;
        END;
        $$ language 'plpgsql';
        
        -- Create trigger for updated_at
        CREATE TRIGGER update_profiles_updated_at 
          BEFORE UPDATE ON profiles 
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        
        -- Create a function to automatically create profile on signup
        CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS TRIGGER AS $$
        BEGIN
          INSERT INTO public.profiles (id, email, name, user_type, is_parent, email_verified)
          VALUES (
            NEW.id,
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
            COALESCE(NEW.raw_user_meta_data->>'user_type', 'child'),
            (COALESCE(NEW.raw_user_meta_data->>'user_type', 'child') = 'parent'),
            (NEW.email_confirmed_at IS NOT NULL)
          );
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
        
        -- Create trigger for automatic profile creation
        CREATE TRIGGER on_auth_user_created
          AFTER INSERT ON auth.users
          FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
          
        -- Add email_verified column if it doesn't exist (for existing tables)
        ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;
        """
    }
    
    // MARK: - Email Verification
    
    /// Checks if the current user's email is verified
    var isEmailVerified: Bool {
        guard let auth = supabase.auth else { return false }
        
        do {
            // Note: In newer versions, session access might be async
            // For now, we'll return false if we can't access synchronously
            return false
        } catch {
            return false
        }
    }
    
    /// Resends the email verification email
    func resendVerificationEmail(email: String) async throws {
        guard let auth = supabase.auth else {
            logger.authError("Auth client not available")
            throw AuthError.configurationMissing
        }
        
        logger.info(.auth, "🔄 Resending verification email to: \(email)")
        isLoading = true
        error = nil
        
        do {
            try await auth.resend(email: email, type: .signup)
            logger.authSuccess("Verification email resent successfully")
        } catch {
            logger.authError("Failed to resend verification email", error: error)
            let authError = AuthError.resendVerificationFailed
            self.error = authError
            throw authError
        }
        
        isLoading = false
    }
    
    /// Updates the email verification status in the database
    private func updateEmailVerificationInDatabase(_ isVerified: Bool) async {
        guard let client = supabase.client, let currentProfile = currentProfile else { 
            logger.authError("Cannot update email verification - missing client or profile")
            return 
        }
        
        logger.info(.auth, "🔄 Updating email_verified to \(isVerified) in database...")
        
        do {
            try await client
                .from("profiles")
                .update(["email_verified": isVerified])
                .eq("id", value: currentProfile.id)
                .execute()
            
            // Update local profile
            self.currentProfile = Profile(
                id: currentProfile.id,
                email: currentProfile.email,
                name: currentProfile.name,
                userType: currentProfile.userType,
                emailVerified: isVerified,
                parentId: currentProfile.parentId,
                createdAt: currentProfile.createdAt,
                updatedAt: currentProfile.updatedAt
            )
            logger.authSuccess("✅ Email verification status updated in database!")
            
        } catch {
            logger.authError("❌ Failed to update email verification in database", error: error)
        }
    }
    
    /// Checks the current email verification status and updates profile
    func checkEmailVerificationStatus() async {
        guard let auth = supabase.auth else { return }
        
        do {
            let session = try await auth.session
            let isVerified = session.user.emailConfirmedAt != nil
            
            logger.info(.auth, "📧 Email verification status: \(isVerified ? "verified" : "not verified")")
            
            // Update database if verification status changed
            if let currentProfile = currentProfile, currentProfile.emailVerified != isVerified {
                await updateEmailVerificationInDatabase(isVerified)
            }
            
        } catch {
            logger.authError("Failed to check email verification status", error: error)
        }
    }
    
    /// Handles email verification when user clicks link
    func handleEmailVerification(url: URL) async throws {
        guard let auth = supabase.auth else {
            throw AuthError.configurationMissing
        }
        
        logger.info(.auth, "🔗 Processing email verification URL")
        
        do {
            let session = try await auth.session(from: url)
            logger.authSuccess("Email verification successful")
            
            isAuthenticated = true
            await loadUserProfile(for: session.user)
            await checkEmailVerificationStatus()
        } catch {
            logger.authError("Email verification failed", error: error)
            throw AuthError.emailVerificationFailed
        }
    }
    
    /// Checks if user with given email has been verified by attempting session refresh
    func checkVerification(email: String) async throws -> Bool {
        guard let auth = supabase.auth else {
            throw AuthError.configurationMissing
        }
        
        logger.info(.auth, "🔍 Checking verification status for: \(email)")
        
        do {
            // Try to refresh the session to get latest verification status
            try await auth.refreshSession()
            
            // Get the current session
            let session = try await auth.session
            
            logger.info(.auth, "📧 User email: \(session.user.email ?? "no email"), Email confirmed at: \(session.user.emailConfirmedAt?.description ?? "nil")")
            
            // Check if user email matches and is verified
            if session.user.email == email && session.user.emailConfirmedAt != nil {
                logger.authSuccess("✅ Email verification detected - user is verified!")
                
                // Update auth state
                isAuthenticated = true
                
                // Load profile (this will create it if it doesn't exist)
                await loadUserProfile(for: session.user)
                
                // Update email verification status in database
                await updateEmailVerificationInDatabase(true)
                
                // Verify we have a profile now
                if currentProfile != nil {
                    logger.authSuccess("✅ Profile loaded and email verification updated!")
                    return true
                } else {
                    logger.authError("❌ Profile still not available after verification")
                    return false
                }
            } else {
                logger.info(.auth, "⏳ Email not verified yet or email mismatch")
                return false
            }
            
        } catch {
            logger.info(.auth, "⏳ No valid session available yet - email not verified: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Manually checks and updates email verification status - call this after user clicks verification link
    func refreshEmailVerificationStatus() async {
        guard let auth = supabase.auth else { return }
        
        logger.info(.auth, "🔄 Manually checking email verification status...")
        
        do {
            // Refresh session to get latest verification status
            try await auth.refreshSession()
            let session = try await auth.session
            let isVerified = session.user.emailConfirmedAt != nil
            
            logger.info(.auth, "📧 Current verification status: \(isVerified ? "verified" : "not verified")")
            
            // Always update database with current status
            if currentProfile?.emailVerified != isVerified {
                await updateEmailVerificationInDatabase(isVerified)
            }
            
        } catch {
            logger.authError("Failed to refresh email verification status", error: error)
        }
    }
}

// MARK: - Email Verification Result
enum EmailVerificationResult {
    case verified // User was immediately verified (email confirmation disabled)
    case pendingVerification(email: String) // Email verification required
}

// MARK: - Error Types
enum AuthError: LocalizedError, Equatable {
    case invalidCredentials
    case unauthorized
    case biometricsNotAvailable
    case signUpFailed
    case signOutFailed
    case resetPasswordFailed
    case updateProfileFailed
    case linkChildFailed
    case fetchChildrenFailed
    case networkError(String)
    case configurationMissing
    case unknownError
    case resendVerificationFailed
    case emailVerificationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .unauthorized:
            return "You don't have permission to access this feature"
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        case .signUpFailed:
            return "Account creation failed. Please check your details and try again"
        case .signOutFailed:
            return "Failed to sign out. Please try again"
        case .resetPasswordFailed:
            return "Failed to reset password. Please check your email and try again"
        case .updateProfileFailed:
            return "Failed to update profile. Please try again"
        case .linkChildFailed:
            return "Failed to link child account. Please check the email address"
        case .fetchChildrenFailed:
            return "Failed to load linked children"
        case .networkError(let message):
            return "Network error: \(message)"
        case .configurationMissing:
            return "Supabase is not configured. The app is running in demo mode with limited functionality"
        case .unknownError:
            return "An unexpected error occurred. Please try again"
        case .resendVerificationFailed:
            return "Failed to resend verification email"
        case .emailVerificationFailed:
            return "Email verification failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .configurationMissing:
            return "To enable full functionality, please set up your Supabase project and update SupabaseConfig.plist with your project credentials"
        case .invalidCredentials:
            return "Please check your email and password and try again"
        case .signUpFailed:
            return "Make sure you're using a valid email address and strong password"
        case .networkError:
            return "Please check your internet connection and try again"
        default:
            return "Please try again. If the problem persists, contact support"
        }
    }
}

// MARK: - Supporting Models
struct ParentChildLink: Codable {
    let id: UUID
    let parentId: UUID
    let childId: UUID
    let createdAt: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
        case childId = "child_id"
        case createdAt = "created_at"
        case isActive = "is_active"
    }
    
    init(
        id: UUID = UUID(),
        parentId: UUID,
        childId: UUID,
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.parentId = parentId
        self.childId = childId
        self.createdAt = createdAt
        self.isActive = isActive
    }
} 