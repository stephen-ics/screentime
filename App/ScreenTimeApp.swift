import SwiftUI

@main
struct ScreenTimeApp: App {
    // MARK: - Properties
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authService = SafeSupabaseAuthService.shared
    
    // MARK: - Scene Configuration
    var body: some Scene {
        WindowGroup {
            if let profile = authService.currentProfile {
                if profile.isParent {
                    ParentDashboardView()
                        .environmentObject(authService)
                } else {
                    ChildDashboardView()
                        .environmentObject(authService)
                }
            } else {
                AuthenticationView()
                    .environmentObject(authService)
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
        // Configure appearance
        configureAppearance()
        
        // Request notification authorization
        Task {
            do {
                _ = try await NotificationService.shared.requestAuthorization()
            } catch {
                print("Failed to request notification authorization: \(error)")
            }
        }
        
        return true
    }
    
    private func configureAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // MARK: - Remote Notifications
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert token to string
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // TODO: Send token to backend service
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
} 