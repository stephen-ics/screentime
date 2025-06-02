**Chapter 8: Generics – Writing Flexible, Reusable Code**

Generics allow you to write flexible, reusable functions and types that can work with *any type*, subject to requirements you define, without sacrificing type safety. This avoids code duplication and allows you to write abstract code that clearly expresses its intent.

**8.1 The Problem That Generics Solve**
Imagine you need a function to swap two integer values, and another to swap two string values, and another for two doubles. Without generics, you'd write multiple functions:

```swift
func swapTwoInts(_ a: inout Int, _ b: inout Int) {
    let temporaryA = a; a = b; b = temporaryA
}
func swapTwoStrings(_ a: inout String, _ b: inout String) {
    let temporaryA = a; a = b; b = temporaryA
}
// ... and so on for other types.
```
This is repetitive. Generics solve this by allowing you to write a single function that can swap values of *any* type.

**8.2 Generic Functions**
Generic functions can work with any type. Swift's standard library arrays and dictionaries are implemented using generic types.

*   **Type Parameters:**
    Generic functions use *type parameters* as placeholders for actual types that will be provided when the function is called. Type parameters are specified in angle brackets `< >` immediately after the function's name (e.g., `<T>`). `T` is a common placeholder name, but you can use any valid identifier (e.g., `Element`, `Key`, `Value`).

    ```swift
    func swapTwoValues<T>(_ a: inout T, _ b: inout T) { // 'T' is a type parameter
        let temporaryA = a
        a = b
        b = temporaryA
    }

    var someInt = 100
    var anotherInt = 200
    swapTwoValues(&someInt, &anotherInt)
    print("someInt is now \(someInt), anotherInt is now \(anotherInt)") // 200, 100

    var someString = "hello"
    var anotherString = "world"
    swapTwoValues(&someString, &anotherString)
    print("someString is now \(someString), anotherString is now \(anotherString)") // world, hello
    ```
    In `swapTwoValues<T>`, `T` is a placeholder. It doesn't specify what type `T` actually is, but it does state that both `a` and `b` must be of the *same* type `T`, whatever that type might be. The actual type to use for `T` is inferred by Swift when you call the function based on the types of the values passed in.

*   **Naming Type Parameters:**
    Use upper camel case names (like `T`, `U`, `V`, `Key`, `Value`, `Element`) to indicate they are placeholders for a type, not a value.

**8.3 Generic Types**
In addition to generic functions, Swift enables you to define your own *generic types*. These are classes, structures, or enumerations that can work with any type, in a similar way to `Array` and `Dictionary`.

*   **Defining a Generic Stack:**
    Let's define a generic stack (a last-in, first-out collection).

    ```swift
    struct Stack<Element> { // 'Element' is the type parameter for the struct
        var items: [Element] = [] // An array to store elements of type 'Element'

        mutating func push(_ item: Element) {
            items.append(item)
        }
        mutating func pop() -> Element? { // Returns an optional Element
            if items.isEmpty {
                return nil
            }
            return items.removeLast()
        }
        func peek() -> Element? {
            return items.last
        }
        var isEmpty: Bool {
            return items.isEmpty
        }
        var count: Int {
            return items.count
        }
    }

    // Using the generic Stack with Ints
    var intStack = Stack<Int>() // Specify the actual type for Element
    intStack.push(1)
    intStack.push(2)
    intStack.push(3)
    print("Int Stack count: \(intStack.count)") // Output: 3
    if let topInt = intStack.pop() {
        print("Popped Int: \(topInt)") // Output: Popped Int: 3
    }

    // Using the generic Stack with Strings
    var stringStack = Stack<String>()
    stringStack.push("apple")
    stringStack.push("banana")
    print("String stack peek: \(stringStack.peek() ?? "empty")") // Output: banana
    ```
    The `Stack<Element>` struct can be used to create a stack of `Int`s, `String`s, or any other type you specify for `Element`.

**8.4 Type Constraints**
Sometimes it's useful to define requirements on the types that can be used with generic functions and types. *Type constraints* specify that a type parameter must inherit from a specific class or conform to a particular protocol or protocol composition.

*   **Syntax:**
    You write type constraints by placing a class or protocol constraint after a type parameter's name, separated by a colon, as part of the type parameter list.

    ```swift
    // A generic function that finds the index of a value in an array-like collection.
    // This requires the elements to be Equatable so we can compare them with ==
    func findIndex<T: Equatable>(of valueToFind: T, in array: [T]) -> Int? {
        for (index, value) in array.enumerated() {
            if value == valueToFind { // '==' can be used because T is constrained to Equatable
                return index
            }
        }
        return nil
    }

    let doubleIndex = findIndex(of: 9.3, in: [3.14159, 0.1, 0.25]) // nil
    let stringIndex = findIndex(of: "Andrea", in: ["Mike", "Malcolm", "Andrea"]) // Optional(2)

    // Example: A function that works with any type conforming to a custom protocol
    protocol Displayable {
        func display() -> String
    }
    struct MyData: Displayable {
        var info: String
        func display() -> String { return "Data: \(info)" }
    }

    func printDisplayable<T: Displayable>(_ item: T) {
        print(item.display())
    }
    let myDataItem = MyData(info: "Important stuff")
    printDisplayable(myDataItem) // Output: Data: Important stuff
    ```

