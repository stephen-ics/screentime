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
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
                    // Fun task emoji
                    Text(getTaskEmoji(task.title))
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        Text(task.title)
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let description = task.taskDescription {
                            Text(description)
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Spacer()
                    
                    // Big fun reward display
                    VStack(spacing: DesignSystem.Spacing.xSmall) {
                        Text("⚡")
                            .font(.system(size: 16))
                        
                        Text("+\(Int(task.rewardSeconds / 60))")
                            .font(DesignSystem.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.success)
                        
                        Text("min")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.success.opacity(0.2),
                                        DesignSystem.Colors.success.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(DesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Status footer
                HStack {
                    statusBadge
                    
                    Spacer()
                    
                    if !task.isCompleted && onComplete != nil {
                        Button(action: {
                            onComplete?()
                        }) {
                            HStack(spacing: DesignSystem.Spacing.small) {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("🙏")
                                        .font(.system(size: 14))
                                }
                                
                                Text(isProcessing ? "Requesting..." : "Request Complete")
                                    .font(DesignSystem.Typography.bodyBold)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                            .padding(.vertical, DesignSystem.Spacing.small)
                            .background(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.childAccent,
                                        DesignSystem.Colors.childAccent.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .shadow(
                                color: DesignSystem.Colors.childAccent.opacity(0.3),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                        }
                        .buttonStyle(FunScaleButtonStyle())
                        .disabled(isProcessing)
                        .opacity(isProcessing ? 0.8 : 1.0)
                    } else if task.isCompleted && !task.isApproved {
                        // Waiting for parent approval state
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            HStack(spacing: DesignSystem.Spacing.buttonIconSpacing) {
                                Text("⏳")
                                    .font(.system(size: 20))
                                
                                Text("Waiting for Parent Approval")
                                    .font(DesignSystem.Typography.bodyBold)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(DesignSystem.Colors.warning)
                            .padding(.horizontal, DesignSystem.Spacing.buttonHorizontalPadding)
                            .padding(.vertical, DesignSystem.Spacing.buttonVerticalPadding)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: DesignSystem.Layout.minButtonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                    .fill(DesignSystem.Colors.warning.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                    .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: 2)
                            )
                            
                            Text("Your request has been sent to your parent for review.")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                    .fill(
                        LinearGradient(
                            colors: [
                                task.isCompleted ? DesignSystem.Colors.success.opacity(0.05) : DesignSystem.Colors.childAccent.opacity(0.03),
                                .white
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                    .stroke(
                        task.isCompleted ? DesignSystem.Colors.success.opacity(0.3) : DesignSystem.Colors.childAccent.opacity(0.2),
                        lineWidth: 2
                    )
            )
            .shadow(
                color: task.isCompleted ? DesignSystem.Colors.success.opacity(0.2) : DesignSystem.Colors.childAccent.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusBadge: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Text(statusEmoji)
                .font(.system(size: 14))
            
            Text(statusText)
                .font(DesignSystem.Typography.caption1)
                .fontWeight(.bold)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.xSmall)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
                .fill(statusColor.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return task.isApproved ? DesignSystem.Colors.success : DesignSystem.Colors.warning
        }
        return DesignSystem.Colors.childAccent
    }
    
    private var statusEmoji: String {
        if task.isCompleted {
            return task.isApproved ? "🎉" : "⏳"
        }
        return "🎯"
    }
    
    private var statusText: String {
        if task.isCompleted {
            return task.isApproved ? "Approved!" : "Requested"
        }
        return "Ready to Do!"
    }
    
    private func getTaskEmoji(_ title: String) -> String {
        let lowercased = title.lowercased()
        if lowercased.contains("clean") || lowercased.contains("room") {
            return "🧹"
        } else if lowercased.contains("homework") || lowercased.contains("math") {
            return "📚"
        } else if lowercased.contains("dog") || lowercased.contains("pet") {
            return "🐕"
        } else if lowercased.contains("piano") || lowercased.contains("music") {
            return "🎹"
        } else if lowercased.contains("dish") || lowercased.contains("kitchen") {
            return "🍽️"
        } else if lowercased.contains("read") {
            return "📖"
        } else {
            return "⭐"
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
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxLarge) {
                    // Fun task header
                    VStack(spacing: DesignSystem.Spacing.large) {
                        Text(getTaskEmoji(task.title))
                            .font(.system(size: 80))
                        
                        Text(task.title)
                            .font(DesignSystem.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                            .multilineTextAlignment(.center)
                        
                        if let description = task.taskDescription {
                            Text(description)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(DesignSystem.Spacing.large)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                        .fill(DesignSystem.Colors.groupedBackground)
                                )
                        }
                    }
                    
                    // Big reward section
                    rewardSection
                    
                    // Status section
                    statusSection
                    
                    Spacer(minLength: DesignSystem.Spacing.xxxLarge)
                }
                .padding(DesignSystem.Spacing.medium)
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
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.childAccent)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    
                    if !task.isCompleted {
                        Button(action: onComplete) {
                            HStack(spacing: DesignSystem.Spacing.buttonIconSpacing) {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("🙏")
                                        .font(.system(size: 20))
                                }
                                
                                Text(isProcessing ? "Requesting..." : "Request Complete")
                                    .font(DesignSystem.Typography.bodyBold)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.buttonHorizontalPadding)
                            .padding(.vertical, DesignSystem.Spacing.buttonVerticalPadding)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: DesignSystem.Layout.minButtonHeight)
                            .background(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.childAccent,
                                        DesignSystem.Colors.childAccent.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(DesignSystem.CornerRadius.button)
                            .shadow(
                                color: DesignSystem.Colors.childAccent.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        }
                        .buttonStyle(FunScaleButtonStyle())
                        .disabled(isProcessing)
                        .opacity(isProcessing ? 0.8 : 1.0)
                    } else if task.isCompleted && !task.isApproved {
                        // Waiting for parent approval state
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            HStack(spacing: DesignSystem.Spacing.buttonIconSpacing) {
                                Text("⏳")
                                    .font(.system(size: 20))
                                
                                Text("Waiting for Parent Approval")
                                    .font(DesignSystem.Typography.bodyBold)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(DesignSystem.Colors.warning)
                            .padding(.horizontal, DesignSystem.Spacing.buttonHorizontalPadding)
                            .padding(.vertical, DesignSystem.Spacing.buttonVerticalPadding)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: DesignSystem.Layout.minButtonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                    .fill(DesignSystem.Colors.warning.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                    .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: 2)
                            )
                            
                            Text("Your request has been sent to your parent for review.")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.medium)
                .background(DesignSystem.Colors.background)
            }
        }
    }
    
    private var rewardSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("🎁 Your Reward")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.large) {
                Text("⚡")
                    .font(.system(size: 48))
                
                VStack(spacing: DesignSystem.Spacing.small) {
                    Text("\(Int(task.rewardSeconds / 60)) minutes")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.success)
                    
                    Text("of awesome screen time! 🚀")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.xxLarge)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.success.opacity(0.15),
                                DesignSystem.Colors.success.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                    .stroke(DesignSystem.Colors.success.opacity(0.3), lineWidth: 2)
            )
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
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("📊 Status")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            HStack(spacing: DesignSystem.Spacing.large) {
                Text(statusEmoji)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text(statusTitle)
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(statusDescription)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
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
    
    private var statusEmoji: String {
        if task.isCompleted {
            return task.isApproved ? "🎉" : "⏳"
        }
        return "🎯"
    }
    
    private var statusTitle: String {
        if task.isCompleted {
            return task.isApproved ? "Completed & Approved!" : "Waiting for Parent"
        }
        return "Ready to Complete!"
    }
    
    private var statusDescription: String {
        if task.isCompleted {
            return task.isApproved ? "Awesome job! Your reward has been added to your screen time." : "Your completion request is being reviewed by your parent. You'll get your reward time once approved!"
        }
        return "Tap 'Request Complete' when you're all done with this task and your parent will review it!"
    }
    
    private func getTaskEmoji(_ title: String) -> String {
        let lowercased = title.lowercased()
        if lowercased.contains("clean") || lowercased.contains("room") {
            return "🧹"
        } else if lowercased.contains("homework") || lowercased.contains("math") {
            return "📚"
        } else if lowercased.contains("dog") || lowercased.contains("pet") {
            return "🐕"
        } else if lowercased.contains("piano") || lowercased.contains("music") {
            return "🎹"
        } else if lowercased.contains("dish") || lowercased.contains("kitchen") {
            return "🍽️"
        } else if lowercased.contains("read") {
            return "📖"
        } else {
            return "⭐"
        }
    }
}

// MARK: - Preview
struct ChildTaskListView_Previews: PreviewProvider {
    static var previews: some View {
        ChildTaskListView()
    }
} 