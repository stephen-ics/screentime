**Chapter 7: Protocols and Extensions – Defining Blueprints and Adding Functionality**

Protocols and extensions are powerful features in Swift that promote code flexibility, reusability, and abstraction. **Protocols** define a blueprint of methods, properties, and other requirements that suit a particular task or piece of functionality. Types (classes, structures, or enumerations) can then *adopt* a protocol to provide an actual implementation of those requirements. **Extensions** allow you to add new functionality to existing types, even types for which you don't have the original source code.

**7.1 Protocols: Defining Blueprints**
A protocol defines a contract or a set of rules that conforming types must adhere to. It doesn't provide implementations itself, only the "what," not the "how."

*   **Protocol Syntax (`protocol`):**

    ```swift
    protocol FullyNamed {
        var fullName: String { get } // Readable property requirement
    }

    protocol RandomNumberGenerator {
        func random() -> Double // Method requirement
    }

    protocol Togglable {
        mutating func toggle() // Mutating method requirement (for value types)
    }

    protocol Account {
        var balance: Double { get set } // Readable and writable property
        init(initialAmount: Double)    // Initializer requirement
    }
    ```

*   **Property Requirements:**
    *   Specify whether a property must be gettable (`{ get }`) or gettable and settable (`{ get set }`).
    *   Do not specify if it's a stored or computed property; that's up to the conforming type.
    *   Type properties are marked with the `static` keyword (e.g., `static var version: Int { get }`).

*   **Method Requirements:**
    *   Defined like function declarations but without curly braces or a body.
    *   Default values for parameters are not allowed in protocol method declarations.
    *   Type methods are marked with the `static` keyword.

*   **Mutating Method Requirements:**
    If a method will modify instances of a value type (structs or enums) that conform to the protocol, you must mark the method requirement with the `mutating` keyword. This keyword is not needed for classes, as their methods can always modify the instance.

*   **Initializer Requirements:**
    Protocols can require conforming types to implement specific initializers.
    *   For class conformance, designated or convenience initializers can satisfy the requirement. The `required` modifier must be used on class implementations of protocol initializers (unless the class is `final`) to ensure that all subclasses also provide that initializer.
    *   Value types (structs, enums) don't need the `required` modifier.

    ```swift
    protocol Named {
        init(name: String)
    }

    class PersonClass: Named {
        var name: String
        required init(name: String) { // 'required' for non-final class
            self.name = name
        }
    }

    struct AnimalStruct: Named {
        var name: String
        init(name: String) { // No 'required' for struct
            self.name = name
        }
    }
    ```

**7.2 Protocol Conformance**
A class, structure, or enumeration can *adopt* (or *conform to*) a protocol by listing it after the type's name, separated by a colon. Multiple protocols can be adopted, separated by commas.

```swift
struct Starship: FullyNamed, Togglable {
    var name: String
    var prefix: String?
    var isShieldUp: Bool = false

    // Conformance to FullyNamed
    var fullName: String {
        return (prefix != nil ? prefix! + " " : "") + name
    }

    // Conformance to Togglable
    mutating func toggle() {
        isShieldUp.toggle() // .toggle() is a built-in Bool method
    }
}

var enterprise = Starship(name: "Enterprise", prefix: "USS")
print(enterprise.fullName) // Output: USS Enterprise
print("Shields up: \(enterprise.isShieldUp)") // Output: Shields up: false
enterprise.toggle()
print("Shields up: \(enterprise.isShieldUp)") // Output: Shields up: true
```

**7.3 Protocols as Types**
Protocols don't just define rules; they become fully-fledged types in their own right. You can use a protocol as:
*   A parameter type or return type in a function.
*   The type of a constant, variable, or property.
*   The type of items in an array, dictionary, or other container.

```swift
protocol TextRepresentable {
    var textualDescription: String { get }
}

struct Game: TextRepresentable {
    var score: Int
    var textualDescription: String {
        return "Game score: \(score)"
    }
}

class Player: TextRepresentable {
    var name: String
    init(name: String) { self.name = name }
    var textualDescription: String {
        return "Player: \(name)"
    }
}

let gameInstance = Game(score: 100)
let playerInstance = Player(name: "Lex")

// Array of things that are TextRepresentable
let things: [TextRepresentable] = [gameInstance, playerInstance]

for thing in things {
    print(thing.textualDescription) // Polymorphism: correct textualDescription is called
}
// Output:
// Game score: 100
// Player: Lex
```
This is powerful because it allows you to write code that works with any type conforming to a protocol, without needing to know the specific underlying type. This is a form of *polymorphism*.

