import SwiftUI
import Combine
import _Concurrency

/// Main parent dashboard view with proper MVVM architecture and dependency injection
struct ParentDashboardView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var authService: SafeSupabaseAuthService
    @EnvironmentObject private var dataRepository: SafeSupabaseDataRepository
    @EnvironmentObject private var router: AppRouter
    
    // MARK: - State
    @StateObject private var viewModel: ParentDashboardViewModel
    
    // MARK: - Initialization
    
    init() {
        // We'll initialize with placeholder router and update it in onAppear
        self._viewModel = StateObject(wrappedValue: ParentDashboardViewModel(
            authService: SafeSupabaseAuthService.shared,
            dataRepository: SupabaseDataRepository.shared,
            router: AppRouter() // This will be replaced with the environment router
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $router.path) {
            DashboardTabView(viewModel: viewModel)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destinationView(for: destination)
                }
        }
        .onAppear {
            // Update the view model to use the environment router
            viewModel.updateRouter(router)
        }
        .sheet(item: $router.presentedSheet) { destination in
            sheetView(for: destination)
        }
        .fullScreenCover(item: $router.presentedFullScreen) { destination in
            modalView(for: destination)
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .childDetail(let child):
            ChildDetailView(child: child)
        case .taskDetail(let task):
            Text("Task Detail: \(task.title)")
        case .timeRequests:
            TimeRequestsView()
        case .analytics:
            AnalyticsView()
        case .tasks:
            TaskListView()
        case .settings:
            SettingsView()
        case .account:
            AccountView()
        case .addTask:
            AddTaskView()
        case .editChild(let child):
            // Placeholder for missing EditChildView
            Text("Edit Child: \(child.name)")
        case .reports:
            AnalyticsView()
        case .approvedApps:
            ApprovedAppsView(child: Profile.mockChild)
        }
    }
    
    @ViewBuilder
    private func sheetView(for destination: SheetDestination) -> some View {
        switch destination {
        case .addChild:
            AddChildView()
        case .addTask:
            AddTaskView()
        case .timeRequests:
            TimeRequestsView()
        case .settings:
            SettingsView()
        case .account:
            AccountView()
        case .editProfile:
            EditProfileView()
        case .changePassword:
            Text("Change Password - Coming Soon")
        case .addApprovedApp:
            ApprovedAppsView(child: Profile.mockChild)
        case .supabaseSetup:
            Text("Supabase Setup - Coming Soon")
        }
    }
    
    @ViewBuilder
    private func modalView(for destination: FullScreenDestination) -> some View {
        switch destination {
        case .authentication:
            AuthenticationView()
        case .onboarding:
            Text("Onboarding - Coming Soon")
        case .parentalControls:
            Text("Parental Controls - Coming Soon")
        case .migrationComplete:
            Text("Migration Complete!")
        }
    }
}

// Alternative initialization approach
struct ParentDashboardView_Alternative: View {
    
    // MARK: - Dependencies
    private let userService: any UserServiceProtocol
    private let dataRepository: DataRepositoryProtocol
    
    // MARK: - State
    @StateObject private var router = AppRouter()
    
    // MARK: - Initialization
    
    init(
        userService: any UserServiceProtocol = UserService(),
        dataRepository: DataRepositoryProtocol = DataRepository()
    ) {
        self.userService = userService
        self.dataRepository = dataRepository
    }
    
    // MARK: - Body
    
    var body: some View {
        DashboardContainer(
            userService: userService,
            dataRepository: dataRepository,
            router: router
        )
        .environmentObject(router)
    }
}

// MARK: - Dashboard Container

/// Container view that creates the view model with proper router reference
struct DashboardContainer: View {
    let userService: any UserServiceProtocol
    let dataRepository: DataRepositoryProtocol
    let router: AppRouter
    
    var body: some View {
        DashboardTabView(
            viewModel: ParentDashboardViewModel(
                authService: SafeSupabaseAuthService.shared,
                dataRepository: SupabaseDataRepository.shared,
                router: router
            )
        )
        .onAppear {
            // Load data when the view appears
        }
    }
}

// MARK: - Dashboard Tab View

