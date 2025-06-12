import SwiftUI

struct AddTaskView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyAuth: FamilyAuthService
    
    // MARK: - Dependencies
    private let dataRepository = SupabaseDataRepository.shared
    
    // MARK: - State
    @State private var taskName = ""
    @State private var taskDescription = ""
    @State private var selectedChild: FamilyProfile?
    @State private var showChildPicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $taskName)
                    TextField("Description", text: $taskDescription)
                }
                
                Section(header: Text("Assign To")) {
                    Button(action: { showChildPicker = true }) {
                        HStack {
                            Text(selectedChild?.name ?? "Select Child")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showChildPicker) {
                ChildPickerView(selectedChild: $selectedChild)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canSave: Bool {
        !taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedChild != nil
    }
    
    // MARK: - Actions
    private func saveTask() {
        guard let child = selectedChild else { return }
        
        Task {
            isSaving = true
            do {
                let task = SupabaseTask(
                    id: UUID(),
                    title: taskName.trimmingCharacters(in: .whitespacesAndNewlines),
                    taskDescription: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    rewardSeconds: 0,
                    completedAt: nil,
                    isApproved: false,
                    isRecurring: false,
                    recurringFrequency: nil,
                    assignedTo: child.id,
                    createdBy: familyAuth.currentProfile?.id
                )
                
                _ = try await dataRepository.createTask(task)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            isSaving = false
        }
    }
}

struct ChildPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @Binding var selectedChild: FamilyProfile?
    
    var body: some View {
        NavigationView {
            List(familyAuth.availableProfiles.filter { $0.role == .child }) { child in
                Button(action: {
                    selectedChild = child
                    dismiss()
                }) {
                    HStack {
                        Text(child.name)
                        Spacer()
                        if selectedChild?.id == child.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddTaskView()
        .environmentObject(FamilyAuthService.shared)
} 