*   **Delegation Pattern:**
    Delegation is a design pattern where one object (the delegator) allows another object (the delegate) to act on its behalf or provide data.
    1.  Define a protocol that outlines the responsibilities the delegate must handle.
    2.  The delegator has a property (often optional and `weak` to avoid retain cycles) of this protocol type.
    3.  The delegate conforms to the protocol and implements its methods.
    This is common in Cocoa/Cocoa Touch frameworks (e.g., `UITableViewDelegate`).

**7.4 Protocol Inheritance**
A protocol can inherit requirements from one or more other protocols.
```swift
protocol PrettyTextRepresentable: TextRepresentable { // Inherits from TextRepresentable
    var prettyTextualDescription: String { get }
}

struct Document: PrettyTextRepresentable {
    var title: String
    var body: String

    // From TextRepresentable
    var textualDescription: String {
        return "Document: \(title)"
    }
    // From PrettyTextRepresentable
    var prettyTextualDescription: String {
        return "== \(title) ==\n\(body)"
    }
}
```

**7.5 Protocol Composition (`&`)**
You can combine multiple protocols into a single temporary requirement called a *protocol composition*. This is useful when you need a type to conform to several protocols simultaneously.

```swift
protocol NamedAgain { var name: String { get } }
protocol Aged { var age: Int { get } }

struct PersonData: NamedAgain, Aged {
    var name: String
    var age: Int
}

// This function requires its argument to conform to BOTH NamedAgain AND Aged
func wishHappyBirthday(to celebrant: NamedAgain & Aged) {
    print("Happy birthday, \(celebrant.name)! You're \(celebrant.age)!")
}

let birthdayPerson = PersonData(name: "Alice", age: 30)
wishHappyBirthday(to: birthdayPerson) // Output: Happy birthday, Alice! You're 30!
```

**7.6 Checking for Protocol Conformance (`is`, `as?`, `as!`)**
You can use the type casting operators (`is`, `as?`, `as!`) to check for protocol conformance and to cast to a protocol type.
*   `is`: Checks if an instance conforms to a protocol (returns `Bool`).
*   `as?`: Tries to downcast to a protocol type; returns an optional value of the protocol type (or `nil` if it fails).
*   `as!`: Force downcasts to a protocol type; triggers a runtime error if the downcast fails.

```swift
let objects: [Any] = [
    Game(score: 50),
    Player(name: "Bob"),
    "A String",
    Starship(name: "Voyager")
]

for object in objects {
    if let representable = object as? TextRepresentable {
        print("Text: \(representable.textualDescription)")
    } else if object is String {
        print("Just a String: \"\(object as! String)\"")
    } else {
        print("Something else: \(object)")
    }
}
```

**7.7 Optional Protocol Requirements (Primarily for Objective-C Interoperability)**
Protocols can define optional requirements—requirements that a conforming type isn't required to implement. These are marked with the `@objc` attribute and the `optional` modifier, and are typically used when interfacing with Objective-C code. Swift types can conform, but optional methods/properties will be accessed via optional chaining.

**7.8 Extensions: Adding Functionality**
Extensions add new functionality to an existing class, structure, enumeration, or protocol type. This includes the ability to extend types for which you do not have access to the original source code (known as *retroactive modeling*).

*   **Extension Syntax (`extension`):**

    ```swift
    extension Double {
        var km: Double { return self * 1_000.0 }
        var m: Double { return self }
        var cm: Double { return self / 100.0 }
        var mm: Double { return self / 1_000.0 }
        var ft: Double { return self / 3.28084 }
    }
    let oneInch = 25.4.mm
    print("One inch is \(oneInch) meters") // Output: One inch is 0.0254 meters
    let threeFeet = 3.0.ft
    print("Three feet is \(threeFeet) meters")
    ```

*   **What Extensions Can Do:**
    *   **Add Computed Properties (Instance and Type):** Cannot add stored properties or property observers to existing properties.
    *   **Define Methods (Instance and Type):**
    *   **Provide New Initializers:** Can add new convenience initializers to classes, but cannot add new designated initializers or a deinitializer. For value types (structs, enums), you can add new initializers if the original type doesn't define any custom initializers and all stored properties have defaults (to preserve the automatic memberwise/default initializer).
    *   **Define Subscripts:**
    *   **Define and Use Nested Types:**
    *   **Make an Existing Type Conform to a Protocol:** This is a very common use case.

    ```swift
    // Extending Int to conform to TextRepresentable
    extension Int: TextRepresentable {
        var textualDescription: String {
            return "The number \(self)"
        }
    }
    print(5.textualDescription) // Output: The number 5

    // Adding a method via extension
    extension String {
        func reversedWords() -> String {
            let words = self.components(separatedBy: " ")
            return words.map { String($0.reversed()) }.joined(separator: " ")
        }
    }
    let hello = "Hello World"
    print(hello.reversedWords()) // Output: olleH dlroW
    ```

Extensions can make your code more organized by grouping related functionality. For example, you might put all your protocol conformances for a complex type in separate extensions.

--- 