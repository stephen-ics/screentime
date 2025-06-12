import SwiftUI
import LocalAuthentication

/// Secure interface components for child profile sessions
struct SecureChildInterface {
    
    /// Secure navigation bar that hides logout for child profiles
    struct SecureNavigationBar: View {
        @StateObject private var familyAuth = FamilyAuthService.shared
        @State private var showingParentAuth = false
        @State private var showingProfileSwitch = false
        
        let title: String
        var showBackButton: Bool = false
        var onBack: (() -> Void)? = nil
        
        var body: some View {
            HStack {
                // Back Button
                if showBackButton {
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                
                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Profile Avatar with Secure Actions
                if let currentProfile = familyAuth.currentProfile {
                    SecureProfileButton(
                        profile: currentProfile,
                        onTap: {
                            if familyAuth.isProfileSwitchingRestricted {
                                showingParentAuth = true
                            } else {
                                showingProfileSwitch = true
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .sheet(isPresented: $showingParentAuth) {
                ParentAuthenticationSheet {
                    showingParentAuth = false
                    showingProfileSwitch = true
                }
            }
            .sheet(isPresented: $showingProfileSwitch) {
                ProfileSwitchSheet {
                    showingProfileSwitch = false
                }
            }
        }
    }
    
    /// Secure profile button that requires authentication for child users
    struct SecureProfileButton: View {
        let profile: FamilyProfile
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    // Profile Avatar
                    ZStack {
                        Circle()
                            .fill(profile.isParent ? Color.blue.gradient : Color.green.gradient)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: profile.isParent ? "person.fill.checkmark" : "person.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Profile Name (abbreviated for space)
                    Text(profile.name.prefix(8))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Lock indicator for child profiles
                    if !profile.isParent {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.regularMaterial)
                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    /// Secure settings button that requires parent auth for child profiles
    struct SecureSettingsButton: View {
        let onAuthorized: () -> Void
        
        @StateObject private var familyAuth = FamilyAuthService.shared
        @State private var showingParentAuth = false
        
        var body: some View {
            Button(action: handleSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            .sheet(isPresented: $showingParentAuth) {
                ParentAuthenticationSheet {
                    showingParentAuth = false
                    onAuthorized()
                }
            }
        }
        
        private func handleSettingsTap() {
            if familyAuth.canManageFamily {
                onAuthorized()
            } else {
                showingParentAuth = true
            }
        }
    }
    
    /// Secure logout button that requires parent auth for child profiles
    struct SecureLogoutButton: View {
        @StateObject private var familyAuth = FamilyAuthService.shared
        @State private var showingParentAuth = false
        @State private var showingLogoutConfirmation = false
        
        var body: some View {
            Button(action: handleLogoutTap) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Sign Out")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red.opacity(0.1))
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                }
            }
            .sheet(isPresented: $showingParentAuth) {
                ParentAuthenticationSheet {
                    showingParentAuth = false
                    showingLogoutConfirmation = true
                }
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showingLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    performLogout()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out of the family account?")
            }
        }
        
        private func handleLogoutTap() {
            if familyAuth.canManageFamily {
                showingLogoutConfirmation = true
            } else {
                showingParentAuth = true
            }
        }
        
        private func performLogout() {
            Task {
                try? await familyAuth.signOut()
            }
        }
    }
}

// MARK: - Parent Authentication Sheet
struct ParentAuthenticationSheet: View {
    let onAuthenticated: () -> Void
    
    @StateObject private var familyAuth = FamilyAuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isAuthenticating = false
    @State private var authError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange.gradient)
                    
                    Text("Parent Authorization Required")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("This action requires parent permission. Please authenticate to continue.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 40)
                
                // Error Display
                if let error = authError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.red.opacity(0.1))
                            .stroke(.red.opacity(0.3), lineWidth: 1)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Authentication Buttons
                VStack(spacing: 16) {
                    // Biometric Authentication
                    BiometricAuthButton(
                        isAuthenticating: $isAuthenticating,
                        onSuccess: handleAuthSuccess,
                        onError: handleAuthError
                    )
                    
                    // Profile Switch (Alternative)
                    Button("Switch to Parent Profile") {
                        switchToProfileSelection()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .disabled(isAuthenticating)
    }
    
    private func handleAuthSuccess() {
        authError = nil
        dismiss()
        onAuthenticated()
    }
    
    private func handleAuthError(_ error: String) {
        authError = error
        isAuthenticating = false
    }
    
    private func switchToProfileSelection() {
        Task {
            try? await familyAuth.switchToProfileSelectionWithSecurity()
            dismiss()
        }
    }
}

// MARK: - Biometric Authentication Button
struct BiometricAuthButton: View {
    @Binding var isAuthenticating: Bool
    let onSuccess: () -> Void
    let onError: (String) -> Void
    
    @StateObject private var familyAuth = FamilyAuthService.shared
    @State private var biometricType: LABiometryType = .none
    
    var body: some View {
        Button(action: authenticateWithBiometrics) {
            HStack {
                if isAuthenticating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: biometricIcon)
                        .font(.system(size: 18, weight: .medium))
                }
                
                Text(biometricText)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.orange.gradient)
            }
        }
        .disabled(isAuthenticating || biometricType == .none)
        .opacity(isAuthenticating || biometricType == .none ? 0.6 : 1.0)
        .onAppear {
            checkBiometricAvailability()
        }
    }
    
    private var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.fill"
        }
    }
    
    private var biometricText: String {
        if isAuthenticating {
            return "Authenticating..."
        }
        
        switch biometricType {
        case .faceID:
            return "Authenticate with Face ID"
        case .touchID:
            return "Authenticate with Touch ID"
        default:
            return "Authenticate with Passcode"
        }
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            biometricType = context.biometryType
        }
    }
    
    private func authenticateWithBiometrics() {
        isAuthenticating = true
        
        Task {
            do {
                try await familyAuth.authenticateWithBiometrics()
                await MainActor.run {
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    onError(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Profile Switch Sheet
struct ProfileSwitchSheet: View {
    let onDismiss: () -> Void
    
    @StateObject private var familyAuth = FamilyAuthService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Switch Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose a different family member profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Profile List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(familyAuth.availableProfiles) { profile in
                            ProfileSwitchRow(
                                profile: profile,
                                isSelected: profile.id == familyAuth.currentProfile?.id
                            ) {
                                switchToProfile(profile)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Sign Out Button
                SecureChildInterface.SecureLogoutButton()
                    .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func switchToProfile(_ profile: FamilyProfile) {
        Task {
            await familyAuth.selectProfile(profile)
            onDismiss()
        }
    }
}

// MARK: - Profile Switch Row
struct ProfileSwitchRow: View {
    let profile: FamilyProfile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Profile Avatar
                ZStack {
                    Circle()
                        .fill(profile.isParent ? Color.blue.gradient : Color.green.gradient)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: profile.isParent ? "person.fill.checkmark" : "person.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Profile Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(profile.displayRole)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AnyShapeStyle(Color.blue.opacity(0.1)) : AnyShapeStyle(Material.regularMaterial))
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.secondary.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isSelected)
    }
}

// MARK: - Preview
#Preview("Secure Navigation Bar") {
    SecureChildInterface.SecureNavigationBar(title: "Screen Time")
}

#Preview("Parent Auth Sheet") {
    ParentAuthenticationSheet {
        print("Authenticated")
    }
} 