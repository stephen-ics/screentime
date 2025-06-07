import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var authService: SupabaseAuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var error: AuthError?
    @State private var hasChanges = false
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $name)
                    .textContentType(.name)
                    .onChange(of: name) { _ in hasChanges = true }
                
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .onChange(of: email) { _ in hasChanges = true }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveChanges() }
                    .disabled(!hasChanges || isLoading)
            }
        }
        .onAppear(perform: loadUserData)
        .alert(isPresented: .constant(error != nil), error: error) { _ in
            Button("OK") { error = nil }
        } message: { error in
            Text(error.recoverySuggestion ?? "Please try again.")
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }
    
    private func loadUserData() {
        guard let profile = authService.currentProfile else { return }
        name = profile.name
        email = profile.email
    }
    
    private func saveChanges() {
        guard var profile = authService.currentProfile else { return }
        
        isLoading = true
        
        Task {
            profile.name = name
            profile.email = email
            
            do {
                try await authService.updateProfile(profile)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch let authError as AuthError {
                await MainActor.run {
                    self.error = authError
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = .unknownError
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Change Password View
struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Change Password")) {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                }
                
                Section(footer: Text("Password must be at least 8 characters long.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Change password logic here
                        dismiss()
                    }
                    .disabled(newPassword.count < 8 || newPassword != confirmPassword)
                }
            }
        }
    }
} 