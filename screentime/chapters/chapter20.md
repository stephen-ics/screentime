**Chapter 20: `screentime` App – Understanding `Models`**

The `Models` directory in your project is where the data structures and business logic of your application reside. These are the blueprints for the objects that your app works with. Based on your file list, you have several distinct models and a Core Data model definition.

**20.1 Role of Models in MVVM**
In an MVVM architecture:
*   Models encapsulate the data and the rules that govern access to and updates of this data.
*   They are independent of the UI (View) and the presentation logic (ViewModel).
*   They can be simple structs or classes.
*   For persistence, they often conform to `Codable` (for JSON/Plist serialization) or are `NSManagedObject` subclasses (for Core Data).

**20.2 Examining Your Swift Model Files**

*   **`ApprovedApp.swift`:**
    *   **Purpose:** Likely represents an application that a parent has approved or for which rules are set.
    *   **Potential Properties:**
        *   `id: UUID` or `String` (bundle identifier of the app)
        *   `name: String` (display name of the app)
        *   `iconData: Data?` (optional, for storing the app's icon)
        *   `timeLimit: TimeInterval?` (e.g., in seconds per day)
        *   `isBlocked: Bool`
        *   `category: String?`
    *   **Considerations:** How are these apps identified? Usually by their bundle identifier. How is the icon fetched and stored?

*   **`ScreenTimeBalance.swift`:**
    *   **Purpose:** Seems to represent the amount of screen time a child has available, possibly earned or allocated.
    *   **Potential Properties:**
        *   `id: UUID`
        *   `userID: UUID` or `String` (linking to a `User` model, likely the child)
        *   `balance: TimeInterval` (current available screen time in seconds)
        *   `lastUpdated: Date`
        *   `earnedTime: TimeInterval` (total time earned)
        *   `usedTime: TimeInterval` (total time used)
    *   **Considerations:** How is this balance updated? When tasks are completed? When time limits are set/reset?

*   **`Task.swift`:**
    *   **Purpose:** Represents a task a child can complete, possibly to earn screen time.
    *   **Potential Properties:**
        *   `id: UUID`
        *   `title: String`
        *   `description: String?`
        *   `assignedToUserID: UUID` or `String` (child user)
        *   `assignedByUserID: UUID` or `String` (parent user)
        *   `isCompleted: Bool`
        *   `creationDate: Date`
        *   `completionDate: Date?`
        *   `rewardTime: TimeInterval?` (screen time awarded upon completion)
    *   **Considerations:** How are tasks created, assigned, and marked complete?

*   **`User.swift`:**
    *   **Purpose:** Represents a user of the app, could be a parent or a child.
    *   **Potential Properties:**
        *   `id: UUID` (or a string ID from your authentication service)
        *   `username: String`
        *   `email: String?` (if using email for login)
        *   `role: UserRole` (an enum, e.g., `.parent`, `.child`)
        *   `hashedPIN: String?` (if using PINs for parent access)
        *   `profileImageURL: String?` or `profileImageData: Data?`
        *   `childIDs: [UUID]?` (if parent, list of associated child user IDs)
        *   `parentID: UUID?` (if child, ID of the parent user)
    *   **`UserRole` Enum (likely defined within User.swift or separately):**
        ```swift
        enum UserRole: String, Codable /* or Int, Codable */ {
            case parent
            case child
        }
        ```
    *   **Considerations:** How is user data linked to authentication data? Is user data stored locally in Core Data, or primarily managed by `AuthenticationService` and potentially fetched from a backend?

**20.3 Core Data Model: `ScreenTime.xcdatamodeld`**
This file is your Core Data Managed Object Model. It's a visual editor in Xcode where you define:
*   **Entities:** These correspond to tables in a relational database or classes in your object graph. Based on your Swift files, you likely have entities such as:
    *   `UserEntity` (for `User.swift`)
    *   `TaskEntity` (for `Task.swift`)
    *   `ApprovedAppEntity` (for `ApprovedApp.swift`)
    *   `ScreenTimeBalanceEntity` (for `ScreenTimeBalance.swift`)
*   **Attributes:** Properties of your entities (e.g., a `UserEntity` might have `name` (String), `userID` (UUID), `role` (String or Int16 for an enum)).
*   **Relationships:** How entities relate to each other (e.g., a `UserEntity` (parent) can have many `TaskEntity`s; a `TaskEntity` belongs to one `UserEntity` (child)).
    *   **To-One:** One instance of an entity relates to one instance of another.
    *   **To-Many:** One instance of an entity relates to multiple instances of another.
    *   **Inverse Relationships:** Essential for data integrity and efficient querying. If Entity A has a to-many relationship to Entity B, Entity B should have an inverse to-one relationship back to Entity A.
    *   **Delete Rules:** Define what happens when an object is deleted (e.g., Cascade, Nullify, Deny).
*   **Configurations:** Allow for different store setups (less common for simpler apps).
*   **Fetch Requests Templates:** Pre-defined queries you can use in your code.

**Generating `NSManagedObject` Subclasses:**
Xcode can automatically generate Swift subclass files for your Core Data entities (or you can create them manually). These subclasses (e.g., `UserEntity+CoreDataClass.swift`, `UserEntity+CoreDataProperties.swift`) provide typed access to your entity's attributes and relationships.

**Example structure for an Entity in the model editor:**
`UserEntity`
    Attributes:
        `userID: UUID` (Unique identifier)
        `username: String`
        `roleRaw: String` (Store the raw value of the `UserRole` enum)
        `profileImageData: Data?` (Optional binary data for image)
    Relationships:
        `tasksAssigned: To-Many -> TaskEntity` (inverse: `assignedToUser`)
        `tasksCreated: To-Many -> TaskEntity` (inverse: `createdByParent`)
        `screenTimeBalance: To-One -> ScreenTimeBalanceEntity` (inverse: `user`)
        `approvedApps: To-Many -> ApprovedAppEntity` (inverse: `managingUser`)

`TaskEntity`
    Attributes:
        `taskID: UUID`
        `title: String`
        `isCompleted: Bool`
        `rewardTime: Double` (TimeInterval is Double)
    Relationships:
        `assignedToUser: To-One -> UserEntity` (inverse: `tasksAssigned`)
        `createdByParent: To-One -> UserEntity` (inverse: `tasksCreated`)

**20.4 Data Integrity and Relationships**
*   How do your Swift structs/classes map to your Core Data entities? Do they duplicate data, or do the Core Data entities *become* your primary models when fetched?
    *   Often, `NSManagedObject` subclasses *are* the models used by ViewModels after being fetched.
    *   Sometimes, you might map `NSManagedObject`s to simpler Swift structs for use in views if you want to decouple from Core Data further up the stack, but this adds a mapping layer.
*   Ensure relationships (like a Task belonging to a User) are correctly defined in the Core Data model with appropriate inverse relationships and delete rules.

**20.5 `Codable` Conformance**
If your models (especially the non-Core Data Swift structs/classes) need to be serialized (e.g., to send to a watch extension, save to a file outside Core Data, or interact with a web API), ensure they conform to `Codable`.
*   Core Data `NSManagedObject`s can be made `Codable` with some extra work, often by overriding `init(from decoder: Decoder)` and `encode(to encoder: Encoder)` to handle managed properties correctly.

The models are the heart of your application's data. A clear, well-defined model layer makes the rest of the app easier to build and maintain.

--- 