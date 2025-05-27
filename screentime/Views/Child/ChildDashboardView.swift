import SwiftUI

struct ChildDashboardView: View {
    // MARK: - Environment
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)],
        predicate: NSPredicate(format: "completedAt == nil")
    ) private var tasks: FetchedResults<Task>
    
    @State private var selectedTab = 0
    @State private var showRequestTime = false
    @State private var requestedMinutes: Int32 = 30
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animateTimer = false
    
    // MARK: - Computed Properties
    private var screenTimeBalance: ScreenTimeBalance? {
        authService.currentUser?.screenTimeBalance
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Screen Time Tab
            NavigationView {
                screenTimeTab
            }
            .tabItem {
                Label("Screen Time", systemImage: "hourglass")
            }
            .tag(0)
            
            // Tasks Tab
            NavigationView {
                tasksTab
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .tag(1)
            
            // Account Tab
            AccountView()
                .environmentObject(authService)
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
                .tag(2)
        }
        .sheet(isPresented: $showRequestTime) {
            RequestTimeView(minutes: $requestedMinutes) {
                requestMoreTime()
            }
        }
        .alert("Notice", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Screen Time Tab
    private var screenTimeTab: some View {
        ZStack {
            // Background gradient
            LinearGradient.childGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xLarge) {
                    // Header
                    headerSection
                        .padding(.top, DesignSystem.Spacing.xLarge)
                    
                    // Time Circle
                    timeCircleSection
                        .padding(.top, DesignSystem.Spacing.medium)
                    
                    // Quick Stats
                    quickStatsSection
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.top, DesignSystem.Spacing.medium)
                    
                    // Request More Time Button
                    requestTimeButton
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.top, DesignSystem.Spacing.large)
                        .padding(.bottom, DesignSystem.Spacing.xxxLarge)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
            Text(greeting)
                .font(DesignSystem.Typography.title3)
                .foregroundColor(.white.opacity(0.85))
            
            Text(authService.currentUser?.name ?? "Friend")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignSystem.Spacing.large)
    }
    
    // MARK: - Time Circle Section
    private var timeCircleSection: some View {
        VStack(spacing: 0) {
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: DesignSystem.Layout.circleTimerSize + 40, 
                           height: DesignSystem.Layout.circleTimerSize + 40)
                    .blur(radius: 20)
                
                // Background circle track
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 24)
                    .frame(width: DesignSystem.Layout.circleTimerSize, 
                           height: DesignSystem.Layout.circleTimerSize)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: timeProgress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.85),
                                Color.white.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: 24,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: DesignSystem.Layout.circleTimerSize, 
                           height: DesignSystem.Layout.circleTimerSize)
                    .rotationEffect(.degrees(-90))
                    .animation(DesignSystem.Animation.springSmooth, value: timeProgress)
                
                // Center content
                VStack(spacing: DesignSystem.Spacing.xSmall) {
                    if let balance = screenTimeBalance {
                        // Time display
                        Text(formatTime(balance.availableMinutes))
                            .font(DesignSystem.Typography.monospacedXLarge)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Text("remaining")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(.white.opacity(0.75))
                        
                        // Timer status
                        if balance.isTimerActive {
                            HStack(spacing: DesignSystem.Spacing.xxSmall) {
                                Circle()
                                    .fill(Color(hex: "32D74B"))
                                    .frame(width: 10, height: 10)
                                    .scaleEffect(animateTimer ? 1.3 : 1.0)
                                    .animation(
                                        DesignSystem.Animation.easeInOut
                                            .repeatForever(autoreverses: true),
                                        value: animateTimer
                                    )
                                
                                Text("Active")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            .padding(.top, DesignSystem.Spacing.xxSmall)
                            .onAppear { animateTimer = true }
                        }
                    } else {
                        VStack(spacing: DesignSystem.Spacing.xSmall) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("No Limit Set")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .frame(width: DesignSystem.Layout.circleTimerSize - 80)
            }
        }
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            StatCard(
                title: "Used Today",
                value: dailyUsedTime,
                icon: "clock.fill",
                color: DesignSystem.Colors.warning
            )
            
            StatCard(
                title: "Tasks Done",
                value: "\(completedTasksToday)",
                icon: "checkmark.circle.fill",
                color: DesignSystem.Colors.success
            )
        }
    }
    
    // MARK: - Request Time Button
    private var requestTimeButton: some View {
        Button(action: { showRequestTime = true }) {
            HStack(spacing: DesignSystem.Spacing.buttonIconSpacing) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: DesignSystem.Layout.buttonIconSize, weight: .medium))
                Text("Request More Time")
                    .font(DesignSystem.Typography.bodyBold)
            }
            .foregroundColor(DesignSystem.Colors.childAccent)
            .padding(.horizontal, DesignSystem.Spacing.buttonHorizontalPadding)
            .padding(.vertical, DesignSystem.Spacing.buttonVerticalPadding)
            .frame(maxWidth: .infinity)
            .frame(minHeight: DesignSystem.Layout.minButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(Color.white)
            )
            .shadow(
                color: DesignSystem.Shadow.medium.color,
                radius: DesignSystem.Shadow.medium.radius,
                x: DesignSystem.Shadow.medium.x,
                y: DesignSystem.Shadow.medium.y
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Tasks Tab
    private var tasksTab: some View {
        ZStack {
            DesignSystem.Colors.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Tasks Header
                    tasksHeader
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.top, DesignSystem.Spacing.xLarge)
                    
                    // Tasks List
                    if tasks.isEmpty {
                        emptyTasksView
                            .padding(.top, DesignSystem.Spacing.xxxLarge)
                    } else {
                        LazyVStack(spacing: DesignSystem.Spacing.listItemSpacing) {
                            ForEach(tasks) { task in
                                TaskCard(task: task)
                                    .padding(.horizontal, DesignSystem.Spacing.large)
                            }
                        }
                        .padding(.top, DesignSystem.Spacing.medium)
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.xxxLarge)
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Tasks Header
    private var tasksHeader: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
            Text("Your Tasks")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(tasks.isEmpty ? "All caught up!" : "\(tasks.count) task\(tasks.count == 1 ? "" : "s") to complete")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Empty Tasks View
    private var emptyTasksView: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.success.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.success)
            }
            
            VStack(spacing: DesignSystem.Spacing.xSmall) {
                Text("All Done!")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("You've completed all your tasks")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Properties
    private var timeProgress: CGFloat {
        guard let balance = screenTimeBalance, balance.dailyLimit > 0 else { return 0 }
        return CGFloat(balance.availableMinutes) / CGFloat(balance.dailyLimit)
    }
    
    private var dailyUsedTime: String {
        guard let balance = screenTimeBalance else { return "0m" }
        let used = max(0, balance.dailyLimit - balance.availableMinutes)
        return formatTime(used)
    }
    
    private var completedTasksToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let request = Task.fetchRequest()
        request.predicate = NSPredicate(
            format: "completedAt >= %@ AND isApproved == true",
            today as NSDate
        )
        
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ minutes: Int32) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
    
    // MARK: - Actions
    private func requestMoreTime() {
        guard let user = authService.currentUser,
              let email = user.email else { return }
        
        if SharedDataManager.shared.requestMoreTime(fromChildEmail: email, minutes: requestedMinutes) != nil {
            showRequestTime = false
            errorMessage = "Time request sent to your parent!"
            showError = true
        } else {
            errorMessage = "Failed to send time request. Make sure you're linked to a parent account."
            showError = true
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
}

// MARK: - Task Card Component
struct TaskCard: View {
    @ObservedObject var task: Task
    @State private var isCompleting = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Task indicator
            RoundedRectangle(cornerRadius: DesignSystem.Metrics.indicatorSize / 2)
                .fill(DesignSystem.Colors.childAccent)
                .frame(width: DesignSystem.Metrics.indicatorSize)
            
            // Task content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(task.title)
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                HStack(spacing: DesignSystem.Spacing.xxSmall) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 12))
                    Text("\(task.rewardMinutes) min")
                        .font(DesignSystem.Typography.caption2)
                }
                .foregroundColor(DesignSystem.Colors.success)
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Complete button
            Button(action: completeTask) {
                ZStack {
                    if isCompleting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 28, height: 28)
                    } else if task.completedAt != nil {
                        Image(systemName: task.isApproved ? "checkmark.circle.fill" : "clock.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(task.isApproved ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
            .disabled(isCompleting || task.completedAt != nil)
            .buttonStyle(ScaleButtonStyle(scale: 0.9))
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .shadow(
            color: DesignSystem.Shadow.small.color,
            radius: DesignSystem.Shadow.small.radius,
            x: DesignSystem.Shadow.small.x,
            y: DesignSystem.Shadow.small.y
        )
    }
    
    private func completeTask() {
        isCompleting = true
        
        withAnimation(DesignSystem.Animation.springBounce) {
            task.completedAt = Date()
            task.updatedAt = Date()
        }
        
        do {
            try CoreDataManager.shared.save()
            
            _Concurrency.Task {
                do {
                    try await NotificationService.shared.scheduleTaskCompletionNotification(task: task)
                } catch {
                    print("Failed to schedule notification: \(error)")
                }
            }
        } catch {
            print("Failed to mark task complete: \(error)")
        }
        
        isCompleting = false
    }
}

