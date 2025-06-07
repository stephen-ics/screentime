import SwiftUI

struct ChildDetailView: View {
    let child: Profile
    @StateObject private var viewModel = ChildDetailViewModel()
    @State private var dailyLimit: Int = 120 // Default 2 hours
    @State private var weeklyLimit: Int = 840 // Default 14 hours
    @State private var showingEditLimits = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Child profile header
                    childProfileHeader
                    
                    // Screen time overview
                    screenTimeOverview
                    
                    // Tasks section
                    tasksSection
                    
                    // Quick actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle(child.name)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadChild(child)
            }
        }
        .sheet(isPresented: $showingEditLimits) {
            EditLimitsView(dailyLimit: $dailyLimit, weeklyLimit: $weeklyLimit)
        }
        .alert("Action Complete", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Child Profile Header
    private var childProfileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(LinearGradient.childGradient)
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(child.name.prefix(1)).uppercased())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 4) {
                Text(child.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(child.userType == .child ? "Child Account" : "Parent Account")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Screen Time Overview
    private var screenTimeOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Screen Time Today")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Daily Limit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(dailyLimit) min")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button("Edit Limits") {
                    showingEditLimits = true
                }
                .buttonStyle(.bordered)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Tasks Section
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assigned Tasks")
                .font(.headline)
            
            if viewModel.tasks.isEmpty {
                Text("No tasks assigned")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.tasks, id: \.id) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if let description = task.taskDescription {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(task.rewardMinutes) min")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            Button("Grant 30 Minutes") {
                grantAdditionalTime(30)
            }
            .primaryButtonStyle()
            
            Button("Remove 15 Minutes") {
                removeTime(15)
            }
            .secondaryButtonStyle()
        }
        .cardStyle()
    }
    
    // MARK: - Actions
    private func grantAdditionalTime(_ minutes: Int) {
        // TODO: Implement with Supabase services
        alertMessage = "Granted \(minutes) minutes of additional screen time"
        showingAlert = true
    }
    
    private func removeTime(_ minutes: Int) {
        // TODO: Implement with Supabase services
        alertMessage = "Removed \(minutes) minutes of screen time"
        showingAlert = true
    }
}

// MARK: - Child Detail View Model
@MainActor
final class ChildDetailViewModel: ObservableObject {
    @Published var tasks: [SupabaseTask] = []
    @Published var screenTimeBalance: SupabaseScreenTimeBalance?
    @Published var isLoading = false
    
    func loadChild(_ child: Profile) {
        // TODO: Load child data from Supabase
        isLoading = true
        
        // Mock data for now
        tasks = []
        
        isLoading = false
    }
}

// MARK: - Edit Limits View
struct EditLimitsView: View {
    @Binding var dailyLimit: Int
    @Binding var weeklyLimit: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Daily Limit") {
                    Stepper("\(dailyLimit) minutes", value: $dailyLimit, in: 30...480, step: 15)
                }
                
                Section("Weekly Limit") {
                    Stepper("\(weeklyLimit) minutes", value: $weeklyLimit, in: 210...3360, step: 30)
                }
            }
            .navigationTitle("Edit Limits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // TODO: Save limits with Supabase
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews
struct ChildDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ChildDetailView(child: Profile.mockChild)
    }
} 