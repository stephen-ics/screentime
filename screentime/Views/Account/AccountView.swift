import SwiftUI
import PhotosUI

struct AccountView: View {
    // MARK: - Environment
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State
    @State private var selectedSection: AccountSection? = nil
    @State private var showingImagePicker = false
    @State private var showingDeleteConfirmation = false
    @State private var showingLogoutConfirmation = false
    @State private var profileImage: UIImage?
    @State private var showingDataExport = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                profileSection
                
                // Account Settings Sections
                accountSection
                securitySection
                preferencesSection
                privacySection
                
                // Account Actions
                accountActionsSection
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Account")
            .sheet(item: $selectedSection) { section in
                sectionDetailView(for: section)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.")
            }
            .alert("Sign Out", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                // Profile Image
                ZStack {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Edit button
                    Button(action: { showingImagePicker = true }) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                    }
                    .offset(x: 28, y: 28)
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(authService.currentUser?.name ?? "User")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(authService.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: authService.currentUser?.isParent == true ? "person.fill" : "person")
                            .font(.caption)
                        Text(authService.currentUser?.isParent == true ? "Parent Account" : "Child Account")
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        Section(header: Text("Account Information")) {
            NavigationLink(destination: EditProfileView()) {
                SettingsRow(
                    icon: "person.circle",
                    title: "Edit Profile",
                    subtitle: "Name and email"
                )
            }
            
            NavigationLink(destination: ChangePasswordView()) {
                SettingsRow(
                    icon: "lock.circle",
                    title: "Change Password",
                    subtitle: nil
                )
            }
            
            NavigationLink(destination: ConnectedAccountsView()) {
                SettingsRow(
                    icon: "link.circle",
                    title: "Connected Accounts",
                    subtitle: "Google, Apple, etc."
                )
            }
        }
    }
    
    // MARK: - Security Section
    private var securitySection: some View {
        Section(header: Text("Security")) {
            NavigationLink(destination: TwoFactorAuthView()) {
                SettingsRow(
                    icon: "lock.shield",
                    title: "Two-Factor Authentication",
                    subtitle: "Not enabled",
                    trailingBadge: "Setup"
                )
            }
            
            NavigationLink(destination: LoginActivityView()) {
                SettingsRow(
                    icon: "clock.arrow.circlepath",
                    title: "Login Activity",
                    subtitle: "Recent logins and devices"
                )
            }
            
            NavigationLink(destination: SecurityAlertsView()) {
                SettingsRow(
                    icon: "exclamationmark.shield",
                    title: "Security Alerts",
                    subtitle: nil,
                    trailingBadge: "2 New"
                )
            }
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        Section(header: Text("Preferences")) {
            NavigationLink(destination: NotificationPreferencesView()) {
                SettingsRow(
                    icon: "bell.circle",
                    title: "Notifications",
                    subtitle: "Email, push, and SMS"
                )
            }
            
            NavigationLink(destination: LanguagePreferencesView()) {
                SettingsRow(
                    icon: "globe",
                    title: "Language & Region",
                    subtitle: "English (US)"
                )
            }
            
            NavigationLink(destination: AppearancePreferencesView()) {
                SettingsRow(
                    icon: "paintbrush.circle",
                    title: "Appearance",
                    subtitle: "System"
                )
            }
        }
    }
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        Section(header: Text("Privacy")) {
            NavigationLink(destination: PrivacySettingsView()) {
                SettingsRow(
                    icon: "hand.raised.circle",
                    title: "Privacy Settings",
                    subtitle: "Data sharing and visibility"
                )
            }
            
            NavigationLink(destination: DataManagementView()) {
                SettingsRow(
                    icon: "doc.circle",
                    title: "Data Management",
                    subtitle: "Export and download"
                )
            }
        }
    }
    
    // MARK: - Account Actions Section
    private var accountActionsSection: some View {
        Section {
            Button(action: { showingDataExport = true }) {
                SettingsRow(
                    icon: "square.and.arrow.down",
                    title: "Export Account Data",
                    subtitle: nil,
                    iconColor: .blue
                )
            }
            
            Button(action: { showingLogoutConfirmation = true }) {
                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    subtitle: nil,
                    iconColor: .orange
                )
            }
            
            Button(action: { showingDeleteConfirmation = true }) {
                SettingsRow(
                    icon: "trash.circle",
                    title: "Delete Account",
                    subtitle: nil,
                    iconColor: .red
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func sectionDetailView(for section: AccountSection) -> some View {
        Group {
            switch section {
            case .editProfile:
                EditProfileView()
            case .changePassword:
                ChangePasswordView()
            case .connectedAccounts:
                ConnectedAccountsView()
            case .twoFactor:
                TwoFactorAuthView()
            case .loginActivity:
                LoginActivityView()
            case .notifications:
                NotificationPreferencesView()
            case .language:
                LanguagePreferencesView()
            case .privacy:
                PrivacySettingsView()
            case .dataExport:
                DataExportView()
            }
        }
    }
    
    private func deleteAccount() {
        // Implement account deletion
        _Concurrency.Task {
            do {
                // Delete user data
                if let user = authService.currentUser {
                    try await MainActor.run {
                        try CoreDataManager.shared.delete(user)
                    }
                }
                
                // Sign out
                authService.signOut()
            } catch {
                print("Failed to delete account: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types
enum AccountSection: String, Identifiable {
    case editProfile
    case changePassword
    case connectedAccounts
    case twoFactor
    case loginActivity
    case notifications
    case language
    case privacy
    case dataExport
    
    var id: String { rawValue }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var iconColor: Color = .accentColor
    var trailingBadge: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let badge = trailingBadge {
                Text(badge)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
            .environmentObject(AuthenticationService.shared)
    }
} 