// MARK: - Request Time View
struct RequestTimeView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var minutes: Int32
    let onRequest: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: DesignSystem.Spacing.medium) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.childAccent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "hourglass.badge.plus")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.childAccent)
                    }
                    
                    VStack(spacing: DesignSystem.Spacing.xSmall) {
                        Text("Request More Time")
                            .font(DesignSystem.Typography.title1)
                        
                        Text("Ask your parent for additional screen time")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                    }
                }
                .padding(.top, DesignSystem.Spacing.xxxLarge)
                
                // Time selector
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Time display
                    HStack(alignment: .bottom, spacing: DesignSystem.Spacing.xxSmall) {
                        Text("\(minutes)")
                            .font(DesignSystem.Typography.monospacedLarge)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("minutes")
                            .font(DesignSystem.Typography.title3)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .padding(.bottom, 6)
                    }
                    
                    // Quick select buttons
                    HStack(spacing: DesignSystem.Spacing.small) {
                        ForEach([15, 30, 45, 60], id: \.self) { time in
                            Button(action: { 
                                withAnimation(DesignSystem.Animation.quick) {
                                    minutes = Int32(time)
                                }
                            }) {
                                Text("\(time)m")
                            }
                            .buttonStyle(CompactButtonStyle(
                                color: minutes == time ? .white : DesignSystem.Colors.primaryText
                            ))
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                    .fill(minutes == time ? DesignSystem.Colors.childAccent : Color.clear)
                            )
                        }
                    }
                    
                    // Custom stepper
                    HStack(spacing: DesignSystem.Spacing.large) {
                        Button(action: {
                            if minutes > 15 {
                                withAnimation(DesignSystem.Animation.quick) {
                                    minutes -= 15
                                }
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(minutes > 15 ? DesignSystem.Colors.childAccent : DesignSystem.Colors.tertiaryText)
                        }
                        .disabled(minutes <= 15)
                        
                        Spacer()
                        
                        Button(action: {
                            if minutes < 120 {
                                withAnimation(DesignSystem.Animation.quick) {
                                    minutes += 15
                                }
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(minutes < 120 ? DesignSystem.Colors.childAccent : DesignSystem.Colors.tertiaryText)
                        }
                        .disabled(minutes >= 120)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                }
                .padding(DesignSystem.Spacing.xLarge)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.large)
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.top, DesignSystem.Spacing.xLarge)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Button(action: {
                        onRequest()
                        dismiss()
                    }) {
                        Text("Send Request")
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: true))
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(TextButtonStyle(color: DesignSystem.Colors.secondaryText))
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.bottom, DesignSystem.Spacing.xLarge)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Preview
struct ChildDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ChildDashboardView()
            .environmentObject(AuthenticationService.shared)
    }
} 