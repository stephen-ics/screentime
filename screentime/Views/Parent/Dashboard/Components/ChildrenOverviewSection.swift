import SwiftUI

/// Children overview section that displays linked children with their screen time information
struct ChildrenOverviewSection: View {
    
    // MARK: - Properties
    let children: [User]
    let onChildTapped: (User) -> Void
    let onSeeAllTapped: () -> Void
    
    // MARK: - Initialization
    
    init(
        children: [User],
        onChildTapped: @escaping (User) -> Void,
        onSeeAllTapped: @escaping () -> Void
    ) {
        self.children = children
        self.onChildTapped = onChildTapped
        self.onSeeAllTapped = onSeeAllTapped
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            sectionHeader
            childrenGrid
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var sectionHeader: some View {
        HStack {
            Text("Your Children")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button("See All") {
                onSeeAllTapped()
            }
            .font(DesignSystem.Typography.callout)
            .fontWeight(.medium)
            .foregroundColor(DesignSystem.Colors.primaryBlue)
        }
    }
    
    @ViewBuilder
    private var childrenGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: DesignSystem.Spacing.medium) {
                ForEach(Array(children.prefix(3).enumerated()), id: \.element.id) { index, child in
                    ChildOverviewCard(child: child) {
                        onChildTapped(child)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.2).delay(Double(index) * 0.1), value: children.count)
                }
            }
            .padding(.horizontal, 1) // Prevent shadow clipping
        }
    }
}

// MARK: - Child Overview Card

/// Individual child overview card component
struct ChildOverviewCard: View {
    
    // MARK: - Properties
    let child: User
    let onTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        BaseCard(style: .compact, action: onTap) {
            VStack(spacing: DesignSystem.Spacing.small) {
                childAvatar
                childInfo
            }
            .frame(width: 100)
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var childAvatar: some View {
        Circle()
            .fill(avatarGradient)
            .frame(width: 60, height: 60)
            .overlay(
                Text(childInitials)
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            )
    }
    
    @ViewBuilder
    private var childInfo: some View {
        VStack(spacing: DesignSystem.Spacing.xxSmall) {
            Text(child.name)
                .font(DesignSystem.Typography.callout)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
            
            if let balance = child.screenTimeBalance {
                screenTimeInfo(balance)
            } else {
                Text("No screen time")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
    }
    
    @ViewBuilder
    private func screenTimeInfo(_ balance: ScreenTimeBalance) -> some View {
        VStack(spacing: 2) {
            Text(balance.formattedTimeRemaining)
                .font(DesignSystem.Typography.caption1)
                .fontWeight(.medium)
                .foregroundColor(timeRemainingColor(balance))
            
            if balance.isTimerActive {
                HStack(spacing: 2) {
                    Circle()
                        .fill(DesignSystem.Colors.success)
                        .frame(width: 6, height: 6)
                    
                    Text("Active")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.success)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var childInitials: String {
        let components = child.name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1))
        } else {
            return String(child.name.prefix(2))
        }
    }
    
    private var avatarGradient: LinearGradient {
        // Create a consistent gradient based on the child's name
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
    
    // MARK: - Helper Methods
    
    private func timeRemainingColor(_ balance: ScreenTimeBalance) -> Color {
        let remaining = balance.availableMinutes
        if remaining <= 15 {
            return DesignSystem.Colors.error
        } else if remaining <= 60 {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.secondaryText
        }
    }
}

// MARK: - Equatable

extension ChildrenOverviewSection: Equatable {
    static func == (lhs: ChildrenOverviewSection, rhs: ChildrenOverviewSection) -> Bool {
        lhs.children.map(\.id) == rhs.children.map(\.id)
    }
}

extension ChildOverviewCard: Equatable {
    static func == (lhs: ChildOverviewCard, rhs: ChildOverviewCard) -> Bool {
        lhs.child.id == rhs.child.id &&
        lhs.child.screenTimeBalance?.availableMinutes == rhs.child.screenTimeBalance?.availableMinutes &&
        lhs.child.screenTimeBalance?.isTimerActive == rhs.child.screenTimeBalance?.isTimerActive
    }
}

// MARK: - Preview

struct ChildrenOverviewSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ChildrenOverviewSection(
                children: User.mockChildren,
                onChildTapped: { child in
                    print("Tapped child: \(child.name)")
                },
                onSeeAllTapped: {
                    print("See all tapped")
                }
            )
            
            ChildrenOverviewSection(
                children: [],
                onChildTapped: { _ in },
                onSeeAllTapped: { }
            )
        }
        .padding()
        .background(DesignSystem.Colors.groupedBackground)
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Mock Data Extension

extension User {
    static var mockChildren: [User] {
        // This would normally come from Core Data
        return [
            // Mock children for preview
        ]
    }
} 