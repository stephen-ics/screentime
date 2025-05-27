import SwiftUI

struct PrivacySettingsView: View {
    @AppStorage("privacy.shareUsageData") private var shareUsageData = false
    @AppStorage("privacy.shareWithParent") private var shareWithParent = true
    @AppStorage("privacy.profileVisibility") private var profileVisibility = "contacts"
    @AppStorage("privacy.activityStatus") private var showActivityStatus = true
    @AppStorage("privacy.allowDataExport") private var allowDataExport = true
    @AppStorage("privacy.analyticsEnabled") private var analyticsEnabled = false
    
    var body: some View {
        Form {
            Section(header: Text("Data Sharing")) {
                Toggle(isOn: $shareUsageData) {
                    VStack(alignment: .leading) {
                        Text("Share Usage Data")
                        Text("Help improve the app by sharing anonymous usage data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $analyticsEnabled) {
                    VStack(alignment: .leading) {
                        Text("Analytics")
                        Text("Allow collection of app performance data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if authService.currentUser?.isParent == false {
                    Toggle(isOn: $shareWithParent) {
                        VStack(alignment: .leading) {
                            Text("Share with Parent")
                            Text("Allow parent to see your screen time data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Profile Visibility")) {
                Picker("Who can see your profile", selection: $profileVisibility) {
                    Text("Everyone").tag("everyone")
                    Text("Contacts Only").tag("contacts")
                    Text("Nobody").tag("nobody")
                }
                
                Toggle(isOn: $showActivityStatus) {
                    VStack(alignment: .leading) {
                        Text("Show Activity Status")
                        Text("Let others see when you're active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Data Management")) {
                Toggle(isOn: $allowDataExport) {
                    VStack(alignment: .leading) {
                        Text("Allow Data Export")
                        Text("Enable downloading your personal data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: clearCache) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.orange)
                        Text("Clear Cache")
                            .foregroundColor(.primary)
                    }
                }
                
                Button(action: resetPrivacySettings) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.red)
                        Text("Reset Privacy Settings")
                            .foregroundColor(.red)
                    }
                }
            }
            
            Section(footer: privacyFooter) {
                EmptyView()
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @EnvironmentObject private var authService: AuthenticationService
    
    private var privacyFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacy Policy")
                .font(.caption)
                .fontWeight(.semibold)
            Text("Your privacy is important to us. We only collect data necessary to provide and improve our services. All data is encrypted and stored securely.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: { }) {
                Text("Read Full Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 4)
        }
    }
    
    private func clearCache() {
        // Implement cache clearing
        print("Clearing cache...")
    }
    
    private func resetPrivacySettings() {
        // Reset all privacy settings to defaults
        shareUsageData = false
        shareWithParent = true
        profileVisibility = "contacts"
        showActivityStatus = true
        allowDataExport = true
        analyticsEnabled = false
    }
} 