import SwiftUI

struct ChildDetailView: View {
    // MARK: - Properties
    @ObservedObject var child: User
    
    // MARK: - State
    @State private var showEditLimits = false
    @State private var showApprovedApps = false
    @State private var showAddTime = false
    @State private var additionalMinutes: Int32 = 30
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    var body: some View {
        List {
            // Screen Time Section
            Section(header: Text("Screen Time")) {
                if let balance = child.screenTimeBalance {
                    HStack {
                        Text("Time Remaining")
                        Spacer()
                        Text(balance.formattedTimeRemaining)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Daily Limit")
                        Spacer()
                        Text("\(balance.dailyLimit) minutes")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Weekly Limit")
                        Spacer()
                        Text("\(balance.weeklyLimit) minutes")
                            .foregroundColor(.secondary)
                    }
                    
                    if balance.isTimerActive {
                        HStack {
                            Text("Timer Active")
                            Spacer()
                            Image(systemName: "hourglass")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            
            // Tasks Section
            Section(header: Text("Tasks")) {
                NavigationLink(destination: TaskListView()) {
                    HStack {
                        Text("View Tasks")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Actions Section
            Section(header: Text("Actions")) {
                Button(action: { showAddTime = true }) {
                    Label("Add Time", systemImage: "plus.circle")
                }
                
                Button(action: { showEditLimits = true }) {
                    Label("Edit Limits", systemImage: "clock")
                }
                
                Button(action: { showApprovedApps = true }) {
                    Label("Approved Apps", systemImage: "app.badge.checkmark")
                }
            }
        }
        .navigationTitle(child.name)
        .sheet(isPresented: $showEditLimits) {
            EditLimitsView(child: child)
        }
        .sheet(isPresented: $showApprovedApps) {
            ApprovedAppsView(child: child)
        }
        .sheet(isPresented: $showAddTime) {
            AddTimeView(minutes: $additionalMinutes) {
                addTime()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    private func addTime() {
        guard let balance = child.screenTimeBalance,
              let childEmail = child.email else { return }
        
        _Concurrency.Task {
            do {
                // Verify parent authorization
                guard try await AuthenticationService.shared.authorizeParentAction() else {
                    throw AuthenticationService.AuthError.unauthorized
                }
                
                // Add time
                balance.addTime(additionalMinutes)
                try CoreDataManager.shared.save()
                
                // Notify SharedDataManager
                SharedDataManager.shared.updateScreenTime(forChildEmail: childEmail, minutes: balance.availableMinutes)
                
                await MainActor.run {
                    showAddTime = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Edit Limits View
struct EditLimitsView: View {
    // MARK: - Properties
    @ObservedObject var child: User
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var dailyLimit: Int32
    @State private var weeklyLimit: Int32
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(child: User) {
        self.child = child
        _dailyLimit = State(initialValue: child.screenTimeBalance?.dailyLimit ?? 120)
        _weeklyLimit = State(initialValue: child.screenTimeBalance?.weeklyLimit ?? 840)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Time Limits")) {
                    Stepper(
                        "Daily Limit: \(dailyLimit) minutes",
                        value: $dailyLimit,
                        in: 0...1440,
                        step: 30
                    )
                    
                    Stepper(
                        "Weekly Limit: \(weeklyLimit) minutes",
                        value: $weeklyLimit,
                        in: 0...10080,
                        step: 60
                    )
                }
            }
            .navigationTitle("Edit Limits")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { saveLimits() }
            )
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Actions
    private func saveLimits() {
        guard let balance = child.screenTimeBalance else { return }
        
        _Concurrency.Task {
            do {
                // Verify parent authorization
                guard try await AuthenticationService.shared.authorizeParentAction() else {
                    throw AuthenticationService.AuthError.unauthorized
                }
                
                // Update limits
                balance.dailyLimit = dailyLimit
                balance.weeklyLimit = weeklyLimit
                try CoreDataManager.shared.save()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Add Time View
struct AddTimeView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @Binding var minutes: Int32
    let onAdd: () -> Void
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add Time")) {
                    Stepper(
                        "Add \(minutes) minutes",
                        value: .init(
                            get: { Int(minutes) },
                            set: { minutes = Int32($0) }
                        ),
                        in: 15...120,
                        step: 15
                    )
                }
            }
            .navigationTitle("Add Screen Time")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    onAdd()
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Preview
struct ChildDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChildDetailView(child: User())
        }
    }
} 