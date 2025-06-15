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
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var showingAddTask = false
    @State private var selectedTask: SupabaseTask?
    @State private var showingTaskDetail = false
    
    // MARK: - Pagination State
    @State private var currentPage = 0
    @State private var hasMoreTasks = true
    @State private var totalTaskCount = 0
    private let pageSize = 25
    
    // MARK: - Filter State
    @State private var searchText = ""
    @State private var selectedChildFilter: FamilyProfile? = nil
    @State private var selectedStatusFilter: TaskStatusFilter = .all
    @State private var selectedTimeFilter: TimeFilter = .recent
    @State private var showingFilters = false
    
    // MARK: - Task Management
    @State private var refreshTask: Task<Void, Never>?
    @State private var loadTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    private var childProfiles: [FamilyProfile] {
        familyAuth.availableProfiles.filter { $0.role == .child }
    }
    
    private var groupedTasks: [(String, [SupabaseTask])] {
        let sortedTasks = filteredTasks.sorted { $0.createdAt > $1.createdAt }
        return Dictionary(grouping: sortedTasks) { task in
            taskDateGroup(for: task.createdAt)
        }
        .sorted { first, second in
            let order = ["Today", "Yesterday", "This Week", "Last Week", "This Month", "Earlier"]
            let firstIndex = order.firstIndex(of: first.key) ?? order.count
            let secondIndex = order.firstIndex(of: second.key) ?? order.count
            return firstIndex < secondIndex
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Section
                filterSection
                
                // Task Count and Load Status
                taskStatusHeader
                
                // Task List
                mainContent
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
                AddTaskView { newTask in
                    // Add the task immediately to local state
                    addTaskToList(newTask)
                }
            }
            .sheet(isPresented: $showingTaskDetail) {
                if let task = selectedTask {
                    TaskDetailSheet(
                        task: task,
                        onTaskUpdated: {
                            // Refresh data in background to sync with server
                            await MainActor.run {
                                handleTaskUpdated()
                            }
                        },
                        onTaskUpdatedImmediately: { updatedTask in
                            // Update the main list immediately for instant feedback
                            updateTaskInList(updatedTask)
                        }
                    )
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
        .navigationViewStyle(.stack)
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
        .onChange(of: selectedTimeFilter) { _, _ in
            Task {
                await refreshTasks()
            }
        }
        .onDisappear {
            // Cancel ongoing tasks when view disappears
            refreshTask?.cancel()
            loadTask?.cancel()
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        Group {
            if isLoading && currentPage == 0 {
                ProgressView("Loading tasks...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredTasks.isEmpty && !isLoading {
                emptyStateView
            } else {
                taskListView
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        ContentUnavailableView(
            hasFiltersApplied ? "No Matching Tasks" : "No Tasks",
            systemImage: hasFiltersApplied ? "magnifyingglass" : "checkmark.circle",
            description: Text(hasFiltersApplied ? "Try adjusting your filters" : "Add tasks to help your child manage their screen time")
        )
    }
    
    // MARK: - Task List View
    private var taskListView: some View {
        List {
            ForEach(groupedTasks, id: \.0) { section, tasks in
                Section(header: sectionHeader(section)) {
                    ForEach(tasks) { task in
                        TaskRow(task: task)
                            .onTapGesture {
                                selectedTask = task
                                showingTaskDetail = true
                            }
                    }
                }
            }
            
            // Load More Button
            if hasMoreTasks && !isLoading {
                loadMoreSection
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await refreshTasks()
        }
    }
    
    // MARK: - Task Status Header
    private var taskStatusHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(filteredTasks.count) of \(totalTaskCount) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if selectedTimeFilter != .all {
                    Text(selectedTimeFilter.description)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            if isLoadingMore {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Load More Section
    private var loadMoreSection: some View {
        HStack {
            Spacer()
            Button(action: { Task { await loadMoreTasks() } }) {
                HStack(spacing: 8) {
                    if isLoadingMore {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.circle")
                    }
                    Text(isLoadingMore ? "Loading..." : "Load More Tasks")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.vertical, 12)
            }
            .disabled(isLoadingMore)
            Spacer()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .textCase(nil)
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
                    // Time Filter
                    Menu {
                        ForEach(TimeFilter.allCases, id: \.self) { timeFilter in
                            Button(action: { selectedTimeFilter = timeFilter }) {
                                HStack {
                                    Text(timeFilter.displayName)
                                    if selectedTimeFilter == timeFilter {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        FilterChip(
                            title: selectedTimeFilter.displayName,
                            isSelected: selectedTimeFilter != .recent,
                            systemImage: "calendar"
                        )
                    }
                    
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
        !searchText.isEmpty || selectedChildFilter != nil || selectedStatusFilter != .all || selectedTimeFilter != .recent
    }
    
    // MARK: - Date Grouping Helper
    private func taskDateGroup(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return "This Week"
        } else if let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now),
                  calendar.isDate(date, equalTo: lastWeek, toGranularity: .weekOfYear) {
            return "Last Week"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            return "This Month"
        } else {
            return "Earlier"
        }
    }
    
    // MARK: - Actions
    private func loadTasks() async {
        // Cancel any existing load task
        loadTask?.cancel()
        
        let task = Task {
            await performLoadTasks()
        }
        loadTask = task
        await task.value
    }
    
    private func performLoadTasks() async {
        print("🔍 DEBUG: Loading tasks - page: \(currentPage)")
        if currentPage == 0 {
            await MainActor.run {
                isLoading = true
                // Clear error message when starting fresh load
                if currentPage == 0 {
                    errorMessage = nil
                }
            }
        } else {
            await MainActor.run {
                isLoadingMore = true
            }
        }
        
        do {
            guard let currentProfile = familyAuth.currentProfile else {
                throw NSError(domain: "TaskListView", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current profile"])
            }
            
            let dateRange = selectedTimeFilter.dateRange
            
            // Check for cancellation
            try Task.checkCancellation()
            
            let newTasks = try await dataRepository.getTasksCreatedBy(
                userId: currentProfile.authUserId,
                fromDate: dateRange.from,
                toDate: dateRange.to,
                limit: pageSize,
                offset: currentPage * pageSize
            )
            
            // Check for cancellation again
            try Task.checkCancellation()
            
            // Get total count for the current filter
            let newTotalCount = try await dataRepository.getTaskCountCreatedBy(
                userId: currentProfile.authUserId,
                fromDate: dateRange.from,
                toDate: dateRange.to
            )
            
            // Check for cancellation before updating UI
            try Task.checkCancellation()
            
            await MainActor.run {
                totalTaskCount = newTotalCount
                
                if currentPage == 0 {
                    allTasks = newTasks
                } else {
                    allTasks.append(contentsOf: newTasks)
                }
                
                hasMoreTasks = newTasks.count == pageSize && allTasks.count < totalTaskCount
                applyFilters()
            }
            
        } catch is CancellationError {
            // Silently handle cancellation - don't show error to user
            print("🔍 DEBUG: Task loading was cancelled")
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isLoading = false
            isLoadingMore = false
        }
    }
    
    private func loadMoreTasks() async {
        guard hasMoreTasks && !isLoadingMore else { return }
        await MainActor.run {
            currentPage += 1
        }
        await loadTasks()
    }
    
    private func refreshTasks() async {
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        let task = Task {
            // Small delay to allow for batching quick successive operations
            do {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                try Task.checkCancellation()
            } catch {
                // Handle cancellation and errors gracefully
                return
            }
            await performRefreshTasks()
        }
        refreshTask = task
        await task.value
    }
    
    @MainActor
    private func performRefreshTasks() async {
        currentPage = 0
        hasMoreTasks = true
        await loadTasks()
    }
    
    @MainActor
    private func handleTaskUpdated() {
        // Trigger a refresh when a task is updated
        Task {
            await refreshTasks()
        }
    }
    
    @MainActor
    private func updateTaskInList(_ updatedTask: SupabaseTask) {
        // Find and update the task immediately in the main list
        if let index = allTasks.firstIndex(where: { $0.id == updatedTask.id }) {
            allTasks[index] = updatedTask
        } else {
            // If task not found (e.g., just created), add it to the list
            allTasks.insert(updatedTask, at: 0)
        }
        applyFilters()
    }
    
    @MainActor
    private func addTaskToList(_ newTask: SupabaseTask) {
        // Add the new task immediately to local state
        allTasks.insert(newTask, at: 0)
        totalTaskCount += 1
        applyFilters()
    }
    
    @MainActor
    private func updateTaskOptimistically(_ taskId: UUID, completion: @escaping (inout SupabaseTask) -> Void) {
        // Find and update the task immediately in local state for instant UI feedback
        if let index = allTasks.firstIndex(where: { $0.id == taskId }) {
            completion(&allTasks[index])
            applyFilters()
        }
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
        selectedTimeFilter = .recent
    }
}

// MARK: - Time Filter
enum TimeFilter: CaseIterable {
    case recent, thisWeek, thisMonth, last3Months, thisYear, all
    
    var displayName: String {
        switch self {
        case .recent: return "Recent"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .last3Months: return "Last 3 Months"
        case .thisYear: return "This Year"
        case .all: return "All Time"
        }
    }
    
    var description: String {
        switch self {
        case .recent: return "Last 30 days"
        case .thisWeek: return "This week"
        case .thisMonth: return "This month"
        case .last3Months: return "Last 3 months"
        case .thisYear: return "This year"
        case .all: return "All tasks"
        }
    }
    
    var dateRange: (from: Date?, to: Date?) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .recent:
            return (calendar.date(byAdding: .day, value: -30, to: now), now)
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            return (startOfWeek, now)
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start
            return (startOfMonth, now)
        case .last3Months:
            return (calendar.date(byAdding: .month, value: -3, to: now), now)
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start
            return (startOfYear, now)
        case .all:
            return (nil, nil)
        }
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
    let onTaskUpdatedImmediately: (SupabaseTask) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @StateObject private var dataRepository = SupabaseDataRepository.shared
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var localTask: SupabaseTask
    
    init(task: SupabaseTask, onTaskUpdated: @escaping () async -> Void, onTaskUpdatedImmediately: @escaping (SupabaseTask) -> Void) {
        self.task = task
        self.onTaskUpdated = onTaskUpdated
        self.onTaskUpdatedImmediately = onTaskUpdatedImmediately
        self._localTask = State(initialValue: task)
    }
    
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
            Text(localTask.title)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Label(localTask.statusDescription, systemImage: statusIcon)
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
            if let description = localTask.taskDescription, !description.isEmpty {
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
                    Text(localTask.formattedReward)
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
                    Text(localTask.createdAt, style: .date)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            if let completedAt = localTask.completedAt {
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
            if !localTask.isCompleted {
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
        guard let assignedTo = localTask.assignedTo else { return nil }
        return familyAuth.availableProfiles.first { $0.id == assignedTo }?.name
    }
    
    private var statusIcon: String {
        if localTask.isCompleted {
            return localTask.isApproved ? "checkmark.circle.fill" : "clock.fill"
        } else {
            return "arrow.right.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if localTask.isCompleted {
            return localTask.isApproved ? .green : .orange
        } else {
            return .blue
        }
    }
    
    private func markAsCompleted() {
        Task {
            isUpdating = true
            
            // First, optimistically update the UI immediately
            await MainActor.run {
                localTask.completeAndApprove()
                // Update the main list immediately as well
                onTaskUpdatedImmediately(localTask)
                // Close the sheet immediately since the task is now "completed"
                dismiss()
            }
            
            do {
                print("🔍 DEBUG: Marking task as completed: \(task.id)")
                var updatedTask = task
                updatedTask.completeAndApprove()
                print("🔍 DEBUG: Updated task after completion: \(updatedTask)")
                _ = try await dataRepository.updateTask(updatedTask)
                print("🔍 DEBUG: Task updated successfully")
                
                // Refresh the list in the background to sync with server
                await onTaskUpdated()
                
            } catch {
                print("🔍 DEBUG: Error marking task as completed: \(error)")
                
                // If the network call fails, refresh to restore correct state
                await onTaskUpdated()
            }
            
            await MainActor.run {
                isUpdating = false
            }
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(FamilyAuthService.shared)
} 