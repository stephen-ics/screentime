import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

/// Manages app usage tracking and screen time restrictions
@available(iOS 15.0, *)
final class AppTrackingService {
    static let shared = AppTrackingService()
    
    // MARK: - Properties
    private let deviceActivityCenter = DeviceActivityCenter()
    private let settingsStore = ManagedSettingsStore()
    
    // MARK: - Constants
    private enum Constants {
        static let monitorSchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        static let monitorName = "ScreenTimeMonitor"
    }
    
    private init() {
        setupActivityMonitoring()
    }
    
    // MARK: - Setup
    private func setupActivityMonitoring() {
        // Request authorization if needed
        _Concurrency.Task {
            do {
                try await requestAuthorization()
            } catch {
                print("Failed to request authorization: \(error)")
            }
        }
    }
    
    // MARK: - Authorization
    func requestAuthorization() async throws {
        let center = AuthorizationCenter.shared
        
        do {
            try await center.requestAuthorization(for: .individual)
            // If we get here, authorization was successful
            try await startMonitoring()
        } catch {
            // Authorization was denied or failed
            throw TrackingError.authorizationDenied
        }
    }
    
    // MARK: - Monitoring
    private func startMonitoring() async throws {
        let schedule = Constants.monitorSchedule
        let activity = DeviceActivityName(Constants.monitorName)
        
        do {
            try await deviceActivityCenter.startMonitoring(
                activity,
                during: schedule
            )
        } catch {
            throw TrackingError.monitoringFailed
        }
    }
    
    func stopMonitoring() {
        let activity = DeviceActivityName(Constants.monitorName)
        deviceActivityCenter.stopMonitoring([activity])
    }
    
    // MARK: - App Restrictions
    func restrictApps(for profile: Profile) {
        // TODO: Implement with SupabaseScreenTimeBalance model
        // Note: Profile model no longer has screenTimeBalance during migration
        print("App restrictions not implemented yet for user: \(profile.name)")
        
        // Remove all restrictions for now
        settingsStore.shield.applications = nil
        settingsStore.shield.applicationCategories = nil
    }
    
    func removeRestrictions() {
        settingsStore.shield.applications = nil
        settingsStore.shield.applicationCategories = nil
    }
    
    // MARK: - App Usage Tracking
    func trackAppUsage(for profile: Profile) {
        // TODO: Implement with SupabaseScreenTimeBalance model
        // Note: Profile model no longer has screenTimeBalance during migration
        print("App usage tracking not implemented yet for user: \(profile.name)")
        return
    }
    
    /// Checks if the user is using approved apps
    /// - Parameter apps: Set of approved apps to check
    /// - Returns: Bool indicating if using approved apps
    private func isUsingApprovedApps(_ apps: Set<SupabaseApprovedApp>) -> Bool {
        // TODO: Implement approved apps checking with SupabaseApprovedApp
        return true
    }
    
    // MARK: - Helper Methods
    
    /// Updates screen time balance for a user
    /// - Parameters:
    ///   - profile: The profile to update
    ///   - minutes: Minutes to add/subtract
    private func updateScreenTimeBalance(for profile: Profile, minutes: Int32) {
        // TODO: Implement screen time balance updates
        // Note: Profile model no longer has screenTimeBalance during migration
        print("Screen time balance update not implemented yet for user: \(profile.name)")
    }
    
    /// Checks if user has exceeded their screen time limit
    /// - Parameter profile: The profile to check
    /// - Returns: Bool indicating if limit is exceeded
    private func hasExceededLimit(for profile: Profile) -> Bool {
        // TODO: Implement screen time limit checking
        // Note: Profile model no longer has screenTimeBalance during migration
        print("Screen time limit checking not implemented yet for user: \(profile.name)")
        return false
    }
    
    /// Handles when screen time limit is reached
    private func handleLimitReached() {
        // TODO: Implement proper screen time limit handling
        // Note: AuthenticationService is deprecated, need to use SupabaseAuthService
        print("Screen time limit reached - implement proper handling")
    }
    
    /// Handles when device becomes inactive
    private func handleDeviceInactive() {
        // TODO: Implement proper device inactive handling
        // Note: AuthenticationService is deprecated, need to use SupabaseAuthService  
        print("Device inactive - implement proper handling")
    }
    
    /// Grants additional screen time to a user
    /// - Parameters:
    ///   - profile: The profile to grant time to
    ///   - minutes: Minutes to grant
    func grantScreenTime(to profile: Profile, minutes: Int32) {
        // TODO: Implement screen time granting with SupabaseScreenTimeBalance
        print("Screen time grant not implemented yet for user: \(profile.name)")
        
        // TODO: Implement notification sending
        // NotificationService.shared.scheduleTimeGrantNotification(for: user, minutes: minutes)
    }
    
    /// Removes screen time from a user
    /// - Parameters:
    ///   - profile: The profile to remove time from
    ///   - minutes: Minutes to remove
    func removeScreenTime(from profile: Profile, minutes: Int32) {
        // TODO: Implement screen time removal with SupabaseScreenTimeBalance
        print("Screen time removal not implemented yet for user: \(profile.name)")
    }
}

// MARK: - Device Activity Monitor Extension
@available(iOS 15.0, *)
extension AppTrackingService {
    class Monitor: DeviceActivityMonitor {
        override func intervalDidStart(for activity: DeviceActivityName) {
            super.intervalDidStart(for: activity)
            
            // TODO: Replace with SupabaseAuthService when fully implemented
            // Note: AuthenticationService is deprecated
            print("Interval started for activity: \(activity)")
            
            // Original implementation commented out:
            // guard let user = AuthenticationService.shared.currentUser else {
            //     return
            // }
            // AppTrackingService.shared.trackAppUsage(for: user)
        }
        
        override func intervalDidEnd(for activity: DeviceActivityName) {
            super.intervalDidEnd(for: activity)
            
            // Handle interval end
            AppTrackingService.shared.removeRestrictions()
        }
        
        override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
            super.eventDidReachThreshold(event, activity: activity)
            
            // TODO: Replace with SupabaseAuthService when fully implemented
            // Note: AuthenticationService is deprecated
            print("Event threshold reached for: \(event)")
            
            // Original implementation commented out:
            // guard let user = AuthenticationService.shared.currentUser else {
            //     return
            // }
            // AppTrackingService.shared.restrictApps(for: user)
        }
    }
}

// MARK: - Error Handling
@available(iOS 15.0, *)
extension AppTrackingService {
    enum TrackingError: LocalizedError {
        case authorizationDenied
        case monitoringFailed
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .authorizationDenied:
                return NSLocalizedString("Screen Time access was denied", comment: "")
            case .monitoringFailed:
                return NSLocalizedString("Failed to start activity monitoring", comment: "")
            case .unknown:
                return NSLocalizedString("An unknown error occurred", comment: "")
            }
        }
    }
} 