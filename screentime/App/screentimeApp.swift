import SwiftUI
import _Concurrency

@main
struct ScreenTimeApp: App {
    // MARK: - Properties
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var familyAuthService = FamilyAuthService.shared
    @StateObject private var router = AppRouter()
    
    // MARK: - Scene Configuration
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(familyAuthService)
                .environmentObject(router)
        }
    }
}

// MARK: - Root View

struct RootView: View {
    
    // MARK: - Services
    @EnvironmentObject private var familyAuthService: FamilyAuthService
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
            } else {
                switch familyAuthService.authenticationState {
                case .unauthenticated:
                    FamilyAuthenticationView()
                case .authenticatedAwaitingProfile:
                    ProfileSelectionView()
                case .fullyAuthenticated(let profile):
                    // Use MainAppView with proper tab navigation
                    MainAppView(profile: profile)
                        .environmentObject(router)
                }
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
        .onChange(of: familyAuthService.error) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                familyAuthService.clearError()
            }
        } message: {
            Text(errorMessage)
        }
        // Handle sheet presentations from router
        .sheet(item: $router.presentedSheet) { sheet in
            sheetContent(for: sheet)
        }
    }
    
    // MARK: - Sheet Content
    
    @ViewBuilder
    private func sheetContent(for sheet: SheetDestination) -> some View {
        NavigationView {
            switch sheet {
            case .addChild:
                AddChildProfileSheet()
                    .environmentObject(familyAuthService)
            case .timeRequests:
                TimeRequestsView()
                    .environmentObject(familyAuthService)
            case .settings:
                ParentSettingsView(profile: familyAuthService.currentProfile ?? FamilyProfile.mockParent)
                    .environmentObject(familyAuthService)
            case .addTask:
                PlaceholderSheetView(title: "Add Task", description: "Create a new task for children")
            case .account:
                PlaceholderSheetView(title: "Account", description: "Manage your account settings")
            case .editProfile:
                PlaceholderSheetView(title: "Edit Profile", description: "Edit your profile information")
            case .changePassword:
                PlaceholderSheetView(title: "Change Password", description: "Change your password")
            case .addApprovedApp:
                PlaceholderSheetView(title: "Add App", description: "Add an approved app")
            case .supabaseSetup:
                PlaceholderSheetView(title: "Setup", description: "Configure Supabase connection")
            }
        }
    }
}

// MARK: - Placeholder Sheet View

struct PlaceholderSheetView: View {
    let title: String
    let description: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(description)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button("Coming Soon") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Main App View with Tab Navigation

struct MainAppView: View {
    let profile: FamilyProfile
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        TabView {
            // Dashboard Tab
            DashboardView(profile: profile)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Screen Time Tab
            ScreenTimeView(profile: profile)
                .tabItem {
                    Image(systemName: "hourglass")
                    Text("Screen Time")
                }
                .tag(1)
            
            // Apps Tab
            AppsView(profile: profile)
                .tabItem {
                    Image(systemName: "app.fill")
                    Text("Apps")
                }
                .tag(2)
            
            // Settings Tab (conditional based on role)
            if profile.canManageFamily {
                ParentSettingsView(profile: profile)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(3)
            } else {
                ChildSettingsView(profile: profile)
                    .tabItem {
                        Image(systemName: "person.crop.circle")
                        Text("Profile")
                    }
                    .tag(3)
            }
        }
        .accentColor(profile.isParent ? .blue : .green)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    let profile: FamilyProfile
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        NavigationView {
            if profile.isParent {
                // Use the existing ParentDashboardView content but with proper navigation
                ParentDashboardView()
                    .environmentObject(router)
            } else {
                ChildDashboardView()
            }
        }
    }
}

// MARK: - Screen Time View
struct ScreenTimeView: View {
    let profile: FamilyProfile
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Screen Time Management")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Role: \(profile.displayRole)")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if profile.isParent {
                    Text("Manage family screen time limits and monitor usage")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Text("View your screen time and request additional time")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Screen Time")
        }
    }
}

// MARK: - Apps View
struct AppsView: View {
    let profile: FamilyProfile
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Apps Management")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Role: \(profile.displayRole)")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if profile.isParent {
                    Text("Approve and manage apps for your children")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Text("View your approved apps and request new ones")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Apps")
        }
    }
}

// MARK: - Settings Views
struct ParentSettingsView: View {
    let profile: FamilyProfile
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Parent Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Manage family and app settings")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                SecureChildInterface.SecureLogoutButton()
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

struct ChildSettingsView: View {
    let profile: FamilyProfile
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Profile Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Limited settings for child profile")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                SecureChildInterface.SecureLogoutButton()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Splash Screen View

/// Loading screen shown during app initialization
struct SplashScreenView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(.white)
                
                Text("ScreenTime")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Family Time Management")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
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
                .environmentObject(FamilyAuthService.shared)
                .previewDisplayName("Main App")
            
            SplashScreenView()
                .previewDisplayName("Splash Screen")
        }
    }
}
#endif 