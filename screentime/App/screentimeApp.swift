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
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView(profile: profile)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "square.grid.2x2.fill" : "square.grid.2x2")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Screen Time Tab (replaces Children functionality)
            ScreenTimeView(profile: profile)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "hourglass.fill" : "hourglass")
                    Text("Screen Time")
                }
                .tag(1)
            
            // Tasks Tab (new addition)
            TasksView(profile: profile)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "checklist" : "checklist")
                    Text("Tasks")
                }
                .tag(2)
            
            // Account Tab (replaces Settings) - Uses existing AccountView.swift
            AccountView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.circle.fill" : "person.circle")
                    Text("Account")
                }
                .tag(3)
        }
        .accentColor(profile.isParent ? .blue : .green)
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    // MARK: - Enhanced Tab Bar Styling
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Enhanced styling for better visual hierarchy
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(profile.isParent ? .blue : .green),
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(profile.isParent ? .blue : .green)
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 12) {
                    Text("Screen Time Management")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Role: \(profile.displayRole)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                Spacer()
                
                // Main Content
                VStack(spacing: 20) {
                    if profile.isParent {
                        VStack(spacing: 16) {
                            Image(systemName: "hourglass.circle")
                                .font(.system(size: 60, weight: .thin))
                                .foregroundColor(.blue)
                            
                            Text("Manage Family Screen Time")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text("Monitor usage, set limits, and manage time requests from your children")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: 60, weight: .thin))
                                .foregroundColor(.green)
                            
                            Text("Your Screen Time")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text("View your usage statistics and request additional time when needed")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Screen Time")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Tasks View
struct TasksView: View {
    let profile: FamilyProfile
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 12) {
                    Text("Tasks & Activities")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Role: \(profile.displayRole)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                Spacer()
                
                // Main Content
                VStack(spacing: 20) {
                    if profile.isParent {
                        VStack(spacing: 16) {
                            Image(systemName: "checklist.checked")
                                .font(.system(size: 60, weight: .thin))
                                .foregroundColor(.blue)
                            
                            Text("Manage Family Tasks")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text("Create and assign tasks to your children, track completion, and reward good behavior")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "star.circle")
                                .font(.system(size: 60, weight: .thin))
                                .foregroundColor(.green)
                            
                            Text("Your Tasks")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text("Complete tasks assigned by your parents to earn extra screen time and rewards")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
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