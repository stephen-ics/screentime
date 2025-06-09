import Foundation

/// User profile model for Supabase backend
struct Profile: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var email: String
    var name: String
    var userType: UserType
    var isParent: Bool
    var emailVerified: Bool
    var createdAt: Date
    var updatedAt: Date
    var parentId: UUID?
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, name, email
        case userType = "user_type"
        case isParent = "is_parent"
        case emailVerified = "email_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case parentId = "parent_id"
    }
    
    // MARK: - User Type
    enum UserType: String, Codable, CaseIterable {
        case parent, child
        
        var displayName: String {
            switch self {
            case .parent:
                return "Parent"
            case .child:
                return "Child"
            }
        }
    }
    
    // MARK: - Initializers
    init(id: UUID, email: String, name: String, userType: UserType, parentId: UUID? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.userType = userType
        self.isParent = (userType == .parent)
        self.emailVerified = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.parentId = parentId
    }
    
    // Full initializer with all properties
    init(id: UUID, email: String, name: String, userType: UserType, emailVerified: Bool = false, parentId: UUID? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.userType = userType
        self.isParent = (userType == .parent)
        self.emailVerified = emailVerified
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt ?? Date()
        self.parentId = parentId
    }
    
    // Default initializer for previews and testing
    init() {
        self.id = UUID()
        self.email = "preview@example.com"
        self.name = "Preview User"
        self.userType = .child
        self.isParent = false
        self.emailVerified = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.parentId = nil
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        
        // Handle date decoding with multiple formats
        createdAt = try container.decodeDate(forKey: .createdAt)
        updatedAt = try container.decodeDate(forKey: .updatedAt)
        
        name = try container.decode(String.self, forKey: .name)
        userType = try container.decode(UserType.self, forKey: .userType)
        parentId = try container.decodeIfPresent(UUID.self, forKey: .parentId)
        email = try container.decode(String.self, forKey: .email)
        isParent = try container.decode(Bool.self, forKey: .isParent)
        emailVerified = try container.decode(Bool.self, forKey: .emailVerified)
    }
    
    // MARK: - Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeDate(createdAt, forKey: .createdAt)
        try container.encodeDate(updatedAt, forKey: .updatedAt)
        try container.encode(name, forKey: .name)
        try container.encode(userType, forKey: .userType)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encode(email, forKey: .email)
        try container.encode(isParent, forKey: .isParent)
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
                return NSLocalizedString("Name cannot be empty", comment: "")
            case .nameTooLong:
                return NSLocalizedString("Name cannot exceed 100 characters", comment: "")
            }
        }
    }
    
    // MARK: - Mutation Methods (for struct immutability)
    func updatingName(_ newName: String) -> Profile {
        var updated = self
        updated.name = newName
        updated.updatedAt = Date()
        return updated
    }
    
    func updatingEmail(_ newEmail: String) -> Profile {
        var updated = self
        updated.email = newEmail
        updated.updatedAt = Date()
        return updated
    }
}

// MARK: - Hashable
extension Profile {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Equatable
extension Profile {
    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Mock Data
extension Profile {
    static func mock(
        name: String = "Test User",
        userType: UserType = .child,
        parentId: UUID? = nil
    ) -> Profile {
        Profile(
            id: UUID(),
            email: "test@example.com",
            name: name,
            userType: userType,
            parentId: parentId
        )
    }
    
    static let mockParent = Profile(
        id: UUID(),
        email: "john@example.com",
        name: "John Parent",
        userType: .parent
    )
    
    static let mockChild = Profile(
        id: UUID(),
        email: "jane@example.com",
        name: "Jane Child",
        userType: .child
    )
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