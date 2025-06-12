import Foundation

/// Family profile model for the new single-auth family system
struct FamilyProfile: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let authUserId: UUID
    var name: String
    let role: ProfileRole
    let createdAt: Date
    var updatedAt: Date
    var emailVerified: Bool
    
    // MARK: - Profile Role
    enum ProfileRole: String, Codable, CaseIterable {
        case parent, child
        
        var displayName: String {
            switch self {
            case .parent: return "Parent"
            case .child: return "Child"
            }
        }
        
        var isParent: Bool {
            return self == .parent
        }
        
        var canManageFamily: Bool {
            return self == .parent
        }
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case name
        case role
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case emailVerified = "email_verified"
    }
    
    // MARK: - Initializers
    
    /// Create a new family profile
    init(id: UUID = UUID(), authUserId: UUID, name: String, role: ProfileRole, emailVerified: Bool = false) {
        self.id = id
        self.authUserId = authUserId
        self.name = name
        self.role = role
        self.createdAt = Date()
        self.updatedAt = Date()
        self.emailVerified = emailVerified
    }
    
    /// Full initializer for database loading
    init(id: UUID, authUserId: UUID, name: String, role: ProfileRole, createdAt: Date, updatedAt: Date, emailVerified: Bool) {
        self.id = id
        self.authUserId = authUserId
        self.name = name
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.emailVerified = emailVerified
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        authUserId = try container.decode(UUID.self, forKey: .authUserId)
        name = try container.decode(String.self, forKey: .name)
        role = try container.decode(ProfileRole.self, forKey: .role)
        createdAt = try container.decodeDate(forKey: .createdAt)
        updatedAt = try container.decodeDate(forKey: .updatedAt)
        emailVerified = try container.decodeIfPresent(Bool.self, forKey: .emailVerified) ?? false
    }
    
    // MARK: - Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(authUserId, forKey: .authUserId)
        try container.encode(name, forKey: .name)
        try container.encode(role, forKey: .role)
        try container.encodeDate(createdAt, forKey: .createdAt)
        try container.encodeDate(updatedAt, forKey: .updatedAt)
        try container.encode(emailVerified, forKey: .emailVerified)
    }
    
    // MARK: - Validation
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyName
        }
        
        guard name.count <= 100 else {
            throw ValidationError.nameTooLong
        }
    }
    
    enum ValidationError: LocalizedError {
        case emptyName
        case nameTooLong
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "Profile name cannot be empty"
            case .nameTooLong:
                return "Profile name cannot exceed 100 characters"
            }
        }
    }
    
    // MARK: - Mutation Methods
    func updatingName(_ newName: String) -> FamilyProfile {
        var updated = self
        updated.name = newName
        updated.updatedAt = Date()
        return updated
    }
    
    // MARK: - Convenience Properties
    var isParent: Bool {
        return role.isParent
    }
    
    var canManageFamily: Bool {
        return role.canManageFamily
    }
    
    var displayRole: String {
        return role.displayName
    }
}

// MARK: - Hashable & Equatable
extension FamilyProfile {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FamilyProfile, rhs: FamilyProfile) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Mock Data
extension FamilyProfile {
    static func mock(
        name: String = "Test User",
        role: ProfileRole = .child,
        authUserId: UUID = UUID()
    ) -> FamilyProfile {
        FamilyProfile(
            id: UUID(),
            authUserId: authUserId,
            name: name,
            role: role
        )
    }
    
    static let mockParent = FamilyProfile(
        id: UUID(),
        authUserId: UUID(),
        name: "John Parent",
        role: .parent
    )
    
    static let mockChild = FamilyProfile(
        id: UUID(),
        authUserId: UUID(),
        name: "Jane Child",
        role: .child
    )
    
    static func mockFamily(parentName: String = "Parent", childNames: [String] = ["Child 1", "Child 2"]) -> [FamilyProfile] {
        let authUserId = UUID()
        var profiles: [FamilyProfile] = []
        
        // Add parent
        profiles.append(FamilyProfile(
            id: UUID(),
            authUserId: authUserId,
            name: parentName,
            role: .parent
        ))
        
        // Add children
        for childName in childNames {
            profiles.append(FamilyProfile(
                id: UUID(),
                authUserId: authUserId,
                name: childName,
                role: .child
            ))
        }
        
        return profiles
    }
}

// MARK: - Date Coding Helpers
private extension KeyedDecodingContainer {
    func decodeDate(forKey key: Key) throws -> Date {
        // Try ISO8601 format first (Supabase default)
        if let dateString = try? decode(String.self, forKey: key) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to standard ISO8601 without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // Fallback to direct Date decoding
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