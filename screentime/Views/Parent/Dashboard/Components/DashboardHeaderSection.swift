import SwiftUI

/// Dashboard header section that displays welcome message and user information
struct DashboardHeaderSection: View {
    
    // MARK: - Properties
    let userName: String
    let pendingRequestsCount: Int
    
    // MARK: - Initialization
    
    init(userName: String, pendingRequestsCount: Int) {
        self.userName = userName
        self.pendingRequestsCount = pendingRequestsCount
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            welcomeMessage
            
            if pendingRequestsCount > 0 {
                pendingRequestsBadge
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.2), value: pendingRequestsCount)
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
            Text("Welcome back")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Text(userName.isEmpty ? "Parent" : userName)
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .fontWeight(.bold)
        }
    }
    
    @ViewBuilder
    private var pendingRequestsBadge: some View {
        HStack(spacing: DesignSystem.Spacing.xSmall) {
            Image(systemName: "bell.badge.fill")
                .foregroundColor(DesignSystem.Colors.warning)
                .font(.system(size: 16, weight: .medium))
            
            Text(pendingRequestsText)
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.warning)
                .fontWeight(.medium)
        }
        .padding(.top, DesignSystem.Spacing.xxSmall)
    }
    
    // MARK: - Computed Properties
    
    private var pendingRequestsText: String {
        if pendingRequestsCount == 1 {
            return "1 pending request"
        } else {
            return "\(pendingRequestsCount) pending requests"
        }
    }
}

// MARK: - Equatable

extension DashboardHeaderSection: Equatable {
    static func == (lhs: DashboardHeaderSection, rhs: DashboardHeaderSection) -> Bool {
        lhs.userName == rhs.userName && 
        lhs.pendingRequestsCount == rhs.pendingRequestsCount
    }
}

// MARK: - Preview

struct DashboardHeaderSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            DashboardHeaderSection(
                userName: "John Doe",
                pendingRequestsCount: 0
            )
            
            DashboardHeaderSection(
                userName: "Jane Smith",
                pendingRequestsCount: 1
            )
            
            DashboardHeaderSection(
                userName: "Parent User",
                pendingRequestsCount: 3
            )
        }
        .padding()
        .background(DesignSystem.Colors.groupedBackground)
        .previewLayout(.sizeThatFits)
    }
} 