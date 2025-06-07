import SwiftUI
import FamilyControls
import ManagedSettings

struct ApprovedAppsView: View {
    // MARK: - Properties
    @ObservedObject var child: Profile
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedApps: Set<SupabaseApprovedApp> = []
    @State private var availableApps: [SupabaseApprovedApp] = []
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading apps...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // TODO: Implement approved apps list with Supabase
                        Text("Approved Apps functionality will be implemented with Supabase integration")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Approved Apps")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveApprovedApps()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .task {
            await loadApprovedApps()
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
            }
        } message: {
            Text(error ?? "")
        }
    }
    
    // MARK: - Actions
    private func loadApprovedApps() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Load approved apps from Supabase
        // For now, just create some sample data
        await MainActor.run {
            availableApps = []
            selectedApps = []
        }
    }
    
    private func saveApprovedApps() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                // TODO: Implement saving approved apps to Supabase
                print("Saving approved apps for child: \(child.name)")
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    private func removeApprovedApp(_ app: SupabaseApprovedApp) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                // TODO: Implement removing approved app from Supabase
                print("Removing approved app: \(app.name)")
                
                await MainActor.run {
                    selectedApps.remove(app)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Approved App Row
struct ApprovedAppRow: View {
    @ObservedObject var app: SupabaseApprovedApp
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "app.fill")
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading) {
                Text(app.name)
                    .font(.headline)
                
                Text(app.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
            }
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
        ApprovedAppsView(child: Profile())
    }
} 