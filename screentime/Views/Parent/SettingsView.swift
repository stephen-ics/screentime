import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let profile = authService.currentProfile {
                        HStack {
                            Circle()
                                .fill(LinearGradient.parentGradient)
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
                                Text(profile.email)
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
                try await authService.signOut()
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
            .environmentObject(SupabaseAuthService())
    }
} 