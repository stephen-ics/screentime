import SwiftUI

struct TaskListView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataRepository = SupabaseDataRepository.shared
    @EnvironmentObject private var familyAuth: FamilyAuthService
    
    // MARK: - State
    @State private var tasks: [SupabaseTask] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddTask = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading tasks...")
                } else if tasks.isEmpty {
                    ContentUnavailableView(
                        "No Tasks",
                        systemImage: "checkmark.circle",
                        description: Text("Add tasks to help your child manage their screen time")
                    )
                } else {
                    List {
                        ForEach(tasks) { task in
                            TaskRow(task: task)
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            await loadTasks()
        }
    }
    
    // MARK: - Actions
    private func loadTasks() async {
        isLoading = true
        do {
            guard let currentProfile = familyAuth.currentProfile else {
                throw NSError(domain: "TaskListView", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current profile"])
            }
            tasks = try await dataRepository.getTasksCreatedBy(userId: currentProfile.authUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct TaskRow: View {
    let task: SupabaseTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.headline)
            
            if let desc = task.taskDescription, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label(task.statusDescription, systemImage: statusIcon)
                    .font(.caption)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                Text(task.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        if task.isCompleted {
            return task.isApproved ? "checkmark.circle" : "clock"
        } else {
            return "arrow.right.circle"
        }
    }
    
    private var statusColor: Color {
        if task.isCompleted {
            return task.isApproved ? .green : .orange
        } else {
            return .blue
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(FamilyAuthService.shared)
} 