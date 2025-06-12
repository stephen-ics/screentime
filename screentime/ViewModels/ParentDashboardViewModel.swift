import Foundation
import Combine
import SwiftUI
import _Concurrency

// MARK: - Supporting Types

struct Activity: Identifiable, Equatable {
    let id: UUID
    let type: ActivityType
    let timestamp: Date
    let description: String
    let childId: UUID?
    
    enum ActivityType: String {
        case taskCompleted = "Task Completed"
        case timeRequested = "Time Requested"
        case timeApproved = "Time Approved"
        case timeDenied = "Time Denied"
        case childLinked = "Child Linked"
    }
}

enum DataUpdateEvent {
    case childLinked
    case timeRequested
    case timeApproved
    case timeDenied
    case taskCompleted
    case profileUpdated
}

enum AuthError: LocalizedError {
    case unauthorized
    case invalidCredentials
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - View Model

/// View model for the parent dashboard that handles all business logic and state management
@MainActor
final class ParentDashboardViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published private(set) var state = DashboardState()
    
    // MARK: - Dependencies
    private let familyAuth: FamilyAuthService
    private let dataRepository: SupabaseDataRepository
    private var router: (any RouterProtocol)?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    /// Default initializer for use with environment objects
    init() {
        self.familyAuth = FamilyAuthService.shared
        self.dataRepository = SupabaseDataRepository.shared
        self.router = nil
        
        setupSubscriptions()
        setupPeriodicRefresh()
        
        // Load initial data
        Task {
            await loadData()
        }
    }
    
    init(
        familyAuth: FamilyAuthService = FamilyAuthService.shared,
        dataRepository: SupabaseDataRepository = SupabaseDataRepository.shared,
        router: any RouterProtocol
    ) {
        self.familyAuth = familyAuth
        self.dataRepository = dataRepository
        self.router = router
        
        setupSubscriptions()
        setupPeriodicRefresh()
        
        // Load initial data
        Task {
            await loadData()
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Dependency Updates
    
    /// Updates the router reference - called from the view when environment router is available
    func updateRouter(_ newRouter: any RouterProtocol) {
        print("🔧 DEBUG: Updating router in view model")
        self.router = newRouter
    }
    
    // MARK: - Public Actions
    
    /// Loads all dashboard data
    func loadData() async {
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
        print("🔘 DEBUG: handleQuickAction called with: \(action.rawValue)")
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
        print("🔘 DEBUG: addChild() called - presenting sheet")
        router?.presentSheet(.addChild)
        print("🔘 DEBUG: router.presentSheet(.addChild) completed")
    }
    
    /// Navigates to time requests view
    func viewTimeRequests() {
        print("🔘 DEBUG: viewTimeRequests() called - presenting sheet")
        router?.presentSheet(.timeRequests)
        print("🔘 DEBUG: router.presentSheet(.timeRequests) completed")
    }
    
    /// Navigates to reports view
    func viewReports() {
        print("🔘 DEBUG: viewReports() called - navigating")
        router?.navigate(to: .reports)
        print("🔘 DEBUG: router.navigate(to: .reports) completed")
    }
    
    /// Opens settings
    func openSettings() {
        print("🔘 DEBUG: openSettings() called - presenting sheet")
        router?.presentSheet(.settings)
        print("🔘 DEBUG: router.presentSheet(.settings) completed")
    }
    
    /// Navigates to child detail view
    /// - Parameter child: The child to view details for
    func goToChildDetail(_ child: FamilyProfile) {
        // Convert FamilyProfile to Profile for navigation
        let profile = Profile(
            id: child.id,
            email: "", // FamilyProfile does not have email
            name: child.name,
            userType: child.role == .parent ? .parent : .child
        )
        router?.navigate(to: .childDetail(profile))
    }
    
    /// Clears the current error
    func clearError() {
        state.clearError()
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        familyAuth.$authenticationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case .fullyAuthenticated(let profile) = state {
                    self?.updateCurrentUser(profile)
                } else {
                    self?.updateCurrentUser(nil)
                }
            }
            .store(in: &cancellables)
        
        familyAuth.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.state.setError(error)
            }
            .store(in: &cancellables)
    }
    
    private func setupPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.refreshPeriodically()
            }
        }
    }
    
    func loadCurrentUser() async {
        guard let profile = familyAuth.currentProfile else {
            await MainActor.run {
                state.setError(AuthError.unauthorized)
            }
            return
        }
        await MainActor.run {
            state.updateCurrentUser(profile)
        }
    }
    
    func loadChildren() async {
        guard let profile = familyAuth.currentProfile else { return }
        
        do {
            // For now, return empty array - child linking not implemented yet
            let children: [FamilyProfile] = []
            
            await MainActor.run {
                state.linkedChildren = children
            }
        } catch {
            await MainActor.run {
                state.setError(error)
            }
        }
    }
    
    func loadPendingRequests() async {
        guard let profile = familyAuth.currentProfile else {
            return
        }
        
        // For now, return 0 pending requests
        await MainActor.run {
            state.pendingRequestsCount = 0
            state.timeRequests = []
        }
    }
    
    private func loadRecentActivities() async {
        // For now, return empty activities
        await MainActor.run {
            state.recentActivities = []
        }
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
        // Handle data updates synchronously on main thread
        Task {
            await refreshData()
        }
    }
    
    private func refreshPeriodically() {
        // Trigger periodic refresh
        Task {
            await loadData()
        }
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
        guard let profile = familyAuth.currentProfile else {
            DispatchQueue.main.async { [weak self] in
                self?.state.setError(AuthError.unauthorized)
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.state.updateCurrentUser(profile)
        }
    }
    
    private func loadChildrenAsync() {
        guard let profile = familyAuth.currentProfile else {
            return
        }
        
        state.isLoadingChildren = true
        
        // For now, return empty children list
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.state.linkedChildren = []
            self.state.isLoadingChildren = false
        }
    }
    
    private func loadPendingRequestsAsync() {
        guard let profile = familyAuth.currentProfile else {
            return
        }
        
        state.isLoadingRequests = true
        
        // For now, return 0 pending requests
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.state.pendingRequestsCount = 0
            self.state.timeRequests = []
            self.state.isLoadingRequests = false
        }
    }
    
    private func loadRecentActivitiesAsync() {
        state.isLoadingActivities = true
        
        // For now, return empty activities
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.state.recentActivities = []
            self.state.isLoadingActivities = false
        }
    }
    
    private func updateCurrentUser(_ profile: FamilyProfile?) {
        if let profile = profile {
            state.currentUserName = profile.name
            state.currentUserEmail = "" // FamilyProfile has no email
        } else {
            state.currentUserName = ""
            state.currentUserEmail = ""
        }
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