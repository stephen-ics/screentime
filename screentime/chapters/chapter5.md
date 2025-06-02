**Chapter 5: Structures, Classes, and Enumerations – Creating Custom Data Types**

Swift provides powerful ways to create your own custom data types: **Structures (`struct`)**, **Classes (`class`)**, and **Enumerations (`enum`)**. These allow you to model the concepts and data relevant to your application in a type-safe and expressive manner.

**5.1 Introduction to Named Types**
Structures, classes, and enumerations are *named types*. Once you define them, you can use their names to create instances, declare variables/constants of their type, and use them as parameter or return types for functions.

**5.2 Structures (`struct`)**
Structures are general-purpose, flexible constructs. They are *value types*, meaning that when they are assigned to a variable or constant, or when they are passed to a function, their value is *copied*.

*   **Definition Syntax:**

    ```swift
    struct Point {
        var x: Double // Stored property
        var y: Double // Stored property
    }

    struct Size {
        var width: Double
        var height: Double
    }

    struct Rectangle {
        var origin: Point   // Property of type Point (another struct)
        var size: Size    // Property of type Size (another struct)

        // Computed property
        var area: Double {
            return size.width * size.height
        }

        // Instance method
        func description() -> String {
            return "Rectangle at (\(origin.x), \(origin.y)) with size (\(size.width) x \(size.height))"
        }

        // Mutating instance method (can modify struct's properties)
        mutating func moveTo(newOrigin: Point) {
            self.origin = newOrigin // 'self' refers to the instance itself
        }
    }
    ```

*   **Creating Instances and Accessing Properties:**
    You create instances of structures using initializer syntax.

    ```swift
    // Memberwise Initializer (automatically provided for structs if no custom initializers are defined)
    let p1 = Point(x: 10.0, y: 20.0)
    var s1 = Size(width: 100.0, height: 50.0)

    var rect1 = Rectangle(origin: p1, size: s1)

    print(rect1.origin.x) // Accessing property: 10.0
    rect1.size.width = 120.0 // Modifying a property (if 'rect1' and 's1' are vars)
    print(rect1.size.width) // Output: 120.0
    print(rect1.area)        // Accessing computed property: 6000.0 (120 * 50)
    print(rect1.description())
    ```

*   **Memberwise Initializers for Structures:**
    All structures automatically receive a *memberwise initializer* if they don't define any custom initializers themselves. This initializer takes parameters with names matching the stored property names.

*   **Value Type Behavior:**
    When a struct instance is assigned to another variable/constant or passed to a function, a *copy* is made.

    ```swift
    var point1 = Point(x: 1.0, y: 2.0)
    var point2 = point1 // point2 is a COPY of point1

    point2.x = 5.0
    point2.y = 7.0

    print("point1: (\(point1.x), \(point1.y))") // Output: point1: (1.0, 2.0) - remains unchanged
    print("point2: (\(point2.x), \(point2.y))") // Output: point2: (5.0, 7.0) - copy was modified
    ```

*   **Methods:**
    Structs (and classes/enums) can define methods, which are functions associated with the type.
    *   **Instance Methods:** Called on an instance of the type (e.g., `rect1.description()`).
    *   **Mutating Methods:** If an instance method needs to modify the properties of a value type (struct or enum), you must prefix its definition with the `mutating` keyword. Constants of struct types cannot call mutating methods.

        ```swift
        var myRect = Rectangle(origin: Point(x:0, y:0), size: Size(width: 10, height: 5))
        myRect.moveTo(newOrigin: Point(x: 1, y: 1)) // Allowed because myRect is 'var'
        print(myRect.origin) // Output: Point(x: 1.0, y: 1.0)

        let fixedRect = Rectangle(origin: Point(x:0, y:0), size: Size(width: 10, height: 5))
        // fixedRect.moveTo(newOrigin: Point(x:1,y:1)) // COMPILE-TIME ERROR: fixedRect is 'let'
        ```
    *   **Type Methods:** Associated with the type itself, not an instance. Use the `static` keyword (or `class` for classes, which allows overriding).

        ```swift
        struct MathHelper {
            static let pi = 3.14159
            static func isEven(_ number: Int) -> Bool {
                return number % 2 == 0
            }
        }
        print(MathHelper.pi)
        print(MathHelper.isEven(4)) // Output: true
        ```

**5.3 Classes (`class`)**
Classes are also general-purpose, flexible constructs. Unlike structures, classes are *reference types*. This means when a class instance is assigned to a variable or constant, or passed to a function, a *reference* to the *same existing instance* is used, not a copy.

