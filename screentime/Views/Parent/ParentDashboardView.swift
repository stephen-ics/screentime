import SwiftUI

struct ParentDashboardView: View {
    // MARK: - Environment
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State
    @State private var linkedChildren: [User] = []
    @State private var pendingRequestsCount = 0
    @State private var selectedTab = 0
    @State private var showAddChild = false
    @State private var showAddTask = false
    @State private var showSettings = false
    @State private var showTimeRequests = false
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationView {
                dashboardTab
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }
            .tag(0)
            
            // Children Tab
            NavigationView {
                childrenTab
            }
            .tabItem {
                Label("Children", systemImage: "person.2")
            }
            .tag(1)
            
            // Tasks Tab
            NavigationView {
                TaskListView()
                    .navigationTitle("Tasks")
                    .navigationBarItems(trailing: addTaskButton)
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .tag(2)
            
            // Account Tab
            AccountView()
                .environmentObject(authService)
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
                .tag(3)
        }
        .sheet(isPresented: $showAddChild) {
            AddChildView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showTimeRequests) {
            NavigationView {
                TimeRequestsView()
                    .environmentObject(authService)
            }
        }
        .onAppear {
            loadLinkedChildren()
            updatePendingRequestsCount()
        }
        .onReceive(authService.objectWillChange) { _ in
            loadLinkedChildren()
            updatePendingRequestsCount()
        }
    }
    
    // MARK: - Dashboard Tab
    private var dashboardTab: some View {
        ZStack {
            DesignSystem.Colors.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xLarge) {
                    // Header
                    dashboardHeader
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.top, DesignSystem.Spacing.large)
                    
                    // Quick Actions
                    quickActionsSection
                        .padding(.horizontal, DesignSystem.Spacing.large)
                    
                    // Children Overview
                    if !linkedChildren.isEmpty {
                        childrenOverviewSection
                            .padding(.horizontal, DesignSystem.Spacing.large)
                    }
                    
                    // Recent Activity
                    recentActivitySection
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.bottom, DesignSystem.Spacing.xxLarge)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Dashboard Header
    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
            Text("Welcome back")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Text(authService.currentUser?.name ?? "Parent")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            if pendingRequestsCount > 0 {
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                    Text("\(pendingRequestsCount) pending requests")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.warning)
                }
                .padding(.top, DesignSystem.Spacing.xxSmall)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Quick Actions")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            HStack(spacing: DesignSystem.Spacing.medium) {
                QuickActionCard(
                    title: "Time Requests",
                    count: pendingRequestsCount,
                    icon: "hourglass.badge.plus",
                    color: DesignSystem.Colors.warning
                ) {
                    showTimeRequests = true
                }
                
                QuickActionCard(
                    title: "Add Child",
                    icon: "person.badge.plus",
                    color: DesignSystem.Colors.primaryBlue
                ) {
                    showAddChild = true
                }
            }
        }
    }
    
    // MARK: - Children Overview Section
    private var childrenOverviewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("Your Children")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button("See All") {
                    selectedTab = 1
                }
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.primaryBlue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.medium) {
                    ForEach(linkedChildren.prefix(3)) { child in
                        ChildOverviewCard(child: child)
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Recent Activity")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.small) {
                ActivityRow(
                    icon: "checkmark.circle.fill",
                    title: "Task Completed",
                    subtitle: "Math homework by Sarah",
                    time: "2 hours ago",
                    color: DesignSystem.Colors.success
                )
                
                ActivityRow(
                    icon: "hourglass",
                    title: "Time Request",
                    subtitle: "30 minutes requested by John",
                    time: "3 hours ago",
                    color: DesignSystem.Colors.warning
                )
                
                ActivityRow(
                    icon: "person.badge.plus",
                    title: "Child Added",
                    subtitle: "Emma linked to account",
                    time: "Yesterday",
                    color: DesignSystem.Colors.primaryBlue
                )
            }
        }
    }
    
    // MARK: - Children Tab
    private var childrenTab: some View {
        ZStack {
            DesignSystem.Colors.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                        Text("Children")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("\(linkedChildren.count) linked accounts")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.top, DesignSystem.Spacing.large)
                    
                    // Children List
                    if linkedChildren.isEmpty {
                        emptyChildrenView
                    } else {
                        LazyVStack(spacing: DesignSystem.Spacing.medium) {
                            ForEach(linkedChildren) { child in
                                NavigationLink(destination: ChildDetailView(child: child)) {
                                    ChildCard(child: child)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.large)
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.xxLarge)
            }
            .navigationBarHidden(true)
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddChild = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(DesignSystem.Colors.primaryBlue)
                                .clipShape(Circle())
                                .shadow(
                                    color: DesignSystem.Shadow.large.color,
                                    radius: DesignSystem.Shadow.large.radius,
                                    x: DesignSystem.Shadow.large.x,
                                    y: DesignSystem.Shadow.large.y
                                )
                        }
                        .padding(.trailing, DesignSystem.Spacing.large)
                        .padding(.bottom, DesignSystem.Spacing.large)
                    }
                }
            )
        }
    }
    
    // MARK: - Empty Children View
    private var emptyChildrenView: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            
            Text("No Children Linked")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("Add your children to start managing their screen time")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: { showAddChild = true }) {
                Text("Add First Child")
                    .frame(maxWidth: 200)
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: true))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxxLarge)
    }
    
    // MARK: - Methods
    private func loadLinkedChildren() {
        guard let parentEmail = authService.currentUser?.email else { return }
        linkedChildren = SharedDataManager.shared.getChildren(forParentEmail: parentEmail)
    }
    
    private func updatePendingRequestsCount() {
        guard let parentEmail = authService.currentUser?.email else { return }
        pendingRequestsCount = SharedDataManager.shared.getPendingRequests(forParentEmail: parentEmail).count
    }
    
    // MARK: - Views
    private var addTaskButton: some View {
        Button(action: { showAddTask = true }) {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    var count: Int? = nil
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if let count = count, count > 0 {
                        Text("\(count)")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color)
                            .clipShape(Capsule())
                    }
                }
                
                Text(title)
                    .font(DesignSystem.Typography.calloutBold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
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
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Child Overview Card
struct ChildOverviewCard: View {
    let child: User
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            // Avatar
            Circle()
                .fill(LinearGradient.childGradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(child.name.prefix(1))
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(.white)
                )
            
            Text(child.name)
                .font(DesignSystem.Typography.calloutBold)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
            
            if let balance = child.screenTimeBalance {
                Text(balance.formattedTimeRemaining)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(width: 100)
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(title)
                    .font(DesignSystem.Typography.calloutBold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Text(time)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

// MARK: - Child Card
struct ChildCard: View {
    let child: User
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Avatar
            Circle()
                .fill(LinearGradient.childGradient)
                .frame(width: 56, height: 56)
                .overlay(
                    Text(child.name.prefix(1))
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(.white)
                )
            
            // Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(child.name)
                    .font(DesignSystem.Typography.bodyBold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if let balance = child.screenTimeBalance {
                    HStack(spacing: DesignSystem.Spacing.xSmall) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 12))
                        Text(balance.formattedTimeRemaining)
                            .font(DesignSystem.Typography.caption1)
                    }
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    if balance.isTimerActive {
                        Label("Timer Active", systemImage: "play.circle.fill")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .shadow(
            color: DesignSystem.Shadow.small.color,
            radius: DesignSystem.Shadow.small.radius,
            x: DesignSystem.Shadow.small.x,
            y: DesignSystem.Shadow.small.y
        )
    }
}

// MARK: - Add Child View
struct AddChildView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authService: AuthenticationService
    
    // MARK: - State
    @State private var childEmail = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isLoading = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.groupedBackground
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.xxLarge) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.primaryBlue)
                        
                        Text("Link Child Account")
                            .font(DesignSystem.Typography.title1)
                        
                        Text("Enter your child's email to connect their account")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignSystem.Spacing.xxLarge)
                    
                    // Form
                    VStack(spacing: DesignSystem.Spacing.large) {
                        CustomTextField(
                            placeholder: "Child's Email",
                            text: $childEmail,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )
                        
                        Text("The child must have already created their account")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        Button(action: linkChild) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Link Account")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(PrimaryButtonStyle(isEnabled: !isLoading && !childEmail.isEmpty))
                        .disabled(isLoading || childEmail.isEmpty)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.bottom, DesignSystem.Spacing.large)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Child account linked successfully!")
            }
        }
    }
    
    // MARK: - Actions
    private func linkChild() {
        guard let parentUser = authService.currentUser,
              let parentEmail = parentUser.email else {
            errorMessage = "Parent email not found"
            showError = true
            return
        }
        
        isLoading = true
        
        // Refresh user cache to ensure we have the latest users
        SharedDataManager.shared.refreshUserCache()
        
        // Check if child exists
        guard let childUser = SharedDataManager.shared.findUser(byEmail: childEmail) else {
            errorMessage = "No child account found with this email. The child must create an account first."
            showError = true
            isLoading = false
            return
        }
        
        // Check if it's actually a child account
        guard !childUser.isParent else {
            errorMessage = "This email belongs to a parent account, not a child account."
            showError = true
            isLoading = false
            return
        }
        
        // Link the child to parent
        if SharedDataManager.shared.linkChildToParent(childEmail: childEmail, parentEmail: parentEmail) {
            showSuccess = true
        } else {
            errorMessage = "Failed to link child account"
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Preview
struct ParentDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ParentDashboardView()
            .environmentObject(AuthenticationService.shared)
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
} 