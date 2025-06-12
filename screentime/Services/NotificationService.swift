import Foundation
import UserNotifications
import UIKit
import CoreData

/// Manages local and remote notifications for the app
final class NotificationService: NSObject {
    static let shared = NotificationService()
    
    // MARK: - Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Constants
    private enum Constants {
        static let taskCompletionCategory = "TASK_COMPLETION"
        static let timeRequestCategory = "TIME_REQUEST"
        static let lowTimeCategory = "LOW_TIME"
        
        static let approveAction = "APPROVE_ACTION"
        static let denyAction = "DENY_ACTION"
        static let grantTimeAction = "GRANT_TIME_ACTION"
    }
    
    private override init() {
        super.init()
        setupNotificationCategories()
        notificationCenter.delegate = self
    }
    
    // MARK: - Setup
    private func setupNotificationCategories() {
        // Task completion category
        let approveAction = UNNotificationAction(
            identifier: Constants.approveAction,
            title: NSLocalizedString("Approve", comment: ""),
            options: .authenticationRequired
        )
        
        let denyAction = UNNotificationAction(
            identifier: Constants.denyAction,
            title: NSLocalizedString("Deny", comment: ""),
            options: .destructive
        )
        
        let taskCompletionCategory = UNNotificationCategory(
            identifier: Constants.taskCompletionCategory,
            actions: [approveAction, denyAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Time request category
        let grantTimeAction = UNNotificationAction(
            identifier: Constants.grantTimeAction,
            title: NSLocalizedString("Grant 30 Minutes", comment: ""),
            options: .authenticationRequired
        )
        
        let timeRequestCategory = UNNotificationCategory(
            identifier: Constants.timeRequestCategory,
            actions: [grantTimeAction, denyAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Low time category
        let lowTimeCategory = UNNotificationCategory(
            identifier: Constants.lowTimeCategory,
            actions: [grantTimeAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            taskCompletionCategory,
            timeRequestCategory,
            lowTimeCategory
        ])
    }
    
    // MARK: - Permission Management
    func requestAuthorization() async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    // MARK: - Notification Scheduling
    /// Schedule notification for task reminders
    func scheduleTaskNotification(for task: SupabaseTask) throws {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "Don't forget to complete: \(task.title)"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = Constants.taskCompletionCategory
        
        // Schedule for a reasonable future time since we don't have due dates yet
        let calendar = Calendar.current
        if let futureDate = calendar.date(byAdding: .hour, value: 1, to: Date()) {
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: futureDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "task-\(task.id.uuidString)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule task notification: \(error)")
                }
            }
        }
    }
    
    /// Schedule notification when a task is completed
    func scheduleTaskCompletionNotification(task: SupabaseTask) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Task Completed!"
        content.body = "Great job completing: \(task.title)"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "task-completed-\(task.id.uuidString)",
            content: content,
            trigger: nil // Immediate notification
        )
        
        try await notificationCenter.add(request)
    }
    
    /// Schedule notification for time requests
    func scheduleTimeRequestNotification(for profile: FamilyProfile, requestedMinutes: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Screen Time Request"
        content.body = "\(profile.name) is requesting \(requestedMinutes) more minutes"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "time-request-\(profile.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    /// Schedule notification for low screen time
    func scheduleLowTimeNotification(for balance: SupabaseScreenTimeBalance) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Low Screen Time"
        content.body = "Only \(Int(balance.availableSeconds / 60)) minutes remaining today"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = Constants.lowTimeCategory
        
        let request = UNNotificationRequest(
            identifier: "low-time-\(balance.userId.uuidString)",
            content: content,
            trigger: nil // Immediate notification
        )
        
        try await notificationCenter.add(request)
    }
    
    // MARK: - Notification Handling
    
    /// Handle notification response (when user taps on notification or action)
    func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        print("Handling notification response: \(identifier), action: \(actionIdentifier)")
        
        // Handle different types of actions
        switch actionIdentifier {
        case Constants.approveAction:
            await handleApproveAction(identifier: identifier)
        case Constants.denyAction:
            await handleDenyAction(identifier: identifier)
        case Constants.grantTimeAction:
            await handleGrantTimeAction(identifier: identifier)
        default:
            // Default tap - just open the app
            break
        }
    }
    
    private func handleApproveAction(identifier: String) async {
        // During transition: simplified handling
        print("Approve action for: \(identifier)")
    }
    
    private func handleDenyAction(identifier: String) async {
        // During transition: simplified handling
        print("Deny action for: \(identifier)")
    }
    
    private func handleGrantTimeAction(identifier: String) async {
        // During transition: simplified handling
        print("Grant time action for: \(identifier)")
    }
    
    // MARK: - Handler Methods
    private func handleTaskApproval(taskID: UUID) async {
        // During architectural transition: simplified implementation
        print("Handling task approval for ID: \(taskID)")
        // TODO: Implement with SupabaseDataRepository when fully migrated
    }
    
    private func handleTimeGrant(userID: UUID, minutes: Int) async {
        // During architectural transition: simplified implementation
        print("Handling time grant for user ID: \(userID), minutes: \(minutes)")
        // TODO: Implement with SupabaseDataRepository when fully migrated
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case Constants.approveAction:
            if let taskID = userInfo["taskID"] as? String,
               let uuid = UUID(uuidString: taskID) {
                await handleTaskApproval(taskID: uuid)
            }
            
        case Constants.grantTimeAction:
            if let userID = userInfo["userID"] as? String,
               let uuid = UUID(uuidString: userID) {
                await handleTimeGrant(userID: uuid, minutes: 30)
            }
            
        default:
            break
        }
    }
} 