*   **Definition Syntax:**

    ```swift
    class Vehicle {
        var currentSpeed = 0.0
        var description: String { // Computed property
            return "traveling at \(currentSpeed) mph"
        }
        func makeNoise() {
            // Do nothing - an arbitrary vehicle doesn't necessarily make a noise
        }
    }
    ```

*   **Creating Instances and Accessing Properties:**
    Similar to structs, but initializers are more explicitly managed.

    ```swift
    let someVehicle = Vehicle() // Uses default initializer (if no custom ones are defined and all properties have defaults)
    print("Vehicle: \(someVehicle.description)") // Output: Vehicle: traveling at 0.0 mph
    someVehicle.currentSpeed = 35.0
    print("Vehicle: \(someVehicle.description)") // Output: Vehicle: traveling at 35.0 mph
    ```

*   **Reference Type Behavior:**
    Multiple constants/variables can refer to the *same single instance* of a class.

    ```swift
    let car1 = Vehicle()
    car1.currentSpeed = 50.0

    let car2 = car1 // car2 now refers to THE SAME INSTANCE as car1

    car2.currentSpeed = 70.0

    print("Car 1 speed: \(car1.currentSpeed)") // Output: Car 1 speed: 70.0 (modified via car2)
    print("Car 2 speed: \(car2.currentSpeed)") // Output: Car 2 speed: 70.0
    ```

*   **Identity Operators (`===`, `!==`):**
    Because classes are reference types, you might want to check if two constants or variables refer to the exact same instance.
    *   `===` (Identical to): Returns `true` if two references point to the same instance.
    *   `!==` (Not identical to): Returns `true` if two references point to different instances.

    ```swift
    let vehicleA = Vehicle()
    let vehicleB = Vehicle() // A different instance
    let vehicleC = vehicleA  // Refers to the same instance as vehicleA

    if vehicleA === vehicleB {
        print("vehicleA and vehicleB are identical.")
    } else {
        print("vehicleA and vehicleB are NOT identical.") // This will print
    }

    if vehicleA === vehicleC {
        print("vehicleA and vehicleC are identical.") // This will print
    }
    ```
    Note: `==` (equal to) checks for *equivalence* in value (if the type implements `Equatable`), while `===` checks for *identity* (same memory address).

*   **Initializers (`init`):**
    Classes do not receive an automatic memberwise initializer (unlike structs). You must define your own initializers if your class has properties that don't have default values.
    *   **Designated Initializers:** The primary initializers for a class. They fully initialize all properties introduced by that class and call an appropriate superclass initializer to continue the initialization process up the chain. Every class must have at least one designated initializer.
    *   **Convenience Initializers:** Secondary, supporting initializers. You can define a convenience initializer to call a designated initializer from the same class with some parameters set to default values. Convenience initializers are prefixed with the `convenience` keyword.

    ```swift
    class Food {
        var name: String
        // Designated initializer
        init(name: String) {
            self.name = name
        }
        // Convenience initializer
        convenience init() {
            self.init(name: "[Unnamed]") // Must call another initializer from the same class
        }
    }
    let namedMeat = Food(name: "Bacon")
    let mysteryMeat = Food() // Uses convenience init, name will be "[Unnamed]"
    print(mysteryMeat.name)
    ```

*   **Deinitializers (`deinit`):**
    A deinitializer is called immediately before a class instance is deallocated (removed from memory). You write deinitializers with the `deinit` keyword. Deinitializers are only available on class types. They are used to perform any cleanup if the instance needs to release resources before it's deallocated.

    ```swift
    class Player {
        var coinsInPurse: Int
        init(coins: Int) {
            self.coinsInPurse = coins
            print("Player initialized with \(coins) coins")
        }
        func win(coins: Int) {
            coinsInPurse += coins
        }
        deinit {
            print("Player deinitialized, had \(coinsInPurse) coins left.")
            // e.g., save player's final state to disk
        }
    }

    var playerOne: Player? = Player(coins: 100)
    playerOne?.win(coins: 50)
    playerOne = nil // This deallocates the instance, deinit is called
    // Output:
    // Player initialized with 100 coins
    // Player deinitialized, had 150 coins left.
    ```

