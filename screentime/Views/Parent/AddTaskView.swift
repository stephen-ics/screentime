import SwiftUI
import CoreData

struct AddTaskView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authService: AuthenticationService
    
    // MARK: - State
    @State private var title = ""
    @State private var description = ""
    @State private var rewardMinutes: Int32 = 30
    @State private var selectedChild: User?
    @State private var isRecurring = false
    @State private var recurringFrequency: Task.RecurringFrequency = .daily
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - Fetch Request
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        predicate: NSPredicate(format: "userType == %@", User.UserType.child.rawValue)
    ) private var children: FetchedResults<User>
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Reward")) {
                    Stepper(
                        "Reward: \(rewardMinutes) minutes",
                        value: $rewardMinutes,
                        in: 5...240,
                        step: 5
                    )
                }
                
                Section(header: Text("Assignment")) {
                    Picker("Assign to", selection: $selectedChild) {
                        Text("Select a child").tag(nil as User?)
                        ForEach(children) { child in
                            Text(child.name).tag(child as User?)
                        }
                    }
                }
                
                Section(header: Text("Recurrence")) {
                    Toggle("Recurring Task", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Frequency", selection: $recurringFrequency) {
                            ForEach([Task.RecurringFrequency.daily, .weekly, .monthly], id: \.self) { frequency in
                                Text(frequency.localizedDescription).tag(frequency)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Create") { createTask() }
                    .disabled(!isValidForm)
            )
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var isValidForm: Bool {
        !title.isEmpty && selectedChild != nil
    }
    
    // MARK: - Actions
    private func createTask() {
        guard let currentUser = authService.currentUser,
              let selectedChild = selectedChild else {
            return
        }
        
        do {
            let task = try CoreDataManager.shared.createTask(
                title: title,
                description: description.isEmpty ? nil : description,
                rewardMinutes: rewardMinutes,
                assignedTo: selectedChild,
                createdBy: currentUser
            )
            
            task.isRecurring = isRecurring
            if isRecurring {
                task.recurringFrequency = recurringFrequency.rawValue
            }
            
            try CoreDataManager.shared.save()
            
            // Schedule notification
            try NotificationService.shared.scheduleTaskNotification(for: task)
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview
struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView()
            .environmentObject(AuthenticationService.shared)
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
} 