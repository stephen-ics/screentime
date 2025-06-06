import Foundation
import Combine
import SwiftUI
import _Concurrency

/// View model for the parent dashboard that handles all business logic and state management
@MainActor
final class ParentDashboardViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published private(set) var state = DashboardState()
    
    // MARK: - Dependencies
    private let userService: any UserServiceProtocol
    private let dataRepository: DataRepositoryProtocol
    private let router: any RouterProtocol
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    init(
        userService: any UserServiceProtocol,
        dataRepository: DataRepositoryProtocol,
        router: any RouterProtocol
    ) {
        self.userService = userService
        self.dataRepository = dataRepository
        self.router = router
        
        setupBindings()
        setupPeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Actions
    
    /// Loads all dashboard data
    func loadData() {
        state.isLoading = true
        
        // Load current user synchronously
        loadCurrentUserSync()
        
        // Load other data asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.loadChildrenAsync()
                self.loadPendingRequestsAsync()
                self.loadRecentActivitiesAsync()
                self.state.isLoading = false
            }
        }
    }
    
    /// Refreshes dashboard data
    func refreshData() async {
        state.isRefreshing = true
        defer { state.isRefreshing = false }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadCurrentUser() }
            group.addTask { await self.loadChildren() }
            group.addTask { await self.loadPendingRequests() }
            group.addTask { await self.loadRecentActivities() }
        }
    }
    
    /// Selects a tab in the dashboard
    /// - Parameter tab: The tab to select
    func selectTab(_ tab: DashboardTab) {
        state.selectedTab = tab
    }
    
    /// Handles quick action taps
    /// - Parameter action: The quick action that was tapped
    func handleQuickAction(_ action: QuickAction) {
        switch action {
        case .timeRequests:
            viewTimeRequests()
        case .addChild:
            addChild()
        case .viewReports:
            viewReports()
        case .settings:
            openSettings()
        }
    }
    
    /// Navigates to add child view
    func addChild() {
        router.presentSheet(.addChild)
    }
    
    /// Navigates to time requests view
    func viewTimeRequests() {
        router.presentSheet(.timeRequests)
    }
    
    /// Navigates to reports view
    func viewReports() {
        router.navigate(to: .reports)
    }
    
    /// Opens settings
    func openSettings() {
        router.presentSheet(.settings)
    }
    
    /// Navigates to child detail view
    /// - Parameter child: The child to view details for
    func viewChildDetail(_ child: User) {
        router.navigate(to: .childDetail(child))
    }
    
    /// Clears the current error
    func clearError() {
        state.clearError()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Subscribe to user service changes
        userService.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if let user = user {
                    self?.state.updateCurrentUser(user)
                } else {
                    self?.state.reset()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to data repository updates
        dataRepository.dataUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                // Handle data update synchronously
                self.handleDataUpdateSync(event)
            }
            .store(in: &cancellables)
    }
    
    private func setupPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Trigger refresh without Task
            self.refreshPeriodically()
        }
    }
    
    private func loadCurrentUser() async {
        guard let user = userService.getCurrentUser() else {
            state.setError(UserServiceError.notAuthenticated)
            return
        }
        
        state.updateCurrentUser(user)
    }
    
    private func loadChildren() async {
        guard let userEmail = userService.getCurrentUser()?.email else {
            return
        }
        
        state.isLoadingChildren = true
        defer { state.isLoadingChildren = false }
        
        do {
            let children = try await dataRepository.getChildren(for: userEmail)
            state.linkedChildren = children
            state.error = nil
        } catch {
            state.setError(error)
        }
    }
    
    private func loadPendingRequests() async {
        guard let userEmail = userService.getCurrentUser()?.email else {
            return
        }
        
        state.isLoadingRequests = true
        defer { state.isLoadingRequests = false }
        
        do {
            let requests = try await dataRepository.getTimeRequests(for: userEmail)
            state.pendingRequestsCount = requests.count
        } catch {
            print("Failed to load pending requests: \(error)")
            // Don't show error for this as it's not critical
        }
    }
    
    private func loadRecentActivities() async {
        state.isLoadingActivities = true
        defer { state.isLoadingActivities = false }
        
        // Generate mock activities based on current data
        // In a real app, this would come from the repository
        state.recentActivities = generateMockActivities()
    }
    
    private func handleDataUpdate(_ event: DataUpdateEvent) async {
        switch event {
        case .childLinked:
            await loadChildren()
            await loadRecentActivities()
            
        case .timeRequested:
            await loadPendingRequests()
            await loadRecentActivities()
            
        case .timeApproved, .timeDenied:
            await loadPendingRequests()
            await loadRecentActivities()
            
        case .taskCompleted:
            await loadRecentActivities()
            
        default:
            break
        }
    }
    
    private func handleDataUpdateSync(_ event: DataUpdateEvent) {
        // Handle data update synchronously where possible
        switch event {
        case .childLinked, .timeRequested, .timeApproved, .timeDenied, .taskCompleted:
            // Trigger a simple refresh that will be handled asynchronously
            DispatchQueue.main.async { [weak self] in
                self?.loadData()
            }
        default:
            break
        }
    }
    
    private func refreshPeriodically() {
        // Trigger periodic refresh
        loadData()
    }
    
    private func generateMockActivities() -> [ActivityItem] {
        var activities: [ActivityItem] = []
        
        // Add activities based on current state
        if !state.linkedChildren.isEmpty {
            activities.append(
                ActivityItem(
                    type: .taskCompleted,
                    title: "Task Completed",
                    subtitle: "Math homework by \(state.linkedChildren.first?.name ?? "Child")",
                    timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                    associatedUser: state.linkedChildren.first?.name
                )
            )
        }
        
        if state.pendingRequestsCount > 0 {
            activities.append(
                ActivityItem(
                    type: .timeRequested,
                    title: "Time Request",
                    subtitle: "30 minutes requested",
                    timestamp: Date().addingTimeInterval(-10800), // 3 hours ago
                    associatedUser: state.linkedChildren.first?.name
                )
            )
        }
        
        activities.append(
            ActivityItem(
                type: .childLinked,
                title: "Child Added",
                subtitle: "Account linked successfully",
                timestamp: Date().addingTimeInterval(-86400), // Yesterday
                associatedUser: nil
            )
        )
        
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func loadCurrentUserSync() {
        guard let user = userService.getCurrentUser() else {
            DispatchQueue.main.async { [weak self] in
                self?.state.setError(UserServiceError.notAuthenticated)
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.state.updateCurrentUser(user)
        }
    }
    
    private func loadChildrenAsync() {
        guard let userEmail = userService.getCurrentUser()?.email else {
            return
        }
        
        state.isLoadingChildren = true
        
        // Use DispatchQueue for background work
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // Call the underlying service directly to avoid async/await complications
            let children = SharedDataManager.shared.getChildren(forParentEmail: userEmail)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.state.linkedChildren = children
                self.state.isLoadingChildren = false
            }
        }
    }
    
    private func loadPendingRequestsAsync() {
        guard let userEmail = userService.getCurrentUser()?.email else {
            return
        }
        
        state.isLoadingRequests = true
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // Call the underlying service directly
            let requests = SharedDataManager.shared.getPendingRequests(forParentEmail: userEmail)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.state.pendingRequestsCount = requests.count
                self.state.isLoadingRequests = false
            }
        }
    }
    
    private func loadRecentActivitiesAsync() {
        state.isLoadingActivities = true
        // Generate mock activities based on current data
        state.recentActivities = generateMockActivities()
        state.isLoadingActivities = false
    }
}

// MARK: - Quick Action Enum

/// Quick actions available on the dashboard
enum QuickAction: String, CaseIterable, Identifiable {
    case timeRequests = "Time Requests"
    case addChild = "Add Child"
    case viewReports = "View Reports"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .timeRequests: return "hourglass.badge.plus"
        case .addChild: return "person.badge.plus"
        case .viewReports: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    var color: String {
        switch self {
        case .timeRequests: return "warning"
        case .addChild: return "primaryBlue"
        case .viewReports: return "success"
        case .settings: return "secondaryText"
        }
    }
} 