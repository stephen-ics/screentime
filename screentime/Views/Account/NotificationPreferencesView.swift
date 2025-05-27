import SwiftUI

struct NotificationPreferencesView: View {
    @AppStorage("notifications.push") private var pushEnabled = true
    @AppStorage("notifications.email") private var emailEnabled = true
    @AppStorage("notifications.sms") private var smsEnabled = false
    @AppStorage("notifications.taskReminders") private var taskReminders = true
    @AppStorage("notifications.screenTimeAlerts") private var screenTimeAlerts = true
    @AppStorage("notifications.parentalAlerts") private var parentalAlerts = true
    @AppStorage("notifications.securityAlerts") private var securityAlerts = true
    
    var body: some View {
        Form {
            Section(header: Text("Notification Methods")) {
                Toggle(isOn: $pushEnabled) {
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Push Notifications")
                            Text("Receive alerts on your device")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Toggle(isOn: $emailEnabled) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Email Notifications")
                            Text("Important updates to your inbox")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Toggle(isOn: $smsEnabled) {
                    HStack {
                        Image(systemName: "message")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("SMS Notifications")
                            Text("Text messages for urgent alerts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Notification Types")) {
                Toggle(isOn: $taskReminders) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Task Reminders")
                            Text("Reminders for pending tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Toggle(isOn: $screenTimeAlerts) {
                    HStack {
                        Image(systemName: "hourglass")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Screen Time Alerts")
                            Text("Low balance and time limit warnings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Toggle(isOn: $parentalAlerts) {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.indigo)
                        VStack(alignment: .leading) {
                            Text("Parental Alerts")
                            Text("Child activity and requests")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Toggle(isOn: $securityAlerts) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Security Alerts")
                            Text("Login attempts and account changes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section(footer: Text("You can change these preferences at any time. Some notifications may be required for security purposes.")) {
                EmptyView()
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
} 