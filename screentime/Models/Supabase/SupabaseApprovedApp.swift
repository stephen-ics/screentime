import Foundation

/// Approved app model for Supabase backend
final class SupabaseApprovedApp: Codable, Identifiable, Hashable, Sendable, ObservableObject {
    let id: UUID
    let createdAt: Date
    @Published var updatedAt: Date
    var name: String
    var bundleIdentifier: String
    var isEnabled: Bool
    var dailyLimitSeconds: Double
    let userId: UUID
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case name
        case bundleIdentifier = "bundle_identifier"
        case isEnabled = "is_enabled"
        case dailyLimitSeconds = "daily_limit_seconds"
        case userId = "user_id"
    }
    
    // MARK: - Computed Properties
    var dailyLimitMinutes: Int32?
    
    var formattedDailyLimit: String {
        guard dailyLimitSeconds > 0 else {
            return NSLocalizedString("No limit", comment: "")
        }
        
        let totalMinutes = Int(dailyLimitSeconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return String(format: NSLocalizedString("%dh %dm daily", comment: ""), hours, minutes)
        } else {
            return String(format: NSLocalizedString("%dm daily", comment: ""), minutes)
        }
    }
    
    var displayName: String {
        name.isEmpty ? bundleIdentifier : name
    }
    
    var statusDescription: String {
        if !isEnabled {
            return NSLocalizedString("Disabled", comment: "")
        } else if dailyLimitSeconds > 0 {
            return formattedDailyLimit
        } else {
            return NSLocalizedString("Unlimited", comment: "")
        }
    }
    
    // MARK: - Initializers
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        name: String,
        bundleIdentifier: String,
        isEnabled: Bool = true,
        dailyLimitSeconds: Double = 0,
        userId: UUID
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.isEnabled = isEnabled
        self.dailyLimitSeconds = dailyLimitSeconds
        self.userId = userId
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decodeDate(forKey: .createdAt)
        updatedAt = try container.decodeDate(forKey: .updatedAt)
        name = try container.decode(String.self, forKey: .name)
        bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        dailyLimitSeconds = try container.decode(Double.self, forKey: .dailyLimitSeconds)
        userId = try container.decode(UUID.self, forKey: .userId)
    }
    
    // MARK: - Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeDate(createdAt, forKey: .createdAt)
        try container.encodeDate(updatedAt, forKey: .updatedAt)
        try container.encode(name, forKey: .name)
        try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(dailyLimitSeconds, forKey: .dailyLimitSeconds)
        try container.encode(userId, forKey: .userId)
    }
    
    // MARK: - Validation
    func validate() throws {
        guard !bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyBundleIdentifier
        }
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyAppName
        }
        
        guard name.count <= 100 else {
            throw ValidationError.appNameTooLong
        }
        
        guard bundleIdentifier.count <= 200 else {
            throw ValidationError.bundleIdentifierTooLong
        }
        
        guard dailyLimitSeconds >= 0 else {
            throw ValidationError.invalidDailyLimit
        }
        
        // Validate bundle identifier format (basic validation)
        guard bundleIdentifier.contains(".") else {
            throw ValidationError.invalidBundleIdentifierFormat
        }
    }
    
    enum ValidationError: LocalizedError {
        case emptyBundleIdentifier
        case emptyAppName
        case appNameTooLong
        case bundleIdentifierTooLong
        case invalidDailyLimit
        case invalidBundleIdentifierFormat
        
        var errorDescription: String? {
            switch self {
            case .emptyBundleIdentifier:
                return NSLocalizedString("Bundle identifier cannot be empty", comment: "")
            case .emptyAppName:
                return NSLocalizedString("App name cannot be empty", comment: "")
            case .appNameTooLong:
                return NSLocalizedString("App name cannot exceed 100 characters", comment: "")
            case .bundleIdentifierTooLong:
                return NSLocalizedString("Bundle identifier cannot exceed 200 characters", comment: "")
            case .invalidDailyLimit:
                return NSLocalizedString("Daily limit must be greater than or equal to 0", comment: "")
            case .invalidBundleIdentifierFormat:
                return NSLocalizedString("Invalid bundle identifier format", comment: "")
            }
        }
    }
    
    // MARK: - App Management Methods
    func enable() {
        isEnabled = true
        updatedAt = Date()
    }
    
    func disable() {
        isEnabled = false
        updatedAt = Date()
    }
    
    func setDailyLimit(minutes: Int32) {
        dailyLimitSeconds = Double(minutes * 60)
        updatedAt = Date()
    }
    
    func removeDailyLimit() {
        dailyLimitSeconds = 0
        updatedAt = Date()
    }
    
    func updateName(_ newName: String) {
        name = newName
        updatedAt = Date()
    }
}