/// Tab view coordinator that manages navigation between different dashboard sections
struct DashboardTabView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: ParentDashboardViewModel
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: Binding(
            get: { viewModel.state.selectedTab },
            set: { viewModel.selectTab($0) }
        )) {
            ForEach(DashboardTab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem { tabItem(for: tab) }
                    .tag(tab)
            }
        }
        .onAppear {
            print("🔘 TAB DEBUG: DashboardTabView appeared")
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private func tabContent(for tab: DashboardTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardContentView(viewModel: viewModel)
                .navigationBarHidden(true)
            
        case .children:
            ChildrenListView(viewModel: viewModel)
                .navigationTitle("Children")
            
        case .tasks:
            TaskListView()
                .navigationTitle("Tasks")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        addTaskButton
                    }
                }
            
        case .account:
            AccountView()
                .navigationTitle("Account")
        }
    }
    
    @ViewBuilder
    private func tabItem(for tab: DashboardTab) -> some View {
        Label(tab.title, systemImage: tab.icon)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var addTaskButton: some View {
        Button(action: { viewModel.selectTab(.tasks) }) {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Children List View

/// Optimized children list view with proper state management
struct ChildrenListView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: ParentDashboardViewModel
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.groupedBackground
                .ignoresSafeArea()
            
            if viewModel.state.isLoadingChildren {
                loadingState
            } else if viewModel.state.linkedChildren.isEmpty {
                emptyState
            } else {
                childrenList
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addChildButton
                        .padding(.trailing, DesignSystem.Spacing.large)
                        .padding(.bottom, DesignSystem.Spacing.large)
                }
            }
        )
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var loadingState: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primaryBlue))
            
            Text("Loading children...")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        EmptyChildrenView {
            viewModel.addChild()
        }
    }
    
    @ViewBuilder
    private var childrenList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.medium) {
                // Header
                childrenHeader
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.top, DesignSystem.Spacing.large)
                
                // Children Cards
                ForEach(viewModel.state.linkedChildren) { child in
                    ModernChildCard(profile: child) {
                        viewModel.viewChildDetail(child)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.small)
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xxLarge)
        }
    }
    
    @ViewBuilder
    private var childrenHeader: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
            Text("Children")
                .font(DesignSystem.Typography.title1)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text("\(viewModel.state.linkedChildren.count) linked accounts")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var addChildButton: some View {
        Button(action: { viewModel.addChild() }) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 56, height: 56)
        .background(DesignSystem.Colors.primaryBlue)
        .clipShape(Circle())
        .shadow(
            color: DesignSystem.Colors.primaryBlue.opacity(0.3),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Modern Child Card

/// Modern child card component with improved design
struct ModernChildCard: View {
    let profile: Profile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Avatar
                Circle()
                    .fill(avatarGradient)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(childInitials)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                // Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    Text(profile.name)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    // Placeholder for screen time info
                    Text("Screen time data not available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                VStack(spacing: DesignSystem.Spacing.xSmall) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var childInitials: String {
        let components = profile.name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1))
        } else {
            return String(profile.name.prefix(2))
        }
    }
    
    private var avatarGradient: LinearGradient {
        let hash = profile.name.hashValue
        let colors = [
            (DesignSystem.Colors.primaryBlue, DesignSystem.Colors.primaryIndigo),
            (DesignSystem.Colors.success, DesignSystem.Colors.warning),
            (DesignSystem.Colors.warning, DesignSystem.Colors.error),
        ]
        let colorPair = colors[abs(hash) % colors.count]
        return LinearGradient(
            colors: [colorPair.0, colorPair.1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Empty Children View

/// Modern empty state for when no children are linked
struct EmptyChildrenView: View {
    let onAddChildTapped: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "person.2.slash")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                
                Text("No Children Linked")
                    .font(DesignSystem.Typography.title1)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Add your children to start managing their screen time")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddChildTapped) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .medium))
                    Text("Add First Child")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: true))
            .frame(maxWidth: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxxLarge)
    }
}

// MARK: - Modern Add Child View

/// Modern add child view with improved UX
struct ModernAddChildView: View {
    @State private var childEmail = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.groupedBackground
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xxLarge) {
                // Header
                headerSection
                
                // Form
                formSection
                
                Spacer()
                
                // Actions
                actionSection
            }
            .padding(DesignSystem.Spacing.large)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
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
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.primaryBlue)
            
            Text("Link Child Account")
                .font(DesignSystem.Typography.title1)
                .fontWeight(.bold)
            
            Text("Enter your child's email to connect their account")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var formSection: some View {
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
    }
    
    @ViewBuilder
    private var actionSection: some View {
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
            .buttonStyle(PrimaryButtonStyle(isEnabled: !isLoading && !childEmail.isEmpty, isLoading: isLoading))
            .disabled(isLoading || childEmail.isEmpty)
        }
    }
    
    private func linkChild() {
        isLoading = true
        
        DispatchQueue.global().async {
            let userService = UserService()
            let currentEmail = self.childEmail
            
            guard let parentUser = userService.getCurrentUser(),
                  let parentEmail = parentUser.email else {
                DispatchQueue.main.async {
                    self.errorMessage = "Parent email not found"
                    self.showError = true
                    self.isLoading = false
                }
                return
            }
            
            // Call the synchronous method directly
            let success = SharedDataManager.shared.linkChildToParent(
                childEmail: currentEmail,
                parentEmail: parentEmail
            )
            
            DispatchQueue.main.async {
                if success {
                    self.showSuccess = true
                } else {
                    self.errorMessage = "Failed to link child account"
                    self.showError = true
                }
                self.isLoading = false
            }
        }
    }
}

// MARK: - Preview

struct ParentDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ParentDashboardView()
            .environmentObject(AppRouter())
            .environmentObject(SafeSupabaseAuthService.shared)
            .environmentObject(SafeSupabaseDataRepository.shared)
    }
} 