import SwiftUI
import CoreData

struct AddTaskView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: AppRouter
    
    // MARK: - State
    @State private var title = ""
    @State private var description = ""
    @State private var rewardMinutes: Int32 = 30
    @State private var selectedChild: User?
    @State private var isRecurring = false
    @State private var recurringFrequency: Task.RecurringFrequency = .daily
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isCreating = false
    
    // MARK: - Fetch Request
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        predicate: NSPredicate(format: "userType == %@", User.UserType.child.rawValue)
    ) private var children: FetchedResults<User>
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.groupedBackground
                    .ignoresSafeArea()
                
                if children.isEmpty {
                    emptyChildrenState
                } else {
                    taskForm
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        router.dismissSheet()
                    }
                    .disabled(isCreating)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(!isValidForm || isCreating)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Empty Children State
    
    @ViewBuilder
    private var emptyChildrenState: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "person.2.slash")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                
                Text("No Children Linked")
                    .font(DesignSystem.Typography.title1)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("You need to link children to your account before creating tasks")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.large)
            }
            
            Button(action: {
                router.dismissSheet()
                router.presentSheet(.addChild)
            }) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .medium))
                    Text("Add Child First")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: true))
            .frame(maxWidth: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxxLarge)
    }
    
    // MARK: - Task Form
    
    @ViewBuilder
    private var taskForm: some View {
        Form {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                // Task Details Header
                Text("Task Details")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .padding(.bottom, DesignSystem.Spacing.small)
                
                CustomTextField(
                    placeholder: "Task Title",
                    text: $title,
                    icon: "text.cursor",
                    keyboardType: .default,
                    textContentType: .none
                )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    Text("Description (Optional)")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    TextField("Add a description...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(DesignSystem.Spacing.medium)
                        .background(DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.input)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.small)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                // Reward Header
                Text("Reward")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .padding(.bottom, DesignSystem.Spacing.small)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    HStack {
                        Text("Screen Time Reward")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Text("\(rewardMinutes) minutes")
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(rewardMinutes) },
                            set: { rewardMinutes = Int32($0) }
                        ),
                        in: 5...240,
                        step: 5
                    )
                    .accentColor(DesignSystem.Colors.success)
                    
                    HStack {
                        Text("5 min")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                        
                        Spacer()
                        
                        Text("4 hours")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.small)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                // Assignment Header
                Text("Assignment")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .padding(.bottom, DesignSystem.Spacing.small)
                
                Picker("Assign to", selection: $selectedChild) {
                    Text("Select a child").tag(nil as User?)
                    ForEach(children) { child in
                        HStack {
                            Text(child.name)
                            Spacer()
                            if child.isParent {
                                Text("Parent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(child as User?)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.vertical, DesignSystem.Spacing.small)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                // Recurrence Header
                Text("Recurrence")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .padding(.bottom, DesignSystem.Spacing.small)
                
                Toggle("Recurring Task", isOn: $isRecurring)
                
                if isRecurring {
                    Picker("Frequency", selection: $recurringFrequency) {
                        ForEach([Task.RecurringFrequency.daily, .weekly, .monthly], id: \.self) { frequency in
                            Text(frequency.localizedDescription).tag(frequency)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.small)
        }
        .disabled(isCreating)
        .overlay {
            if isCreating {
                ProgressView("Creating Task...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignSystem.Colors.background.opacity(0.8))
            }
        }
    }
    
    // MARK: - Computed Properties
    private var isValidForm: Bool {
        !title.isEmpty && selectedChild != nil
    }
    
    // MARK: - Actions
    private func createTask() {
        guard let currentUser = UserService.shared.getCurrentUser(),
              let selectedChild = selectedChild else {
            errorMessage = "Unable to create task. Please try again."
            showError = true
            return
        }
        
        isCreating = true
        
        // Use DispatchQueue to avoid Task naming conflict
        DispatchQueue.global(qos: .userInitiated).async {
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
                
                // Schedule notification on background queue
                _Concurrency.Task {
                    do {
                        try await NotificationService.shared.scheduleTaskNotification(for: task)
                    } catch {
                        print("Failed to schedule notification: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    router.dismissSheet()
                }
                
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showError = true
                    isCreating = false
                }
            }
        }
    }
}

// MARK: - Preview
struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView()
            .environmentObject(AppRouter())
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
} 