*   **Inheritance:**
    A key feature of classes is that they can *inherit* characteristics (properties, methods) from a parent class (superclass). The class that inherits is the *subclass*.
    *   **Base Class:** A class that does not inherit from another class.
    *   **Subclassing Syntax:** `class SubclassName: SuperclassName { ... }`

    ```swift
    class Bicycle: Vehicle { // Bicycle inherits from Vehicle
        var hasBasket: Bool
        init(hasBasket: Bool) {
            self.hasBasket = hasBasket
            // Superclass initializer is implicitly called if Vehicle had a no-argument init
            // If Vehicle had an init with parameters, we would need super.init(...)
        }
        override func makeNoise() { // 'override' keyword is required
            print("Ring ring!")
        }
    }

    let myBike = Bicycle(hasBasket: true)
    myBike.currentSpeed = 15.0
    print("Bike: \(myBike.description), Basket: \(myBike.hasBasket)") // Accesses inherited 'description'
    myBike.makeNoise() // Calls overridden method
    ```
    *   **Overriding:** A subclass can provide its own custom implementation of an instance method, type method, instance property (computed or stored with observers), or subscript that it would otherwise inherit from a superclass. This is known as *overriding*. Use the `override` keyword.
    *   **Accessing Superclass Members:** You can access the superclass's version of a method, property, or subscript using the `super` prefix (e.g., `super.makeNoise()`, `super.someProperty`).
    *   **Preventing Overrides:** You can prevent a method, property, or subscript from being overridden by marking it as `final` (e.g., `final var cantChangeThisProperty`, `final func cantOverrideThis()`). You can also mark an entire class as `final` to prevent it from being subclassed.

**5.4 Structures vs. Classes: Choosing the Right One**

*   **Similarities:**
    *   Define properties to store values.
    *   Define methods to provide functionality.
    *   Define subscripts to provide access to their values using subscript syntax.
    *   Define initializers to set up their initial state.
    *   Be extended to expand their functionality beyond a default implementation.
    *   Conform to protocols to provide standard functionality of a certain kind.
*   **Differences (Classes have additional capabilities):**
    *   Inheritance allows one class to inherit the characteristics of another.
    *   Type casting enables you to check and interpret the type of a class instance at runtime.
    *   Deinitializers allow an instance of a class to free up any resources it has assigned.
    *   Reference counting allows more than one reference to a class instance. (Classes are reference types, Structs are value types).
*   **When to Use Structures (General Recommendation):**
    *   The primary purpose is to encapsulate a few relatively simple data values.
    *   You expect that instances will be copied rather than referenced when assigned or passed.
    *   Any properties that store data are also value types (and would also be copied).
    *   You don't need to inherit properties or behavior from another existing type.
    *   Examples: `Point`, `Size`, `Rectangle`, `Temperature`, `Coordinate`. Most custom data types you define will likely be structures or enumerations.
*   **When to Use Classes:**
    *   You need Objective-C interoperability.
    *   You want to control identity (e.g., comparing instances with `===`).
    *   You need inheritance.
    *   The lifetime and state of the instance are managed externally or by shared references (e.g., a shared database connection, a file handler).

**5.5 Enumerations (`enum`)**
Enumerations define a common type for a group of related values and enable you to work with those values in a type-safe way within your code.

*   **Basic Enumeration Syntax:**

    ```swift
    enum CompassPoint {
        case north
        case south
        case east
        case west
    }

    enum Planet {
        case mercury, venus, earth, mars, jupiter, saturn, uranus, neptune // Cases can be on one line
    }

    var directionToHead = CompassPoint.west
    directionToHead = .east // Type is inferred once 'directionToHead' is declared as CompassPoint

    switch directionToHead {
    case .north:
        print("Lots of planets have a north")
    case .south:
        print("Watch out for penguins")
    case .east:
        print("Where the sun rises")
    case .west:
        print("Where the skies are blue")
    // No default needed because all CompassPoint cases are covered
    }
    ```

*   **Iterating Over Enumeration Cases (`CaseIterable`):**
    For enumerations that don't have associated values, you can enable iteration over all cases by conforming to the `CaseIterable` protocol. Swift then provides an `allCases` collection.

    ```swift
    enum Beverage: CaseIterable {
        case coffee, tea, juice
    }
    let numberOfChoices = Beverage.allCases.count
    print("\(numberOfChoices) beverages available") // Output: 3 beverages available
    for beverage in Beverage.allCases {
        print(beverage)
    }
    // Output:
    // coffee
    // tea
    // juice
    ```

