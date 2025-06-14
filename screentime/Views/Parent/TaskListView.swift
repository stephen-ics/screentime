import SwiftUI

struct TaskListView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataRepository = SupabaseDataRepository.shared
    @EnvironmentObject private var familyAuth: FamilyAuthService
    
    // MARK: - State
    @State private var allTasks: [SupabaseTask] = []
    @State private var filteredTasks: [SupabaseTask] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddTask = false
    @State private var selectedTask: SupabaseTask?
    @State private var showingTaskDetail = false
    
    // MARK: - Filter State
    @State private var searchText = ""
    @State private var selectedChildFilter: FamilyProfile? = nil
    @State private var selectedStatusFilter: TaskStatusFilter = .all
    @State private var showingFilters = false
    
    // MARK: - Computed Properties
    private var childProfiles: [FamilyProfile] {
        familyAuth.availableProfiles.filter { $0.role == .child }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Section
                filterSection
                
                // Task List
                Group {
                    if isLoading {
                        ProgressView("Loading tasks...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredTasks.isEmpty {
                        ContentUnavailableView(
                            hasFiltersApplied ? "No Matching Tasks" : "No Tasks",
                            systemImage: hasFiltersApplied ? "magnifyingglass" : "checkmark.circle",
                            description: Text(hasFiltersApplied ? "Try adjusting your filters" : "Add tasks to help your child manage their screen time")
                        )
                    } else {
                        List {
                            ForEach(filteredTasks) { task in
                                TaskRow(task: task)
                                    .onTapGesture {
                                        selectedTask = task
                                        showingTaskDetail = true
                                    }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(isPresented: $showingTaskDetail) {
                if let task = selectedTask {
                    TaskDetailSheet(task: task) {
                        await loadTasks()
                    }
                }
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
        .task {
            await loadTasks()
        }
        .onChange(of: searchText) { _, _ in
            applyFilters()
        }
        .onChange(of: selectedChildFilter) { _, _ in
            applyFilters()
        }
        .onChange(of: selectedStatusFilter) { _, _ in
            applyFilters()
        }
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search tasks...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
            .padding(.horizontal, 20)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Status Filter
                    Menu {
                        ForEach(TaskStatusFilter.allCases, id: \.self) { status in
                            Button(action: { selectedStatusFilter = status }) {
                                HStack {
                                    Text(status.displayName)
                                    if selectedStatusFilter == status {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        FilterChip(
                            title: selectedStatusFilter.displayName,
                            isSelected: selectedStatusFilter != .all,
                            systemImage: "list.bullet.circle"
                        )
                    }
                    
                    // Child Filter
                    if !childProfiles.isEmpty {
                        Menu {
                            Button(action: { selectedChildFilter = nil }) {
                                HStack {
                                    Text("All Children")
                                    if selectedChildFilter == nil {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            ForEach(childProfiles, id: \.id) { child in
                                Button(action: { selectedChildFilter = child }) {
                                    HStack {
                                        Text(child.name)
                                        if selectedChildFilter?.id == child.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            FilterChip(
                                title: selectedChildFilter?.name ?? "All Children",
                                isSelected: selectedChildFilter != nil,
                                systemImage: "person.circle"
                            )
                        }
                    }
                    
                    // Clear Filters
                    if hasFiltersApplied {
                        Button(action: clearFilters) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Clear")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.red.opacity(0.1))
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                            .foregroundColor(.red)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
    
    // MARK: - Helper Properties
    private var hasFiltersApplied: Bool {
        !searchText.isEmpty || selectedChildFilter != nil || selectedStatusFilter != .all
    }
    
    // MARK: - Actions
    private func loadTasks() async {
        isLoading = true
        do {
            guard let currentProfile = familyAuth.currentProfile else {
                throw NSError(domain: "TaskListView", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current profile"])
            }
            allTasks = try await dataRepository.getTasksCreatedBy(userId: currentProfile.authUserId)
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func applyFilters() {
        var filtered = allTasks
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.taskDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply child filter
        if let selectedChild = selectedChildFilter {
            filtered = filtered.filter { $0.assignedTo == selectedChild.id }
        }
        
        // Apply status filter
        switch selectedStatusFilter {
        case .all:
            break
        case .pending:
            filtered = filtered.filter { !$0.isCompleted }
        case .completed:
            filtered = filtered.filter { $0.isCompleted && $0.isApproved }
        case .pendingApproval:
            filtered = filtered.filter { $0.isCompleted && !$0.isApproved }
        }
        
        filteredTasks = filtered
    }
    
    private func clearFilters() {
        searchText = ""
        selectedChildFilter = nil
        selectedStatusFilter = .all
    }
}

// MARK: - Task Status Filter
enum TaskStatusFilter: CaseIterable {
    case all, pending, completed, pendingApproval
    
    var displayName: String {
        switch self {
        case .all: return "All Tasks"
        case .pending: return "Pending"
        case .completed: return "Completed"
        case .pendingApproval: return "Pending Approval"
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.blue : Color(.systemGray5))
        )
        .foregroundColor(isSelected ? .white : .primary)
    }
}

// MARK: - Task Row
struct TaskRow: View {
    let task: SupabaseTask
    @EnvironmentObject private var familyAuth: FamilyAuthService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if let childName = assignedChildName {
                    Text(childName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .foregroundColor(.blue)
                }
            }
            
            if let desc = task.taskDescription, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label(task.statusDescription, systemImage: statusIcon)
                    .font(.caption)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Label(task.formattedReward, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(task.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var assignedChildName: String? {
        guard let assignedTo = task.assignedTo else { return nil }
        return familyAuth.availableProfiles.first { $0.id == assignedTo }?.name
    }
    
    private var statusIcon: String {
        if task.isCompleted {
            return task.isApproved ? "checkmark.circle" : "clock"
        } else {
            return "arrow.right.circle"
        }
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return task.isApproved ? .green : .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Task Detail Sheet
struct TaskDetailSheet: View {
    let task: SupabaseTask
    let onTaskUpdated: () async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @StateObject private var dataRepository = SupabaseDataRepository.shared
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Task Header
                    taskHeader
                    
                    // Task Details
                    taskDetails
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
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
    
    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(task.title)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Label(task.statusDescription, systemImage: statusIcon)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(statusColor.opacity(0.1))
                    )
                
                Spacer()
                
                if let childName = assignedChildName {
                    Label(childName, systemImage: "person.circle")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
        }
    }
    
    private var taskDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let description = task.taskDescription, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Reward")
                    .font(.headline)
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text(task.formattedReward)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Created")
                    .font(.headline)
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text(task.createdAt, style: .date)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            if let completedAt = task.completedAt {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed")
                        .font(.headline)
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text(completedAt, style: .date)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !task.isCompleted {
                Button(action: markAsCompleted) {
                    HStack {
                        if isUpdating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle")
                        }
                        Text("Mark as Completed")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                    )
                    .foregroundColor(.white)
                    .font(.headline)
                }
                .disabled(isUpdating)
            }
        }
    }
    
    private var assignedChildName: String? {
        guard let assignedTo = task.assignedTo else { return nil }
        return familyAuth.availableProfiles.first { $0.id == assignedTo }?.name
    }
    
    private var statusIcon: String {
        if task.isCompleted {
            return task.isApproved ? "checkmark.circle.fill" : "clock.fill"
        } else {
            return "arrow.right.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return task.isApproved ? .green : .orange
        } else {
            return .blue
        }
    }
    
    private func markAsCompleted() {
        Task {
            isUpdating = true
            do {
                print("🔍 DEBUG: Marking task as completed: \(task.id)")
                var updatedTask = task
                print("🔍 DEBUG: Updated task: \(updatedTask)")
                updatedTask.complete()
                updatedTask.approve()
                print("🔍 DEBUG: Updated task after completion: \(updatedTask)")
                _ = try await dataRepository.updateTask(updatedTask)
                print("🔍 DEBUG: Task updated successfully")
                await onTaskUpdated()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("🔍 DEBUG: Error marking task as completed: \(error)")
                errorMessage = error.localizedDescription
            }
            isUpdating = false
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(FamilyAuthService.shared)
} 