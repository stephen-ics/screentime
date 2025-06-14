import Foundation
#if canImport(Supabase)
import Supabase
#endif
import Combine
import SwiftUI

// MARK: - ParentChildLink Model
struct ParentChildLink: Codable, Identifiable {
    let id: UUID
    let parentId: UUID
    let childId: UUID
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
        case childId = "child_id"
        case isActive = "is_active"
    }
}

/// Repository for managing all data operations with Supabase
@MainActor
final class SupabaseDataRepository: ObservableObject, @unchecked Sendable {
    static let shared = SupabaseDataRepository()
    
    private let supabase = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    #if canImport(Supabase)
    // MARK: - Profile Operations
    func getFamilyProfile(for userId: UUID) async throws -> FamilyProfile {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let profile: FamilyProfile = try await database
            .from("family_profiles")
            .select()
            .eq("auth_user_id", value: userId)
            .single()
            .execute()
            .value
        
        return profile
    }
    
    func updateFamilyProfile(_ profile: FamilyProfile) async throws -> FamilyProfile {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let updatedProfile: FamilyProfile = try await database
            .from("family_profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .single()
            .execute()
            .value
        
        return updatedProfile
    }
    
    // MARK: - Screen Time Balance Operations
    func getScreenTimeBalance(for userId: UUID) async throws -> SupabaseScreenTimeBalance {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let balance: SupabaseScreenTimeBalance = try await database
            .from("screentime_balances")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        
        return balance
    }
    
    func updateScreenTimeBalance(_ balance: SupabaseScreenTimeBalance) async throws -> SupabaseScreenTimeBalance {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let updatedBalance: SupabaseScreenTimeBalance = try await database
            .from("screentime_balances")
            .update(balance)
            .eq("id", value: balance.id)
            .single()
            .execute()
            .value
        
        return updatedBalance
    }
    
    // MARK: - Time Management
    private struct AddTimeParams: Codable {
        let child_id: String
        let minutes_to_add: Double
    }
    
    func addTime(toChild childId: UUID, minutes: Double) async throws {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let params = AddTimeParams(child_id: childId.uuidString, minutes_to_add: minutes)
        try await database.rpc("add_time_to_balance", params: params).execute()
    }
    
    private struct DecrementTimeParams: Codable {
        let child_id: String
        let minutes_to_remove: Double
    }
    
    func decrementTime(fromChild childId: UUID, minutes: Double) async throws {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let params = DecrementTimeParams(child_id: childId.uuidString, minutes_to_remove: minutes)
        try await database.rpc("decrement_time_from_balance", params: params).execute()
    }
    
    // MARK: - Task Operations
    func getTasks(for userId: UUID) async throws -> [SupabaseTask] {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let tasks: [SupabaseTask] = try await database
            .from("tasks")
            .select()
            .eq("assigned_to", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return tasks
    }
    
    func getTasksCreatedBy(userId: UUID) async throws -> [SupabaseTask] {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let tasks: [SupabaseTask] = try await database
            .from("tasks")
            .select()
            .eq("created_by", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return tasks
    }
    
    func createTask(_ task: SupabaseTask) async throws -> SupabaseTask {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let createdTasks: [SupabaseTask] = try await database
            .from("tasks")
            .insert(task)
            .select()
            .execute()
            .value
        
        guard let createdTask = createdTasks.first else {
            throw RepositoryError.databaseError("No task returned from insert operation")
        }
        
        return createdTask
    }
    
    func updateTask(_ task: SupabaseTask) async throws -> SupabaseTask {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let updatedTask: SupabaseTask = try await database
            .from("tasks")
            .update(task)
            .eq("id", value: task.id)
            .single()
            .execute()
            .value
        
        return updatedTask
    }
    
    func deleteTask(id: UUID) async throws {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        try await database
            .from("tasks")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    func completeTask(_ taskId: UUID) async throws -> SupabaseTask {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let payload: [String: AnyJSON] = [
            "is_approved": .bool(true),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        let updatedTask: SupabaseTask = try await database
            .from("tasks")
            .update(payload)
            .eq("id", value: taskId)
            .single()
            .execute()
            .value
        
        return updatedTask
    }
    
    func approveTask(id: UUID) async throws -> SupabaseTask {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let payload: [String: AnyJSON] = [
            "is_approved": .bool(true),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        let updatedTask: SupabaseTask = try await database
            .from("tasks")
            .update(payload)
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        return updatedTask
    }
    
    // MARK: - Approved Apps Operations
    func getApprovedApps(for userId: UUID) async throws -> [SupabaseApprovedApp] {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let apps: [SupabaseApprovedApp] = try await database
            .from("approved_apps")
            .select()
            .eq("user_id", value: userId)
            .order("name", ascending: true)
            .execute()
            .value
        
        return apps
    }
    
    func createApprovedApp(_ app: SupabaseApprovedApp) async throws -> SupabaseApprovedApp {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let createdApp: SupabaseApprovedApp = try await database
            .from("approved_apps")
            .insert(app)
            .single()
            .execute()
            .value
        
        return createdApp
    }
    
    func updateApprovedApp(_ app: SupabaseApprovedApp) async throws -> SupabaseApprovedApp {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let updatedApp: SupabaseApprovedApp = try await database
            .from("approved_apps")
            .update(app)
            .eq("id", value: app.id)
            .single()
            .execute()
            .value
        
        return updatedApp
    }
    
    func deleteApprovedApp(id: UUID) async throws {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        try await database
            .from("approved_apps")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Time Request Operations
    func getTimeRequests(for parentId: UUID) async throws -> [TimeRequest] {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let requests: [TimeRequest] = try await database
            .from("time_requests")
            .select()
            .eq("parent_id", value: parentId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return requests
    }
    
    func getTimeRequestsFromChild(childId: UUID) async throws -> [TimeRequest] {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let requests: [TimeRequest] = try await database
            .from("time_requests")
            .select()
            .eq("child_id", value: childId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return requests
    }
    
    func createTimeRequest(_ request: TimeRequest) async throws -> TimeRequest {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let createdRequest: TimeRequest = try await database
            .from("time_requests")
            .insert(request)
            .single()
            .execute()
            .value
        
        return createdRequest
    }
    
    func updateTimeRequest(_ request: TimeRequest) async throws -> TimeRequest {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let updatedRequest: TimeRequest = try await database
            .from("time_requests")
            .update(request)
            .eq("id", value: request.id)
            .single()
            .execute()
            .value
        
        return updatedRequest
    }
    
    func approveTimeRequest(_ requestId: UUID, message: String? = nil) async throws -> TimeRequest {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        var payload: [String: AnyJSON] = [
            "status": .string("approved"),
            "responded_at": .string(ISO8601DateFormatter().string(from: Date())),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        payload["response_message"] = message.map { .string($0) } ?? .null
        
        let updatedRequest: TimeRequest = try await database
            .from("time_requests")
            .update(payload)
            .eq("id", value: requestId)
            .single()
            .execute()
            .value
        
        return updatedRequest
    }
    
    func denyTimeRequest(_ requestId: UUID, message: String? = nil) async throws -> TimeRequest {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        var payload: [String: AnyJSON] = [
            "status": .string("denied"),
            "responded_at": .string(ISO8601DateFormatter().string(from: Date())),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        payload["response_message"] = message.map { .string($0) } ?? .null
        
        let updatedRequest: TimeRequest = try await database
            .from("time_requests")
            .update(payload)
            .eq("id", value: requestId)
            .single()
            .execute()
            .value
        
        return updatedRequest
    }
    
    // MARK: - Parent-Child Link Operations
    func getChildrenForParent(_ parentId: UUID) async throws -> [UUID] {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let links: [ParentChildLink] = try await database
            .from("parent_child_links")
            .select()
            .eq("parent_id", value: parentId)
            .eq("is_active", value: true)
            .execute()
            .value
            
        return links.map { $0.childId }
    }
    
    func getParentsForChild(_ childId: UUID) async throws -> [UUID] {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let links: [ParentChildLink] = try await database
            .from("parent_child_links")
            .select()
            .eq("child_id", value: childId)
            .eq("is_active", value: true)
            .execute()
            .value
            
        return links.map { $0.parentId }
    }
    
    // MARK: - Real-time Subscriptions
    func subscribeToUserUpdates(userId: UUID) -> AnyPublisher<DatabaseEvent, Never> {
        return supabase.userUpdatesPublisher
            .filter { event in
                switch event {
                case .insert(let data), .update(_, let data), .delete(let data):
                    return (data["id"] as? String) == userId.uuidString
                }
            }
            .eraseToAnyPublisher()
    }
    
    func subscribeToTaskUpdates(userId: UUID) -> AnyPublisher<DatabaseEvent, Never> {
        return supabase.taskUpdatesPublisher
            .filter { event in
                switch event {
                case .insert(let data), .update(_, let data), .delete(let data):
                    return (data["assigned_to"] as? String) == userId.uuidString ||
                           (data["created_by"] as? String) == userId.uuidString
                }
            }
            .eraseToAnyPublisher()
    }
    
    func subscribeToTimeRequestUpdates(userId: UUID) -> AnyPublisher<DatabaseEvent, Never> {
        return supabase.timeRequestUpdatesPublisher
            .filter { event in
                switch event {
                case .insert(let data), .update(_, let data), .delete(let data):
                    return (data["parent_id"] as? String) == userId.uuidString ||
                           (data["child_id"] as? String) == userId.uuidString
                }
            }
            .eraseToAnyPublisher()
    }
    
    func unlinkChildFromParent(parentId: UUID, childId: UUID) async throws {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let payload: [String: AnyJSON] = [
            "is_active": .bool(false),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await database
            .from("parent_child_links")
            .update(payload)
            .eq("parent_id", value: parentId)
            .eq("child_id", value: childId)
            .execute()
    }
    
    // MARK: - Child Profile Operations
    func createChildProfile(_ profile: Profile) async throws -> Profile {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let createdProfile: Profile = try await database
            .from("profiles")
            .insert(profile)
            .single()
            .execute()
            .value
        
        return createdProfile
    }
    
    func createScreenTimeBalance(_ balance: SupabaseScreenTimeBalance) async throws -> SupabaseScreenTimeBalance {
        guard let database = supabase.database else {
            throw RepositoryError.configurationMissing
        }
        
        let createdBalance: SupabaseScreenTimeBalance = try await database
            .from("screentime_balances")
            .insert(balance)
            .single()
            .execute()
            .value
        
        return createdBalance
    }
    
    #else
    // MARK: - Stub Methods (when Supabase not available)
    func getFamilyProfile(for userId: UUID) async throws -> FamilyProfile {
        throw RepositoryError.configurationMissing
    }
    
    func updateFamilyProfile(_ profile: FamilyProfile) async throws -> FamilyProfile {
        throw RepositoryError.configurationMissing
    }
    
    func getScreenTimeBalance(for userId: UUID) async throws -> SupabaseScreenTimeBalance {
        throw RepositoryError.configurationMissing
    }
    
    func updateScreenTimeBalance(_ balance: SupabaseScreenTimeBalance) async throws -> SupabaseScreenTimeBalance {
        throw RepositoryError.configurationMissing
    }
    
    func addTime(toChild childId: UUID, minutes: Double) async throws {
        throw RepositoryError.configurationMissing
    }
    
    func decrementTime(fromChild childId: UUID, minutes: Double) async throws {
        throw RepositoryError.configurationMissing
    }
    
    func getTasks(for userId: UUID) async throws -> [SupabaseTask] {
        throw RepositoryError.configurationMissing
    }
    
    func getTasksCreatedBy(userId: UUID) async throws -> [SupabaseTask] {
        throw RepositoryError.configurationMissing
    }
    
    func createTask(_ task: SupabaseTask) async throws -> SupabaseTask {
        throw RepositoryError.configurationMissing
    }
    
    func updateTask(_ task: SupabaseTask) async throws -> SupabaseTask {
        throw RepositoryError.configurationMissing
    }
    
    func deleteTask(id: UUID) async throws {
        throw RepositoryError.configurationMissing
    }
    
    func completeTask(_ taskId: UUID) async throws -> SupabaseTask {
        throw RepositoryError.configurationMissing
    }
    
    func approveTask(id: UUID) async throws -> SupabaseTask {
        throw RepositoryError.configurationMissing
    }
    
    func getApprovedApps(for userId: UUID) async throws -> [SupabaseApprovedApp] {
        throw RepositoryError.configurationMissing
    }
    
    func createApprovedApp(_ app: SupabaseApprovedApp) async throws -> SupabaseApprovedApp {
        throw RepositoryError.configurationMissing
    }
    
    func updateApprovedApp(_ app: SupabaseApprovedApp) async throws -> SupabaseApprovedApp {
        throw RepositoryError.configurationMissing
    }
    
    func deleteApprovedApp(id: UUID) async throws {
        throw RepositoryError.configurationMissing
    }
    
    func getTimeRequests(for parentId: UUID) async throws -> [TimeRequest] {
        throw RepositoryError.configurationMissing
    }
    
    func getTimeRequestsFromChild(childId: UUID) async throws -> [TimeRequest] {
        throw RepositoryError.configurationMissing
    }
    
    func createTimeRequest(_ request: TimeRequest) async throws -> TimeRequest {
        throw RepositoryError.configurationMissing
    }
    
    func updateTimeRequest(_ request: TimeRequest) async throws -> TimeRequest {
        throw RepositoryError.configurationMissing
    }
    
    func approveTimeRequest(id: UUID, message: String? = nil) async throws -> TimeRequest {
        throw RepositoryError.configurationMissing
    }
    
    func denyTimeRequest(id: UUID, message: String? = nil) async throws -> TimeRequest {
        throw RepositoryError.configurationMissing
    }
    
    func getChildrenForParent(_ parentId: UUID) async throws -> [UUID] {
        throw RepositoryError.configurationMissing
    }
    
    func getParentsForChild(_ childId: UUID) async throws -> [UUID] {
        throw RepositoryError.configurationMissing
    }
    
    func subscribeToUserUpdates(userId: UUID) -> AnyPublisher<DatabaseEvent, Never> {
        return Empty().eraseToAnyPublisher()
    }
    
    func subscribeToTaskUpdates(userId: UUID) -> AnyPublisher<DatabaseEvent, Never> {
        return Empty().eraseToAnyPublisher()
    }
    
    func subscribeToTimeRequestUpdates(userId: UUID) -> AnyPublisher<DatabaseEvent, Never> {
        return Empty().eraseToAnyPublisher()
    }
    #endif
}

// MARK: - Error Handling
extension SupabaseDataRepository {
    enum RepositoryError: LocalizedError {
        case notFound
        case unauthorized
        case networkError(String)
        case databaseError(String)
        case configurationMissing
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .notFound:
                return NSLocalizedString("Data not found", comment: "")
            case .unauthorized:
                return NSLocalizedString("Unauthorized access", comment: "")
            case .networkError(let message):
                return NSLocalizedString("Network error: \(message)", comment: "")
            case .databaseError(let message):
                return NSLocalizedString("Database error: \(message)", comment: "")
            case .configurationMissing:
                return NSLocalizedString("Supabase configuration missing. Please add Supabase package and configuration.", comment: "")
            case .unknownError:
                return NSLocalizedString("An unknown error occurred", comment: "")
            }
        }
    }
} 