// MARK: - Hashable
extension SupabaseApprovedApp {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Equatable
extension SupabaseApprovedApp {
    static func == (lhs: SupabaseApprovedApp, rhs: SupabaseApprovedApp) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Mock Data
extension SupabaseApprovedApp {
    static func mock(
        name: String = "YouTube",
        bundleIdentifier: String = "com.google.ios.youtube",
        dailyLimitMinutes: Int32 = 60,
        userId: UUID = UUID()
    ) -> SupabaseApprovedApp {
        SupabaseApprovedApp(
            name: name,
            bundleIdentifier: bundleIdentifier,
            dailyLimitSeconds: Double(dailyLimitMinutes * 60),
            userId: userId
        )
    }
    
    static func mockApps(userId: UUID = UUID()) -> [SupabaseApprovedApp] {
        [
            .mock(name: "YouTube", bundleIdentifier: "com.google.ios.youtube", dailyLimitMinutes: 60, userId: userId),
            .mock(name: "Instagram", bundleIdentifier: "com.burbn.instagram", dailyLimitMinutes: 45, userId: userId),
            .mock(name: "TikTok", bundleIdentifier: "com.zhiliaoapp.musically", dailyLimitMinutes: 30, userId: userId),
            .mock(name: "Minecraft", bundleIdentifier: "com.mojang.minecraftpe", dailyLimitMinutes: 90, userId: userId),
            .mock(name: "Roblox", bundleIdentifier: "com.roblox.robloxmobile", dailyLimitMinutes: 75, userId: userId)
        ]
    }
}

// MARK: - App Category (computed from bundle identifier)
extension SupabaseApprovedApp {
    enum AppCategory: String, CaseIterable {
        case social = "Social"
        case games = "Games"
        case entertainment = "Entertainment"
        case education = "Education"
        case productivity = "Productivity"
        case other = "Other"
        
        var displayName: String {
            switch self {
            case .social:
                return NSLocalizedString("Social", comment: "")
            case .games:
                return NSLocalizedString("Games", comment: "")
            case .entertainment:
                return NSLocalizedString("Entertainment", comment: "")
            case .education:
                return NSLocalizedString("Education", comment: "")
            case .productivity:
                return NSLocalizedString("Productivity", comment: "")
            case .other:
                return NSLocalizedString("Other", comment: "")
            }
        }
        
        var systemImageName: String {
            switch self {
            case .social:
                return "person.2.fill"
            case .games:
                return "gamecontroller.fill"
            case .entertainment:
                return "tv.fill"
            case .education:
                return "book.fill"
            case .productivity:
                return "briefcase.fill"
            case .other:
                return "app.fill"
            }
        }
    }
    
    var category: AppCategory {
        let identifier = bundleIdentifier.lowercased()
        
        // Social apps
        if identifier.contains("instagram") || 
           identifier.contains("facebook") || 
           identifier.contains("snapchat") || 
           identifier.contains("twitter") || 
           identifier.contains("discord") ||
           identifier.contains("whatsapp") {
            return .social
        }
        
        // Games
        if identifier.contains("minecraft") || 
           identifier.contains("roblox") || 
           identifier.contains("fortnite") || 
           identifier.contains("game") ||
           identifier.contains("mojang") {
            return .games
        }
        
        // Entertainment
        if identifier.contains("youtube") || 
           identifier.contains("netflix") || 
           identifier.contains("tiktok") || 
           identifier.contains("spotify") ||
           identifier.contains("musically") {
            return .entertainment
        }
        
        // Education
        if identifier.contains("khan") || 
           identifier.contains("duolingo") || 
           identifier.contains("education") ||
           identifier.contains("school") {
            return .education
        }
        
        // Productivity
        if identifier.contains("office") || 
           identifier.contains("microsoft") || 
           identifier.contains("google") ||
           identifier.contains("apple") {
            return .productivity
        }
        
        return .other
    }
}

// MARK: - Date Coding Helpers
private extension KeyedDecodingContainer {
    func decodeDate(forKey key: Key) throws -> Date {
        if let dateString = try? decode(String.self, forKey: key) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return try decode(Date.self, forKey: key)
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeDate(_ date: Date, forKey key: Key) throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)
        try encode(dateString, forKey: key)
    }
} 