*   **Multiple Constraints:**
    A type parameter can have multiple constraints (e.g., inherit from a class *and* conform to one or more protocols). List them separated by an ampersand `&`.
    `func someFunction<T: SomeClass & SomeProtocol & AnotherProtocol>(someT: T) { ... }`

**8.5 Associated Types in Protocols**
When defining a protocol, it's sometimes useful to declare one or more *associated types* as part of the protocol's definition. An associated type gives a placeholder name to a type that is used as part of the protocol. The actual type to use for that associated type isn't specified until the protocol is adopted. Associated types are specified with the `associatedtype` keyword.

```swift
protocol Container {
    associatedtype Item // Placeholder for the type of items the container holds
    mutating func append(_ item: Item)
    var count: Int { get }
    subscript(i: Int) -> Item { get }
}

// Conforming our Stack to the Container protocol
// For Stack<Element>, the 'Item' associated type will be inferred as 'Element'
struct GenericStack<Element>: Container {
    // Original Stack<Element> implementation...
    var items: [Element] = []
    mutating func push(_ item: Element) {
        items.append(item)
    }
    mutating func pop() -> Element? {
        if items.isEmpty { return nil }
        return items.removeLast()
    }

    // Container protocol requirements
    typealias Item = Element // Explicitly state that Item is Element (often inferred)
    mutating func append(_ item: Item) { // Item is now Element
        self.push(item)
    }
    var count: Int {
        return items.count
    }
    subscript(i: Int) -> Item { // Item is Element
        return items[i]
    }
}

var myIntStack = GenericStack<Int>()
myIntStack.append(10)
myIntStack.append(20)
print(myIntStack[0]) // Output: 10
```
*   **Constraints on Associated Types:**
    You can add type constraints to an associated type in a protocol to require that conforming types provide an associated type that satisfies those constraints (e.g., `associatedtype Item: Equatable`).

**8.6 Generic `where` Clauses**
Type constraints allow you to define requirements on the type parameters associated with a generic function, subscript, or type. It can also be useful to define requirements for associated types. You do this by using a *generic `where` clause*. A generic `where` clause enables you to require that an associated type must conform to a certain protocol, or that certain type parameters and associated types must be the same.

*   **Syntax:**
    A generic `where` clause starts with the `where` keyword, followed by one or more constraints separated by commas.

    ```swift
    protocol AnotherContainer {
        associatedtype Item
        mutating func append(_ item: Item)
        var count: Int { get }
        subscript(i: Int) -> Item { get }
    }

    // A function that checks if two containers contain the same items in the same order.
    // Requires:
    // 1. C1 and C2 conform to AnotherContainer.
    // 2. The Item type of C1 must be the same as the Item type of C2.
    // 3. The Item type for both C1 and C2 must conform to Equatable.
    func allItemsMatch<C1: AnotherContainer, C2: AnotherContainer>
        (_ someContainer: C1, _ anotherContainer: C2) -> Bool
        where C1.Item == C2.Item, C1.Item: Equatable { // Generic 'where' clause

            // Check that both containers contain the same number of items.
            if someContainer.count != anotherContainer.count {
                return false
            }

            // Check each pair of items to see if they are equivalent.
            for i in 0..<someContainer.count {
                if someContainer[i] != anotherContainer[i] { // '!=' is available because C1.Item is Equatable
                    return false
                }
            }
            // All items match, so return true.
            return true
    }

    var stackOfStrings = GenericStack<String>()
    stackOfStrings.append("uno")
    stackOfStrings.append("dos")

    var arrayOfStringsAsContainer = GenericStack<String>() // Using GenericStack which conforms to Container/AnotherContainer
    arrayOfStringsAsContainer.append("uno")
    arrayOfStringsAsContainer.append("dos")

    if allItemsMatch(stackOfStrings, arrayOfStringsAsContainer) {
        print("All items match.") // This will print
    }
    ```

*   **Extensions with a Generic `where` Clause:**
    You can also use a generic `where` clause as part of an extension. This allows you to add new methods, properties, or conformances to a generic type, but only when its type parameter meets certain criteria.

    ```swift
    extension GenericStack where Element: Equatable { // Extend GenericStack only when Element is Equatable
        func isTop(_ item: Element) -> Bool {
            guard let topItem = items.last else {
                return false
            }
            return topItem == item // Can use '==' because Element is Equatable
        }
    }

    if myIntStack.isTop(20) { // myIntStack's Element is Int, which is Equatable
        print("Top element is 20.") // Output: Top element is 20.
    }

    // A stack of non-equatable items would not have this 'isTop' method.
    struct NonEquatableType {}
    var nonEquatableStack = GenericStack<NonEquatableType>()
    // nonEquatableStack.isTop(NonEquatableType()) // COMPILE-TIME ERROR
    ```

--- 