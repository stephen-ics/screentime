import DeviceActivity
import ManagedSettings
import FamilyControls

// This extension is required for the DeviceActivity framework to work properly
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Handle interval start
        if let user = AuthenticationService.shared.currentUser {
            AppTrackingService.shared.trackAppUsage(for: user)
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Handle interval end
        AppTrackingService.shared.removeRestrictions()
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Handle threshold events
        if let user = AuthenticationService.shared.currentUser {
            AppTrackingService.shared.restrictApps(for: user)
        }
    }
} 