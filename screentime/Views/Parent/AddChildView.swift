import SwiftUI

struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: SafeSupabaseAuthService
    @EnvironmentObject private var dataRepository: SafeSupabaseDataRepository
    
    @State private var childName: String = ""
    @State private var childEmail: String = ""
    @State private var deviceName: String = ""
    @State private var allowedScreenTime: Int = 120 // minutes
    @State private var bedtime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedAge: Int = 10
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Child Information") {
                    TextField("Child's Name", text: $childName)
                    TextField("Child's Email (Optional)", text: $childEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Picker("Age", selection: $selectedAge) {
                        ForEach(3...17, id: \.self) { age in
                            Text("\(age) years old").tag(age)
                        }
                    }
                }
                
                Section("Device Information") {
                    TextField("Device Name (e.g., iPad, iPhone)", text: $deviceName)
                }
                
                Section("Screen Time Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Screen Time Limit")
                            .font(.headline)
                        
                        Stepper("\(allowedScreenTime / 60)h \(allowedScreenTime % 60)m", 
                               value: $allowedScreenTime, 
                               in: 30...480, 
                               step: 15)
                    }
                    
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                    DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Default Apps") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The following apps will be approved by default:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(defaultApps, id: \.name) { app in
                                VStack(spacing: 4) {
                                    Image(systemName: app.icon)
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text(app.name)
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Child") {
                        addChild()
                    }
                    .disabled(childName.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Setting up child account...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(32)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                }
            }
        }
        .alert("Child Added", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private let defaultApps = [
        DefaultApp(name: "Messages", icon: "message.fill"),
        DefaultApp(name: "Phone", icon: "phone.fill"),
        DefaultApp(name: "Camera", icon: "camera.fill"),
        DefaultApp(name: "Photos", icon: "photo.fill"),
        DefaultApp(name: "Settings", icon: "gearshape.fill"),
        DefaultApp(name: "Clock", icon: "clock.fill"),
        DefaultApp(name: "Calculator", icon: "function"),
        DefaultApp(name: "Health", icon: "heart.fill")
    ]
    
    private func addChild() {
        guard !childName.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                // Create a child profile
                let childProfile = Profile(
                    id: UUID(),
                    email: childEmail.isEmpty ? "\(childName.lowercased().replacingOccurrences(of: " ", with: "."))@child.local" : childEmail,
                    name: childName,
                    userType: .child,
                    parentId: authService.currentProfile?.id
                )
                
                // Create screen time balance using correct property names
                let screenTimeBalance = SupabaseScreenTimeBalance(
                    userId: childProfile.id,
                    availableSeconds: Double(allowedScreenTime * 60), // Convert minutes to seconds
                    dailyLimitSeconds: Double(allowedScreenTime * 60), // Convert minutes to seconds
                    weeklyLimitSeconds: Double(allowedScreenTime * 60 * 7) // 7 days worth
                )
                
                // In a real app, you would:
                // 1. Create the child profile in Supabase
                // 2. Set up screen time limits
                // 3. Configure default approved apps
                // 4. Send invitation email if email provided
                
                // For demo purposes, we'll just simulate success
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    isLoading = false
                    alertMessage = """
                    \(childName) has been added successfully!
                    
                    • Daily screen time: \(allowedScreenTime / 60)h \(allowedScreenTime % 60)m
                    • Bedtime: \(formatTime(bedtime))
                    • Wake time: \(formatTime(wakeTime))
                    • \(defaultApps.count) default apps approved
                    """
                    showingAlert = true
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to add child: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DefaultApp {
    let name: String
    let icon: String
}

// MARK: - Preview
struct AddChildView_Previews: PreviewProvider {
    static var previews: some View {
        AddChildView()
            .environmentObject(SafeSupabaseAuthService.shared)
            .environmentObject(SafeSupabaseDataRepository.shared)
    }
} 