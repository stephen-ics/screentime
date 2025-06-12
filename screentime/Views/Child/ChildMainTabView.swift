import SwiftUI

struct ChildMainTabView: View {
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            ChildDashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Tasks Tab
            ChildTaskListView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "star.fill" : "star")
                    Text("Tasks")
                }
                .tag(1)
            
            // Accounts Tab (Profile)
            ChildProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.crop.circle.fill" : "person.crop.circle")
                    Text("Accounts")
                }
                .tag(2)
        }
        .accentColor(DesignSystem.Colors.childAccent)
        .onAppear {
            // Customize tab bar appearance for child-friendly design
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Make tab bar more colorful for children
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(DesignSystem.Colors.childAccent)
            ]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DesignSystem.Colors.childAccent)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Preview
struct ChildMainTabView_Previews: PreviewProvider {
    static var previews: some View {
        ChildMainTabView()
            .environmentObject(FamilyAuthService.shared)
    }
} 