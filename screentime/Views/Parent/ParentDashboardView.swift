import SwiftUI
import Combine
import _Concurrency

/// Main parent dashboard view with proper MVVM architecture and dependency injection
struct ParentDashboardView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @EnvironmentObject private var router: AppRouter
    
    // MARK: - State Objects
    @StateObject private var viewModel = ParentDashboardViewModel()
    
    // MARK: - State
    @State private var showingAddChild = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Welcome Header
                welcomeHeader
                
                // Quick Actions
                quickActionsSection
                
                // Recent Activity Placeholder
                recentActivitySection
                
                Spacer(minLength: 20)
            }
            .padding()
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
        .sheet(isPresented: $showingAddChild) {
            AddChildProfileSheet()
                .environmentObject(familyAuth)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Activity will appear here once your children start using the app")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(.regularMaterial)
            .cornerRadius(12)
        }
    }
}

// MARK: - Quick Action Card
struct NewQuickActionCard: View {
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
            .background(.regularMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
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