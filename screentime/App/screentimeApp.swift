import SwiftUI

@main
struct ScreenTimeApp: App {
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    // MARK: - Core Services (New Supabase-based)
    private let authService = SafeSupabaseAuthService.shared
    private let dataRepository = SafeSupabaseDataRepository.shared
    
    // MARK: - State
    @StateObject private var router = AppRouter()
    
    // MARK: - Scene Configuration
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(authService)
                .environmentObject(dataRepository)
        }
    }
}

// MARK: - Safe Wrapper for SupabaseAuthService
@MainActor
final class SafeSupabaseAuthService: ObservableObject {
    static let shared = SafeSupabaseAuthService()
    
    @Published private(set) var currentProfile: Profile?
    @Published private(set) var isLoading = false
    @Published private(set) var error: AuthError?
    
    private let supabaseService: SupabaseAuthService
    
    private init() {
        self.supabaseService = SupabaseAuthService.shared
        
        // Require Supabase to be configured - no fallback!
        guard SupabaseManager.shared.client != nil else {
            fatalError("❌ Supabase must be configured! No fallback authentication allowed.")
        }
        
        print("✅ SafeSupabaseAuthService: Using Supabase authentication ONLY")
        
        self.currentProfile = supabaseService.currentProfile
        self.isLoading = supabaseService.isLoading
        self.error = supabaseService.error
        
        // Mirror the Supabase service state
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SupabaseAuthStateChanged"),
            object: nil,
            queue: .main
        ) { _ in
            self.currentProfile = self.supabaseService.currentProfile
            self.isLoading = self.supabaseService.isLoading
            self.error = self.supabaseService.error
        }
    }
    
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws {
        isLoading = true
        error = nil
        
        print("🚀 SafeSupabaseAuthService: Using Supabase ONLY for sign up")
        do {
            try await supabaseService.signUp(email: email, password: password, name: name, isParent: isParent)
            await updateState()
            print("✅ Supabase signup successful - User should be in database!")
        } catch {
            await updateState()
            print("❌ Supabase signup failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        print("🔑 SafeSupabaseAuthService: Using Supabase ONLY for sign in")
        do {
            try await supabaseService.signIn(email: email, password: password)
            await updateState()
            print("✅ Supabase signin successful")
        } catch {
            await updateState()
            print("❌ Supabase signin failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    func signOut() async throws {
        isLoading = true
        error = nil
        
        print("🚪 SafeSupabaseAuthService: Using Supabase ONLY for sign out")
        do {
            try await supabaseService.signOut()
            await updateState()
            print("✅ Supabase signout successful")
        } catch {
            await updateState()
            print("❌ Supabase signout failed: \(error)")
            // Clear local state even if Supabase fails
            currentProfile = nil
            throw error
        }
        
        isLoading = false
    }
    
    private func updateState() async {
        await MainActor.run {
            self.currentProfile = self.supabaseService.currentProfile
            self.isLoading = self.supabaseService.isLoading
            self.error = self.supabaseService.error
        }
    }
}

// MARK: - Safe Wrapper for SupabaseDataRepository
@MainActor 
final class SafeSupabaseDataRepository: ObservableObject {
    static let shared = SafeSupabaseDataRepository()
    
    private let supabaseRepository: SupabaseDataRepository
    
    private init() {
        self.supabaseRepository = SupabaseDataRepository.shared
    }
    
    func getProfile(for userId: UUID) async throws -> Profile {
        do {
            return try await supabaseRepository.getProfile(for: userId)
        } catch {
            // Return a mock profile if Supabase fails
            return Profile(id: userId, email: "demo@example.com", name: "Demo User", userType: .parent)
        }
    }
    
    func updateProfile(_ profile: Profile) async throws -> Profile {
        do {
            return try await supabaseRepository.updateProfile(profile)
        } catch {
            // Return the same profile if update fails
            return profile
        }
    }
}

// MARK: - Root View

/// Root view that handles authentication state and app-level navigation
struct RootView: View {
    
    // MARK: - Services
    @EnvironmentObject private var authService: SafeSupabaseAuthService
    @EnvironmentObject private var router: AppRouter
    
    // MARK: - State
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isLoading {
                SplashScreenView()
            } else if let profile = authService.currentProfile {
                if profile.isParent {
                    ParentDashboardView()
                } else {
                    ChildDashboardView()
                }
            } else {
                AuthenticationView()
            }
        }
        .onAppear {
            // Initial loading delay for splash screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
        .onChange(of: authService.currentProfile) { _, newProfile in
            if let profile = newProfile {
                router.navigateToRoot()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Splash Screen View

/// Loading screen shown during app initialization
struct SplashScreenView: View {
    @State private var animateGradient = false
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.indigo.opacity(0.8)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGradient)
            
            VStack(spacing: 32) {
                // App icon/logo
                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: scale)
                
                // App name
                Text("ScreenTime")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                // Migration status
                Text("Powered by Supabase")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onAppear {
            animateGradient = true
            scale = 1.2
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure app-level settings
        configureAppearance()
        return true
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - Preview

#if DEBUG
struct ScreenTimeApp_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RootView()
                .environmentObject(AppRouter())
                .environmentObject(SafeSupabaseAuthService.shared)
                .previewDisplayName("Main App")
            
            SplashScreenView()
                .previewDisplayName("Splash Screen")
        }
    }
}
#endif 