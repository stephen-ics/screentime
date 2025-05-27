import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
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
            
            Section(footer: Text("Changes to your email address will require you to sign in again.")) {
                EmptyView()
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") { dismiss() },
            trailing: Button("Save") { saveChanges() }
                .disabled(!hasChanges || isLoading)
        )
        .onAppear {
            loadCurrentData()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
    
    private func loadCurrentData() {
        guard let user = authService.currentUser else { return }
        name = user.name
        email = user.email ?? ""
    }
    
    private func saveChanges() {
        guard let user = authService.currentUser else { return }
        
        isLoading = true
        
        _Concurrency.Task {
            do {
                await MainActor.run {
                    user.name = name
                    user.email = email
                    user.updatedAt = Date()
                }
                
                try await MainActor.run {
                    try viewContext.save()
                }
                
                // Update SharedDataManager if email changed
                if email != user.email {
                    SharedDataManager.shared.registerUser(user, email: email)
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
} 