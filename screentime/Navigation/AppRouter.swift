import SwiftUI
import Combine

/// Centralized navigation coordinator for the application
final class AppRouter: RouterProtocol {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreen: FullScreenDestination?
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific destination
    /// - Parameter destination: The destination to navigate to
    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }
    
    /// Present a sheet modal
    /// - Parameter destination: The sheet destination to present
    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
    }
    
    /// Present a full screen modal
    /// - Parameter destination: The full screen destination to present
    func presentFullScreen(_ destination: FullScreenDestination) {
        presentedFullScreen = destination
    }
    
    /// Dismiss the current navigation level
    func dismiss() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    /// Dismiss the currently presented sheet
    func dismissSheet() {
        presentedSheet = nil
    }
    
    /// Dismiss the currently presented full screen modal
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
    
    /// Navigate to root (clear all navigation)
    func navigateToRoot() {
        path = NavigationPath()
    }
    
    /// Deep link navigation
    /// - Parameter url: The URL to handle
    func handleDeepLink(_ url: URL) {
        // Parse URL and navigate accordingly
        // Implementation depends on your URL scheme
    }
}

// MARK: - Navigation Destinations

/// Represents navigation destinations within the app
enum NavigationDestination: Hashable {
    case childDetail(User)
    case taskDetail(Task)
    case settings
    case editProfile
    case timeRequestDetail(TimeRequest)
    case reports
}

/// Represents sheet modal destinations
enum SheetDestination: Identifiable {
    case addChild
    case addTask
    case timeRequests
    case settings
    case editProfile
    case changePassword
    
    var id: String {
        switch self {
        case .addChild: return "addChild"
        case .addTask: return "addTask"
        case .timeRequests: return "timeRequests"
        case .settings: return "settings"
        case .editProfile: return "editProfile"
        case .changePassword: return "changePassword"
        }
    }
}

/// Represents full screen modal destinations
enum FullScreenDestination: Identifiable {
    case authentication
    case onboarding
    case parentalControls
    
    var id: String {
        switch self {
        case .authentication: return "authentication"
        case .onboarding: return "onboarding"
        case .parentalControls: return "parentalControls"
        }
    }
}

// MARK: - Router Protocol

/// Protocol for navigation routing
protocol RouterProtocol: ObservableObject {
    var path: NavigationPath { get set }
    var presentedSheet: SheetDestination? { get set }
    var presentedFullScreen: FullScreenDestination? { get set }
    
    func navigate(to destination: NavigationDestination)
    func presentSheet(_ destination: SheetDestination)
    func presentFullScreen(_ destination: FullScreenDestination)
    func dismiss()
    func dismissSheet()
    func dismissFullScreen()
    func navigateToRoot()
} 