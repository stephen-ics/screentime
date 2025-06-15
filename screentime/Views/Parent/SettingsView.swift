import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showingSwitchProfileConfirmation = false
    
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
                    
                    if familyAuth.currentProfile?.isParent == true {
                        NavigationLink("Privacy Settings") {
                            PrivacySettingsView()
                        }
                        
                        NavigationLink("Notification Preferences") {
                            NotificationPreferencesView()
                        }
                    } else {
                        NavigationLink("My Preferences") {
                            Text("Child Preferences - Coming Soon")
                                .navigationTitle("My Preferences")
                        }
                    }
                } header: {
                    Text("Preferences")
                }
                
                Section {
                    NavigationLink("Help & Support") {
                        Text("Help & Support - Coming Soon")
                            .navigationTitle("Help & Support")
                    }
                    
                    NavigationLink("About") {
                        Text("About ScreenTime - Coming Soon")
                            .navigationTitle("About")
                    }
                } header: {
                    Text("Support")
                }
                
                Section {
                    Button(action: {
                        showingSwitchProfileConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                            Text("Switch Profiles")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button("Sign Out", role: .destructive) {
                        signOut()
                    }
                } header: {
                    Text("Account Actions")
                }
            }
            .navigationTitle(familyAuth.currentProfile?.isParent == true ? "Settings" : "My Account")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
        .confirmationDialog(
            "Switch Profiles",
            isPresented: $showingSwitchProfileConfirmation,
            titleVisibility: .visible
        ) {
            Button("Switch Profiles") {
                switchToProfileSelection()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Return to the profile selection screen to switch between family members.")
        }
    }
    
    private func switchToProfileSelection() {
        Task {
            do {
                try await familyAuth.switchToProfileSelectionWithSecurity()
            } catch {
                print("Failed to switch to profile selection: \(error)")
            }
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