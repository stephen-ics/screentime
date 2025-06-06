import SwiftUI

@main
struct ScreenTimeApp: App {
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    // MARK: - Core Services
    private let coreDataManager = CoreDataManager.shared
    private let userService = UserService.shared
    private let dataRepository = DataRepository.shared
    
    // MARK: - State
    @StateObject private var router = AppRouter()
    
    // MARK: - Scene Configuration
    var body: some Scene {
        WindowGroup {
            RootView(
                userService: userService,
                dataRepository: dataRepository
            )
            .environmentObject(router)
            .environmentObject(AuthenticationService.shared)
            .environment(\.managedObjectContext, coreDataManager.viewContext)
        }
    }
}

// MARK: - Root View

/// Root view that handles authentication state and app-level navigation
struct RootView: View {
    
    // MARK: - Dependencies
    private let userService: any UserServiceProtocol
    private let dataRepository: any DataRepositoryProtocol
    
    // MARK: - State
    @EnvironmentObject private var router: AppRouter
    @State private var currentUser: User?
    @State private var isLoading = true
    
    // MARK: - Initialization
    
    init(
        userService: any UserServiceProtocol,
        dataRepository: any DataRepositoryProtocol
    ) {
        self.userService = userService
        self.dataRepository = dataRepository
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isLoading {
                SplashScreenView()
            } else if let user = currentUser {
                if user.isParent {
                    ParentDashboardView(
                        userService: userService,
                        dataRepository: dataRepository
                    )
                } else {
                    ChildDashboardView()
                        .environmentObject(userService as! UserService)
                        .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
                }
            } else {
                AuthenticationView()
                    .environmentObject(userService as! UserService)
                    .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
            }
        }
        .onAppear {
            loadCurrentUser()
        }
        .onReceive(userService.currentUserPublisher) { user in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentUser = user
                isLoading = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadCurrentUser() {
        currentUser = userService.getCurrentUser()
        isLoading = false
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
                    DesignSystem.Colors.primaryBlue,
                    DesignSystem.Colors.primaryIndigo
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGradient)
            
            VStack(spacing: DesignSystem.Spacing.large) {
                // App icon/logo
                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: scale)
                
                // App name
                Text("ScreenTime")
                    .font(DesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
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
        navigationBarAppearance.backgroundColor = UIColor(DesignSystem.Colors.background)
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(DesignSystem.Colors.primaryText),
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor(DesignSystem.Colors.background)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - Preview

struct ScreenTimeApp_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RootView(
                userService: UserService.shared,
                dataRepository: DataRepository.shared
            )
            .environmentObject(AppRouter())
            .previewDisplayName("Main App")
            
            SplashScreenView()
                .previewDisplayName("Splash Screen")
        }
    }
} 