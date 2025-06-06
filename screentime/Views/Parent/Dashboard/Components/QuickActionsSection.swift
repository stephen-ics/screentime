import SwiftUI

/// Quick actions section that displays action cards for common parent tasks
struct QuickActionsSection: View {
    
    // MARK: - Properties
    let actions: [QuickAction]
    let pendingRequestsCount: Int
    let onActionTapped: (QuickAction) -> Void
    
    // MARK: - Initialization
    
    init(
        actions: [QuickAction] = QuickAction.allCases,
        pendingRequestsCount: Int,
        onActionTapped: @escaping (QuickAction) -> Void
    ) {
        self.actions = actions
        self.pendingRequestsCount = pendingRequestsCount
        self.onActionTapped = onActionTapped
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            sectionHeader
            actionGrid
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var sectionHeader: some View {
        Text("Quick Actions")
            .font(DesignSystem.Typography.title3)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .fontWeight(.semibold)
    }
    
    @ViewBuilder
    private var actionGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.medium), count: 2),
            spacing: DesignSystem.Spacing.medium
        ) {
            ForEach(actions) { action in
                QuickActionCard(
                    action: action,
                    count: action == .timeRequests ? pendingRequestsCount : nil
                ) {
                    onActionTapped(action)
                }
            }
        }
    }
}

// MARK: - Quick Action Card

/// Individual quick action card component
struct QuickActionCard: View {
    
    // MARK: - Properties
    let action: QuickAction
    let count: Int?
    let onTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        BaseCard(action: onTap) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                cardHeader
                actionTitle
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var cardHeader: some View {
        HStack {
            Image(systemName: action.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(colorForAction(action))
            
            Spacer()
            
            if let count = count, count > 0 {
                countBadge(count)
            }
        }
    }
    
    @ViewBuilder
    private var actionTitle: some View {
        Text(action.rawValue)
            .font(DesignSystem.Typography.callout)
            .fontWeight(.semibold)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
    
    @ViewBuilder
    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(DesignSystem.Typography.caption1)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForAction(action))
            .clipShape(Capsule())
    }
    
    // MARK: - Helper Methods
    
    private func colorForAction(_ action: QuickAction) -> Color {
        switch action.color {
        case "warning":
            return DesignSystem.Colors.warning
        case "primaryBlue":
            return DesignSystem.Colors.primaryBlue
        case "success":
            return DesignSystem.Colors.success
        case "secondaryText":
            return DesignSystem.Colors.secondaryText
        default:
            return DesignSystem.Colors.primaryBlue
        }
    }
}

// MARK: - Equatable

extension QuickActionsSection: Equatable {
    static func == (lhs: QuickActionsSection, rhs: QuickActionsSection) -> Bool {
        lhs.actions.map(\.id) == rhs.actions.map(\.id) &&
        lhs.pendingRequestsCount == rhs.pendingRequestsCount
    }
}

extension QuickActionCard: Equatable {
    static func == (lhs: QuickActionCard, rhs: QuickActionCard) -> Bool {
        lhs.action.id == rhs.action.id &&
        lhs.count == rhs.count
    }
}

// MARK: - Preview

struct QuickActionsSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            QuickActionsSection(pendingRequestsCount: 0) { action in
                print("Tapped: \(action.rawValue)")
            }
            
            QuickActionsSection(pendingRequestsCount: 3) { action in
                print("Tapped: \(action.rawValue)")
            }
        }
        .padding()
        .background(DesignSystem.Colors.groupedBackground)
        .previewLayout(.sizeThatFits)
    }
} 