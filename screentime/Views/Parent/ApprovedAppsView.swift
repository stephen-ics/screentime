import SwiftUI
import FamilyControls
import ManagedSettings

struct ApprovedAppsView: View {
    // MARK: - Properties
    @ObservedObject var child: User
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var showAppPicker = false
    @State private var selectedApps: Set<ApprovedApp> = []
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                if let apps = child.screenTimeBalance?.approvedApps {
                    ForEach(Array(apps)) { app in
                        ApprovedAppRow(app: app)
                    }
                    .onDelete(perform: deleteApps)
                }
            }
            .navigationTitle("Approved Apps")
            .navigationBarItems(
                leading: Button("Done") { dismiss() },
                trailing: Button(action: { showAppPicker = true }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showAppPicker) {
                AppPickerView { selections in
                    addApps(selections)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Actions
    private func addApps(_ selections: FamilyActivitySelection) {
        guard let balance = child.screenTimeBalance else { return }
        
        _Concurrency.Task {
            do {
                // Verify parent authorization
                guard try await AuthenticationService.shared.authorizeParentAction() else {
                    throw AuthenticationService.AuthError.unauthorized
                }
                
                // Add selected apps
                for token in selections.applicationTokens {
                    // In a real implementation, you would get the bundle ID from the token
                    // For now, we'll use a placeholder
                    let bundleId = "app.bundle.id"
                    let appName = "App Name"
                    
                    try CoreDataManager.shared.createApprovedApp(
                        bundleIdentifier: bundleId,
                        appName: appName,
                        for: balance
                    )
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func deleteApps(at offsets: IndexSet) {
        guard let apps = child.screenTimeBalance?.approvedApps else { return }
        
        _Concurrency.Task {
            do {
                // Verify parent authorization
                guard try await AuthenticationService.shared.authorizeParentAction() else {
                    throw AuthenticationService.AuthError.unauthorized
                }
                
                // Delete selected apps
                for index in offsets {
                    let app = Array(apps)[index]
                    try CoreDataManager.shared.delete(app)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Approved App Row
struct ApprovedAppRow: View {
    @ObservedObject var app: ApprovedApp
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(app.appName)
                    .font(.headline)
                
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { app.isEnabled },
                set: { newValue in
                    app.isEnabled = newValue
                    try? CoreDataManager.shared.save()
                }
            ))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - App Picker View
struct AppPickerView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    let onSelect: (FamilyActivitySelection) -> Void
    
    // MARK: - State
    @State private var selection = FamilyActivitySelection()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select Apps")
                .navigationBarItems(
                    leading: Button("Cancel") { dismiss() },
                    trailing: Button("Done") {
                        onSelect(selection)
                        dismiss()
                    }
                )
        }
    }
}

// MARK: - Preview
struct ApprovedAppsView_Previews: PreviewProvider {
    static var previews: some View {
        ApprovedAppsView(child: User())
    }
} 