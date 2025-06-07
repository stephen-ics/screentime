import Foundation

/// Time request model for Supabase backend
struct TimeRequest: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let childId: UUID
    let parentId: UUID
    var requestedSeconds: Double
    var status: Status
    var responseMessage: String?
    var respondedAt: Date?
    let childEmail: String
    let parentEmail: String
    let requestedMinutes: Int32
    let timestamp: Date
    var processedAt: Date?
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case childId = "child_id"
        case parentId = "parent_id"
        case requestedSeconds = "requested_seconds"
        case status
        case responseMessage = "response_message"
        case respondedAt = "responded_at"
        case childEmail = "child_email"
        case parentEmail = "parent_email"
        case requestedMinutes = "requested_minutes"
        case timestamp = "timestamp"
        case processedAt = "processed_at"
    }
    
    // MARK: - Status
    enum Status: String, Codable, CaseIterable {
        case pending = "pending"
        case approved = "approved"
        case denied = "denied"
        
        var displayName: String {
            switch self {
            case .pending:
                return NSLocalizedString("Pending", comment: "")
            case .approved:
                return NSLocalizedString("Approved", comment: "")
            case .denied:
                return NSLocalizedString("Denied", comment: "")
            }
        }
        
        var systemImageName: String {
            switch self {
            case .pending:
                return "clock.fill"
            case .approved:
                return "checkmark.circle.fill"
            case .denied:
                return "xmark.circle.fill"
            }
        }
    }
    
    // MARK: - Computed Properties
    var formattedRequestedTime: String {
        let minutes = Int(requestedSeconds / 60)
        let seconds = Int(requestedSeconds.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return String(format: NSLocalizedString("%dm %ds", comment: ""), minutes, seconds)
        } else {
            return String(format: NSLocalizedString("%ds", comment: ""), seconds)
        }
    }
    
    var isPending: Bool {
        status == .pending
    }
    
    var isApproved: Bool {
        status == .approved
    }
    
    var isDenied: Bool {
        status == .denied
    }
    
    var statusDescription: String {
        switch status {
        case .pending:
            return NSLocalizedString("Waiting for parent approval", comment: "")
        case .approved:
            return NSLocalizedString("Approved by parent", comment: "")
        case .denied:
            let message = responseMessage ?? NSLocalizedString("Denied by parent", comment: "")
            return message
        }
    }
    
    // MARK: - Initializers
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        childId: UUID,
        parentId: UUID,
        requestedSeconds: Double,
        status: Status = .pending,
        responseMessage: String? = nil,
        respondedAt: Date? = nil,
        childEmail: String,
        parentEmail: String,
        requestedMinutes: Int32,
        timestamp: Date,
        processedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.childId = childId
        self.parentId = parentId
        self.requestedSeconds = requestedSeconds
        self.status = status
        self.responseMessage = responseMessage
        self.respondedAt = respondedAt
        self.childEmail = childEmail
        self.parentEmail = parentEmail
        self.requestedMinutes = requestedMinutes
        self.timestamp = timestamp
        self.processedAt = processedAt
    }
    
    init(id: String, childEmail: String, parentEmail: String, requestedMinutes: Int32, timestamp: Date) {
        self.id = UUID(uuidString: id) ?? UUID()
        self.createdAt = timestamp
        self.updatedAt = timestamp
        self.childId = UUID() // Generate temp ID
        self.parentId = UUID() // Generate temp ID
        self.requestedSeconds = Double(requestedMinutes * 60)
        self.status = .pending
        self.responseMessage = nil
        self.respondedAt = nil
        self.childEmail = childEmail
        self.parentEmail = parentEmail
        self.requestedMinutes = requestedMinutes
        self.timestamp = timestamp
        self.processedAt = nil
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decodeDate(forKey: .createdAt)
        updatedAt = try container.decodeDate(forKey: .updatedAt)
        childId = try container.decode(UUID.self, forKey: .childId)
        parentId = try container.decode(UUID.self, forKey: .parentId)
        requestedSeconds = try container.decode(Double.self, forKey: .requestedSeconds)
        status = try container.decode(Status.self, forKey: .status)
        responseMessage = try container.decodeIfPresent(String.self, forKey: .responseMessage)
        respondedAt = try container.decodeDateIfPresent(forKey: .respondedAt)
        childEmail = try container.decode(String.self, forKey: .childEmail)
        parentEmail = try container.decode(String.self, forKey: .parentEmail)
        requestedMinutes = try container.decode(Int32.self, forKey: .requestedMinutes)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        processedAt = try container.decodeDateIfPresent(forKey: .processedAt)
    }
    
    // MARK: - Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeDate(createdAt, forKey: .createdAt)
        try container.encodeDate(updatedAt, forKey: .updatedAt)
        try container.encode(childId, forKey: .childId)
        try container.encode(parentId, forKey: .parentId)
        try container.encode(requestedSeconds, forKey: .requestedSeconds)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(responseMessage, forKey: .responseMessage)
        try container.encodeDateIfPresent(respondedAt, forKey: .respondedAt)
        try container.encode(childEmail, forKey: .childEmail)
        try container.encode(parentEmail, forKey: .parentEmail)
        try container.encode(requestedMinutes, forKey: .requestedMinutes)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeDateIfPresent(processedAt, forKey: .processedAt)
    }
    
    // MARK: - Validation
    func validate() throws {
        guard requestedSeconds > 0 else {
            throw ValidationError.invalidRequestedTime
        }
        
        guard requestedSeconds <= 86400 else { // 24 hours max
            throw ValidationError.requestedTimeTooLarge
        }
        
        if let message = responseMessage, message.count > 500 {
            throw ValidationError.responseMessageTooLong
        }
    }
    
    enum ValidationError: LocalizedError {
        case invalidRequestedTime
        case requestedTimeTooLarge
        case responseMessageTooLong
        
        var errorDescription: String? {
            switch self {
            case .invalidRequestedTime:
                return NSLocalizedString("Requested time must be greater than 0", comment: "")
            case .requestedTimeTooLarge:
                return NSLocalizedString("Requested time cannot exceed 24 hours", comment: "")
            case .responseMessageTooLong:
                return NSLocalizedString("Response message cannot exceed 500 characters", comment: "")
            }
        }
    }
    
    // MARK: - Request Actions
    mutating func approve(message: String? = nil) {
        status = .approved
        responseMessage = message
        respondedAt = Date()
        updatedAt = Date()
    }
    
    mutating func deny(message: String? = nil) {
        status = .denied
        responseMessage = message
        respondedAt = Date()
        updatedAt = Date()
    }
    
    mutating func setRequestedMinutes(_ minutes: Int32) {
        requestedSeconds = Double(minutes * 60)
        updatedAt = Date()
    }
}

