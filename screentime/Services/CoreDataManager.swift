import CoreData
import CloudKit

/// Manages Core Data stack and provides CRUD operations for the app
final class CoreDataManager {
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    private let modelName = "ScreenTime"
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        
        // Use SQLite store for persistence
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ScreenTime.sqlite")
        
        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        // Set options for better performance
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
                // In production, handle this more gracefully
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        // Configure automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        
        // User Entity
        let userEntity = NSEntityDescription()
        userEntity.name = "User"
        userEntity.managedObjectClassName = "User"
        
        // User attributes
        let userIdAttribute = NSAttributeDescription()
        userIdAttribute.name = "id"
        userIdAttribute.attributeType = .UUIDAttributeType
        userIdAttribute.isOptional = true
        
        let userNameAttribute = NSAttributeDescription()
        userNameAttribute.name = "name"
        userNameAttribute.attributeType = .stringAttributeType
        userNameAttribute.isOptional = false
        userNameAttribute.defaultValue = ""
        
        let userTypeAttribute = NSAttributeDescription()
        userTypeAttribute.name = "userType"
        userTypeAttribute.attributeType = .stringAttributeType
        userTypeAttribute.isOptional = false
        userTypeAttribute.defaultValue = "child"
        
        let emailAttribute = NSAttributeDescription()
        emailAttribute.name = "email"
        emailAttribute.attributeType = .stringAttributeType
        emailAttribute.isOptional = true
        
        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true
        
        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = true
        
        userEntity.properties = [userIdAttribute, userNameAttribute, userTypeAttribute, emailAttribute, createdAtAttribute, updatedAtAttribute]
        
        // Task Entity
        let taskEntity = NSEntityDescription()
        taskEntity.name = "Task"
        taskEntity.managedObjectClassName = "Task"
        
        // Task attributes
        let taskIdAttribute = NSAttributeDescription()
        taskIdAttribute.name = "id"
        taskIdAttribute.attributeType = .UUIDAttributeType
        taskIdAttribute.isOptional = true
        
        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false
        titleAttribute.defaultValue = ""
        
        let taskDescriptionAttribute = NSAttributeDescription()
        taskDescriptionAttribute.name = "taskDescription"
        taskDescriptionAttribute.attributeType = .stringAttributeType
        taskDescriptionAttribute.isOptional = true
        
        let rewardMinutesAttribute = NSAttributeDescription()
        rewardMinutesAttribute.name = "rewardMinutes"
        rewardMinutesAttribute.attributeType = .integer32AttributeType
        rewardMinutesAttribute.isOptional = false
        rewardMinutesAttribute.defaultValue = 0
        
        let completedAtAttribute = NSAttributeDescription()
        completedAtAttribute.name = "completedAt"
        completedAtAttribute.attributeType = .dateAttributeType
        completedAtAttribute.isOptional = true
        
        let isApprovedAttribute = NSAttributeDescription()
        isApprovedAttribute.name = "isApproved"
        isApprovedAttribute.attributeType = .booleanAttributeType
        isApprovedAttribute.isOptional = false
        isApprovedAttribute.defaultValue = false
        
        let isRecurringAttribute = NSAttributeDescription()
        isRecurringAttribute.name = "isRecurring"
        isRecurringAttribute.attributeType = .booleanAttributeType
        isRecurringAttribute.isOptional = false
        isRecurringAttribute.defaultValue = false
        
        let recurringFrequencyAttribute = NSAttributeDescription()
        recurringFrequencyAttribute.name = "recurringFrequency"
        recurringFrequencyAttribute.attributeType = .stringAttributeType
        recurringFrequencyAttribute.isOptional = true
        
        taskEntity.properties = [taskIdAttribute, titleAttribute, taskDescriptionAttribute, rewardMinutesAttribute, 
                                completedAtAttribute, createdAtAttribute, updatedAtAttribute, isApprovedAttribute, 
                                isRecurringAttribute, recurringFrequencyAttribute]
        
        // ScreenTimeBalance Entity
        let balanceEntity = NSEntityDescription()
        balanceEntity.name = "ScreenTimeBalance"
        balanceEntity.managedObjectClassName = "ScreenTimeBalance"
        
