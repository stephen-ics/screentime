import SwiftUI

// MARK: - ChildDashboardViewModel
@MainActor
final class ChildDashboardViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var tasks: [SupabaseTask] = []
    @Published var completedTasksToday: Int = 0
    @Published var screenTimeBalance: SupabaseScreenTimeBalance?
    @Published var recentActivities: [ActivityItem] = []
    @Published var currentStreak: Int = 0
    @Published var errorMessage: String?
    @Published var showingTimeRequest = false
    @Published var showingTimeAllocation = false
    
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
        // Add earned time to balance
        if let balance = screenTimeBalance {
            screenTimeBalance = SupabaseScreenTimeBalance(
                id: balance.id,
                userId: balance.userId,
                availableSeconds: balance.availableSeconds + task.rewardSeconds,
                dailyLimitSeconds: balance.dailyLimitSeconds,
                weeklyLimitSeconds: balance.weeklyLimitSeconds,
                lastUpdated: Date(),
                isTimerActive: balance.isTimerActive,
                lastTimerStart: balance.lastTimerStart,
                createdAt: balance.createdAt,
                updatedAt: Date()
            )
        }
        
        // Mark task as completed and add to completed count
        completedTasksToday += 1
        
        // Add to recent activities
        let activity = ActivityItem(
            type: .taskCompleted,
            title: "Task Completed",
            subtitle: "Completed task: \(task.title)",
            timestamp: Date(),
            associatedUser: nil
        )
        recentActivities.insert(activity, at: 0)
    }
    
    func requestMoreTime(duration: Int, reason: String) {
        // Handle time request
        let activity = ActivityItem(
            type: .timeRequested,
            title: "Time Requested",
            subtitle: "Requested \(duration) more minutes",
            timestamp: Date(),
            associatedUser: nil
        )
        recentActivities.insert(activity, at: 0)
    }
    
    func unlockScreenTime(minutes: Int) {
        // Deduct the unlocked time from available balance
        if let balance = screenTimeBalance {
            let unlockedSeconds = Double(minutes * 60)
            let newAvailableSeconds = max(0, balance.availableSeconds - unlockedSeconds)
            
            screenTimeBalance = SupabaseScreenTimeBalance(
                id: balance.id,
                userId: balance.userId,
                availableSeconds: newAvailableSeconds,
                dailyLimitSeconds: balance.dailyLimitSeconds,
                weeklyLimitSeconds: balance.weeklyLimitSeconds,
                lastUpdated: Date(),
                isTimerActive: true, // Start the timer
                lastTimerStart: Date(),
                createdAt: balance.createdAt,
                updatedAt: Date()
            )
            
            // Add to recent activities
            let activity = ActivityItem(
                type: .timeApproved,
                title: "Screen Time Unlocked",
                subtitle: "Unlocked \(minutes) minutes of screen time",
                timestamp: Date(),
                associatedUser: nil
            )
            recentActivities.insert(activity, at: 0)
            
            print("✅ Unlocked \(minutes) minutes of screen time!")
        }
    }
    
    private func loadMockData() {
        // Mock tasks - only pending ones for motivation
        tasks = [
            SupabaseTask(
                title: "🧹 Clean Your Room",
                taskDescription: "Make bed, organize toys, and put clothes away",
                rewardSeconds: 900 // 15 minutes
            ),
            SupabaseTask(
                title: "📚 Homework - Math", 
                taskDescription: "Complete pages 45-47 in math workbook",
                rewardSeconds: 1800 // 30 minutes
            )
        ]
        
        // Mock screen time balance
        screenTimeBalance = SupabaseScreenTimeBalance(
            userId: UUID(),
            availableSeconds: 3600, // 1 hour available
            dailyLimitSeconds: 7200 // 2 hours daily limit
        )
        
        // Mock completed tasks today
        completedTasksToday = 1
        
        // Mock current streak
        currentStreak = 3
        
        // Mock recent activities
        recentActivities = [
            ActivityItem(
                type: .taskCompleted,
                title: "Task Completed",
                subtitle: "Completed task: Feed the Dog (+10 min)",
                timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
                associatedUser: nil
            ),
            ActivityItem(
                type: .timeApproved,
                title: "Time Request Approved",
                subtitle: "Got 30 more minutes from Mom",
                timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
                associatedUser: nil
            )
        ]
    }
}

