import Foundation

/// State model for the parent dashboard
struct DashboardState {
    // MARK: - Data State
    var linkedChildren: [User] = []
    var pendingRequestsCount: Int = 0
    var recentActivities: [ActivityItem] = []
    
    // MARK: - UI State
    var selectedTab: DashboardTab = .dashboard
    var isLoading: Bool = false
    var isRefreshing: Bool = false
    
    // MARK: - Error State
    var error: Error? = nil
    var showErrorAlert: Bool = false
    var errorMessage: String = ""
    
    // MARK: - User State
    var currentUserName: String = ""
    var currentUserEmail: String = ""
    
    // MARK: - Computed Properties
    
    /// Whether the parent has any linked children
    var hasChildren: Bool { 
        !linkedChildren.isEmpty 
    }
    
    /// Whether to show the pending requests badge
    var shouldShowPendingBadge: Bool { 
        pendingRequestsCount > 0 
    }
    
    /// Preview children for the overview section (limited to 3)
    var previewChildren: [User] {
        Array(linkedChildren.prefix(3))
    }
    
    /// Recent activities for display (limited to 5)
    var recentActivitiesPreview: [ActivityItem] {
        Array(recentActivities.prefix(5))
    }
    
    /// Loading state for specific sections
    var isLoadingChildren: Bool = false
    var isLoadingRequests: Bool = false
    var isLoadingActivities: Bool = false
    
    // MARK: - State Management Methods
    
    /// Sets an error and shows the alert
    mutating func setError(_ error: Error) {
        self.error = error
        self.errorMessage = error.localizedDescription
        self.showErrorAlert = true
    }
    
    /// Clears the current error state
    mutating func clearError() {
        self.error = nil
        self.errorMessage = ""
        self.showErrorAlert = false
    }
    
    /// Updates the current user information
    mutating func updateCurrentUser(_ user: User) {
        self.currentUserName = user.name
        self.currentUserEmail = user.email ?? ""
    }
    
    /// Resets all state to initial values
    mutating func reset() {
        self = DashboardState()
    }
}

/// Represents the different tabs in the dashboard
enum DashboardTab: Int, CaseIterable {
    case dashboard = 0
    case children = 1
    case tasks = 2
    case account = 3
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .children: return "Children"
        case .tasks: return "Tasks"
        case .account: return "Account"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .children: return "person.2"
        case .tasks: return "checklist"
        case .account: return "person.circle"
        }
    }
}

/// Represents an activity item for the recent activities section
struct ActivityItem: Identifiable, Equatable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let subtitle: String
    let timestamp: Date
    let associatedUser: String?
    
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

/// Types of activities that can occur in the system
enum ActivityType: CaseIterable {
    case taskCompleted
    case timeRequested
    case timeApproved
    case timeDenied
    case childLinked
    case screenTimeExpired
    
    var icon: String {
        switch self {
        case .taskCompleted: return "checkmark.circle.fill"
        case .timeRequested: return "hourglass"
        case .timeApproved: return "checkmark.circle"
        case .timeDenied: return "xmark.circle"
        case .childLinked: return "person.badge.plus"
        case .screenTimeExpired: return "hourglass.bottomhalf.filled"
        }
    }
    
    var color: String {
        switch self {
        case .taskCompleted: return "success"
        case .timeRequested: return "warning"
        case .timeApproved: return "success"
        case .timeDenied: return "error"
        case .childLinked: return "primaryBlue"
        case .screenTimeExpired: return "warning"
        }
    }
} 