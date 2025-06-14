import SwiftUI

// MARK: - ChildTaskListViewModel
@MainActor
final class ChildTaskListViewModel: ObservableObject {
    @Published var tasks: [SupabaseTask] = []
    @Published var isLoading = true
    @Published var completedTasksToday = 0
    @Published var selectedTask: SupabaseTask?
    @Published var showingTaskDetail = false
    @Published var processingTaskId: UUID?
    
    init() {
        loadMockData()
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Replace with actual Supabase data loading
        loadMockData()
    }
    
    func refreshData() async {
        await loadData()
    }
    
    func completeTask(_ task: SupabaseTask) {
        // Set processing state
        processingTaskId = task.id
        
        // Simulate a brief delay for user feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Instead of completing immediately, request completion from parent
            self.requestTaskCompletion(task)
            
            // Clear processing state
            self.processingTaskId = nil
            
            // Close task detail if it's open
            if self.selectedTask?.id == task.id {
                self.selectedTask = nil
            }
        }
    }
    
    func requestTaskCompletion(_ task: SupabaseTask) {
        // Mark task as pending approval
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            // Create updated task with completion request
            var updatedTask = task
            updatedTask.completedAt = Date() // Set completion time
            updatedTask.isApproved = false // Waiting for parent approval
            
            // Update the task in the array
            tasks[index] = SupabaseTask(
                id: updatedTask.id,
                createdAt: updatedTask.createdAt,
                updatedAt: Date(),
                title: updatedTask.title,
                taskDescription: updatedTask.taskDescription,
                rewardSeconds: updatedTask.rewardSeconds,
                completedAt: updatedTask.completedAt,
                isApproved: updatedTask.isApproved,
                isRecurring: updatedTask.isRecurring,
                recurringFrequency: updatedTask.recurringFrequency,
                assignedTo: updatedTask.assignedTo,
                createdBy: updatedTask.createdBy
            )
            
            // TODO: Send notification to parent
            // This would integrate with your notification system
            print("🔔 Notification sent to parent: Child requested completion of '\(task.title)'")
            print("📝 Task status updated - ID: \(task.id), Completed: \(updatedTask.completedAt != nil), Approved: \(updatedTask.isApproved)")
        }
    }
    
    private func loadMockData() {
        // Mock tasks for the child with fun emojis
        tasks = [
            SupabaseTask(
                title: "🧹 Clean Your Room",
                taskDescription: "Make your bed, organize toys, and put clothes in the hamper",
                rewardSeconds: 900 // 15 minutes
            ),
            SupabaseTask(
                title: "📚 Math Homework",
                taskDescription: "Complete pages 45-47 in your math workbook",
                rewardSeconds: 1800 // 30 minutes
            ),
            SupabaseTask(
                title: "🐕 Feed the Dog",
                taskDescription: "Give Max his food and fresh water bowls",
                rewardSeconds: 600, // 10 minutes
                completedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())
            ),
            SupabaseTask(
                title: "🎹 Practice Piano",
                taskDescription: "Practice scales and your new song for 20 minutes",
                rewardSeconds: 1200 // 20 minutes
            ),
            SupabaseTask(
                title: "🍽️ Help with Dishes",
                taskDescription: "Load the dishwasher and wipe down the counters",
                rewardSeconds: 600 // 10 minutes
            ),
            SupabaseTask(
                title: "📖 Read for 30 Minutes",
                taskDescription: "Read your chapter book for at least 30 minutes",
                rewardSeconds: 1500, // 25 minutes
                completedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                isApproved: true
            )
        ]
        
        // Count completed tasks today
        let today = Calendar.current.startOfDay(for: Date())
        completedTasksToday = tasks.filter { task in
            if let completedAt = task.completedAt {
                return Calendar.current.startOfDay(for: completedAt) == today
            }
            return false
        }.count
        
        isLoading = false
    }
}

struct ChildTaskListView: View {
    @StateObject private var viewModel = ChildTaskListViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fun Header stats
                funHeaderStats
                
