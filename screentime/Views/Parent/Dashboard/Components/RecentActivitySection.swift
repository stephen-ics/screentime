import SwiftUI

/// Recent activity section that displays recent activities in the family account
struct RecentActivitySection: View {
    
    // MARK: - Properties
    let activities: [ActivityItem]
    
    // MARK: - Initialization
    
    init(activities: [ActivityItem]) {
        self.activities = activities
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            sectionHeader
            
            if activities.isEmpty {
                emptyState
            } else {
                activitiesList
            }
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var sectionHeader: some View {
        Text("Recent Activity")
            .font(DesignSystem.Typography.title3)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .fontWeight(.semibold)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        BaseCard(style: .compact) {
            VStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "clock")
                    .font(.system(size: 24))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                
                Text("No recent activity")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text("Activities will appear here as they happen")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.medium)
        }
    }
    
    @ViewBuilder
    private var activitiesList: some View {
        LazyVStack(spacing: DesignSystem.Spacing.small) {
            ForEach(Array(activities.prefix(5).enumerated()), id: \.element.id) { index, activity in
                ActivityRow(activity: activity)
                    .opacity(1.0 - (Double(index) * 0.1)) // Fade older activities slightly
                    .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: activities.count)
            }
        }
    }
}

// MARK: - Activity Row

/// Individual activity row component
struct ActivityRow: View {
    
    // MARK: - Properties
    let activity: ActivityItem
    
    // MARK: - Body
    
    var body: some View {
        BaseCard(style: .compact) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                activityIcon
                activityInfo
                Spacer()
                activityTime
            }
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var activityIcon: some View {
        Circle()
            .fill(activityColor.opacity(0.15))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: activity.type.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(activityColor)
            )
    }
    
    @ViewBuilder
    private var activityInfo: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
            Text(activity.title)
                .font(DesignSystem.Typography.callout)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
            
            Text(activity.subtitle)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineLimit(2)
        }
    }
    
    @ViewBuilder
    private var activityTime: some View {
        Text(activity.timeAgoString)
            .font(DesignSystem.Typography.caption2)
            .foregroundColor(DesignSystem.Colors.tertiaryText)
            .fixedSize(horizontal: true, vertical: false)
    }
    
    // MARK: - Computed Properties
    
    private var activityColor: Color {
        switch activity.type.color {
        case "success":
            return DesignSystem.Colors.success
        case "warning":
            return DesignSystem.Colors.warning
        case "error":
            return DesignSystem.Colors.error
        case "primaryBlue":
            return DesignSystem.Colors.primaryBlue
        default:
            return DesignSystem.Colors.secondaryText
        }
    }
}

// MARK: - Equatable

extension RecentActivitySection: Equatable {
    static func == (lhs: RecentActivitySection, rhs: RecentActivitySection) -> Bool {
        lhs.activities.map(\.id) == rhs.activities.map(\.id)
    }
}

extension ActivityRow: Equatable {
    static func == (lhs: ActivityRow, rhs: ActivityRow) -> Bool {
        lhs.activity.id == rhs.activity.id
    }
}

// MARK: - Preview

struct RecentActivitySection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            RecentActivitySection(activities: sampleActivities)
            
            RecentActivitySection(activities: [])
        }
        .padding()
        .background(DesignSystem.Colors.groupedBackground)
        .previewLayout(.sizeThatFits)
    }
    
    static var sampleActivities: [ActivityItem] {
        [
            ActivityItem(
                type: .taskCompleted,
                title: "Task Completed",
                subtitle: "Math homework by Sarah",
                timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                associatedUser: "Sarah"
            ),
            ActivityItem(
                type: .timeRequested,
                title: "Time Request",
                subtitle: "30 minutes requested by John",
                timestamp: Date().addingTimeInterval(-10800), // 3 hours ago
                associatedUser: "John"
            ),
            ActivityItem(
                type: .childLinked,
                title: "Child Added",
                subtitle: "Emma linked to account",
                timestamp: Date().addingTimeInterval(-86400), // Yesterday
                associatedUser: "Emma"
            ),
            ActivityItem(
                type: .timeApproved,
                title: "Time Approved",
                subtitle: "15 minutes granted to Sarah",
                timestamp: Date().addingTimeInterval(-172800), // 2 days ago
                associatedUser: "Sarah"
            )
        ]
    }
} 