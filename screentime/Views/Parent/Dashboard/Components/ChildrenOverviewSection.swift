import SwiftUI

/// Children overview section that displays linked children with their screen time information
struct ChildrenOverviewSection: View {
    
    // MARK: - Properties
    let children: [FamilyProfile]
    let onChildTapped: (FamilyProfile) -> Void
    let onSeeAllTapped: () -> Void
    
    // MARK: - Initialization
    
    init(
        children: [FamilyProfile],
        onChildTapped: @escaping (FamilyProfile) -> Void,
        onSeeAllTapped: @escaping () -> Void
    ) {
        self.children = children
        self.onChildTapped = onChildTapped
        self.onSeeAllTapped = onSeeAllTapped
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxSmall) {
                    Text("Your Children")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    if children.isEmpty {
                        Text("No children linked yet")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    } else {
                        Text("\(children.count) child\(children.count == 1 ? "" : "ren") linked")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Button(action: onSeeAllTapped) {
                    Text("See All")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primaryBlue)
                }
            }
            
            // Content
            if children.isEmpty {
                emptyState
            } else {
                childrenScrollView
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.Spacing.medium)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var childrenScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: DesignSystem.Spacing.medium) {
                ForEach(children, id: \.id) { child in
                    ChildCard(child: child) {
                        onChildTapped(child)
                    }
                }
            }
            .padding(.horizontal, 2) // Small padding for shadow
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("No children linked yet")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
}

// MARK: - Child Card Component
struct ChildCard: View {
    let child: FamilyProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignSystem.Spacing.small) {
                // Avatar
                Circle()
                    .fill(LinearGradient.childGradient)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(child.name.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                // Name
                Text(child.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                
                // Status indicator
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.success)
            }
            .padding(DesignSystem.Spacing.small)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Previews
struct ChildrenOverviewSection_Previews: PreviewProvider {
    static var previews: some View {
        ChildrenOverviewSection(
            children: [FamilyProfile.mockChild],
            onChildTapped: { _ in },
            onSeeAllTapped: { }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Equatable

extension ChildrenOverviewSection: Equatable {
    static func == (lhs: ChildrenOverviewSection, rhs: ChildrenOverviewSection) -> Bool {
        lhs.children.map(\.id) == rhs.children.map(\.id)
    }
}

extension ChildCard: Equatable {
    static func == (lhs: ChildCard, rhs: ChildCard) -> Bool {
        lhs.child.id == rhs.child.id
    }
}

// MARK: - Mock Data Extension

extension FamilyProfile {
    static var mockChildren: [FamilyProfile] {
        // This would normally come from Supabase
        return [
            // Mock children for preview
        ]
    }
} 