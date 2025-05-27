import SwiftUI

// MARK: - Change Password View
struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        Form {
            Section(header: Text("Current Password")) {
                SecureField("Enter current password", text: $currentPassword)
            }
            
            Section(header: Text("New Password")) {
                SecureField("Enter new password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
            }
            
            Section(footer: Text("Password must be at least 8 characters long and contain a mix of letters and numbers.")) {
                Button(action: {}) {
                    Text("Update Password")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
            }
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Connected Accounts View
struct ConnectedAccountsView: View {
    var body: some View {
        List {
            Section(header: Text("Available Connections")) {
                ConnectedAccountRow(
                    provider: "Apple",
                    icon: "apple.logo",
                    isConnected: false
                )
                
                ConnectedAccountRow(
                    provider: "Google",
                    icon: "g.circle.fill",
                    isConnected: false
                )
                
                ConnectedAccountRow(
                    provider: "Facebook",
                    icon: "f.circle.fill",
                    isConnected: false
                )
            }
        }
        .navigationTitle("Connected Accounts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ConnectedAccountRow: View {
    let provider: String
    let icon: String
    let isConnected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isConnected ? .green : .gray)
            
            Text(provider)
            
            Spacer()
            
            Button(action: {}) {
                Text(isConnected ? "Disconnect" : "Connect")
                    .font(.caption)
                    .foregroundColor(isConnected ? .red : .accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Two-Factor Authentication View
struct TwoFactorAuthView: View {
    @State private var isEnabled = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Two-Factor Authentication", isOn: $isEnabled)
            }
            
            if isEnabled {
                Section(header: Text("Authentication Methods")) {
                    NavigationLink(destination: EmptyView()) {
                        Label("SMS Authentication", systemImage: "message")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Authenticator App", systemImage: "lock.shield")
                    }
                }
                
                Section(header: Text("Backup Codes")) {
                    Button(action: {}) {
                        Label("Generate Backup Codes", systemImage: "key")
                    }
                }
            }
        }
        .navigationTitle("Two-Factor Authentication")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Login Activity View
struct LoginActivityView: View {
    var body: some View {
        List {
            Section(header: Text("Recent Activity")) {
                LoginActivityRow(
                    device: "iPhone 16 Pro",
                    location: "San Francisco, CA",
                    time: "2 minutes ago",
                    isCurrentDevice: true
                )
                
                LoginActivityRow(
                    device: "MacBook Pro",
                    location: "San Francisco, CA",
                    time: "1 hour ago",
                    isCurrentDevice: false
                )
                
                LoginActivityRow(
                    device: "iPad Air",
                    location: "San Francisco, CA",
                    time: "Yesterday",
                    isCurrentDevice: false
                )
            }
        }
        .navigationTitle("Login Activity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LoginActivityRow: View {
    let device: String
    let location: String
    let time: String
    let isCurrentDevice: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(device)
                    .font(.headline)
                if isCurrentDevice {
                    Text("Current")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Image(systemName: "location")
                    .font(.caption)
                Text(location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Security Alerts View
struct SecurityAlertsView: View {
    var body: some View {
        List {
            Section(header: Text("Recent Alerts")) {
                SecurityAlertRow(
                    title: "New Login from Unknown Device",
                    description: "A new device logged into your account",
                    time: "2 hours ago",
                    severity: .warning
                )
                
                SecurityAlertRow(
                    title: "Password Changed",
                    description: "Your password was successfully updated",
                    time: "3 days ago",
                    severity: .info
                )
            }
        }
        .navigationTitle("Security Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SecurityAlertRow: View {
    let title: String
    let description: String
    let time: String
    let severity: AlertSeverity
    
    enum AlertSeverity {
        case info, warning, critical
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: severity.icon)
                .foregroundColor(severity.color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Language Preferences View
struct LanguagePreferencesView: View {
    @AppStorage("app.language") private var selectedLanguage = "en"
    @AppStorage("app.region") private var selectedRegion = "US"
    
    var body: some View {
        Form {
            Section(header: Text("Language")) {
                Picker("Language", selection: $selectedLanguage) {
                    Text("English").tag("en")
                    Text("Spanish").tag("es")
                    Text("French").tag("fr")
                    Text("German").tag("de")
                    Text("Chinese").tag("zh")
                    Text("Japanese").tag("ja")
                }
            }
            
            Section(header: Text("Region")) {
                Picker("Region", selection: $selectedRegion) {
                    Text("United States").tag("US")
                    Text("United Kingdom").tag("UK")
                    Text("Canada").tag("CA")
                    Text("Australia").tag("AU")
                    Text("Europe").tag("EU")
                }
            }
        }
        .navigationTitle("Language & Region")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Appearance Preferences View
struct AppearancePreferencesView: View {
    @AppStorage("app.theme") private var selectedTheme = "system"
    @AppStorage("app.accentColor") private var accentColor = "blue"
    
    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Picker("Appearance", selection: $selectedTheme) {
                    Label("System", systemImage: "iphone").tag("system")
                    Label("Light", systemImage: "sun.max").tag("light")
                    Label("Dark", systemImage: "moon").tag("dark")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Accent Color")) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                    ForEach(["blue", "purple", "pink", "red", "orange", "yellow", "green", "teal"], id: \.self) { color in
                        Circle()
                            .fill(Color(color))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: accentColor == color ? 3 : 0)
                            )
                            .onTapGesture {
                                accentColor = color
                            }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data Management View
struct DataManagementView: View {
    @State private var showExportOptions = false
    
    var body: some View {
        List {
            Section(header: Text("Export Your Data")) {
                Button(action: { showExportOptions = true }) {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }
                
                NavigationLink(destination: EmptyView()) {
                    Label("Select Data to Export", systemImage: "checklist")
                }
            }
            
            Section(header: Text("Data Storage")) {
                HStack {
                    Text("Storage Used")
                    Spacer()
                    Text("124 MB")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Documents")
                    Spacer()
                    Text("12 MB")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Cache")
                    Spacer()
                    Text("112 MB")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .actionSheet(isPresented: $showExportOptions) {
            ActionSheet(
                title: Text("Export Format"),
                message: Text("Choose how you'd like to export your data"),
                buttons: [
                    .default(Text("JSON Format")) {},
                    .default(Text("CSV Format")) {},
                    .default(Text("PDF Report")) {},
                    .cancel()
                ]
            )
        }
    }
}

// MARK: - Data Export View
struct DataExportView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.zipper")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Export Your Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Download a copy of all your Screen Time Manager data including tasks, screen time history, and account information.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {}) {
                Label("Start Export", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
        .navigationTitle("Data Export")
        .navigationBarTitleDisplayMode(.inline)
    }
} 