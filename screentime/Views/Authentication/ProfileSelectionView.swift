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
                // Enhanced Background
                LinearGradient(
                    colors: [Color.indigo.opacity(0.2), Color.cyan.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.indigo.gradient)
                        
                        Text("Select Your Profile")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        
                        Text("Choose who is using the device to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Profiles Grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(familyAuth.availableProfiles) { profile in
                                ProfileCard(profile: profile) {
                                    selectProfile(profile)
                                }
                                .contextMenu {
                                    if profile.isParent {
                                        Button {
                                            selectedProfileForSettings = profile
                                            showingProfileSettings = true
                                        } label: {
                                            Label("Profile Settings", systemImage: "gearshape")
                                        }
                                    }
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
        .navigationViewStyle(.stack)
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
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 16) {
                    // Profile Avatar
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(profile.isParent ? Color.indigo.gradient : Color.teal.gradient)
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
                        
                        Image(systemName: profile.isParent ? "person.fill.checkmark" : "person.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                            .offset(y: profile.isParent ? 0 : 5)
                        
                        if profile.isParent {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white, .indigo)
                                .background(Circle().fill(.white).padding(2))
                                .offset(x: 4, y: 4)
                                .transition(.scale)
                                .accessibilityLabel("Long press for settings")
                        }
                    }
                    
                    // Profile Info
                    VStack(spacing: 2) {
                        Text(profile.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text(profile.displayRole)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.regularMaterial)
                        .stroke(.secondary.opacity(0.2), lineWidth: 1)
                }
            }
            .buttonStyle(CardButtonStyle())
        }
    }
    
    // MARK: - Add Child Card
    struct AddChildCard: View {
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(spacing: 2) {
                        Text("Add Child")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Create a new profile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.regularMaterial)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .buttonStyle(CardButtonStyle())
        }
    }
    
    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button(action: signOut) {
            Label("Sign Out of Family", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(.regularMaterial)
                )
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
    @State private var editingName: String
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    
    init(profile: FamilyProfile, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.onDismiss = onDismiss
        self._editingName = State(initialValue: profile.name)
    }
    
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
                        HStack(spacing: 8) {
                            TextField("Profile Name", text: $editingName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .padding(.leading, 32)
                            
                            Button(action: cancelEditing) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary, .quaternary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                    } else {
                        Text(editingName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text(profile.displayRole)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)
                
                // Settings Options
                VStack(spacing: 16) {
                    if !isEditing {
                        ProfileSettingsRow(
                            icon: "pencil",
                            title: "Edit Name",
                            color: .blue
                        ) {
                            startEditing()
                        }
                    }
                    
                    if !profile.isParent {
                        ProfileSettingsRow(
                            icon: "trash",
                            title: "Delete Profile",
                            color: .red
                        ) {
                            showingDeleteConfirmation = true
                        }
                        .disabled(isEditing)
                        .opacity(isEditing ? 0.5 : 1.0)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Button
                Button(action: {
                    if isEditing {
                        saveNameEdit()
                    } else {
                        onDismiss()
                    }
                }) {
                    Text(isEditing ? "Save Changes" : "Done")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isEditing ? Color.green.gradient : Color.blue.gradient)
                        }
                }
                .foregroundColor(.white)
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
    }
    
    private func startEditing() {
        isEditing = true
    }
    
    private func cancelEditing() {
        editingName = profile.name
        isEditing = false
    }
    
    private func saveNameEdit() {
        Task {
            do {
                let trimmedName = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    try await familyAuth.updateProfile(profile, newName: trimmedName)
                    onDismiss()
                }
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

// MARK: - Custom Button Style
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.bouncy(duration: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ProfileSelectionView()
} 