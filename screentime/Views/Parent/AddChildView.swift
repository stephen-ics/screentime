import SwiftUI

struct AddChildView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var familyAuth: FamilyAuthService
    
    @State private var childName: String = ""
    @State private var selectedAge: Int = 10
    @State private var allowedScreenTime: Int = 120 // minutes
    @State private var bedtime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Child Information") {
                    TextField("Child's Name", text: $childName)
                    
                    Picker("Age", selection: $selectedAge) {
                        ForEach(3...17, id: \.self) { age in
                            Text("\(age) years old").tag(age)
                        }
                    }
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
                        
                        Text("Creating child profile...")
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
                // Create child profile using FamilyAuthService
                try await familyAuth.createChildProfile(name: childName.trimmingCharacters(in: .whitespacesAndNewlines))
                
                await MainActor.run {
                    isLoading = false
                    alertMessage = """
                    \(childName) has been added successfully!
                    
                    • Daily screen time: \(allowedScreenTime / 60)h \(allowedScreenTime % 60)m
                    • Bedtime: \(formatTime(bedtime))
                    • Wake time: \(formatTime(wakeTime))
                    • \(defaultApps.count) default apps will be approved
                    
                    Note: Screen time settings and app management will be configured in the full app.
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
            .environmentObject(FamilyAuthService.shared)
    }
} 