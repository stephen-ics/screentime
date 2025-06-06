import SwiftUI

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

// MARK: - Connected Accounts View  
struct ConnectedAccountsView: View {
    var body: some View {
        List {
            Section(header: Text("Connected Accounts")) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Google")
                        Text("Not connected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Connect") {
                        // Connect Google account
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    Image(systemName: "applelogo")
                        .foregroundColor(.black)
                    VStack(alignment: .leading) {
                        Text("Apple")
                        Text("Not connected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Connect") {
                        // Connect Apple account
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Connected Accounts")
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
        .padding()
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
} 