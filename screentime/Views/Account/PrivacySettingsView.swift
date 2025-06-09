import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject private var authService: SafeSupabaseAuthService
    @State private var shareUsageData = false
    @State private var analyticsEnabled = false
    @State private var allowDataExport = false
    @State private var shareAnalytics = false
    @State private var allowRecommendations = false
    @State private var sharePerformanceData = false
    @AppStorage("privacy.shareWithParent") private var shareWithParent = true
    @AppStorage("privacy.profileVisibility") private var profileVisibility = "contacts"
    @AppStorage("privacy.activityStatus") private var showActivityStatus = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Share Usage Analytics", isOn: $shareAnalytics)
                Toggle("Allow App Recommendations", isOn: $allowRecommendations)
                Toggle("Share Performance Data", isOn: $sharePerformanceData)
            } header: {
                Text("Data Sharing")
            }
            
            Section {
                Button("Reset Privacy Settings") {
                    resetPrivacySettings()
                }
                .foregroundColor(.red)
                
                Button("Export My Data") {
                    exportUserData()
                }
            } header: {
                Text("Privacy Actions")
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
            }
            
            Section(footer: privacyFooter) {
                EmptyView()
            }
        }
        .navigationTitle("Privacy Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
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
        allowDataExport = false
        analyticsEnabled = false
        shareAnalytics = false
        allowRecommendations = false
        sharePerformanceData = false
    }
    
    private func exportUserData() {
        // Implement user data export
        print("Exporting user data...")
    }
} 