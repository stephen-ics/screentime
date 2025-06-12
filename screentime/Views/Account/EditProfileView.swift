import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: ProfileEditViewModel
    
    init() {
        // We'll initialize the viewModel with a placeholder and update it in onAppear
        self._viewModel = StateObject(wrappedValue: ProfileEditViewModel(profile: FamilyProfile(
            id: UUID(),
            authUserId: UUID(),
            name: "",
            role: .parent,
            createdAt: Date(),
            updatedAt: Date(),
            emailVerified: false
        )))
    }
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Information")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Name", text: $viewModel.name)
                        .textContentType(.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if viewModel.showSuccessMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Profile updated successfully")
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
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
        guard let profile = familyAuth.currentProfile else { return }
        
        // Update the viewModel properties directly since we can't reassign @StateObject
        viewModel.name = profile.name
    }
    
    private func saveChanges() async {
        do {
            try await viewModel.saveChanges()
            
            // Update the auth service with the new profile
            let updatedProfile = viewModel.updatedProfile
            try await familyAuth.updateProfile(updatedProfile, newName: viewModel.name)
            
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
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Change Password")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        SecureField("Current Password", text: $currentPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("New Password", text: $newPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("Confirm New Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Text("Password must be at least 8 characters long.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
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