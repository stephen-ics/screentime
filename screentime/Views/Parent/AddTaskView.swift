import SwiftUI

struct AddTaskView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyAuth: FamilyAuthService
    
    // MARK: - Dependencies
    private let dataRepository = SupabaseDataRepository.shared
    private let onTaskCreated: ((SupabaseTask) -> Void)?
    
    // MARK: - State
    @State private var taskName = ""
    @State private var taskDescription = ""
    @State private var selectedChild: FamilyProfile?
    @State private var rewardMinutes = 15
    @State private var isRecurring = false
    @State private var recurringFrequency: SupabaseTask.RecurringFrequency = .daily
    @State private var showChildPicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    // MARK: - Initializer
    init(onTaskCreated: ((SupabaseTask) -> Void)? = nil) {
        self.onTaskCreated = onTaskCreated
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Task Information Section
                Section {
                    TextField("Task Name", text: $taskName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                } header: {
                    Label("Task Details", systemImage: "list.bullet.clipboard")
                } footer: {
                    Text("Give your task a clear name and description so your child knows what to do.")
                }
                
                // Assignment Section
                Section {
                    Button(action: { showChildPicker = true }) {
                        HStack {
                            Label("Assign to", systemImage: "person")
                            Spacer()
                            Text(selectedChild?.name ?? "Select Child")
                                .foregroundColor(selectedChild == nil ? .secondary : .primary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Label("Assignment", systemImage: "person.crop.circle")
                }
                
                // Reward Section
                Section {
                    HStack {
                        Label("Reward Time", systemImage: "stopwatch")
                        Spacer()
                        
                        Picker("Minutes", selection: $rewardMinutes) {
                            ForEach([5, 10, 15, 20, 25, 30, 45, 60, 90, 120], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Preview:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack {
                            Text("⚡")
                            Text("+\(rewardMinutes) minutes of screen time")
                                .font(.callout)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                } header: {
                    Label("Screen Time Reward", systemImage: "gift")
                } footer: {
                    Text("Choose how much screen time your child earns for completing this task.")
                }
                
                // Recurring Section
                Section {
                    Toggle(isOn: $isRecurring) {
                        Label("Recurring Task", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    if isRecurring {
                        Picker("Frequency", selection: $recurringFrequency) {
                            ForEach(SupabaseTask.RecurringFrequency.allCases, id: \.self) { frequency in
                                HStack {
                                    Text(frequencyEmoji(for: frequency))
                                    Text(frequency.displayName)
                                    Text("(\(frequencyExample(for: frequency)))")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .tag(frequency)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Label("Recurrence", systemImage: "repeat")
                } footer: {
                    if isRecurring {
                        Text("This task will automatically reappear \(recurringFrequency.displayName.lowercased()) after completion.")
                    } else {
                        Text("Turn on to make this a repeating task.")
                    }
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        saveTask()
                    }
                    .disabled(!canSave || isSaving)
                    .fontWeight(.semibold)
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
    
    // MARK: - Helper Methods
    private func frequencyEmoji(for frequency: SupabaseTask.RecurringFrequency) -> String {
        switch frequency {
        case .daily: return "📅 Daily"
        case .weekly: return "📆 Weekly"
        case .monthly: return "📋 Monthly"
        }
    }
    
    private func frequencyExample(for frequency: SupabaseTask.RecurringFrequency) -> String {
        switch frequency {
        case .daily: return "every day"
        case .weekly: return "every week"
        case .monthly: return "every month"
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
                    taskDescription: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    rewardSeconds: Double(rewardMinutes * 60),
                    completedAt: nil,
                    isApproved: false,
                    isRecurring: isRecurring,
                    recurringFrequency: isRecurring ? recurringFrequency : nil,
                    assignedTo: child.id,
                    createdBy: familyAuth.currentProfile?.authUserId
                )
                
                _ = try await dataRepository.createTask(task)
                await MainActor.run {
                    dismiss()
                    onTaskCreated?(task)
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

// MARK: - Child Picker View
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
                        Circle()
                            .fill(Color.green.gradient)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(child.name.prefix(1)).uppercased())
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Text(child.name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedChild?.id == child.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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









