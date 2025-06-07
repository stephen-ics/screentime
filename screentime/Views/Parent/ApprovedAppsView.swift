import SwiftUI
import FamilyControls
import ManagedSettings

struct ApprovedAppsView: View {
    // MARK: - Properties
    let childProfile: Profile
    @StateObject private var viewModel: ApprovedAppsViewModel
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(child: Profile) {
        self.childProfile = child
        self._viewModel = StateObject(wrappedValue: ApprovedAppsViewModel(childProfile: child))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading apps...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        // Search bar
                        SearchBar(text: $viewModel.searchText)
                            .padding(.horizontal)
                        
                        // Apps list
                        List {
                            ForEach(Array(viewModel.appsByCategory.keys.sorted(by: { $0.displayName < $1.displayName })), id: \.self) { category in
                                if let apps = viewModel.appsByCategory[category], !apps.isEmpty {
                                    Section(header: Text(category.displayName)) {
                                        ForEach(apps) { app in
                                            ApprovedAppRow(
                                                app: app,
                                                isSelected: viewModel.selectedApps.contains(app),
                                                onToggle: {
                                                    viewModel.toggleAppSelection(app)
                                                },
                                                onRemove: {
                                                    Task {
                                                        await viewModel.removeApprovedApp(app)
                                                    }
                                                },
                                                onUpdateLimit: { minutes in
                                                    Task {
                                                        await viewModel.updateDailyLimit(for: app, minutes: minutes)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .refreshable {
                            await viewModel.loadApprovedApps()
                        }
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
                        Task {
                            await viewModel.saveApprovedApps()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving || !viewModel.hasUnsavedChanges)
                }
            }
        }
        .task {
            await viewModel.loadApprovedApps()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Success", isPresented: $viewModel.showSuccessMessage) {
            Button("OK") {
                viewModel.clearSuccessMessage()
            }
        } message: {
            Text("Approved apps updated successfully")
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
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search apps...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// MARK: - Approved App Row
struct ApprovedAppRow: View {
    let app: SupabaseApprovedApp
    let isSelected: Bool
    let onToggle: () -> Void
    let onRemove: () -> Void
    let onUpdateLimit: (Int32) -> Void
    
    @State private var showingLimitEditor = false
    @State private var limitMinutes: Int32
    
    init(app: SupabaseApprovedApp, isSelected: Bool, onToggle: @escaping () -> Void, onRemove: @escaping () -> Void, onUpdateLimit: @escaping (Int32) -> Void) {
        self.app = app
        self.isSelected = isSelected
        self.onToggle = onToggle
        self.onRemove = onRemove
        self.onUpdateLimit = onUpdateLimit
        self._limitMinutes = State(initialValue: app.dailyLimitMinutes)
    }
    
    var body: some View {
        HStack {
            // App icon placeholder
            Image(systemName: app.category.systemImageName)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.displayName)
                    .font(.headline)
                
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if app.dailyLimitSeconds > 0 {
                    Text(app.formattedDailyLimit)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            VStack {
                // Selection toggle
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .green : .gray)
                        .font(.title2)
                }
                
                // Daily limit button
                Button(action: { showingLimitEditor = true }) {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingLimitEditor) {
            DailyLimitEditor(
                appName: app.displayName,
                currentMinutes: limitMinutes,
                onSave: { minutes in
                    limitMinutes = minutes
                    onUpdateLimit(minutes)
                }
            )
        }
    }
}

// MARK: - Daily Limit Editor
struct DailyLimitEditor: View {
    let appName: String
    @State var currentMinutes: Int32
    let onSave: (Int32) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Daily Limit for \(appName)")
                    .font(.headline)
                    .padding()
                
                Stepper(value: $currentMinutes, in: 0...480, step: 15) {
                    HStack {
                        Text("Daily Limit:")
                        Spacer()
                        Text("\(currentMinutes) minutes")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                if currentMinutes == 0 {
                    Text("No daily limit")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                
                Spacer()
            }
            .navigationTitle("Set Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(currentMinutes)
                        dismiss()
                    }
                }
            }
        }
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
        ApprovedAppsView(child: Profile.mockChild)
    }
} 