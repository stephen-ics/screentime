import Foundation
#if canImport(Supabase)
import Supabase
import Combine
#endif

/// Manages Supabase client and provides centralized access to backend services
final class SupabaseManager: @unchecked Sendable {
    static let shared = SupabaseManager()
    
    // MARK: - Properties
    #if canImport(Supabase)
    private let supabase: SupabaseClient?
    #endif
    private let logger = Logger.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Publishers for real-time updates
    private let userUpdatesSubject = PassthroughSubject<DatabaseEvent, Never>()
    private let taskUpdatesSubject = PassthroughSubject<DatabaseEvent, Never>()
    private let timeRequestUpdatesSubject = PassthroughSubject<DatabaseEvent, Never>()
    
    var userUpdatesPublisher: AnyPublisher<DatabaseEvent, Never> {
        userUpdatesSubject.eraseToAnyPublisher()
    }
    
    var taskUpdatesPublisher: AnyPublisher<DatabaseEvent, Never> {
        taskUpdatesSubject.eraseToAnyPublisher()
    }
    
    var timeRequestUpdatesPublisher: AnyPublisher<DatabaseEvent, Never> {
        timeRequestUpdatesSubject.eraseToAnyPublisher()
    }
    
    private init() {
        #if canImport(Supabase)
        // Load configuration from plist
        if let config = SupabaseManager.loadConfiguration() {
            // Initialize Supabase client
            self.supabase = SupabaseClient(
                supabaseURL: config.url,
                supabaseKey: config.anonKey
            )
            logger.dbSuccess("Supabase client initialized successfully")
            logger.info(.database, "🔗 Supabase URL: \(config.url)")
            Task {
                await setupRealtimeSubscriptions()
                await testSupabaseConnection()
            }
        } else {
            logger.dbError("Supabase configuration not found. Please create SupabaseConfig.plist")
            self.supabase = nil
        }
        #else
        logger.warning(.database, "Supabase package not found. Please add the Supabase Swift package to your project.")
        self.supabase = nil
        #endif
    }
    
