import SwiftUI
import Combine
import _Concurrency

/// Main parent dashboard view with proper MVVM architecture and dependency injection
struct ParentDashboardView: View {
    
    // MARK: - Dependencies
    private let userService: any UserServiceProtocol
    private let dataRepository: DataRepositoryProtocol
    
    // MARK: - State
    @StateObject private var router = AppRouter()
    @StateObject private var viewModel: ParentDashboardViewModel
    
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Initialization
    
    init(
        userService: any UserServiceProtocol = UserService.shared,
        dataRepository: DataRepositoryProtocol = DataRepository.shared
    ) {
        self.userService = userService
        self.dataRepository = dataRepository
        
        // Create router and view model
        let tempRouter = AppRouter()
        self._router = StateObject(wrappedValue: tempRouter)
        self._viewModel = StateObject(wrappedValue: ParentDashboardViewModel(
            userService: userService,
            dataRepository: dataRepository,
            router: tempRouter
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
        .environmentObject(router)
        .onAppear {
            viewModel.loadData()
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .childDetail(let user):
            Text("Child Detail for \(user.name)")
                .navigationTitle(user.name)
        case .taskDetail(_):
            Text("Task Detail")
                .navigationTitle("Task")
        case .settings:
            SettingsView()
        case .editProfile:
            Text("Edit Profile - Coming Soon")
                .navigationTitle("Edit Profile")
        case .timeRequestDetail(_):
            Text("Time Request Detail")
                .navigationTitle("Request")
        case .reports:
            ReportsView()
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
        userService: any UserServiceProtocol = UserService.shared,
        dataRepository: DataRepositoryProtocol = DataRepository.shared
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
                userService: userService,
                dataRepository: dataRepository,
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
    @EnvironmentObject private var router: AppRouter
    
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
        .sheet(item: $router.presentedSheet) { destination in
            sheetContent(for: destination)
                .environmentObject(router)
        }
        .fullScreenCover(item: $router.presentedFullScreen) { destination in
            fullScreenContent(for: destination)
                .environmentObject(router)
        }
        .onAppear {
            viewModel.loadData()
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
    
    // MARK: - Sheet Content
    
    @ViewBuilder
    private func sheetContent(for destination: SheetDestination) -> some View {
        switch destination {
        case .addChild:
            NavigationView {
                ModernAddChildView()
                    .environmentObject(router)
            }
            
        case .addTask:
            NavigationView {
                AddTaskView()
                    .environmentObject(router)
            }
            
        case .timeRequests:
            NavigationView {
                TimeRequestsView()
                    .environmentObject(router)
            }
            
        case .settings:
            NavigationView {
                SettingsView()
                    .environmentObject(router)
            }
            
        case .editProfile:
            NavigationView {
                EditProfileView()
                    .environmentObject(router)
            }
            
        case .changePassword:
            NavigationView {
                ChangePasswordView()
                    .environmentObject(router)
            }
        }
    }
    
    @ViewBuilder
    private func fullScreenContent(for destination: FullScreenDestination) -> some View {
        switch destination {
        case .authentication:
            AuthenticationView()
                .environmentObject(router)
            
        case .onboarding:
            Text("Onboarding - Coming Soon")
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
        case .parentalControls:
            Text("Parental Controls - Coming Soon")
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var addTaskButton: some View {
        Button(action: { router.presentSheet(.addTask) }) {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Children List View

/// Optimized children list view with proper state management
struct ChildrenListView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: ParentDashboardViewModel
    @EnvironmentObject private var router: AppRouter
    
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
                    ModernChildCard(child: child) {
                        viewModel.viewChildDetail(child)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
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
    let child: User
    let onTap: () -> Void
    
    var body: some View {
        BaseCard(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Avatar
                childAvatar
                
                // Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    Text(child.name)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    screenTimeInfo
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
    }
    
    @ViewBuilder
    private var childAvatar: some View {
        Circle()
            .fill(avatarGradient)
            .frame(width: 56, height: 56)
            .overlay(
                Text(childInitials)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
    }
    
    @ViewBuilder
    private var screenTimeInfo: some View {
        if let balance = child.screenTimeBalance {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text(balance.formattedTimeRemaining)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                if balance.isTimerActive {
                    HStack(spacing: DesignSystem.Spacing.xSmall) {
                        Circle()
                            .fill(DesignSystem.Colors.success)
                            .frame(width: 8, height: 8)
                        
                        Text("Timer Active")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
            }
        } else {
            Text("No screen time set")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
    }
    
    private var childInitials: String {
        let components = child.name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1))
        } else {
            return String(child.name.prefix(2))
        }
    }
    
    private var avatarGradient: LinearGradient {
        let hash = child.name.hashValue
        let colors = [
            (DesignSystem.Colors.primaryBlue, DesignSystem.Colors.primaryIndigo),
            (DesignSystem.Colors.success, Color.green),
            (DesignSystem.Colors.warning, Color.orange),
            (Color.purple, Color.pink),
            (Color.teal, Color.cyan)
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
    @EnvironmentObject private var router: AppRouter
    @State private var childEmail = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
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
                    router.dismissSheet()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { router.dismissSheet() }
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
            let userService = UserService.shared
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
        ParentDashboardView_Alternative()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
} 