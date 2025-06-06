import SwiftUI

struct SettingsView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    
    // MARK: - State
    @State private var showSignOutAlert = false
    @State private var enableNotifications = true
    @State private var enableBiometrics = true
    @State private var showAbout = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // User Section
                Section(header: Text("Account")) {
                    if let user = authService.currentUser {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                if let email = user.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Text(user.isParent ? "Parent" : "Child")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Button(action: { showSignOutAlert = true }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
                
                // Preferences Section
                Section(header: Text("Preferences")) {
                    Toggle("Push Notifications", isOn: $enableNotifications)
                        .onChange(of: enableNotifications) { newValue in
                            updateNotificationSettings(enabled: newValue)
                        }
                    
                    Toggle("Biometric Authentication", isOn: $enableBiometrics)
                        .onChange(of: enableBiometrics) { newValue in
                            updateBiometricSettings(enabled: newValue)
                        }
                }
                
                // About Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showAbout = true }) {
                        Text("About Screen Time Manager")
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy") ?? URL(string: "https://apple.com")!)
                    
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms") ?? URL(string: "https://apple.com")!)
                }
                
                // Support Section
                Section(header: Text("Support")) {
                    Link("Contact Support", destination: URL(string: "mailto:support@example.com") ?? URL(string: "https://apple.com")!)
                    
                    Link("FAQ", destination: URL(string: "https://example.com/faq") ?? URL(string: "https://apple.com")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }
    
    // MARK: - Actions
    private func signOut() {
        authService.signOut()
        dismiss()
    }
    
    private func updateNotificationSettings(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
        
        if enabled {
            _Concurrency.Task {
                do {
                    _ = try await NotificationService.shared.requestAuthorization()
                } catch {
                    print("Failed to enable notifications: \(error)")
                }
            }
        }
    }
    
    private func updateBiometricSettings(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "biometricsEnabled")
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "hourglass")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("Screen Time Manager")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("A smart way to manage screen time for families")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Text("© 2024 Screen Time World")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthenticationService.shared)
    }
} 