        // Balance attributes
        let balanceIdAttribute = NSAttributeDescription()
        balanceIdAttribute.name = "id"
        balanceIdAttribute.attributeType = .UUIDAttributeType
        balanceIdAttribute.isOptional = true
        
        let availableMinutesAttribute = NSAttributeDescription()
        availableMinutesAttribute.name = "availableMinutes"
        availableMinutesAttribute.attributeType = .integer32AttributeType
        availableMinutesAttribute.isOptional = false
        availableMinutesAttribute.defaultValue = 0
        
        let dailyLimitAttribute = NSAttributeDescription()
        dailyLimitAttribute.name = "dailyLimit"
        dailyLimitAttribute.attributeType = .integer32AttributeType
        dailyLimitAttribute.isOptional = false
        dailyLimitAttribute.defaultValue = 120
        
        let weeklyLimitAttribute = NSAttributeDescription()
        weeklyLimitAttribute.name = "weeklyLimit"
        weeklyLimitAttribute.attributeType = .integer32AttributeType
        weeklyLimitAttribute.isOptional = false
        weeklyLimitAttribute.defaultValue = 840
        
        let lastUpdatedAttribute = NSAttributeDescription()
        lastUpdatedAttribute.name = "lastUpdated"
        lastUpdatedAttribute.attributeType = .dateAttributeType
        lastUpdatedAttribute.isOptional = true
        
        let isTimerActiveAttribute = NSAttributeDescription()
        isTimerActiveAttribute.name = "isTimerActive"
        isTimerActiveAttribute.attributeType = .booleanAttributeType
        isTimerActiveAttribute.isOptional = false
        isTimerActiveAttribute.defaultValue = false
        
        let lastTimerStartAttribute = NSAttributeDescription()
        lastTimerStartAttribute.name = "lastTimerStart"
        lastTimerStartAttribute.attributeType = .dateAttributeType
        lastTimerStartAttribute.isOptional = true
        
        balanceEntity.properties = [balanceIdAttribute, availableMinutesAttribute, dailyLimitAttribute, 
                                   weeklyLimitAttribute, lastUpdatedAttribute, isTimerActiveAttribute, lastTimerStartAttribute]
        
        // ApprovedApp Entity
        let appEntity = NSEntityDescription()
        appEntity.name = "ApprovedApp"
        appEntity.managedObjectClassName = "ApprovedApp"
        
        // App attributes
        let appIdAttribute = NSAttributeDescription()
        appIdAttribute.name = "id"
        appIdAttribute.attributeType = .UUIDAttributeType
        appIdAttribute.isOptional = true
        
        let bundleIdentifierAttribute = NSAttributeDescription()
        bundleIdentifierAttribute.name = "bundleIdentifier"
        bundleIdentifierAttribute.attributeType = .stringAttributeType
        bundleIdentifierAttribute.isOptional = false
        bundleIdentifierAttribute.defaultValue = ""
        
        let appNameAttribute = NSAttributeDescription()
        appNameAttribute.name = "appName"
        appNameAttribute.attributeType = .stringAttributeType
        appNameAttribute.isOptional = false
        appNameAttribute.defaultValue = ""
        
        let isEnabledAttribute = NSAttributeDescription()
        isEnabledAttribute.name = "isEnabled"
        isEnabledAttribute.attributeType = .booleanAttributeType
        isEnabledAttribute.isOptional = false
        isEnabledAttribute.defaultValue = true
        
        let appDailyLimitAttribute = NSAttributeDescription()
        appDailyLimitAttribute.name = "dailyLimit"
        appDailyLimitAttribute.attributeType = .integer32AttributeType
        appDailyLimitAttribute.isOptional = false
        appDailyLimitAttribute.defaultValue = 0
        
        appEntity.properties = [appIdAttribute, bundleIdentifierAttribute, appNameAttribute, isEnabledAttribute, 
                               createdAtAttribute, updatedAtAttribute, appDailyLimitAttribute]
        