                // Task content
                taskContent
            }
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.groupedBackground,
                        DesignSystem.Colors.childAccent.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("⭐ My Tasks")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(item: $viewModel.selectedTask) { task in
                ChildTaskDetailView(
                    task: task,
                    isProcessing: viewModel.processingTaskId == task.id,
                    onComplete: {
                        viewModel.completeTask(task)
                    },
                    onDismiss: {
                        viewModel.selectedTask = nil
                    }
                )
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Fun Header Stats
    private var funHeaderStats: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            HStack(spacing: DesignSystem.Spacing.large) {
                FunStatBubble(
                    emoji: "⏰",
                    value: "\(pendingTasks.count)",
                    label: "To Do",
                    color: DesignSystem.Colors.warning
                )
                
                FunStatBubble(
                    emoji: "🎉",
                    value: "\(viewModel.completedTasksToday)",
                    label: "Done Today",
                    color: DesignSystem.Colors.success
                )
                
                FunStatBubble(
                    emoji: "⚡",
                    value: "+\(totalPendingReward)m",
                    label: "Can Earn",
                    color: DesignSystem.Colors.childAccent
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.medium)
        }
        .background(.white)
        .shadow(
            color: DesignSystem.Shadow.small.color.opacity(0.1),
            radius: DesignSystem.Shadow.small.radius,
            x: DesignSystem.Shadow.small.x,
            y: DesignSystem.Shadow.small.y
        )
    }
    
    // MARK: - Task Content
    private var taskContent: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.tasks.isEmpty {
                emptyStateView
            } else {
                tasksList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Text("⏳")
                .font(.system(size: 48))
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.childAccent))
                .scaleEffect(1.2)
            
            Text("Loading your awesome tasks...")
                .font(DesignSystem.Typography.bodyBold)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Text("🌟")
                .font(.system(size: 80))
            
            Text("All Done!")
                .font(DesignSystem.Typography.title1)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("Amazing job! You've completed all your tasks. Check back later for new ones! 🎉")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.large) {
                // Pending tasks section
                if !pendingTasks.isEmpty {
                    taskSection(
                        title: "🎯 Tasks to Complete",
                        subtitle: "Complete these to earn screen time!",
                        tasks: pendingTasks,
                        showCompleted: false
                    )
                }
                
                // Completed tasks section
                if !completedTasks.isEmpty {
                    taskSection(
                        title: "✅ Completed Tasks",
                        subtitle: "Great job on these!",
                        tasks: completedTasks,
                        showCompleted: true
                    )
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.xxxLarge) // Extra padding for tab bar
        }
    }
    
    private func taskSection(title: String, subtitle: String, tasks: [SupabaseTask], showCompleted: Bool) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                HStack {
                    Text(title)
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text("\(tasks.count)")
                        .font(DesignSystem.Typography.bodyBold)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.vertical, DesignSystem.Spacing.xSmall)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
                                .fill(showCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.childAccent)
                        )
                }
                
                Text(subtitle)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                ForEach(tasks, id: \.id) { task in
                    FunChildTaskCard(
                        task: task,
                        isProcessing: viewModel.processingTaskId == task.id,
                        onTap: {
                            viewModel.selectedTask = task
                        },
                        onComplete: {
                            viewModel.completeTask(task)
                        }
                    )
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                .fill(.white)
        )
        .shadow(
            color: DesignSystem.Shadow.card.color.opacity(0.1),
            radius: DesignSystem.Shadow.card.radius,
            x: DesignSystem.Shadow.card.x,
            y: DesignSystem.Shadow.card.y
        )
    }
    
    // MARK: - Computed Properties
    private var pendingTasks: [SupabaseTask] {
        viewModel.tasks
            .filter { !$0.isCompleted }
            .sorted(by: { $0.rewardSeconds > $1.rewardSeconds }) // Sort by reward amount
    }
    
    private var completedTasks: [SupabaseTask] {
        viewModel.tasks
            .filter { $0.isCompleted }
            .sorted(by: { 
                ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast)
            })
    }
    
    private var totalPendingReward: Int {
        Int(pendingTasks.reduce(0) { $0 + $1.rewardSeconds } / 60)
    }
}

// MARK: - Supporting Views

struct FunStatBubble: View {
    let emoji: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text(emoji)
                .font(.system(size: 20))
            
