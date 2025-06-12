import SwiftUI

/// Main coordinator for family authentication flow
struct FamilyAuthCoordinator: View {
    @StateObject private var familyAuth = FamilyAuthService.shared
    
    var body: some View {
        Group {
            switch familyAuth.authenticationState {
            case .unauthenticated:
                // Show authentication (sign in/up) view
                FamilyAuthenticationView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                
            case .authenticatedAwaitingProfile:
                // Show profile selection view
                ProfileSelectionView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                
            case .fullyAuthenticated(let profile):
                // Show main app with role-based interface - use the one from screentimeApp.swift
                MainAppView(profile: profile)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: familyAuth.authenticationState)
        .onAppear {
            // The service will automatically restore session if available
        }
    }
}

// MARK: - Welcome Header
struct WelcomeHeader: View {
    let profile: FamilyProfile
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(profile.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: profile.isParent ? "shield.checkered" : "star.fill")
                            .font(.caption)
                            .foregroundColor(profile.isParent ? .blue : .green)
                        
                        Text(profile.displayRole)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Profile Avatar
                ZStack {
                    Circle()
                        .fill(profile.isParent ? Color.blue.gradient : Color.green.gradient)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: profile.isParent ? "person.fill.checkmark" : "person.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            }
        }
    }
}

// MARK: - Parent Dashboard Content
struct ParentDashboardContent: View {
    var body: some View {
        VStack(spacing: 20) {
            // Family Overview Card
            DashboardCard(
                title: "Family Overview",
                icon: "person.2.fill",
                color: .blue
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Manage your family's screen time and app usage")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("Total screen time today: 4h 32m")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundColor(.green)
                        Text("3 apps currently restricted")
                            .font(.caption)
                    }
                }
            }
            
            // Quick Actions
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FamilyQuickActionCard(
                    title: "Add Child",
                    icon: "person.badge.plus",
                    color: .green
                ) {
                    // Action to add child
                }
                
                FamilyQuickActionCard(
                    title: "App Limits",
                    icon: "app.badge",
                    color: .orange
                ) {
                    // Action to manage app limits
                }
                
                FamilyQuickActionCard(
                    title: "Time Reports",
                    icon: "chart.bar.fill",
                    color: .purple
                ) {
                    // Action to view reports
                }
                
                FamilyQuickActionCard(
                    title: "Family Settings",
                    icon: "gearshape.2.fill",
                    color: .blue
                ) {
                    // Action to manage settings
                }
            }
        }
    }
}

// MARK: - Child Dashboard Content
struct ChildDashboardContent: View {
    var body: some View {
        VStack(spacing: 20) {
            // Today's Progress Card
            DashboardCard(
                title: "Today's Progress",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Keep up the great work!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.green)
                        Text("Screen time: 2h 15m / 3h limit")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Earned 45 minutes extra time")
                            .font(.caption)
                    }
                }
            }
            
            // Available Apps
            DashboardCard(
                title: "Available Apps",
                icon: "app.fill",
                color: .blue
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Apps you can use right now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(0..<8) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.gray.opacity(0.2))
                                .frame(height: 40)
                                .overlay {
                                    Image(systemName: "app")
                                        .foregroundColor(.secondary)
                                }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Dashboard Card
struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - Family Quick Action Card (renamed to avoid conflicts)
struct FamilyQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    FamilyAuthCoordinator()
} 