        // Set up relationships
        // User relationships
        let childrenRelationship = NSRelationshipDescription()
        childrenRelationship.name = "children"
        childrenRelationship.destinationEntity = userEntity
        childrenRelationship.minCount = 0
        childrenRelationship.maxCount = 0  // 0 means to-many
        childrenRelationship.deleteRule = .cascadeDeleteRule
        childrenRelationship.isOptional = true
        
        let parentRelationship = NSRelationshipDescription()
        parentRelationship.name = "parent"
        parentRelationship.destinationEntity = userEntity
        parentRelationship.minCount = 0
        parentRelationship.maxCount = 1
        parentRelationship.deleteRule = .nullifyDeleteRule
        parentRelationship.isOptional = true
        
        childrenRelationship.inverseRelationship = parentRelationship
        parentRelationship.inverseRelationship = childrenRelationship
        
        let tasksRelationship = NSRelationshipDescription()
        tasksRelationship.name = "tasks"
        tasksRelationship.destinationEntity = taskEntity
        tasksRelationship.minCount = 0
        tasksRelationship.maxCount = 0  // 0 means to-many
        tasksRelationship.deleteRule = .cascadeDeleteRule
        tasksRelationship.isOptional = true
        
        let createdTasksRelationship = NSRelationshipDescription()
        createdTasksRelationship.name = "createdTasks"
        createdTasksRelationship.destinationEntity = taskEntity
        createdTasksRelationship.minCount = 0
        createdTasksRelationship.maxCount = 0  // 0 means to-many
        createdTasksRelationship.deleteRule = .cascadeDeleteRule
        createdTasksRelationship.isOptional = true
        
        let screenTimeBalanceRelationship = NSRelationshipDescription()
        screenTimeBalanceRelationship.name = "screenTimeBalance"
        screenTimeBalanceRelationship.destinationEntity = balanceEntity
        screenTimeBalanceRelationship.minCount = 0
        screenTimeBalanceRelationship.maxCount = 1
        screenTimeBalanceRelationship.deleteRule = .cascadeDeleteRule
        screenTimeBalanceRelationship.isOptional = true
        
        // Task relationships
        let assignedToRelationship = NSRelationshipDescription()
        assignedToRelationship.name = "assignedTo"
        assignedToRelationship.destinationEntity = userEntity
        assignedToRelationship.minCount = 0
        assignedToRelationship.maxCount = 1
        assignedToRelationship.deleteRule = .nullifyDeleteRule
        assignedToRelationship.isOptional = true
        
        let createdByRelationship = NSRelationshipDescription()
        createdByRelationship.name = "createdBy"
        createdByRelationship.destinationEntity = userEntity
        createdByRelationship.minCount = 0
        createdByRelationship.maxCount = 1
        createdByRelationship.deleteRule = .nullifyDeleteRule
        createdByRelationship.isOptional = true
        
        tasksRelationship.inverseRelationship = assignedToRelationship
        assignedToRelationship.inverseRelationship = tasksRelationship
        
        createdTasksRelationship.inverseRelationship = createdByRelationship
        createdByRelationship.inverseRelationship = createdTasksRelationship
        
        // Balance relationships
        let userRelationship = NSRelationshipDescription()
        userRelationship.name = "user"
        userRelationship.destinationEntity = userEntity
        userRelationship.minCount = 0
        userRelationship.maxCount = 1
        userRelationship.deleteRule = .nullifyDeleteRule
        userRelationship.isOptional = true
        
        let approvedAppsRelationship = NSRelationshipDescription()
        approvedAppsRelationship.name = "approvedApps"
        approvedAppsRelationship.destinationEntity = appEntity
        approvedAppsRelationship.minCount = 0
        approvedAppsRelationship.maxCount = 0  // 0 means to-many
        approvedAppsRelationship.deleteRule = .cascadeDeleteRule
        approvedAppsRelationship.isOptional = true
        
        screenTimeBalanceRelationship.inverseRelationship = userRelationship
        userRelationship.inverseRelationship = screenTimeBalanceRelationship
        