    // MARK: - Configuration
    private static func loadConfiguration() -> (url: URL, anonKey: String)? {
        guard let path = Bundle.main.path(forResource: "SupabaseConfig", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let urlString = plist["SUPABASE_URL"] as? String,
              let anonKey = plist["SUPABASE_ANON_KEY"] as? String,
              let url = URL(string: urlString),
              !urlString.contains("placeholder") && !anonKey.contains("placeholder") else {
            print("❌ Failed to load valid Supabase configuration from SupabaseConfig.plist")
            return nil
        }
        
        return (url: url, anonKey: anonKey)
    }
    
    // MARK: - Client Access
    #if canImport(Supabase)
    var client: SupabaseClient? {
        supabase
    }
    
    var auth: AuthClient? {
        supabase?.auth
    }
    
    // MARK: - Database Access (New API)
    var database: SupabaseClient? {
        // Return the client itself for database operations
        // Use client.from("table_name") for database queries
        supabase
    }
    
    /// Check if the Supabase client is properly configured and available
    var isConfigured: Bool {
        supabase != nil
    }
    
    /// Test database connectivity
    func testConnection() async -> Bool {
        await testSupabaseConnection()
        return supabase != nil
    }
    #endif
    
    // MARK: - Real-time Subscriptions
    private func setupRealtimeSubscriptions() async {
        #if canImport(Supabase)
        guard supabase != nil else { return }
        
        // Note: Realtime subscriptions disabled during transition
        // The newer Supabase Swift SDK requires different APIs for realtime
        // These will be re-implemented when the user sets up their Supabase project
        
        print("Realtime subscriptions disabled during transition period")
        
        /*
        // Profile changes
        do {
            let channel = await supabase.realtime.channel("profiles")
            await channel
                .on(.postgresChanges, filter: PostgresChangesFilter(event: .all, schema: "public", table: "profiles")) { payload in
                await self.handleProfileUpdate(payload)
            }
            await channel.subscribe()
        } catch {
            print("Failed to setup profile subscription: \(error)")
        }
        
        // Task changes
        do {
            let channel = await supabase.realtime.channel("tasks")
            await channel
                .on(.postgresChanges, filter: PostgresChangesFilter(event: .all, schema: "public", table: "tasks")) { payload in
                await self.handleTaskUpdate(payload)
            }
            await channel.subscribe()
        } catch {
            print("Failed to setup task subscription: \(error)")
        }
        
        // Time request changes
        do {
            let channel = await supabase.realtime.channel("time_requests")
            await channel
                .on(.postgresChanges, filter: PostgresChangesFilter(event: .all, schema: "public", table: "time_requests")) { payload in
                await self.handleTimeRequestUpdate(payload)
            }
            await channel.subscribe()
        } catch {
            print("Failed to setup time request subscription: \(error)")
        }
        */
        #endif
    }
    
    #if canImport(Supabase)
    // Note: Individual subscription methods removed during transition
    // Will be re-implemented with proper APIs when user sets up Supabase project
    #endif
    
    // MARK: - Real-time Event Handlers
    private func handleRealtimeUpdate(payload: [String: Any]) async {
        // During transition: simplified payload handling
        // In production: implement proper real-time update handling
        print("Received realtime update: \(payload)")
    }
    
    // MARK: - Debug Testing
    #if canImport(Supabase)
    func testSupabaseConnection() async {
        guard let supabase = supabase else {
            logger.dbError("Supabase client is nil")
            return
        }
        
        logger.info(.database, "🧪 Testing Supabase connection...")
        
        do {
            // Test database connection by querying profiles table
            let result: [Profile] = try await supabase
                .from("profiles")
                .select()
                .limit(1)
                .execute()
                .value
            
            logger.dbSuccess("Database connection successful! Found \(result.count) profiles")
            
            // Test auth connection
            do {
                let session = try await supabase.auth.session
                logger.dbSuccess("Auth session found: \(session.user.email ?? "no email")")
            } catch {
                logger.info(.database, "ℹ️ No active auth session (this is normal for first run)")
            }
            
        } catch {
            logger.dbError("Database connection failed", error: error)
        }
    }
    
    func testSignUp(email: String, password: String, name: String, isParent: Bool) async throws -> AuthResponse {
        guard let supabase = supabase else {
            throw SupabaseError.configurationMissing
        }
        
        print("🧪 Testing sign up for: \(email)")
        
        do {
            // Step 1: Sign up with Supabase Auth (this triggers profile creation)
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "name": .string(name),
                    "user_type": .string(isParent ? "parent" : "child")
                ]
            )
            
            print("✅ Auth signup successful for: \(authResponse.user.email ?? email)")
            print("✅ User ID: \(authResponse.user.id)")
            print("✅ Database trigger will automatically create profile and time bank")
            
            // Return the auth response so the caller can use the session
            return authResponse
            
        } catch {
            print("❌ Test sign up failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }
    #endif
}

// MARK: - Database Event Types
enum DatabaseEvent {
    case insert([String: Any])
    case update(old: [String: Any], new: [String: Any])
    case delete([String: Any])
}

// MARK: - Error Types
extension SupabaseManager {
    enum SupabaseError: LocalizedError, Equatable {
        case configurationMissing
        case invalidConfiguration
        case authenticationFailed
        case networkError(String)
        case databaseError(String)
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .configurationMissing:
                return "Supabase configuration file is missing"
            case .invalidConfiguration:
                return "Invalid Supabase configuration"
            case .authenticationFailed:
                return "Authentication failed"
            case .networkError(let message):
                return "Network error: \(message)"
            case .databaseError(let message):
                return "Database error: \(message)"
            case .unknownError:
                return "An unknown error occurred"
            }
        }
        
        static func == (lhs: SupabaseManager.SupabaseError, rhs: SupabaseManager.SupabaseError) -> Bool {
            switch (lhs, rhs) {
            case (.configurationMissing, .configurationMissing),
                 (.invalidConfiguration, .invalidConfiguration),
                 (.authenticationFailed, .authenticationFailed),
                 (.unknownError, .unknownError):
                return true
            case (.networkError(let lhsMessage), .networkError(let rhsMessage)):
                return lhsMessage == rhsMessage
            case (.databaseError(let lhsMessage), .databaseError(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
} 