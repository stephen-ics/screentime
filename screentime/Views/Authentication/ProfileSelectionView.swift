import SwiftUI

/// Profile selection view shown after family authentication
struct ProfileSelectionView: View {
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @State private var showingAddChild = false
    @State private var showingProfileSettings = false
    @State private var selectedProfileForSettings: FamilyProfile?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue.gradient)
                        
                        Text("Choose Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Select which family member is using the device")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Profiles Grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(familyAuth.availableProfiles) { profile in
                                ProfileCard(
                                    profile: profile,
                                    isSelected: false
                                ) {
                                    selectProfile(profile)
                                } onSettings: {
                                    selectedProfileForSettings = profile
                                    showingProfileSettings = true
                                }
                            }
                            
                            // Add Child Button (Parent Only)
                            if hasParentProfile {
                                AddChildCard {
                                    showingAddChild = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Sign Out Button
                    signOutButton
                }
                .navigationBarHidden(true)
            }
        }
        .sheet(isPresented: $showingAddChild) {
            AddChildProfileSheet()
                .environmentObject(familyAuth)
        }
        .sheet(isPresented: $showingProfileSettings) {
            if let profile = selectedProfileForSettings {
                ProfileSettingsSheet(profile: profile) {
                    selectedProfileForSettings = nil
                    showingProfileSettings = false
                }
                .environmentObject(familyAuth)
            }
        }
        .disabled(familyAuth.isLoading)
    }
    
    // MARK: - Profile Card
    struct ProfileCard: View {
        let profile: FamilyProfile
        let isSelected: Bool
        let onTap: () -> Void
        let onSettings: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 12) {
                    // Profile Avatar
                    ZStack {
                        Circle()
                            .fill(profile.isParent ? Color.blue.gradient : Color.green.gradient)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: profile.isParent ? "person.fill.checkmark" : "person.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Profile Info
                    VStack(spacing: 4) {
                        Text(profile.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text(profile.displayRole)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Settings Button for Parents
                    if profile.isParent {
                        Button(action: onSettings) {
                            Image(systemName: "gearshape.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(isSelected ? 0.95 : 1.0)
            .animation(.bouncy(duration: 0.2), value: isSelected)
        }
    }
    
    // MARK: - Add Child Card
    struct AddChildCard: View {
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Add Child")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("New Profile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .stroke(.blue.opacity(0.5), lineWidth: 1.5)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button(action: signOut) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Sign Out")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.red)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red.opacity(0.1))
                    .stroke(.red.opacity(0.3), lineWidth: 1)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Computed Properties
    private var hasParentProfile: Bool {
        familyAuth.availableProfiles.contains { $0.isParent }
    }
    
    // MARK: - Actions
    private func selectProfile(_ profile: FamilyProfile) {
        Task {
            await familyAuth.selectProfile(profile)
        }
    }
    
    private func signOut() {
        Task {
            try? await familyAuth.signOut()
        }
    }
}

// MARK: - Add Child Profile Sheet
struct AddChildProfileSheet: View {
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @Environment(\.dismiss) private var dismiss
    @State private var childName = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.green.gradient)
                    
                    Text("Add Child Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create a new profile for a family member")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Child's Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        TextField("Enter child's name", text: $childName)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: createChildProfile) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text("Create Profile")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.green.gradient)
                        }
                    }
                    .disabled(childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                    .opacity(childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating ? 0.6 : 1.0)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func createChildProfile() {
        Task {
            isCreating = true
            do {
                try await familyAuth.createChildProfile(name: childName.trimmingCharacters(in: .whitespacesAndNewlines))
                dismiss()
            } catch {
                // Error handling could be improved with error display
                print("Failed to create child profile: \(error)")
            }
            isCreating = false
        }
    }
}

// MARK: - Profile Settings Sheet
struct ProfileSettingsSheet: View {
    let profile: FamilyProfile
    let onDismiss: () -> Void
    
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @State private var editingName = ""
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(profile.isParent ? Color.blue.gradient : Color.green.gradient)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: profile.isParent ? "person.fill.checkmark" : "person.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    if isEditing {
                        TextField("Profile Name", text: $editingName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 40)
                    } else {
                        Text(profile.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text(profile.displayRole)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Settings Options
                VStack(spacing: 16) {
                    ProfileSettingsRow(
                        icon: "pencil",
                        title: "Edit Name",
                        color: .blue
                    ) {
                        if isEditing {
                            saveNameEdit()
                        } else {
                            startEditing()
                        }
                    }
                    .opacity(isEditing ? 0.5 : 1.0)
                    
                    if !profile.isParent {
                        ProfileSettingsRow(
                            icon: "trash",
                            title: "Delete Profile",
                            color: .red
                        ) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Done Button
                Button("Done") {
                    if isEditing {
                        saveNameEdit()
                    } else {
                        onDismiss()
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.blue.gradient)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
        .confirmationDialog(
            "Delete \(profile.name)?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteProfile()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            editingName = profile.name
        }
    }
    
    private func startEditing() {
        editingName = profile.name
        isEditing = true
    }
    
    private func saveNameEdit() {
        Task {
            do {
                try await familyAuth.updateProfile(profile, newName: editingName)
                isEditing = false
            } catch {
                print("Failed to update profile: \(error)")
            }
        }
    }
    
    private func deleteProfile() {
        Task {
            do {
                try await familyAuth.deleteChildProfile(profile)
                onDismiss()
            } catch {
                print("Failed to delete profile: \(error)")
            }
        }
    }
}

// MARK: - Profile Settings Row
struct ProfileSettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ProfileSelectionView()
} 