        // App relationships
        let screenTimeBalanceAppRelationship = NSRelationshipDescription()
        screenTimeBalanceAppRelationship.name = "screenTimeBalance"
        screenTimeBalanceAppRelationship.destinationEntity = balanceEntity
        screenTimeBalanceAppRelationship.minCount = 0
        screenTimeBalanceAppRelationship.maxCount = 1
        screenTimeBalanceAppRelationship.deleteRule = .nullifyDeleteRule
        screenTimeBalanceAppRelationship.isOptional = true
        
        approvedAppsRelationship.inverseRelationship = screenTimeBalanceAppRelationship
        screenTimeBalanceAppRelationship.inverseRelationship = approvedAppsRelationship
        
        // Add relationships to entities
        userEntity.properties.append(contentsOf: [childrenRelationship, parentRelationship, tasksRelationship, 
                                                  createdTasksRelationship, screenTimeBalanceRelationship])
        taskEntity.properties.append(contentsOf: [assignedToRelationship, createdByRelationship])
        balanceEntity.properties.append(contentsOf: [userRelationship, approvedAppsRelationship])
        appEntity.properties.append(screenTimeBalanceAppRelationship)
        
        // Add entities to model
        model.entities = [userEntity, taskEntity, balanceEntity, appEntity]
        
        return model
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Context Management
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - CRUD Operations
    func save() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
    
    func delete(_ object: NSManagedObject) throws {
        viewContext.delete(object)
        try save()
    }
    
    // MARK: - Fetch Operations
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
        try viewContext.fetch(request)
    }
    
    // MARK: - User Operations
    func createUser(name: String, type: String, email: String? = nil) throws -> User {
        let user = User(context: viewContext)
        user.id = UUID()
        user.name = name
        user.userType = type
        user.email = email
        user.createdAt = Date()
        user.updatedAt = Date()
        
        try save()
        return user
    }
    
    func fetchUser(withID id: UUID) throws -> User? {
        let request = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try fetch(request).first
    }
    
    // MARK: - Task Operations
    func createTask(title: String, description: String?, rewardMinutes: Int32, assignedTo: User, createdBy: User) throws -> Task {
        let task = Task(context: viewContext)
        task.id = UUID()
        task.title = title
        task.taskDescription = description
        task.rewardMinutes = rewardMinutes
        task.assignedTo = assignedTo
        task.createdBy = createdBy
        task.createdAt = Date()
        task.updatedAt = Date()
        task.isApproved = false
        
        try save()
        return task
    }
    
    // MARK: - Screen Time Balance Operations
    func createScreenTimeBalance(for user: User, dailyLimit: Int32? = nil, weeklyLimit: Int32? = nil) throws -> ScreenTimeBalance {
        let balance = ScreenTimeBalance(context: viewContext)
        balance.id = UUID()
        balance.user = user
        balance.availableMinutes = 0
        balance.dailyLimit = dailyLimit ?? 120  // Default 2 hours daily
        balance.weeklyLimit = weeklyLimit ?? 840  // Default 14 hours weekly
        balance.lastUpdated = Date()
        balance.isTimerActive = false
        
        try save()
        return balance
    }
    
    // MARK: - Approved App Operations
    func createApprovedApp(bundleIdentifier: String, appName: String, for balance: ScreenTimeBalance) throws -> ApprovedApp {
        let app = ApprovedApp(context: viewContext)
        app.id = UUID()
        app.bundleIdentifier = bundleIdentifier
        app.appName = appName
        app.screenTimeBalance = balance
        app.isEnabled = true
        app.createdAt = Date()
        app.updatedAt = Date()
        
        try save()
        return app
    }
}

// MARK: - Error Handling
extension CoreDataManager {
    enum CoreDataError: LocalizedError {
        case saveFailed
        case fetchFailed
        case deleteFailed
        case invalidObject
        
        var errorDescription: String? {
            switch self {
            case .saveFailed:
                return NSLocalizedString("Failed to save data", comment: "")
            case .fetchFailed:
                return NSLocalizedString("Failed to fetch data", comment: "")
            case .deleteFailed:
                return NSLocalizedString("Failed to delete data", comment: "")
            case .invalidObject:
                return NSLocalizedString("Invalid object", comment: "")
            }
        }
    }
} 