// MARK: - Hashable
extension TimeRequest {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Equatable
extension TimeRequest {
    static func == (lhs: TimeRequest, rhs: TimeRequest) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Mock Data
extension TimeRequest {
    static func mock(
        childId: UUID = UUID(),
        parentId: UUID = UUID(),
        requestedMinutes: Int32 = 30,
        status: Status = .pending
    ) -> TimeRequest {
        TimeRequest(
            childId: childId,
            parentId: parentId,
            requestedSeconds: Double(requestedMinutes * 60),
            status: status,
            childEmail: "child@example.com",
            parentEmail: "parent@example.com",
            requestedMinutes: requestedMinutes,
            timestamp: Date()
        )
    }
    
    static let mockRequests: [TimeRequest] = [
        .mock(requestedMinutes: 30, status: .pending),
        .mock(requestedMinutes: 60, status: .approved),
        .mock(requestedMinutes: 15, status: .denied)
    ]
    
    static let mockRequest = TimeRequest(
        id: "mock-request-id",
        childEmail: "child@example.com",
        parentEmail: "parent@example.com",
        requestedMinutes: 30,
        timestamp: Date()
    )
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
    
    func decodeDateIfPresent(forKey key: Key) throws -> Date? {
        if let dateString = try? decodeIfPresent(String.self, forKey: key) {
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
        
        return try decodeIfPresent(Date.self, forKey: key)
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeDate(_ date: Date, forKey key: Key) throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)
        try encode(dateString, forKey: key)
    }
    
    mutating func encodeDateIfPresent(_ date: Date?, forKey key: Key) throws {
        guard let date = date else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)
        try encode(dateString, forKey: key)
    }
} 