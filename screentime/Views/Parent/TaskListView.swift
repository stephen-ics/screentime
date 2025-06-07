import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var authService: SafeSupabaseAuthService
    @EnvironmentObject private var dataRepository: SafeSupabaseDataRepository
    @State private var tasks: [SupabaseTask] = []
    @State private var children: [Profile] = []
    @State private var showingAddTask = false
    @State private var selectedFilter = TaskFilter.all
    @State private var selectedChild: Profile?
    @State private var isLoading = true
    @State private var searchText = ""
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
        case overdue = "Overdue"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .pending: return "clock"
            case .completed: return "checkmark.circle"
            case .overdue: return "exclamationmark.triangle"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .pending: return .orange
            case .completed: return .green
            case .overdue: return .red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Filter chips
                filterChips
                
                // Child selector if multiple children
                if children.count > 1 {
                    childSelector
                }
                
                // Stats overview
                statsOverview
                
                // Tasks content
                tasksContent
            }
            .background(DesignSystem.Colors.groupedBackground)
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .refreshable {
                await loadData()
            }
        }
        .task {
            await loadData()
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tasks...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: taskCount(for: filter)
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Child Selector
    private var childSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ChildFilterChip(
                    child: nil,
                    isSelected: selectedChild == nil,
                    taskCount: filteredTasks.count
                ) {
                    selectedChild = nil
                }
                
                ForEach(children, id: \.id) { child in
                    ChildFilterChip(
                        child: child,
                        isSelected: selectedChild?.id == child.id,
                        taskCount: tasks.filter { $0.assignedTo == child.id }.count
                    ) {
                        selectedChild = child
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    // MARK: - Stats Overview
    private var statsOverview: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total",
                value: "\(tasks.count)",
                icon: "list.bullet",
                color: .blue
            )
            
            StatCard(
                title: "Completed",
                value: "\(completedTasks.count)",
                icon: "checkmark.circle",
                color: .green
            )
            
            StatCard(
                title: "Pending",
                value: "\(pendingTasks.count)",
                icon: "clock",
                color: .orange
            )
            
            StatCard(
                title: "Overdue",
                value: "\(overdueTasks.count)",
                icon: "exclamationmark.triangle",
                color: .red
            )
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Tasks Content
    private var tasksContent: some View {
        Group {
            if isLoading {
                loadingView
            } else if filteredTasks.isEmpty {
                emptyStateView
            } else {
                tasksList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.2)
            
            Text("Loading tasks...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedFilter == .all ? "list.bullet.clipboard" : selectedFilter.icon)
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(selectedFilter.color)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(emptyStateSubtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if selectedFilter == .all {
                Button("Add First Task") {
                    showingAddTask = true
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTasks, id: \.id) { task in
                    ModernTaskCard(
                        task: task,
                        child: children.first { $0.id == task.assignedTo }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // Add bottom padding for floating action button
        }
    }
    
    // MARK: - Computed Properties
    private var filteredTasks: [SupabaseTask] {
        var filtered = tasks
        
        // Filter by selected child
        if let selectedChild = selectedChild {
            filtered = filtered.filter { $0.assignedTo == selectedChild.id }
        }
        
        // Filter by status
        switch selectedFilter {
        case .all:
            break
        case .pending:
            filtered = filtered.filter { !$0.isCompleted }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        case .overdue:
            filtered = []
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.taskDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered.sorted(by: { task1, task2 in
            // Sort by completion status first, then by creation date
            if task1.isCompleted != task2.isCompleted {
                return !task1.isCompleted && task2.isCompleted
            }
            
            return task1.createdAt > task2.createdAt
        })
    }
    
    private var completedTasks: [SupabaseTask] {
        tasks.filter { $0.isCompleted }
    }
    
    private var pendingTasks: [SupabaseTask] {
        tasks.filter { !$0.isCompleted }
    }
    
    private var overdueTasks: [SupabaseTask] {
        []
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return searchText.isEmpty ? "No Tasks Yet" : "No Results"
        case .pending:
            return "No Pending Tasks"
        case .completed:
            return "No Completed Tasks"
        case .overdue:
            return "No Overdue Tasks"
        }
    }
    
    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .all:
            return searchText.isEmpty ? 
                "Get started by creating your first task to assign to your children." :
                "Try adjusting your search terms or filters."
        case .pending:
            return "All tasks have been completed! Great job."
        case .completed:
            return "No tasks have been completed yet."
        case .overdue:
            return "No tasks are currently overdue."
        }
    }
    
    // MARK: - Helper Methods
    private func taskCount(for filter: TaskFilter) -> Int {
        switch filter {
        case .all: return tasks.count
        case .pending: return pendingTasks.count
        case .completed: return completedTasks.count
        case .overdue: return overdueTasks.count
        }
    }
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load mock data - in a real app, this would fetch from Supabase
        await loadMockData()
    }
    
    private func loadMockData() async {
        // Mock children
        children = [
            Profile(id: UUID(), email: "alice@child.local", name: "Alice", userType: .child),
            Profile(id: UUID(), email: "bob@child.local", name: "Bob", userType: .child)
        ]
        
        // Mock tasks
        tasks = [
            SupabaseTask(
                title: "Clean Your Room",
                taskDescription: "Make bed, organize toys, and put clothes away",
                rewardSeconds: 900 // 15 minutes
            ),
            SupabaseTask(
                title: "Homework - Math",
                taskDescription: "Complete pages 45-47 in math workbook",
                rewardSeconds: 1800 // 30 minutes
            ),
            SupabaseTask(
                title: "Feed the Dog",
                taskDescription: "Give Max his food and fresh water",
                rewardSeconds: 600, // 10 minutes
                completedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())
            ),
            SupabaseTask(
                title: "Practice Piano",
                taskDescription: "Practice scales and the new song for 30 minutes",
                rewardSeconds: 1200 // 20 minutes
            ),
            SupabaseTask(
                title: "Organize Backpack",
                taskDescription: "Clean out and organize school backpack",
                rewardSeconds: 600 // 10 minutes
            )
        ]
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let filter: TaskListView.TaskFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : filter.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.white.opacity(0.3) : filter.color.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : filter.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? filter.color : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChildFilterChip: View {
    let child: Profile?
    let isSelected: Bool
    let taskCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Avatar
                Circle()
                    .fill(child == nil ? Color.gray : Color.blue)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(child?.name.prefix(1) ?? "A")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                Text(child?.name ?? "All Children")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(taskCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.white.opacity(0.3) : Color.blue.opacity(0.2))
                    )
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ModernTaskCard: View {
    let task: SupabaseTask
    let child: Profile?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Task status icon
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: statusIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(statusColor)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let child = child {
                        Text("Assigned to \(child.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Reward badge
                VStack(spacing: 2) {
                    Text("+\(Int(task.rewardSeconds / 60))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Description
            if let description = task.taskDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Footer
            HStack {
                // Completion info
                if let completedAt = task.completedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Completed \(formatDate(completedAt))")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("Pending")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Recurring indicator
                if task.isRecurring {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.2.circlepath")
                            .font(.caption2)
                        Text("Recurring")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(task.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return .green
        } else {
            return .orange
        }
    }
    
    private var statusIcon: String {
        if task.isCompleted {
            return "checkmark.circle.fill"
        } else {
            return "clock.fill"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
            .environmentObject(SafeSupabaseAuthService.shared)
            .environmentObject(SafeSupabaseDataRepository.shared)
    }
}

// MARK: - Reports View (Placeholder)
struct ReportsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Reports")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Detailed analytics and reports will be available in a future update.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reports")
        }
    }
} 