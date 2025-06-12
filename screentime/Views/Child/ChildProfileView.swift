import SwiftUI

struct ChildProfileView: View {
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xxLarge) {
                    // Fun Profile Header
                    funProfileHeader
                    
                    // Account Information with fun styling
                    funProfileInformation
                    
                    // Actions Section with fun elements
                    funActionsSection
                    
                    Spacer(minLength: DesignSystem.Spacing.xxxLarge)
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.groupedBackground,
                        DesignSystem.Colors.childAccent.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("👤 My Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $showingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    do {
                        try await familyAuth.signOut()
                    } catch {
                        // Handle signout error silently for now
                        print("Error signing out: \(error)")
                    }
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    // MARK: - Fun Profile Header
    private var funProfileHeader: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Big fun avatar
            funAvatarView
            
            // Name and fun greeting
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("Hey \(familyAuth.currentProfile?.name ?? "Champion")! 👋")
                    .font(DesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: DesignSystem.Spacing.small) {
                    Text("🌟 Keep being awesome! 🌟")
                        .font(DesignSystem.Typography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.childAccent)
                    
                    Text("You're doing a great job completing tasks and managing your screen time!")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxLarge)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                .fill(
                    LinearGradient(
                        colors: [
                            .white,
                            DesignSystem.Colors.childAccent.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                .stroke(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.childAccent.opacity(0.3),
                            DesignSystem.Colors.childAccent.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(
            color: DesignSystem.Colors.childAccent.opacity(0.2),
            radius: 20,
            x: 0,
            y: 8
        )
    }
    
    // MARK: - Fun Avatar View
    private var funAvatarView: some View {
        ZStack {
            // Colorful background with multiple layers
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.childAccent,
                            DesignSystem.Colors.childAccent.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            // Fun decorative ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 110, height: 110)
            
            // Initial or avatar with fun styling
            if let name = familyAuth.currentProfile?.name, !name.isEmpty {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            } else {
                Text("😊")
                    .font(.system(size: 48))
            }
        }
        .shadow(
            color: DesignSystem.Colors.childAccent.opacity(0.4),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    // MARK: - Fun Profile Information
    private var funProfileInformation: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("📝 My Info")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                FunProfileInfoRow(
                    emoji: "👤",
                    title: "My Name",
                    value: familyAuth.currentProfile?.name ?? "Not available",
                    color: DesignSystem.Colors.childAccent
                )
                
                FunProfileInfoRow(
                    emoji: "📧",
                    title: "Email",
                    value: "Not available for child profiles",
                    color: DesignSystem.Colors.info
                )
                
                FunProfileInfoRow(
                    emoji: "🎮",
                    title: "Account Type",
                    value: "Kid Account - Super Cool! 😎",
                    color: DesignSystem.Colors.success
                )
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                .fill(.white)
        )
        .shadow(
            color: DesignSystem.Shadow.card.color.opacity(0.1),
            radius: DesignSystem.Shadow.card.radius,
            x: DesignSystem.Shadow.card.x,
            y: DesignSystem.Shadow.card.y
        )
    }
    
    // MARK: - Fun Actions Section
    private var funActionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("🎯 Quick Actions")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                // About Section Button
                FunProfileActionButton(
                    emoji: "ℹ️",
                    title: "About ScreenTime",
                    subtitle: "Learn how this awesome app works!",
                    color: DesignSystem.Colors.info
                ) {
                    // TODO: Show about screen
                }
                
                // Help Button
                FunProfileActionButton(
                    emoji: "🆘",
                    title: "Need Help?",
                    subtitle: "Get help using the app",
                    color: DesignSystem.Colors.warning
                ) {
                    // TODO: Show help screen
                }
                
                // Fun divider
                HStack {
                    VStack {
                        Divider()
                    }
                    
                    Text("⭐")
                        .font(.system(size: 16))
                        .padding(.horizontal, DesignSystem.Spacing.small)
                    
                    VStack {
                        Divider()
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.small)
                
                // Logout Button with warning styling
                FunProfileActionButton(
                    emoji: "👋",
                    title: "Sign Out",
                    subtitle: "Leave the app (you can come back anytime!)",
                    color: DesignSystem.Colors.error,
                    isDestructive: true
                ) {
                    showingLogoutConfirmation = true
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                .fill(.white)
        )
        .shadow(
            color: DesignSystem.Shadow.card.color.opacity(0.1),
            radius: DesignSystem.Shadow.card.radius,
            x: DesignSystem.Shadow.card.x,
            y: DesignSystem.Shadow.card.y
        )
    }
}

// MARK: - Supporting Views

struct FunProfileInfoRow: View {
    let emoji: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Fun emoji in a circle
            Text(emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                Text(title)
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(value)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.small)
    }
}

struct FunProfileActionButton: View {
    let emoji: String
    let title: String
    let subtitle: String
    let color: Color
    let isDestructive: Bool
    let action: () -> Void
    
    init(
        emoji: String,
        title: String,
        subtitle: String,
        color: Color,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.emoji = emoji
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Fun emoji with animated background
                Text(emoji)
                    .font(.system(size: 24))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.2),
                                        color.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyBold)
                        .fontWeight(.bold)
                        .foregroundColor(isDestructive ? color : DesignSystem.Colors.primaryText)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Fun arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color.opacity(0.7))
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.05),
                                color.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(FunScaleButtonStyle())
    }
}

// MARK: - Preview
struct ChildProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ChildProfileView()
            .environmentObject(FamilyAuthService.shared)
    }
} 