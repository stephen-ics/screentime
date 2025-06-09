import Foundation
import OSLog

/// Centralized logging utility for the ScreenTime app
/// Provides consistent logging across the app with different log levels
final class Logger {
    
    // MARK: - Singleton
    static let shared = Logger()
    
    // MARK: - Log Categories
    enum Category: String, CaseIterable {
        case auth = "🔑 AUTH"
        case database = "🗄️ DATABASE" 
        case network = "🌐 NETWORK"
        case timeBank = "⏱️ TIME_BANK"
        case familyControls = "👨‍👩‍👧‍👦 FAMILY_CONTROLS"
        case sync = "🔄 SYNC"
        case ui = "🎨 UI"
        case general = "📱 GENERAL"
        
        var logger: OSLog {
            return OSLog(subsystem: "world.screentime", category: self.rawValue)
        }
    }
    
    // MARK: - Log Levels
    enum Level {
        case debug
        case info
        case warning
        case error
        case critical
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }
    }
    
    // MARK: - Private Properties
    private let dateFormatter: DateFormatter
    private let isDebugMode: Bool
    
    // MARK: - Initialization
    private init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "HH:mm:ss.SSS"
        #if DEBUG
        self.isDebugMode = true
        #else
        self.isDebugMode = false
        #endif
        
        info(.general, "Logger initialized - Debug mode: \(isDebugMode)")
    }
    
    // MARK: - Public Logging Methods
    
    /// Log a debug message (only in debug builds)
    func debug(_ category: Category, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isDebugMode else { return }
        log(level: .debug, category: category, message: message, file: file, function: function, line: line)
    }
    
    /// Log an informational message
    func info(_ category: Category, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, category: category, message: message, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    func warning(_ category: Category, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, category: category, message: message, file: file, function: function, line: line)
    }
    
    /// Log an error message
    func error(_ category: Category, _ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        log(level: .error, category: category, message: fullMessage, file: file, function: function, line: line)
    }
    
    /// Log a critical error message
    func critical(_ category: Category, _ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        log(level: .critical, category: category, message: fullMessage, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    private func log(level: Level, category: Category, message: String, file: String, function: String, line: Int) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        // Create formatted message
        let logMessage = "\(level.emoji) \(category.rawValue): \(message)"
        let detailedMessage = "\(timestamp) \(logMessage) [\(fileName):\(line) \(function)]"
        
        // Output to console (visible in Cursor terminal when using print)
        print(logMessage)
        
        // Output to OSLog (visible in Xcode console and Console.app)
        if #available(iOS 14.0, *) {
            let logger = os.Logger(subsystem: "world.screentime", category: category.rawValue)
            logger.log(level: level.osLogType, "\(message, privacy: .public)")
        } else {
            os_log("%{public}@", log: category.logger, type: level.osLogType, detailedMessage)
        }
        
        // In debug mode, also include file/line info in console
        if isDebugMode && (level == .error || level == .critical) {
            print("   📍 Location: \(fileName):\(line) in \(function)")
        }
    }
}

// MARK: - Convenience Extensions
extension Logger {
    
    // MARK: - Auth Logging
    func authSuccess(_ message: String) {
        info(.auth, "✅ \(message)")
    }
    
    func authError(_ message: String, error: Error? = nil) {
        self.error(.auth, "❌ \(message)", error: error)
    }
    
    func authWarning(_ message: String) {
        warning(.auth, "⚠️ \(message)")
    }
    
    // MARK: - Database Logging
    func dbSuccess(_ message: String) {
        info(.database, "✅ \(message)")
    }
    
    func dbError(_ message: String, error: Error? = nil) {
        self.error(.database, "❌ \(message)", error: error)
    }
    
    func dbQuery(_ message: String) {
        debug(.database, "🔍 \(message)")
    }
    
    // MARK: - Network Logging
    func networkConnected(_ message: String) {
        info(.network, "🟢 \(message)")
    }
    
    func networkDisconnected(_ message: String) {
        warning(.network, "🔴 \(message)")
    }
    
    func networkError(_ message: String, error: Error? = nil) {
        self.error(.network, "❌ \(message)", error: error)
    }
    
    // MARK: - Time Bank Logging
    func timeBankTransaction(_ message: String) {
        info(.timeBank, "💰 \(message)")
    }
    
    func timeBankSession(_ message: String) {
        info(.timeBank, "🔓 \(message)")
    }
    
    func timeBankError(_ message: String, error: Error? = nil) {
        self.error(.timeBank, "❌ \(message)", error: error)
    }
    
    // MARK: - Sync Logging
    func syncStarted(_ message: String) {
        info(.sync, "🔄 \(message)")
    }
    
    func syncSuccess(_ message: String) {
        info(.sync, "✅ \(message)")
    }
    
    func syncError(_ message: String, error: Error? = nil) {
        self.error(.sync, "❌ \(message)", error: error)
    }
}

// MARK: - Global Convenience Functions
/// Quick access to logger - use these for cleaner code
func logInfo(_ category: Logger.Category, _ message: String) {
    Logger.shared.info(category, message)
}

func logError(_ category: Logger.Category, _ message: String, error: Error? = nil) {
    Logger.shared.error(category, message, error: error)
}

func logWarning(_ category: Logger.Category, _ message: String) {
    Logger.shared.warning(category, message)
}

func logDebug(_ category: Logger.Category, _ message: String) {
    Logger.shared.debug(category, message)
} 