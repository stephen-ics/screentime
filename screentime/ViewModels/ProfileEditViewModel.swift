import SwiftUI
import Combine

/// ViewModel for editing user profiles
final class ProfileEditViewModel: ObservableObject {
    // The pristine, original model. Keep as private source of truth.
    private var originalProfile: Profile

    // --- Published Properties for UI Binding ---
    // These are what the View will read and write to.
    @Published var name: String
    @Published var email: String

    // --- Published Properties for UI State ---
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var canSave = false
    @Published var showSuccessMessage = false

    private var cancellables = Set<AnyCancellable>()

    init(profile: Profile) {
        self.originalProfile = profile
        
        // Initialize editable fields
        self.name = profile.name
        self.email = profile.email

        // Logic to enable/disable the save button
        $name.combineLatest($email)
            .map { [weak self] name, email in
                // Enable save only if there are changes and fields are valid
                guard let self = self else { return false }
                let hasChanges = name != self.originalProfile.name || email != self.originalProfile.email
                let isValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                             !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                return hasChanges && isValid
            }
            .assign(to: \.canSave, on: self)
            .store(in: &cancellables)
    }
    
    /// Returns the updated profile with current field values
    var updatedProfile: Profile {
        originalProfile
            .updatingName(name.trimmingCharacters(in: .whitespacesAndNewlines))
            .updatingEmail(email.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func saveChanges() async throws {
        guard canSave else { return }

        await MainActor.run {
            isSaving = true
            errorMessage = nil
            showSuccessMessage = false
        }

        do {
            // Create an updated model from our published properties
            let profileToSave = updatedProfile
            
            // Validate the profile
            try profileToSave.validate()
            
            // Here you would typically call your repository/service to save
            // For now, we'll simulate an async operation
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay for demo
            
            await MainActor.run {
                // On success:
                self.originalProfile = profileToSave // Update the source of truth
                self.canSave = false // Disable button since changes are saved
                self.showSuccessMessage = true
                self.isSaving = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isSaving = false
            }
            throw error
        }
    }
    
    /// Resets all fields to original values
    func resetFields() {
        name = originalProfile.name
        email = originalProfile.email
        errorMessage = nil
        showSuccessMessage = false
    }
    
    /// Clears any error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Clears the success message
    func clearSuccessMessage() {
        showSuccessMessage = false
    }
} 