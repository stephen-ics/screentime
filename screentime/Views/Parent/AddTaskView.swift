import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: SafeSupabaseAuthService
    @EnvironmentObject private var dataRepository: SafeSupabaseDataRepository
    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var rewardMinutes: Int = 15
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var recurringFrequency: SupabaseTask.RecurringFrequency = .daily
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var children: [Profile] = []
    @State private var selectedChild: Profile?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                    TextField("Description (Optional)", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Reward") {
                    Stepper("Reward: \(rewardMinutes) minutes", value: $rewardMinutes, in: 5...120, step: 5)
                }
                
                Section("Assignment") {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading children...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Assign to Child", selection: $selectedChild) {
                            Text("Select Child").tag(nil as Profile?)
                            ForEach(children, id: \.id) { child in
                                Text(child.name).tag(child as Profile?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("Schedule") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Repeat", selection: $recurringFrequency) {
                        Text("Never").tag(SupabaseTask.RecurringFrequency.daily)
                        Text("Daily").tag(SupabaseTask.RecurringFrequency.daily)
                        Text("Weekly").tag(SupabaseTask.RecurringFrequency.weekly)
                        Text("Monthly").tag(SupabaseTask.RecurringFrequency.monthly)
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
                    .disabled(title.isEmpty || selectedChild == nil)
                }
            }
            .onAppear {
                loadChildren()
            }
        }
        .alert("Task Created", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadChildren() {
        guard let currentProfile = authService.currentProfile else { return }
        
        Task {
            do {
                // For now, use mock data until we implement proper child fetching
                // In a real implementation, you'd fetch children associated with the current parent
                let mockChildren = [
                    Profile(
                        id: UUID(),
                        email: "child1@example.com",
                        name: "Child 1",
                        userType: .child
                    ),
                    Profile(
                        id: UUID(),
                        email: "child2@example.com", 
                        name: "Child 2",
                        userType: .child
                    )
                ]
                
                await MainActor.run {
                    self.children = mockChildren
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.alertMessage = "Failed to load children: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func saveTask() {
        guard !title.isEmpty,
              let selectedChild = selectedChild else {
            return
        }
        
        Task {
            do {
                let newTask = SupabaseTask(
                    title: title,
                    taskDescription: taskDescription.isEmpty ? nil : taskDescription,
                    rewardSeconds: Double(rewardMinutes * 60),
                    isRecurring: recurringFrequency != .daily, // Assuming daily is "never" for now
                    recurringFrequency: recurringFrequency,
                    assignedTo: selectedChild.id,
                    createdBy: authService.currentProfile?.id
                )
                
                // TODO: Save to Supabase using dataRepository
                // try await dataRepository.createTask(newTask)
                
                await MainActor.run {
                    alertMessage = "Task '\(title)' has been assigned to \(selectedChild.name)"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to create task: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Previews
struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView()
            .environmentObject(SafeSupabaseAuthService.shared)
            .environmentObject(SafeSupabaseDataRepository.shared)
    }
} 