*   **Associated Values:**
    Enum cases can store *associated values* of any given type alongside the case value itself. This allows you to attach additional, custom information to a case.

    ```swift
    enum Barcode {
        case upc(Int, Int, Int, Int) // Associated values: (numberSystem, manufacturer, product, check)
        case qrCode(String)         // Associated value: productURL as String
    }

    var productBarcode = Barcode.upc(8, 85909, 51226, 3)
    productBarcode = .qrCode("https://www.example.com")

    switch productBarcode {
    case .upc(let numberSystem, let manufacturer, let product, let check):
        print("UPC: \(numberSystem), \(manufacturer), \(product), \(check).")
    case .qrCode(let productURL): // 'let' can be outside for all bindings
        print("QR code: \(productURL).")
    // case let .qrCode(productURL): // Alternative syntax for binding
    //     print("QR code: \(productURL).")
    }
    // Output based on the last assignment: QR code: https://www.example.com.
    ```

*   **Raw Values:**
    Enum cases can come prepopulated with default values (called *raw values*), which are all of the same type. Raw values can be strings, characters, or any of the integer or floating-point number types. Each raw value must be unique within its enumeration declaration.

    ```swift
    enum ASCIIControlCharacter: Character {
        case tab = "\t"
        case lineFeed = "\n"
        case carriageReturn = "\r"
    }

    enum Month: Int { // Raw values are Int
        case january = 1, february, march, april, may, june, july, august, september, october, november, december
        // If raw values are Ints, and you only specify for the first, subsequent cases get incrementing values.
        // So, february is 2, march is 3, etc.
    }

    let currentMonth = Month.march
    print("Current month raw value: \(currentMonth.rawValue)") // Output: Current month raw value: 3

    // Initializing from a Raw Value
    // The raw value initializer is failable (returns an optional enum case) because not all raw values may correspond to a case.
    if let possibleMonth = Month(rawValue: 7) {
        print("Month for raw value 7 is \(possibleMonth)") // Output: Month for raw value 7 is july
    } else {
        print("Invalid raw value for Month.")
    }

    if let nonExistentMonth = Month(rawValue: 13) {
        // This won't execute
    } else {
        print("Raw value 13 does not correspond to a Month.") // This will print
    }
    ```

*   **Methods and Computed Properties in Enums:**
    Enumerations can define methods and computed properties, just like structs and classes.

    ```swift
    enum Device {
        case iPhone(model: String, color: String)
        case iPad(model: String, storage: Int)
        case macBook(model: String, year: Int)

        var displayName: String { // Computed property
            switch self {
            case .iPhone(let model, _):
                return "iPhone \(model)"
            case .iPad(let model, _):
                return "iPad \(model)"
            case .macBook(let model, _):
                return "MacBook \(model)"
            }
        }

        func showDetails() { // Method
            switch self {
            case .iPhone(let model, let color):
                print("This is an iPhone \(model) in \(color).")
            case .iPad(let model, let storage):
                print("This is an iPad \(model) with \(storage)GB.")
            case .macBook(let model, let year):
                print("This is a MacBook \(model) from \(year).")
            }
        }
    }

    let myDevice = Device.iPhone(model: "15 Pro", color: "Natural Titanium")
    print(myDevice.displayName) // Output: iPhone 15 Pro
    myDevice.showDetails()     // Output: This is an iPhone 15 Pro in Natural Titanium.
    ```

*   **Recursive Enumerations:**
    A recursive enumeration is an enumeration that has another instance of the enumeration as the associated value for one or more of its cases. You indicate this by writing `indirect` before a case, or before the `enum` keyword to make all cases with associated values indirect.

    ```swift
    indirect enum ArithmeticExpression {
        case number(Int)
        case addition(ArithmeticExpression, ArithmeticExpression)
        case multiplication(ArithmeticExpression, ArithmeticExpression)
    }

    // Represents (5 + 4) * 2
    let five = ArithmeticExpression.number(5)
    let four = ArithmeticExpression.number(4)
    let sum = ArithmeticExpression.addition(five, four)
    let productExpr = ArithmeticExpression.multiplication(sum, ArithmeticExpression.number(2))

    func evaluate(_ expression: ArithmeticExpression) -> Int {
        switch expression {
        case .number(let value):
            return value
        case .addition(let left, let right):
            return evaluate(left) + evaluate(right)
        case .multiplication(let left, let right):
            return evaluate(left) * evaluate(right)
        }
    }
    print("Result of expression: \(evaluate(productExpr))") // Output: Result of expression: 18
    ```

--- 