struct ChildDashboardView: View {
    @StateObject private var viewModel = ChildDashboardViewModel()
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @Binding var selectedTab: Int
    @State private var selectedPage = 0
    
    init(selectedTab: Binding<Int> = .constant(0)) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Content area
                Group {
                    switch selectedPage {
                    case 0:
                        homePageContent
                    case 1:
                        tasksPageContent
                    case 2:
                        statsPageContent
                    default:
                        homePageContent
                    }
                }
                
                // Bottom navigation bar
                bottomNavigationBar
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
            .navigationTitle("🎮 My Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    profileSwitchButton
                }
            }
            .sheet(isPresented: $viewModel.showingTimeRequest) {
                TimeRequestView()
            }
            .sheet(isPresented: $viewModel.showingTimeAllocation) {
                TimeAllocationView(
                    availableMinutes: Int((viewModel.screenTimeBalance?.availableSeconds ?? 0) / 60),
                    onTimeUnlocked: { unlockedMinutes in
                        viewModel.unlockScreenTime(minutes: unlockedMinutes)
                    }
                )
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Profile Switch Button
    private var profileSwitchButton: some View {
        Button(action: {
            Task {
                try? await familyAuth.switchToProfileSelectionWithSecurity()
            }
        }) {
            if let currentProfile = familyAuth.currentProfile {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 28, height: 28)
                        
                        Text(String(currentProfile.name.prefix(1)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    // MARK: - Home Page Content
    private var homePageContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.large) {
                // Fun Header with greeting and streak
                funHeaderSection
                
                // Big Fun Time Display
                timeDisplayHero
                
                // Primary Action Buttons
                primaryActionButtons
            }
            .padding(DesignSystem.Spacing.medium)
            .refreshable {
                await viewModel.refreshData()
            }
        }
    }
    
    // MARK: - Tasks Page Content
    private var tasksPageContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.large) {
                // Tasks header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    HStack {
                        Text("⭐ My Tasks")
                            .font(DesignSystem.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Text("\(viewModel.completedTasksToday) done today! 🎉")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.success)
                            .padding(.horizontal, DesignSystem.Spacing.small)
                            .padding(.vertical, DesignSystem.Spacing.xxSmall)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                    .fill(DesignSystem.Colors.success.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                
                // Tasks list
                if viewModel.tasks.isEmpty {
                    emptyTasksView
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                } else {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        ForEach(viewModel.tasks, id: \.id) { task in
                            FunTaskCard(task: task)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.medium)
        }
    }
    
    // MARK: - Stats Page Content
    private var statsPageContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.large) {
                // Stats header
                Text("📊 My Stats")
                    .font(DesignSystem.Typography.title1)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                
                // Fun stats cards
                VStack(spacing: DesignSystem.Spacing.medium) {
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        FunStatCard(
                            emoji: "🔥",
                            title: "Streak",
                            value: "\(viewModel.currentStreak) days",
                            color: DesignSystem.Colors.warning
                        )
                        
                        FunStatCard(
                            emoji: "⭐",
                            title: "Tasks Done",
                            value: "\(viewModel.completedTasksToday) today",
                            color: DesignSystem.Colors.success
                        )
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        FunStatCard(
                            emoji: "⏰",
                            title: "Time Earned",
                            value: formatTime(viewModel.screenTimeBalance?.availableSeconds ?? 0),
                            color: DesignSystem.Colors.childAccent
                        )
                        
                        FunStatCard(
                            emoji: "🎯",
                            title: "Daily Goal",
                            value: formatTime(viewModel.screenTimeBalance?.dailyLimitSeconds ?? 0),
                            color: DesignSystem.Colors.info
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                
                // Progress visualization
                funProgressSection
                    .padding(.horizontal, DesignSystem.Spacing.medium)
            }
            .padding(.vertical, DesignSystem.Spacing.medium)
        }
    }
    
    // MARK: - Bottom Navigation Bar
    private var bottomNavigationBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                // Home tab
                BottomNavButton(
                    emoji: "🏠",
                    title: "Home",
                    isSelected: selectedPage == 0
                ) {
                    selectedPage = 0
                }
                
                Spacer()
                
                // Tasks tab
                BottomNavButton(
                    emoji: "⭐",
                    title: "Tasks",
                    isSelected: selectedPage == 1
                ) {
                    selectedPage = 1
                }
                
                Spacer()
                
                // Stats tab
                BottomNavButton(
                    emoji: "📊",
                    title: "Stats",
                    isSelected: selectedPage == 2
                ) {
                    selectedPage = 2
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.background)
        }
    }
    
    // MARK: - Fun Header Section
    private var funHeaderSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("Hey \(familyAuth.currentProfile?.name ?? "Champion")! 👋")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Ready to earn some fun time?")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Fun streak counter with emoji
            VStack(spacing: DesignSystem.Spacing.xxSmall) {
                Text("🔥")
                    .font(.system(size: 24))
                
                Text("\(viewModel.currentStreak)")
                    .font(DesignSystem.Typography.monospacedDigit)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.childAccent)
                
                Text("Day Streak!")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.childAccent.opacity(0.2),
                                DesignSystem.Colors.childAccent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
    }
    
    // MARK: - Big Fun Time Display
    private var timeDisplayHero: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Big time display with fun elements
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("⏰")
                    .font(.system(size: 48))
                
                Text("Your Fun Time")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(formatTime(viewModel.screenTimeBalance?.availableSeconds ?? 0))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.childAccent)
                    .contentTransition(.numericText())
                
                Text("ready to use! 🚀")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Fun progress bar
            VStack(spacing: DesignSystem.Spacing.small) {
                funProgressBar
                
                HStack {
                    VStack(spacing: 2) {
                        Text("📱")
                        Text("Used")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("🎯")
                        Text("Available")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("⚡")
                        Text("Daily Max")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.xxLarge)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                .fill(
                    LinearGradient(
                        colors: [
                            .white,
                            DesignSystem.Colors.childAccent.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                .stroke(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.childAccent.opacity(0.3),
                            DesignSystem.Colors.childAccent.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(
            color: DesignSystem.Colors.childAccent.opacity(0.2),
            radius: 20,
            x: 0,
            y: 8
        )
    }
    
    // MARK: - Primary Action Buttons
    private var primaryActionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Allocate Time Button
            Button(action: {
                viewModel.showingTimeAllocation = true
            }) {
                HStack(spacing: DesignSystem.Spacing.buttonIconSpacing) {
                    Text("🎮")
                        .font(.system(size: 20))
                    
                    Text("Unlock My Time!")
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
            
            HStack(spacing: DesignSystem.Spacing.medium) {
                // View Tasks Button (FIXED NAVIGATION)
                Button(action: {
                    selectedPage = 1 // Navigate to Tasks page within dashboard
                }) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Text("⭐")
                            .font(.system(size: 16))
                        
                        Text("My Tasks")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(DesignSystem.Colors.childAccent)
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(DesignSystem.Colors.childAccent.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.childAccent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(FunScaleButtonStyle())
                
                // Request More Time Button  
                Button(action: {
                    viewModel.showingTimeRequest = true
                }) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Text("🙏")
                            .font(.system(size: 16))
                        
                        Text("Ask for More")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(DesignSystem.Colors.warning)
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(DesignSystem.Colors.warning.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(FunScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Views and Methods
    private var funProgressBar: some View {
        let totalTime = viewModel.screenTimeBalance?.dailyLimitSeconds ?? 0
        let availableTime = viewModel.screenTimeBalance?.availableSeconds ?? 0
        let usedTime = totalTime - availableTime
        let progress = totalTime > 0 ? min(usedTime / totalTime, 1.0) : 0
        
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.separator.opacity(0.3))
                    .frame(height: 12)
                
                // Progress
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.childAccent,
                                DesignSystem.Colors.childAccent.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geometry.size.width * progress), height: 12)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 12)
    }
    
    private var emptyTasksView: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Text("🌟")
                .font(.system(size: 40))
            
            Text("All caught up!")
                .font(DesignSystem.Typography.bodyBold)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("Awesome job! New tasks might appear later.")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.large)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.success.opacity(0.1),
                    DesignSystem.Colors.success.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignSystem.CornerRadius.large)
    }
    
    private var funProgressSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("📈 Progress Today")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.large) {
                timeProgressView
                taskProgressView
            }
        }
        .funCardStyle()
    }
    
    private var timeProgressView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text("Screen Time Usage")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text(timeUsageText)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.childAccent)
            }
            
            funProgressBar
        }
    }
    
    private var taskProgressView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text("Tasks Completed")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text("\(viewModel.completedTasksToday) / \(viewModel.tasks.count)")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.success)
            }
            
            taskProgressBar
        }
    }
    
    private var taskProgressBar: some View {
        let taskProgress = viewModel.tasks.count > 0 ? Double(viewModel.completedTasksToday) / Double(viewModel.tasks.count) : 0
        
        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.separator.opacity(0.3))
                    .frame(height: 12)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.success,
                                DesignSystem.Colors.success.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geometry.size.width * taskProgress), height: 12)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: taskProgress)
            }
        }
        .frame(height: 12)
    }
    
    private var timeUsageText: String {
        let dailyLimitSeconds = viewModel.screenTimeBalance?.dailyLimitSeconds ?? 0
        let availableSeconds = viewModel.screenTimeBalance?.availableSeconds ?? 0
        let usedSeconds = dailyLimitSeconds - availableSeconds
        
        let usedMinutes = Int(usedSeconds / 60)
        let totalMinutes = Int(dailyLimitSeconds / 60)
        
        return "\(usedMinutes)m / \(totalMinutes)m"
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views

struct BottomNavButton: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xSmall) {
                Text(emoji)
                    .font(.system(size: isSelected ? 24 : 20))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                
                Text(title)
                    .font(isSelected ? DesignSystem.Typography.caption1 : DesignSystem.Typography.caption2)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? DesignSystem.Colors.childAccent : DesignSystem.Colors.secondaryText)
            }
            .padding(.vertical, DesignSystem.Spacing.xSmall)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? DesignSystem.Colors.childAccent.opacity(0.1) : Color.clear)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FunStatCard: View {
    let emoji: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Text(emoji)
                .font(.system(size: 32))
            
            VStack(spacing: DesignSystem.Spacing.xSmall) {
                Text(value)
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.cardPadding)
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

struct FunTaskCard: View {
    let task: SupabaseTask
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Fun emoji based on task type
            Text(getTaskEmoji(task.title))
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(DesignSystem.Typography.calloutBold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                
                if let description = task.taskDescription {
                    Text(description)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Reward with fun styling
            HStack(spacing: DesignSystem.Spacing.xxSmall) {
                Text("⚡")
                    .font(.system(size: 12))
                
                Text("+\(Int(task.rewardSeconds / 60))m")
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
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(
            color: DesignSystem.Shadow.small.color,
            radius: DesignSystem.Shadow.small.radius,
            x: DesignSystem.Shadow.small.x,
            y: DesignSystem.Shadow.small.y
        )
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

// MARK: - Fun Button Style
struct FunScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Fun Card Style Extension
extension View {
    func funCardStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(.white)
            )
            .shadow(
                color: DesignSystem.Shadow.card.color.opacity(0.1),
                radius: DesignSystem.Shadow.card.radius,
                x: DesignSystem.Shadow.card.x,
                y: DesignSystem.Shadow.card.y
            )
    }
}

// MARK: - Preview
struct ChildDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ChildDashboardView()
            .environmentObject(FamilyAuthService.shared)
    }
} 