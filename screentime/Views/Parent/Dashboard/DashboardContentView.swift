import SwiftUI
import Combine

/// Main dashboard content view that combines all dashboard sections
struct DashboardContentView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: ParentDashboardViewModel
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.groupedBackground
                .ignoresSafeArea()
            
            if viewModel.state.isLoading && viewModel.state.linkedChildren.isEmpty {
                loadingState
            } else {
                mainContent
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
        .alert("Error", isPresented: .constant(viewModel.state.showErrorAlert)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.state.errorMessage)
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var loadingState: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primaryBlue))
                .scaleEffect(1.2)
            
            Text("Loading dashboard...")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.xLarge, pinnedViews: []) {
                // Dashboard Header
                headerSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
                
                // Quick Actions
                quickActionsSection
                    .transition(.opacity.combined(with: .scale))
                
                // Children Overview (only if has children)
                if viewModel.state.hasChildren {
                    childrenOverviewSection
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
                
                // Recent Activity
                recentActivitySection
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.top, DesignSystem.Spacing.large)
            .padding(.bottom, DesignSystem.Spacing.xxLarge)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.state.hasChildren)
    }
    
    @ViewBuilder
    private var headerSection: some View {
        DashboardHeaderSection(
            userName: viewModel.state.currentUserName,
            pendingRequestsCount: viewModel.state.pendingRequestsCount
        )
        .equatable()
    }
    
    @ViewBuilder
    private var quickActionsSection: some View {
        QuickActionsSection(
            pendingRequestsCount: viewModel.state.pendingRequestsCount
        ) { action in
            viewModel.handleQuickAction(action)
        }
        .equatable()
    }
    
    @ViewBuilder
    private var childrenOverviewSection: some View {
        ChildrenOverviewSection(
            children: viewModel.state.previewChildren,
            onChildTapped: { child in
                viewModel.viewChildDetail(child)
            },
            onSeeAllTapped: {
                viewModel.selectTab(.children)
            }
        )
        .equatable()
    }
    
    @ViewBuilder
    private var recentActivitySection: some View {
        RecentActivitySection(
            activities: viewModel.state.recentActivitiesPreview
        )
        .equatable()
    }
}

// MARK: - Optimized Empty State

/// Empty state view for when no children are linked
struct EmptyDashboardState: View {
    let onAddChildTapped: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "person.2.slash")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                
                Text("No Children Linked")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Add your children to start managing their screen time and see your family activity here")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            Button(action: onAddChildTapped) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .medium))
                    Text("Add Your First Child")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: true))
            .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxxLarge)
        .padding(.horizontal, DesignSystem.Spacing.large)
    }
}

// MARK: - Preview

struct DashboardContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Dashboard with children
            DashboardContentView(viewModel: mockViewModelWithChildren)
                .previewDisplayName("With Children")
            
            // Dashboard without children
            DashboardContentView(viewModel: mockViewModelEmpty)
                .previewDisplayName("Empty State")
            
            // Loading state
            DashboardContentView(viewModel: mockViewModelLoading)
                .previewDisplayName("Loading")
        }
    }
    
    // MARK: - Mock View Models
    
    static var mockViewModelWithChildren: ParentDashboardViewModel {
        let authService = SafeSupabaseAuthService.shared
        let dataRepository = SupabaseDataRepository.shared
        let router = MockRouter()
        
        let viewModel = ParentDashboardViewModel(
            authService: authService,
            dataRepository: dataRepository,
            router: router
        )
        
        // Note: In real implementation, we'd need to make state mutable for testing
        // For now, this is just for preview purposes
        return viewModel
    }
    
    static var mockViewModelEmpty: ParentDashboardViewModel {
        let authService = SafeSupabaseAuthService.shared
        let dataRepository = SupabaseDataRepository.shared
        let router = MockRouter()
        
        let viewModel = ParentDashboardViewModel(
            authService: authService,
            dataRepository: dataRepository,
            router: router
        )
        
        return viewModel
    }
    
    static var mockViewModelLoading: ParentDashboardViewModel {
        let authService = SafeSupabaseAuthService.shared
        let dataRepository = SupabaseDataRepository.shared
        let router = MockRouter()
        
        let viewModel = ParentDashboardViewModel(
            authService: authService,
            dataRepository: dataRepository,
            router: router
        )
        
        return viewModel
    }
}

// MARK: - Mock Services

class MockRouter: RouterProtocol {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreen: FullScreenDestination?
    
    func navigate(to destination: NavigationDestination) {
        // Mock implementation - no-op for previews
    }
    
    func presentSheet(_ destination: SheetDestination) {
        // Mock implementation - no-op for previews
    }
    
    func presentFullScreen(_ destination: FullScreenDestination) {
        // Mock implementation - no-op for previews
    }
    
    func dismiss() {
        // Mock implementation - no-op for previews
    }
    
    func dismissSheet() {
        // Mock implementation - no-op for previews
    }
    
    func dismissFullScreen() {
        // Mock implementation - no-op for previews
    }
    
    func navigateToRoot() {
        // Mock implementation - no-op for previews
    }
}

class MockUserService: UserServiceProtocol {
    @Published var currentUser: User?
    var currentUserPublisher: AnyPublisher<User?, Never> { $currentUser.eraseToAnyPublisher() }
    
    func getCurrentUser() -> User? { currentUser }
    func getChildren(for parentEmail: String) -> [User] { [] }
    func getPendingRequestsCount(for parentEmail: String) -> Int { 0 }
    func signIn(email: String, password: String) async throws -> User { currentUser! }
    func signUp(email: String, password: String, name: String, isParent: Bool) async throws -> User { currentUser! }
    func signOut() { currentUser = nil }
}

class MockDataRepository: DataRepositoryProtocol {
    var dataUpdatePublisher: AnyPublisher<DataUpdateEvent, Never> {
        Just(.userRegistered(email: "test")).eraseToAnyPublisher()
    }
    
    func getChildren(for parentEmail: String) async throws -> [User] { [] }
    func getTimeRequests(for parentEmail: String) async throws -> [TimeRequest] { [] }
    func linkChild(email childEmail: String, to parentEmail: String) async throws -> Bool { true }
    func approveTimeRequest(_ requestId: String) async throws -> Bool { true }
    func denyTimeRequest(_ requestId: String) async throws -> Bool { true }
    func createTimeRequest(childEmail: String, parentEmail: String, minutes: Int32) async throws -> TimeRequest {
        TimeRequest(id: "1", childEmail: childEmail, parentEmail: parentEmail, requestedMinutes: minutes, timestamp: Date())
    }
    func refreshUserCache() async {}
    func findUser(byEmail email: String) async -> User? { nil }
} 