            Text(value)
                .font(DesignSystem.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(DesignSystem.Typography.caption1)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.15),
                            color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct FunChildTaskCard: View {
    let task: SupabaseTask
    let isProcessing: Bool
    let onTap: () -> Void
    let onComplete: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text(task.title)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let description = task.taskDescription {
                        Text(description)
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Compact status row
                    HStack(spacing: DesignSystem.Spacing.small) {
                        statusBadge
                        
                        Spacer()
                        
                        // Reward display
                        HStack(spacing: DesignSystem.Spacing.xSmall) {
                            Text("⚡")
                                .font(.system(size: 12))
                            
                            Text("+\(Int(task.rewardSeconds / 60)) min")
                                .font(DesignSystem.Typography.caption1)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, DesignSystem.Spacing.xxSmall)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
                                .fill(DesignSystem.Colors.success.opacity(0.15))
                        )
                    }
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(
                        task.isCompleted ? DesignSystem.Colors.success.opacity(0.3) : DesignSystem.Colors.separator.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: DesignSystem.Shadow.small.color.opacity(0.1),
                radius: DesignSystem.Shadow.small.radius,
                x: DesignSystem.Shadow.small.x,
                y: DesignSystem.Shadow.small.y
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Status Badge
    private var statusBadge: some View {
        Group {
            if task.isCompleted {
                if task.isApproved {
                    HStack(spacing: DesignSystem.Spacing.xSmall) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Approved")
                            .font(DesignSystem.Typography.caption1)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(DesignSystem.Colors.success)
                } else {
                    HStack(spacing: DesignSystem.Spacing.xSmall) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text("Pending Approval")
                            .font(DesignSystem.Typography.caption1)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(DesignSystem.Colors.warning)
                }
            } else {
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: "circle")
                        .font(.system(size: 12))
                    Text("Tap to complete")
                        .font(DesignSystem.Typography.caption1)
                        .fontWeight(.medium)
                }
                .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
    }
}

// MARK: - Task Detail View
struct ChildTaskDetailView: View {
    let task: SupabaseTask
    let isProcessing: Bool
    let onComplete: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Task header
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Text(task.title)
                        .font(DesignSystem.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    if let description = task.taskDescription {
                        Text(description)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                    }
                }
                .padding(.top, DesignSystem.Spacing.large)
                
                // Reward info
                HStack(spacing: DesignSystem.Spacing.medium) {
                    VStack(spacing: DesignSystem.Spacing.small) {
                        Text("⚡")
                            .font(.system(size: 24))
                        Text("Reward")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        Text("\(Int(task.rewardSeconds / 60)) min")
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .fill(DesignSystem.Colors.success.opacity(0.1))
                    )
                    
                    VStack(spacing: DesignSystem.Spacing.small) {
                        Text(statusEmoji)
                            .font(.system(size: 24))
                        Text("Status")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        Text(statusTitle)
                            .font(DesignSystem.Typography.caption1)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .fill(statusColor.opacity(0.1))
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                
                Spacer()
                
                // Completion button (only for pending tasks)
                if !task.isCompleted {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        Text("Ready to mark this task as complete?")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        Button(action: onComplete) {
                            HStack(spacing: DesignSystem.Spacing.small) {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                }
                                
                                Text(isProcessing ? "Requesting..." : "Mark Complete")
                                    .font(DesignSystem.Typography.body)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                            .padding(.vertical, DesignSystem.Spacing.medium)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(DesignSystem.Colors.childAccent)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isProcessing)
                        .opacity(isProcessing ? 0.8 : 1.0)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                }
                
                Spacer()
            }
            .background(DesignSystem.Colors.groupedBackground)
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.childAccent)
                }
            }
        }
    }
    
    private var statusEmoji: String {
        if task.isCompleted {
            return task.isApproved ? "✅" : "⏳"
        }
        return "⭐"
    }
    
    private var statusTitle: String {
        if task.isCompleted {
            return task.isApproved ? "Approved" : "Pending"
        }
        return "To Do"
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return task.isApproved ? DesignSystem.Colors.success : DesignSystem.Colors.warning
        }
        return DesignSystem.Colors.childAccent
    }
}

// MARK: - Preview
struct ChildTaskListView_Previews: PreviewProvider {
    static var previews: some View {
        ChildTaskListView()
    }
} 