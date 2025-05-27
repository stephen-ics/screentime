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
    func restrictApps(for user: User) {
        guard let balance = user.screenTimeBalance,
              !balance.hasTimeRemaining else {
            return
        }
        
        // Get the list of restricted apps
        let restrictedApps = balance.approvedApps
            .filter { $0.isEnabled }
            .compactMap { app -> ApplicationToken? in
                // In a real implementation, you would get the ApplicationToken
                // from the FamilyControls selection
                return nil
            }
        
        // Apply restrictions
        if !restrictedApps.isEmpty {
            settingsStore.shield.applications = Set(restrictedApps)
        } else {
            settingsStore.shield.applications = nil
        }
        
        // Set category policy
        settingsStore.shield.applicationCategories = .specific([], except: Set())
    }
    
    func removeRestrictions() {
        settingsStore.shield.applications = nil
        settingsStore.shield.applicationCategories = nil
    }
    
    // MARK: - App Usage Tracking
    func trackAppUsage(for user: User) {
        guard let balance = user.screenTimeBalance,
              balance.hasTimeRemaining,
              balance.isTimerActive else {
            return
        }
        
        // Start the timer if approved apps are being used
        if isUsingApprovedApps(balance.approvedApps) {
            balance.startTimer()
        } else {
            balance.stopTimer()
        }
    }
    
    private func isUsingApprovedApps(_ apps: Set<ApprovedApp>) -> Bool {
        // In a real implementation, we would use the FamilyControls framework
        // to check if any of the approved apps are currently active
        // For demo purposes, we'll just return true
        return true
    }
}

// MARK: - Device Activity Monitor Extension
@available(iOS 15.0, *)
extension AppTrackingService {
    class Monitor: DeviceActivityMonitor {
        override func intervalDidStart(for activity: DeviceActivityName) {
            super.intervalDidStart(for: activity)
            
            // Handle interval start
            guard let user = AuthenticationService.shared.currentUser else {
                return
            }
            
            AppTrackingService.shared.trackAppUsage(for: user)
        }
        
        override func intervalDidEnd(for activity: DeviceActivityName) {
            super.intervalDidEnd(for: activity)
            
            // Handle interval end
            AppTrackingService.shared.removeRestrictions()
        }
        
        override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
            super.eventDidReachThreshold(event, activity: activity)
            
            // Handle threshold events
            guard let user = AuthenticationService.shared.currentUser else {
                return
            }
            
            AppTrackingService.shared.restrictApps(for: user)
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