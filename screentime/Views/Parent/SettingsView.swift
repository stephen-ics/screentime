import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let profile = familyAuth.currentProfile {
                        HStack {
                            Circle()
                                .fill(profile.isParent ? Color.blue.gradient : Color.green.gradient)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(profile.name.prefix(1)).uppercased())
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .font(.headline)
                                Text(profile.displayRole)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Account")
                }
                
                Section {
                    NavigationLink("Edit Profile") {
                        EditProfileView()
                    }
                    
                    NavigationLink("Privacy Settings") {
                        PrivacySettingsView()
                    }
                    
                    NavigationLink("Notification Preferences") {
                        NotificationPreferencesView()
                    }
                } header: {
                    Text("Preferences")
                }
                
                Section {
                    NavigationLink("Help & Support") {
                        Text("Help & Support - Coming Soon")
                    }
                    
                    NavigationLink("About") {
                        Text("About - Coming Soon")
                    }
                } header: {
                    Text("Support")
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        signOut()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func signOut() {
        Task {
            do {
                try await familyAuth.signOut()
            } catch {
                print("Failed to sign out: \(error)")
            }
        }
    }
}

// MARK: - Previews
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(FamilyAuthService.shared)
    }
} 