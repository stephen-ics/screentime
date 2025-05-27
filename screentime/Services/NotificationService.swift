import Foundation
import UserNotifications
import UIKit

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
    func scheduleTaskNotification(for task: Task) throws {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("New Task Assigned", comment: "")
        content.body = String(format: NSLocalizedString("You have a new task: %@", comment: ""), task.title)
        content.sound = .default
        
        if let taskID = task.id {
            content.userInfo = ["taskID": taskID.uuidString]
        }
        
        let request = UNNotificationRequest(
            identifier: "new-task-\(task.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule task notification: \(error)")
            }
        }
    }
    
    func scheduleTaskCompletionNotification(task: Task) async throws {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Task Completed", comment: "")
        content.body = String(format: NSLocalizedString("%@ has completed the task: %@", comment: ""), task.assignedTo?.name ?? "", task.title)
        content.sound = .default
        content.categoryIdentifier = Constants.taskCompletionCategory
        
        if let taskID = task.id {
            content.userInfo = ["taskID": taskID.uuidString]
        }
        
        let request = UNNotificationRequest(
            identifier: "task-\(task.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await notificationCenter.add(request)
    }
    
    func scheduleTimeRequestNotification(from user: User) async throws {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Screen Time Request", comment: "")
        content.body = String(format: NSLocalizedString("%@ is requesting more screen time", comment: ""), user.name)
        content.sound = .default
        content.categoryIdentifier = Constants.timeRequestCategory
        
        if let userID = user.id {
            content.userInfo = ["userID": userID.uuidString]
        }
        
        let request = UNNotificationRequest(
            identifier: "time-request-\(user.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await notificationCenter.add(request)
    }
    
    func scheduleLowTimeNotification(for balance: ScreenTimeBalance) async throws {
        guard let user = balance.user else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Low Screen Time", comment: "")
        content.body = String(format: NSLocalizedString("%@ has 5 minutes of screen time remaining", comment: ""), user.name)
        content.sound = .default
        content.categoryIdentifier = Constants.lowTimeCategory
        
        if let userID = user.id {
            content.userInfo = ["userID": userID.uuidString]
        }
        
        let request = UNNotificationRequest(
            identifier: "low-time-\(user.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await notificationCenter.add(request)
    }
    
    // MARK: - Notification Handling
    func handleTaskApproval(taskID: UUID) async {
        do {
            let request = Task.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", taskID as CVarArg)
            
            guard let task = try CoreDataManager.shared.fetch(request).first else {
                return
            }
            
            task.isApproved = true
            if let assignedTo = task.assignedTo {
                assignedTo.screenTimeBalance?.addTime(task.rewardMinutes)
            }
            try CoreDataManager.shared.save()
        } catch {
            print("Failed to handle task approval: \(error)")
        }
    }
    
    func handleTimeGrant(userID: UUID, minutes: Int32) async {
        guard let user = try? await CoreDataManager.shared.fetchUser(withID: userID) else {
            return
        }
        
        user.screenTimeBalance?.addTime(minutes)
        try? CoreDataManager.shared.save()
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