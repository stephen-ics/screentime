**Chapter 15: Data Persistence – Saving and Loading Data**

Most applications need to store data persistently so it's available across app launches. Swift and its associated frameworks offer several ways to achieve this.

**15.1 `UserDefaults`**
`UserDefaults` is a simple way to store small amounts of user preferences or application settings. It's essentially a key-value store.
*   **Best for:** Simple data like boolean flags (e.g., "isDarkModeEnabled"), strings, numbers, dates, `Data` objects, and small arrays/dictionaries of these types.
*   **Not for:** Large datasets, complex object graphs, or sensitive information (it's not secure by default).

```swift
// Saving data
let defaults = UserDefaults.standard
defaults.set("John Doe", forKey: "username")
defaults.set(true, forKey: "isTutorialCompleted")
defaults.set(25, forKey: "userAge")

// Reading data
let username = defaults.string(forKey: "username") ?? "Guest"
let isTutorialCompleted = defaults.bool(forKey: "isTutorialCompleted") // defaults to false if not found
let userAge = defaults.integer(forKey: "userAge") // defaults to 0 if not found

print("Username: \(username), Tutorial: \(isTutorialCompleted), Age: \(userAge)")

// Removing data
// defaults.removeObject(forKey: "userAge")
```
Changes to `UserDefaults` are typically saved to disk asynchronously and at opportune times by the system. You can force a save using `defaults.synchronize()`, but this is often unnecessary and can impact performance if overused.

**15.2 Property Lists (Plists)**
Property lists are a common way to store structured data in XML or binary format. `UserDefaults` itself uses plists. You can work with plists directly for storing collections of basic data types.
*   **Supported types:** `String`, `Number` (`Int`, `Double`, etc.), `Bool`, `Date`, `Data`, `Array` (of plist-compatible types), `Dictionary` (with `String` keys and plist-compatible values).
*   **Reading from a Plist file in your app bundle:**

    ```swift
    // Assume you have a "MySettings.plist" file in your app bundle
    // with a root dictionary.
    var appSettings: [String: Any]?

    if let plistURL = Bundle.main.url(forResource: "MySettings", withExtension: "plist") {
        do {
            let plistData = try Data(contentsOf: plistURL)
            if let dict = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                appSettings = dict
                print("Loaded settings: \(appSettings ?? [:])")
            }
        } catch {
            print("Error reading plist: \(error)")
        }
    }
    ```
*   **Writing to a Plist file (e.g., in the Documents directory):**
    ```swift
    let userPreferences: [String: Any] = ["theme": "dark", "fontSize": 14]
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let plistPath = documentsDirectory.appendingPathComponent("userPrefs.plist")

    do {
        let plistData = try PropertyListSerialization.data(fromPropertyList: userPreferences, format: .xml, options: 0)
        try plistData.write(to: plistPath)
        print("Saved preferences to: \(plistPath)")
    } catch {
        print("Error writing plist: \(error)")
    }
    ```

**15.3 Codable Protocol (`Encodable` & `Decodable`)**
Swift's `Codable` type alias (a combination of `Encodable` and `Decodable` protocols) provides a powerful and easy way to serialize and deserialize your custom data types to and from formats like JSON, Plists, etc.
Most built-in Swift types (`String`, `Int`, `Double`, `Bool`, `Array`, `Dictionary`, `URL`, `Date`) are already `Codable` if their elements/values are `Codable`. For custom types, you often just need to declare conformance.

```swift
struct Note: Codable, Identifiable { // Conforms to Codable
    let id: UUID
    var title: String
    var content: String
    var createdDate: Date
}

// Encoding (Swift object to Data, e.g., JSON)
let myNote = Note(id: UUID(), title: "Grocery List", content: "Milk, Eggs, Bread", createdDate: Date())
let jsonEncoder = JSONEncoder()
jsonEncoder.outputFormatting = .prettyPrinted // For readable JSON
jsonEncoder.dateEncodingStrategy = .iso8601 // How to encode dates

do {
    let jsonData = try jsonEncoder.encode(myNote)
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("Encoded JSON:\n\(jsonString)")
        // You can save jsonData to a file here
    }
} catch {
    print("Error encoding note: \(error)")
}

// Decoding (Data, e.g., JSON, to Swift object)
let sampleJsonString = """
{
    "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
    "title": "Meeting Notes",
    "content": "Discuss project X.",
    "createdDate": "2023-10-27T10:30:00Z"
}
"""
let jsonDataToDecode = Data(sampleJsonString.utf8)
let jsonDecoder = JSONDecoder()
jsonDecoder.dateDecodingStrategy = .iso8601 // Must match encoding strategy

do {
    let decodedNote = try jsonDecoder.decode(Note.self, from: jsonDataToDecode)
    print("\nDecoded Note Title: \(decodedNote.title)")
    print("Content: \(decodedNote.content)")
} catch {
    print("Error decoding note: \(error)")
}
```
You can save the `Data` (e.g., `jsonData`) to a file and load it back.

**15.4 Core Data**
Core Data is a powerful and mature Apple framework for object graph management and persistence. It's much more than just a database; it allows you to model, save, fetch, and manage complex relationships between objects.
*   **Key Components:**
    *   **Managed Object Model (`.xcdatamodeld`):** Defines your entities (like tables in a database), their attributes (properties), and relationships.
    *   **`NSManagedObject`:** Instances of your entities are subclasses of `NSManagedObject`.
    *   **`NSManagedObjectContext`:** A "scratchpad" where you create, modify, and delete managed objects. Changes are in memory until saved.
    *   **`NSPersistentStoreCoordinator`:** Manages one or more persistent stores (e.g., SQLite database files).
    *   **`NSPersistentContainer` (iOS 10+):** Simplifies Core Data setup by encapsulating the model, context, and store coordinator.

*   **Setting up Core Data (Simplified with `NSPersistentContainer`):**
    Your `screentime` app likely has `ScreenTime.xcdatamodeld`, which indicates Core Data use.

    ```swift
    // Typically in your AppDelegate or a dedicated CoreDataStack class
    import CoreData

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ScreenTime") // Name of your .xcdatamodeld file
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)") // Handle errors appropriately
            }
        })
        return container
    }()

    var viewContext: NSManagedObjectContext { // The main context for UI-related work
        return persistentContainer.viewContext
    }

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    ```

*   **Creating and Saving Objects:**
    You create instances of your `NSManagedObject` subclasses (e.g., `User`, `ApprovedApp` based on your model file names) using the context.

    ```swift
    // Assuming 'UserEntity' is an NSManagedObject subclass generated from your model
    // let newUser = UserEntity(context: viewContext)
    // newUser.id = UUID()
    // newUser.name = "Stephen"
    // newUser.lastLogin = Date()
    // saveContext() // Saves changes from the context to the persistent store
    ```

*   **Fetching Objects (`NSFetchRequest`):**
    You retrieve objects using `NSFetchRequest`.
    ```swift
    // func fetchUsers() -> [UserEntity] {
    //     let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
    //     // Add sort descriptors or predicates (filters) if needed
    //     // request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.name, ascending: true)]
    //     // request.predicate = NSPredicate(format: "age > %d", 18)
    //     do {
    //         return try viewContext.fetch(request)
    //     } catch {
    //         print("Failed to fetch users: \(error)")
    //         return []
    //     }
    // }
    ```

*   **SwiftUI and Core Data (`@FetchRequest`):**
    SwiftUI has a property wrapper `@FetchRequest` that makes it easy to fetch and display Core Data objects directly in your views.

    ```swift
    // struct UserListView: View {
    //     @Environment(\.managedObjectContext) private var viewContext
    //     @FetchRequest(
    //         sortDescriptors: [NSSortDescriptor(keyPath: \UserEntity.name, ascending: true)],
    //         animation: .default)
    //     private var users: FetchedResults<UserEntity>

    //     var body: some View {
    //         List {
    //             ForEach(users) { user in
    //                 Text(user.name ?? "Unknown")
    //             }
    //         }
    //     }
    // }
    ```
    Core Data is a large topic, but it's very powerful for managing structured application data.

**15.5 Realm, SQLite, and Other Third-Party Databases**
While Core Data is Apple's primary solution, there are other popular options:
*   **Realm:** A mobile-first database designed for speed and ease of use. It uses its own engine and offers features like live objects and easy data synchronization.
*   **FMDB/GRDB (SQLite wrappers):** If you prefer working directly with SQL and SQLite, these libraries provide a Swift-friendly wrapper around the C-based SQLite API.
*   **Cloud-based databases (Firebase Realtime Database, Cloud Firestore, etc.):** For apps that need real-time data synchronization across devices and platforms.

Choosing a persistence method depends on the complexity of your data, performance needs, and whether you need cross-platform or cloud features.

--- 