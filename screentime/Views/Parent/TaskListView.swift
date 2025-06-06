import SwiftUI
import CoreData

struct TaskListView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: AppRouter
    
    // MARK: - Fetch Request
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)],
        animation: .default
    ) private var tasks: FetchedResults<Task>
    
    // MARK: - Body
    var body: some View {
        ZStack {
            DesignSystem.Colors.groupedBackground
                .ignoresSafeArea()
            
            if tasks.isEmpty {
                emptyState
            } else {
                tasksList
            }
        }
        .refreshable {
            // Refresh data if needed
        }
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "checklist")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                
                Text("No Tasks Yet")
                    .font(DesignSystem.Typography.title1)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Create tasks for your children to earn screen time by completing activities")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.large)
            }
            
            Button(action: { router.presentSheet(.addTask) }) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Create First Task")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: true))
            .frame(maxWidth: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxxLarge)
    }
    
    // MARK: - Tasks List
    
    @ViewBuilder
    private var tasksList: some View {
        List {
            Section {
                ForEach(tasks) { task in
                    TaskRowView(task: task)
                }
                .onDelete(perform: deleteTasks)
            } header: {
                HStack {
                    Text("Active Tasks")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(tasks.count) task\(tasks.count == 1 ? "" : "s")")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Actions
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { tasks[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete tasks: \(error)")
            }
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    @ObservedObject var task: Task
    
    var body: some View {
        BaseCard(style: .compact) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                // Header
                HStack {
                    Text(task.title)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    statusIcon
                }
                
                // Description
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                // Footer
                HStack(spacing: DesignSystem.Spacing.medium) {
                    // Assigned child
                    if let assignedTo = task.assignedTo {
                        HStack(spacing: DesignSystem.Spacing.xSmall) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(DesignSystem.Colors.primaryBlue)
                            
                            Text(assignedTo.name)
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Reward
                    HStack(spacing: DesignSystem.Spacing.xSmall) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.success)
                        
                        Text("\(task.rewardMinutes) min")
                            .font(DesignSystem.Typography.caption1)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets(
            top: DesignSystem.Spacing.small,
            leading: 0,
            bottom: DesignSystem.Spacing.small,
            trailing: 0
        ))
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        if task.isCompleted {
            Image(systemName: task.isApproved ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(task.isApproved ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
        } else {
            Image(systemName: "circle.dashed")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
    }
}

// MARK: - Preview
struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}

// MARK: - Reports View (Placeholder)
struct ReportsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Reports")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Detailed analytics and reports will be available in a future update.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reports")
        }
    }
} 