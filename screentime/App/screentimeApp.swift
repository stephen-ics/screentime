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
        .onChange(of: familyAuthService.error) { _, error in
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
                PlaceholderSheetView(title: "Settings", description: "Manage family and app settings")
            case .addTask:
                AddTaskView()
                    .environmentObject(familyAuthService)
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

// MARK: - Main App View with Role-Based Navigation

struct MainAppView: View {
    let profile: FamilyProfile
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        if profile.isParent {
            // Parent interface with Dashboard, Tasks, Analytics, Accounts
            ParentMainTabView()
                .environmentObject(router)
        } else {
            // Child interface with Dashboard, Tasks, Accounts (uses existing ChildMainTabView)
            ChildMainTabView()
        }
    }
}

// MARK: - Parent Main Tab View
struct ParentMainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationView {
                ParentDashboardView()
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "square.grid.2x2.fill" : "square.grid.2x2")
                Text("Dashboard")
            }
            .tag(0)
            
            // Tasks Tab - Use existing TaskListView
            TaskListView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "checklist" : "checklist")
                    Text("Tasks")
                }
                .tag(1)
            
            // Analytics Tab - Use existing AnalyticsView
            NavigationView {
                AnalyticsView()
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                Text("Analytics")
            }
            .tag(2)
            
            // Accounts Tab - Use existing SettingsView
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.circle.fill" : "person.circle")
                    Text("Accounts")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            configureParentTabBarAppearance()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToAnalytics)) { _ in
            selectedTab = 2 // Navigate to Analytics tab
        }
    }
    
    private func configureParentTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Parent-specific styling
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToAnalytics = Notification.Name("navigateToAnalytics")
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
                // App icon/logo with better hourglass design
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
                
                // Subtitle
                Text("Family Time Management")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.top, 20)
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
                .environmentObject(FamilyAuthService.shared)
                .previewDisplayName("Main App")
            
            SplashScreenView()
                .previewDisplayName("Splash Screen")
        }
    }
}
#endif 