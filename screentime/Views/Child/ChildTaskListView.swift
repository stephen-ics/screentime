import SwiftUI

struct ChildTaskListView: View {
    @StateObject private var dataRepository = SupabaseDataRepository.shared
    @EnvironmentObject private var familyAuth: FamilyAuthService
    
    // MARK: - State
    @State private var tasks: [SupabaseTask] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTask: SupabaseTask?
    @State private var processingTaskId: UUID?
    
    // MARK: - Pagination State
    @State private var currentPage = 0
    @State private var hasMoreTasks = true
    @State private var totalTaskCount = 0
    @State private var isLoadingMore = false
    private let pageSize = 20

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
                await loadTasks(refresh: true)
            }
            .sheet(item: $selectedTask) { task in
                ChildTaskDetailView(
                    task: task,
                    isProcessing: processingTaskId == task.id,
                    onComplete: {
                        completeTask(task)
                    },
                    onDismiss: {
                        selectedTask = nil
                    }
                )
            }
        }
        .navigationViewStyle(.stack)
        .task {
            await loadTasks()
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
                    value: "\(completedTasksToday)",
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
            if isLoading && currentPage == 0 {
                loadingView
            } else if tasks.isEmpty && !isLoading {
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
                        tasks: pendingTasks
                    )
                }
                
                // Pending approval section
                if !pendingApprovalTasks.isEmpty {
                    taskSection(
                        title: "⏳ Pending Approval",
                        subtitle: "Your parents will review these soon!",
                        tasks: pendingApprovalTasks
                    )
                }

                // Completed tasks section
                if !completedTasks.isEmpty {
                    taskSection(
                        title: "✅ Approved Tasks",
                        subtitle: "Great job on these!",
                        tasks: completedTasks
                    )
                }

                // Load More Button
                if hasMoreTasks {
                    loadMoreButton
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.xxxLarge)
        }
    }

    private var loadMoreButton: some View {
        Button(action: {
            Task { await loadMoreTasks() }
        }) {
            HStack(spacing: 8) {
                if isLoadingMore {
                    ProgressView()
                        .tint(DesignSystem.Colors.childAccent)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(DesignSystem.Colors.childAccent)
                }
                Text(isLoadingMore ? "Loading More..." : "Load More Tasks")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.childAccent)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.white)
            .cornerRadius(DesignSystem.CornerRadius.large)
        }
        .disabled(isLoadingMore)
    }
    
    private func taskSection(title: String, subtitle: String, tasks: [SupabaseTask]) -> some View {
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
                            Capsule()
                                .fill(colorForSection(title: title))
                        )
                }
                
                Text(subtitle)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                ForEach(tasks) { task in
                    FunChildTaskCard(
                        task: task,
                        isProcessing: processingTaskId == task.id,
                        onTap: {
                            selectedTask = task
                        },
                        onComplete: {
                            completeTask(task)
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

    private func colorForSection(title: String) -> Color {
        if title.contains("To Complete") {
            return DesignSystem.Colors.childAccent
        } else if title.contains("Pending") {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.success
        }
    }

    // MARK: - Data Logic
    private func loadTasks(refresh: Bool = false) async {
        if refresh {
            currentPage = 0
            hasMoreTasks = true
        }

        guard hasMoreTasks, !isLoadingMore else { return }

        if currentPage == 0 {
            isLoading = true
        } else {
            isLoadingMore = true
        }
        
        errorMessage = nil
        
        guard let profile = familyAuth.currentProfile else {
            errorMessage = "Could not load profile. Please try again."
            isLoading = false
            isLoadingMore = false
            return
        }

        do {
            if currentPage == 0 {
                totalTaskCount = try await dataRepository.getTaskCount(for: profile.id)
            }

            let newTasks = try await dataRepository.getTasks(for: profile.id, limit: pageSize, offset: currentPage * pageSize)
            
            if refresh {
                tasks = newTasks
            } else {
                tasks.append(contentsOf: newTasks)
            }

            hasMoreTasks = tasks.count < totalTaskCount
            currentPage += 1

        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            print("❌ Error loading tasks: \(error)")
        }
        
        isLoading = false
        isLoadingMore = false
    }

    private func loadMoreTasks() async {
        await loadTasks()
    }
    
    private func completeTask(_ task: SupabaseTask) {
        processingTaskId = task.id
        
        // Optimistic UI update
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].completedAt = Date()
            tasks[index].isApproved = false
        }
        
        Task {
            // Give UI time to update
            try? await Task.sleep(for: .seconds(0.5))
            
            do {
                _ = try await dataRepository.updateTask(tasks.first(where: { $0.id == task.id })!)
                print("✅ Task completion requested and updated in Supabase.")
            } catch {
                errorMessage = "Failed to submit task for approval. Please try again."
                print("❌ Error updating task completion status: \(error)")
                // Revert optimistic update on failure
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index].completedAt = nil
                }
            }
            
            await MainActor.run {
                processingTaskId = nil
                if selectedTask?.id == task.id {
                    selectedTask = nil
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var pendingTasks: [SupabaseTask] {
        tasks
            .filter { !$0.isCompleted }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }

    private var pendingApprovalTasks: [SupabaseTask] {
        tasks
            .filter { $0.isCompleted && !$0.isApproved }
            .sorted(by: { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) })
    }
    
    private var completedTasks: [SupabaseTask] {
        tasks
            .filter { $0.isCompleted && $0.isApproved }
            .sorted(by: { 
                ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
            })
    }
    
    private var completedTasksToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter { task in
            if let completedAt = task.completedAt {
                return Calendar.current.isDate(completedAt, inSameDayAs: today)
            }
            return false
        }.count
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
            .environmentObject(FamilyAuthService.shared)
    }
} 