import SwiftUI
import CoreData

struct TaskListView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Fetch Request
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)],
        animation: .default
    ) private var tasks: FetchedResults<Task>
    
    // MARK: - Body
    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskRowView(task: task)
            }
            .onDelete(perform: deleteTasks)
        }
        .listStyle(InsetGroupedListStyle())
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(task.title)
                    .font(.headline)
                
                Spacer()
                
                if task.isCompleted {
                    Image(systemName: task.isApproved ? "checkmark.circle.fill" : "clock.fill")
                        .foregroundColor(task.isApproved ? .green : .orange)
                }
            }
            
            if let description = task.taskDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let assignedTo = task.assignedTo {
                    Label(assignedTo.name, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(task.rewardMinutes) min")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
} 