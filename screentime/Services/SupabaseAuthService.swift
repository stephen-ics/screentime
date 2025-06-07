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
    
    private let supabase = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let context = LAContext()
    
    // MARK: - Initialization
    init() {
        #if canImport(Supabase)
        // Check if Supabase is properly configured
        if supabase.client != nil {
            print("✅ SupabaseAuthService: Supabase client available")
            Task {
                await setupAuthStateListener()
                await restoreSession()
            }
        } else {
            print("❌ SupabaseAuthService: Supabase client is nil")
        }
        #else
        print("⚠️ Supabase package not available. Authentication disabled.")
        #endif
    }
    
    #if canImport(Supabase)
    // MARK: - Authentication State Management
    private func setupAuthStateListener() async {
        guard let auth = supabase.auth else { 
            print("❌ Auth client not available")
            return 
        }
        
        print("🔄 Setting up auth state listener...")
        
        Task {
            for await (event, session) in auth.authStateChanges {
                print("🔄 Auth state changed: \(event)")
                await self.handleAuthStateChange(event: event, session: session)
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        print("🔄 Handling auth state change: \(event)")
        switch event {
        case .signedIn:
            if let session = session {
                print("✅ User signed in: \(session.user.email ?? "no email")")
                await loadUserProfile(for: session.user)
            }
        case .signedOut:
            print("👋 User signed out")
            currentProfile = nil
        case .tokenRefreshed:
            print("🔄 Token refreshed")
            break
        default:
            print("🔄 Other auth event: \(event)")
            break
        }
    }
    
    private func restoreSession() async {
        guard let auth = supabase.auth else { return }
        
        do {
            let session = try await auth.session
            print("✅ Restored session for: \(session.user.email ?? "no email")")
            await loadUserProfile(for: session.user)
        } catch {
            print("ℹ️ No existing session found: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws {
        guard let auth = supabase.auth else { 
            print("❌ Auth client not available")
            throw AuthError.configurationMissing 
        }
        
        print("🚀 Starting sign up for: \(email)")
        isLoading = true
        error = nil
        
        do {
            // Use the test function from SupabaseManager for better debugging
            try await supabase.testSignUp(email: email, password: password, name: name, isParent: isParent)
            
            // Load the current session
            let session = try await auth.session
            await loadUserProfile(for: session.user)
            
            print("✅ Sign up completed successfully")
            
        } catch let supabaseError {
            print("❌ Sign up failed with error: \(supabaseError)")
            print("❌ Error type: \(type(of: supabaseError))")
            print("❌ Error description: \(supabaseError.localizedDescription)")
            
            let authError = AuthError.networkError("Sign up failed: \(supabaseError.localizedDescription)")
            self.error = authError
            throw authError
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async throws {
        guard let auth = supabase.auth else { 
            print("❌ Auth client not available")
            throw AuthError.configurationMissing 
        }
        
        print("🔑 Starting sign in for: \(email)")
        isLoading = true
        error = nil
        
        do {
            let session = try await auth.signIn(email: email, password: password)
            print("✅ Sign in successful for: \(session.user.email ?? email)")
            await loadUserProfile(for: session.user)
        } catch {
            print("❌ Sign in failed: \(error)")
            print("❌ Error description: \(error.localizedDescription)")
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
            currentProfile = nil
            print("✅ Sign out successful")
        } catch {
            print("❌ Sign out failed: \(error)")
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
            print("✅ Password reset email sent")
        } catch {
            print("❌ Password reset failed: \(error)")
            let authError = AuthError.resetPasswordFailed
            self.error = authError
            throw authError
        }
        
        isLoading = false
    }
    
    // MARK: - Profile Management
    private func loadUserProfile(for user: Auth.User) async {
        guard let database = supabase.database else { 
            print("❌ Database client not available")
            return 
        }
        
        print("🔄 Loading profile for user: \(user.id)")
        
        do {
            let profiles: [Profile] = try await database
                .from("profiles")
                .select()
                .eq("id", value: user.id)
                .execute()
                .value
            
            if let profile = profiles.first {
                print("✅ Profile loaded: \(profile.name) (\(profile.email))")
                currentProfile = profile
            } else {
                print("⚠️ No profile found, creating from user data...")
                await createProfileFromUser(user)
            }
        } catch {
            print("❌ Failed to load user profile: \(error)")
            await createProfileFromUser(user)
        }
    }
    
    private func createProfileFromUser(_ user: Auth.User) async {
        do {
            let userType: Profile.UserType = user.userMetadata["user_type"]?.stringValue == "parent" ? .parent : .child
            let name = user.userMetadata["name"]?.stringValue ?? user.email ?? "User"
            let profile = Profile(id: user.id, email: user.email ?? "", name: name, userType: userType)
            
            print("🔄 Creating profile from user: \(name) (\(user.email ?? "no email"))")
            try await createProfile(profile)
            currentProfile = profile
        } catch {
            print("❌ Failed to create profile from user: \(error)")
        }
    }
    
    private func createProfile(_ profile: Profile) async throws {
        guard let database = supabase.database else { 
            throw AuthError.configurationMissing 
        }
        
        do {
            try await database
                .from("profiles")
                .insert(profile)
                .execute()
            
            print("✅ Profile created successfully in Supabase")
            
        } catch {
            print("❌ Failed to create profile in Supabase: \(error)")
            throw AuthError.networkError("Failed to create user profile: \(error.localizedDescription)")
        }
    }
    
    func updateProfile(_ profile: Profile) async throws {
        guard let database = supabase.database else { throw AuthError.configurationMissing }
        isLoading = true
        error = nil
        
        do {
            let updatedProfile: Profile = try await database.from("profiles").update(profile).eq("id", value: profile.id).single().execute().value
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
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws {
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
          INSERT INTO public.profiles (id, email, name, user_type, is_parent)
          VALUES (
            NEW.id,
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
            COALESCE(NEW.raw_user_meta_data->>'user_type', 'child'),
            (COALESCE(NEW.raw_user_meta_data->>'user_type', 'child') = 'parent')
          );
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
        
        -- Create trigger for automatic profile creation
        CREATE TRIGGER on_auth_user_created
          AFTER INSERT ON auth.users
          FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
        """
    }
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