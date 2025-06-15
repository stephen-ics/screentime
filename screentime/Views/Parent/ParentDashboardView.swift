import SwiftUI
import Combine
import _Concurrency

/// Main parent dashboard view with proper MVVM architecture and dependency injection
struct ParentDashboardView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @EnvironmentObject private var router: AppRouter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - State Objects
    @StateObject private var viewModel = ParentDashboardViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            if horizontalSizeClass == .regular {
                // iPad layout
                VStack(spacing: 20) {
                    welcomeHeader
                    
                    HStack(alignment: .top, spacing: 20) {
                        quickActionsSection
                        recentActivitySection
                    }
                }
                .padding()
            } else {
                // iPhone layout
                VStack(spacing: 20) {
                    welcomeHeader
                    quickActionsSection
                    recentActivitySection
                    Spacer(minLength: 24)
                }
                .padding()
            }
        }
        .navigationTitle("Family Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SecureChildInterface.SecureSettingsButton {
                    // Handle settings
                }
            }
        }
        .onAppear {
            viewModel.updateRouter(router)
        }
    }

    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let currentProfile = familyAuth.currentProfile {
                        Text(currentProfile.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Parent Account")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Profile Avatar
                if let currentProfile = familyAuth.currentProfile {
                    ZStack {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 60, height: 60)
                        
                        Text(String(currentProfile.name.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(QuickAction.allCases) { action in
                    QuickActionCard(
                        action: action,
                        count: action == .timeRequests ? viewModel.state.pendingRequestsCount : nil,
                        onTap: { viewModel.handleQuickAction(action) }
                    )
                }
            }
        }
    }

    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to full activity view
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 16) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                
                Text("No recent activity")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Activity will appear here once your children start using the app")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(.regularMaterial)
            .cornerRadius(16)
        }
    }
}

// MARK: - Preview
struct ParentDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ParentDashboardView()
            .environmentObject(AppRouter())
            .environmentObject(FamilyAuthService.shared)
    }
} 