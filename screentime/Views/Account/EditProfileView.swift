import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var authService: SafeSupabaseAuthService
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: ProfileEditViewModel
    
    init() {
        // We'll initialize the viewModel with a placeholder and update it in onAppear
        self._viewModel = StateObject(wrappedValue: ProfileEditViewModel(profile: Profile(
            id: UUID(), 
            email: "", 
            name: "", 
            userType: .parent
        )))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Name", text: $viewModel.name)
                    .textContentType(.name)
                
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            if viewModel.showSuccessMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Profile updated successfully")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { 
                    viewModel.resetFields()
                    dismiss() 
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { 
                    Task {
                        await saveChanges()
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
        .onAppear {
            loadUserData()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { 
                viewModel.clearError() 
            }
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView("Saving...")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func loadUserData() {
        guard let profile = authService.currentProfile else { return }
        
        // Update the viewModel properties directly since we can't reassign @StateObject
        viewModel.name = profile.name
        viewModel.email = profile.email
    }
    
    private func saveChanges() async {
        do {
            try await viewModel.saveChanges()
            
            // Update the auth service with the new profile
            let updatedProfile = viewModel.updatedProfile
            try await authService.updateProfile(updatedProfile)
            
            // Automatically dismiss after successful save
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
            
        } catch {
            // Error is already handled by the viewModel
            print("Failed to save profile: \(error)")
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