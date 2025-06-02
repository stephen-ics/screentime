**Chapter 1: Introduction to Swift – The Building Blocks**

Welcome to Swift! If you're coming from other programming languages, you'll likely find Swift to be a modern, safe, and expressive language. It's designed by Apple and is the primary language for developing applications across all Apple platforms (iOS, macOS, watchOS, tvOS, and even visionOS). Swift also has a growing presence in server-side development and other areas.

This chapter will introduce you to the very basics: how to store data using variables and constants, the different types of data Swift can handle, and the fundamental operations you can perform on that data.

---

**1.1 What is Swift? Key Characteristics**

Before diving into code, let's briefly touch upon what makes Swift, Swift:

*   **Safe:** Swift is designed to be safe by default. It has features like strong typing, optionals (which we'll cover later), and automatic memory management that help prevent common programming errors, especially those related to null pointers and memory leaks.
*   **Fast:** Swift is built with performance in mind, using the highly optimized LLVM compiler. Its performance is often comparable to C++.
*   **Modern:** Swift incorporates many modern programming language features, such as closures, generics, type inference, and a clean syntax that's relatively easy to read and write.
*   **Expressive:** The syntax is concise yet powerful, allowing you to write code that clearly expresses your intent.
*   **Open Source:** Swift is an open-source project with a vibrant community, meaning its development is transparent, and anyone can contribute.
*   **Interoperable with Objective-C:** Swift can coexist and interact seamlessly with Objective-C code within the same project. This was crucial for its adoption, as much of Apple's existing frameworks were written in Objective-C.

**1.2 Your First Swift Code: "Hello, World!" (and Playgrounds)**

Traditionally, the first program you write in a new language is "Hello, World!". In Swift, it's incredibly simple:

```swift
print("Hello, World!")
```

*   `print()`: This is a built-in Swift function that outputs the given text (or other data) to the console.
*   `"Hello, World!"`: This is a *string literal* – a sequence of characters enclosed in double quotes.

**Xcode Playgrounds: Your Swift Sandbox**

For learning and experimenting with Swift code snippets without creating a full application, Xcode Playgrounds are invaluable.

*   **What they are:** Playgrounds are interactive environments where you can write Swift code and see the results immediately. As you type, your code is compiled and run, and you can see the output and the state of your variables line by line.
*   **Creating a Playground:**
    1.  Open Xcode.
    2.  Choose "Get started with a playground" (or File > New > Playground).
    3.  Select a template (e.g., "Blank" under iOS or macOS).
    4.  Name your playground and choose where to save it.

You'll see an editor on the left and a results sidebar on the right. As you type `print("Hello, World!")` in the editor, you should see "Hello, World!" appear in the console at the bottom or in the results sidebar.

**1.3 Comments: Explaining Your Code**

Comments are notes in your code that are ignored by the compiler. They are for human readers to understand what the code is doing.

*   **Single-line comments:** Start with `//`
    ```swift
    // This is a single-line comment.
    print("Hello!") // This comment is at the end of a line.
    ```

*   **Multi-line comments (or block comments):** Start with `/*` and end with `*/`
    ```swift
    /*
    This is a multi-line comment.
    It can span several lines and is useful
    for longer explanations.
    */
    ```
    Multi-line comments can also be nested, which can be useful for temporarily commenting out large blocks of code that might already contain comments.

**1.4 Constants and Variables: Storing Data**

In Swift, you use *constants* and *variables* to store and refer to values by an identifying name.

*   **Constants (`let`):**
    *   Used for values that will **not** change after they are set.
    *   Declared using the `let` keyword.
    *   It's good practice to use constants by default, and only use variables when you know a value needs to change. This makes your code safer and easier to reason about.

    ```swift
    let maximumLoginAttempts = 10
    let welcomeMessage = "Welcome to the App!"
    // maximumLoginAttempts = 5 // This would cause a compile-time error because it's a constant.
    ```

*   **Variables (`var`):**
    *   Used for values that **can** change after they are initially set.
    *   Declared using the `var` keyword.

    ```swift
    var currentLoginAttempt = 0
    var userScore = 0
    currentLoginAttempt = 1
    userScore = 100
    ```

**Naming Conventions:**

Swift uses **camelCase** for naming constants, variables, functions, methods, etc.
*   Start with a lowercase letter.
*   Capitalize the first letter of each subsequent word.
*   Examples: `userName`, `isUserLoggedIn`, `numberOfApples`.

Names should be descriptive and clear. Avoid single-letter names unless they are for very short-lived loop counters (like `i`, `j`, `k`).

**1.5 Type Safety and Type Inference**

Swift is a *type-safe* language. This means every constant and variable has a specific *type* (like "integer" or "text"), and Swift checks these types at compile time to prevent errors. You can't, for example, accidentally assign a text value to a variable expecting a number.

*   **Type Annotation (Explicit Typing):**
    You can explicitly declare the type of a constant or variable using a colon (`:`) followed by the type name.

    ```swift
    let explicitWelcomeMessage: String = "Hello!"
    var explicitUserAge: Int = 30
    ```

*   **Type Inference (Implicit Typing):**
    In many cases, Swift is smart enough to *infer* the type of a constant or variable from the initial value you assign to it. This makes your code more concise.

    ```swift
    let inferredWelcomeMessage = "Hello!" // Swift infers this is a String
    var inferredUserAge = 30             // Swift infers this is an Int
    ```
    For `inferredWelcomeMessage`, Swift sees `"Hello!"` (a string literal) and knows the constant must be of type `String`. For `inferredUserAge`, Swift sees `30` (an integer literal) and knows the variable must be of type `Int`.

    While type inference is powerful and often used, sometimes providing an explicit type annotation can make your code clearer, especially when the initial value isn't obvious or when you're defining something without an initial value (though this is less common for simple types).

**1.6 Basic Data Types**

Swift provides several fundamental data types. Here are the most common ones you'll encounter initially:

*   **`Int` (Integers):**
    *   Used for whole numbers (numbers without a fractional component).
    *   Can be positive, negative, or zero.
    *   Examples: `0`, `42`, `-100`.
    *   The size of an `Int` (e.g., 32-bit or 64-bit) depends on the platform your code is running on. On modern platforms, it's typically 64-bit.
    *   Swift also provides fixed-size integers like `Int8`, `Int16`, `Int32`, `Int64` (and their unsigned counterparts `UInt8`, etc.) if you need specific sizes.

    ```swift
    let myAge: Int = 30
    var numberOfItems = 150
    ```

*   **`Double` and `Float` (Floating-Point Numbers):**
    *   Used for numbers with a fractional component (decimal numbers).
    *   `Double` represents a 64-bit floating-point number. It has higher precision and is generally preferred for most floating-point calculations.
    *   `Float` represents a 32-bit floating-point number. Use it when floating-point values don't require 64-bit precision, or for compatibility with older APIs that expect `Float`.
    *   By default, if you assign a decimal number, Swift infers it as a `Double`.

    ```swift
    let pi: Double = 3.14159
    var accountBalance = 1234.56 // Inferred as Double
    let gravity: Float = 9.81     // Explicitly Float
    ```

*   **`Bool` (Booleans):**
    *   Used for logical values, representing truth or falsehood.
    *   Can only have two possible values: `true` or `false`.
    *   Essential for conditional logic (e.g., `if` statements).

    ```swift
    let isUserActive: Bool = true
    var hasCompletedTutorial = false
    ```

*   **`String` (Text):**
    *   Used for sequences of characters, like words or sentences.
    *   String literals are enclosed in double quotes (`"`).
    *   Strings in Swift are powerful and support full Unicode.

    ```swift
    let name: String = "Alice"
    var message = "Welcome to Swift programming!"
    ```
    *   **String Interpolation:** You can create strings by embedding constants, variables, literals, and expressions within a string literal. Wrap the item to be embedded in parentheses, prefixed by a backslash (`\(` `)`).

        ```swift
        let userName = "Bob"
        let userAge = 25
        let greeting = "Hello, my name is \(userName) and I am \(userAge) years old."
        // greeting will be "Hello, my name is Bob and I am 25 years old."

        let price = 10.0
        let tax = 0.07
        let totalMessage = "The total price is \(price * (1 + tax))."
        // totalMessage will be "The total price is 10.7."
        ```

    *   **Multi-line String Literals:** For strings that span multiple lines, use triple double quotes (`"""`).

        ```swift
        let longMessage = """
        This is a very long string
        that spans multiple lines
        in the source code.
        """
        ```
        The indentation of the closing `"""` determines the indentation ignored for all lines within the literal.

*   **`Character` (Single Characters):**
    *   Used for a single character.
    *   While `String` is a collection of `Character` values, you can explicitly define a `Character`.

    ```swift
    let firstLetter: Character = "A"
    let exclamationMark: Character = "!"
    ```
    Note: Most of the time, you'll work with `String`s directly. `Character` is used less frequently but is important to understand the composition of strings.

**Type Aliases (`typealias`)**

Type aliases allow you to define an alternative name for an existing type. This can be useful for clarity or when working with complex types.

```swift
typealias AudioSample = UInt16
typealias UserID = String

var mySample: AudioSample = 0
var currentUserID: UserID = "user123"
```
Here, `AudioSample` is now another name for `UInt16`, and `UserID` is another name for `String`.

**1.7 Basic Operators**

Operators are special symbols or phrases that you use to check, change, or combine values.

*   **Assignment Operator (`=`):**
    *   Assigns a value to a variable or constant. We've already seen this:
        ```swift
        let a = 10
        var b = 5
        b = a // b is now 10
        ```
    *   Unlike C and Objective-C, the assignment operator in Swift does not itself return a value. This prevents accidental use of `=` (assignment) when `==` (equality) is intended in conditional statements.
        ```swift
        // if (x = y) { ... } // This is a compile-time error in Swift
        ```

*   **Arithmetic Operators:**
    *   Perform standard mathematical operations.
    *   `+` (addition)
    *   `-` (subtraction)
    *   `*` (multiplication)
    *   `/` (division)
    *   `%` (remainder / modulo)

    ```swift
    let sum = 10 + 5       // sum is 15
    let difference = 10 - 5  // difference is 5
    let product = 10 * 5     // product is 50
    let quotient = 10 / 5    // quotient is 2

    let dividend = 10.0
    let divisor = 4.0
    let floatingQuotient = dividend / divisor // floatingQuotient is 2.5 (because inputs are Double)

    let remainder = 9 % 4    // remainder is 1 (because 9 = 4 * 2 + 1)
    ```
    *   **Note on Division:** If you divide two `Int`s, the result will be an `Int`, and any fractional part is truncated (not rounded). `10 / 4` is `2`. If you need a floating-point result, at least one of the operands must be a floating-point type.
    *   **Remainder Operator:** The `%` operator works with both integers and floating-point numbers.
    *   **Unary Minus Operator (`-`):** Toggles the sign of a numeric value.
        ```swift
        let positiveNumber = 5
        let negativeNumber = -positiveNumber // negativeNumber is -5
        ```
    *   **Unary Plus Operator (`+`):** Doesn't actually change the value, but it's there for symmetry with the unary minus.
        ```swift
        let stillPositive = +positiveNumber // stillPositive is 5
        ```

*   **Compound Assignment Operators:**
    *   Combine assignment (`=`) with another operation.
    *   `+=` (add and assign)
    *   `-=` (subtract and assign)
    *   `*=` (multiply and assign)
    *   `/=` (divide and assign)
    *   `%=` (remainder and assign)

    ```swift
    var score = 100
    score += 10 // score is now 110 (equivalent to score = score + 10)
    score -= 5  // score is now 105
    score *= 2  // score is now 210
    score /= 3  // score is now 70
    ```

*   **Comparison Operators:**
    *   Compare two values and return a `Bool` (`true` or `false`).
    *   `==` (equal to)
    *   `!=` (not equal to)
    *   `>` (greater than)
    *   `<` (less than)
    *   `>=` (greater than or equal to)
    *   `<=` (less than or equal to)

    ```swift
    let x = 10
    let y = 5

    let isEqual = (x == y)     // false
    let isNotEqual = (x != y)   // true
    let isGreater = (x > y)    // true
    let isLess = (x < y)       // false
    let isGreaterOrEqual = (x >= 10) // true
    let isLessOrEqual = (y <= 5)    // true
    ```
    You can also compare strings:
    ```swift
    "apple" == "apple" // true
    "apple" < "banana" // true (lexicographical comparison)
    ```
    *   **Identity Operators (`===`, `!==`):** These are used to check if two *class instance* constants or variables refer to the exact same instance, not just if their values are equivalent. We'll discuss classes in a later chapter. For now, just be aware they exist.

*   **Ternary Conditional Operator (`a ? b : c`):**
    *   A shorthand for a simple `if-else` statement.
    *   It takes three parts: `question ? answerIfTrue : answerIfFalse`.
    *   If `question` is true, it evaluates and returns `answerIfTrue`; otherwise, it evaluates and returns `answerIfFalse`.

    ```swift
    let contentHeight = 40
    let hasHeader = true
    let rowHeight = contentHeight + (hasHeader ? 50 : 20)
    // If hasHeader is true, rowHeight is 40 + 50 = 90
    // If hasHeader is false, rowHeight is 40 + 20 = 60
    ```
    Use the ternary operator sparingly. It's great for concise assignments like the one above, but for more complex logic, a full `if-else` statement is more readable.

*   **Nil-Coalescing Operator (`a ?? b`):**
    *   Used with *optionals* (which we'll cover in detail later).
    *   It unwraps an optional `a` if it contains a value, or returns a default value `b` if `a` is `nil` (represents the absence of a value).
    *   Think of it as: `(a != nil) ? a! : b` (where `a!` forcefully unwraps `a`).

    ```swift
    let defaultColorName = "red"
    var userDefinedColorName: String? // This is an optional String, could be nil
    // userDefinedColorName = "blue" // Try uncommenting this

    let colorNameToUse = userDefinedColorName ?? defaultColorName
    // If userDefinedColorName is nil, colorNameToUse will be "red".
    // If userDefinedColorName was set to "blue", colorNameToUse would be "blue".
    ```
    We'll revisit this operator when we discuss optionals thoroughly.

*   **Range Operators:**
    *   Used to express a range of values.
    *   **Closed Range Operator (`a...b`):** Defines a range that runs from `a` to `b`, and *includes* the values `a` and `b`. `a` must not be greater than `b`.
        ```swift
        for index in 1...5 {
            print("\(index) times 5 is \(index * 5)")
        }
        // Output:
        // 1 times 5 is 5
        // 2 times 5 is 10
        // 3 times 5 is 15
        // 4 times 5 is 20
        // 5 times 5 is 25
        ```
    *   **Half-Open Range Operator (`a..<b`):** Defines a range that runs from `a` to `b`, but *excludes* `b`. `a` must not be greater than `b`.
        ```swift
        let names = ["Anna", "Alex", "Brian", "Jack"]
        let count = names.count // count is 4
        for i in 0..<count { // iterates from 0 up to (but not including) 4
            print("Person \(i + 1) is \(names[i])")
        }
        // Output:
        // Person 1 is Anna
        // Person 2 is Alex
        // Person 3 is Brian
        // Person 4 is Jack
        ```
    *   **One-Sided Ranges:** You can create ranges that continue as far as possible in one direction.
        *   `a...`: From `a` up to the end of the collection.
        *   `...a`: From the beginning of the collection up to and including `a`.
        *   `..<a`: From the beginning of the collection up to but not including `a`.

        ```swift
        // Example with an array (we'll cover arrays in detail soon)
        let numbers = [10, 20, 30, 40, 50]
        let firstThree = numbers[..<3] // [10, 20, 30]
        let fromIndexTwo = numbers[2...] // [30, 40, 50]
        ```

*   **Logical Operators:**
    *   Used to combine or modify boolean (`Bool`) values.
    *   Typically used in `if` statement conditions.
    *   `!` (Logical NOT / Prefix `!`): Inverts a boolean value. `!true` is `false`, and `!false` is `true`.
        ```swift
        let isAllowedEntry = false
        if !isAllowedEntry {
            print("Access denied.") // This will print
        }
        ```
    *   `&&` (Logical AND): Evaluates to `true` if *both* expressions on either side are `true`. If the left side is `false`, the right side is not even evaluated (short-circuit evaluation).
        ```swift
        let hasDoorKey = true
        let knowsPassword = false
        if hasDoorKey && knowsPassword {
            print("Welcome!")
        } else {
            print("Cannot enter.") // This will print
        }
        ```
    *   `||` (Logical OR): Evaluates to `true` if *at least one* of the expressions on either side is `true`. If the left side is `true`, the right side is not even evaluated (short-circuit evaluation).
        ```swift
        let hasCoupon = true
        let isMember = false
        if hasCoupon || isMember {
            print("Discount applied.") // This will print
        }
        ```
    *   **Combining Logical Operators:** You can combine multiple logical operators. Use parentheses `()` to clarify precedence if needed, though Swift has standard precedence rules (`!` first, then `&&`, then `||`).

        ```swift
        let enteredDoorCode = true
        let passedRetinaScan = false
        let hasOverrideKey = true

        if (enteredDoorCode && passedRetinaScan) || hasOverrideKey {
            print("Access granted.") // This will print
        }
        ```

**1.8 Numeric Type Conversion**

Swift is very strict about types. You cannot, for example, directly add an `Int` to a `Double` without explicitly converting one of them.

*   **Integer and Floating-Point Conversion:**
    To combine numeric types, you must explicitly convert them to a common type.

    ```swift
    let three = 3                 // Int
    let pointOneFourOneFiveNine = 0.14159 // Double

    // let pi = three + pointOneFourOneFiveNine // This is a COMPILE-TIME ERROR

    let piValue = Double(three) + pointOneFourOneFiveNine // piValue is 3.14159 (Double)
    // Double(three) creates a new Double value from the Int 'three'

    let integerPi = Int(piValue) // integerPi is 3 (Int), fractional part is truncated
    ```
    *   When converting a floating-point number to an integer, the fractional part is always truncated (removed), not rounded. `Int(3.99)` is `3`.
    *   When converting an integer to a floating-point number, the value is represented exactly if it fits.

*   **Literal Values:**
    Numeric literals themselves can be inferred by Swift to be whatever type is needed by their context, as long as the value fits:
    ```swift
    let myDouble = 3.14159 // Inferred as Double
    let myInt = 5          // Inferred as Int

    let anotherDouble = Double(myInt) + myDouble // Works because myInt is converted
    let yetAnotherDouble = 3 + 0.14159 // Works! The literal '3' can be treated as a Double here.
                                       // Swift can infer the type for integer and floating-point literals
                                       // if the context demands a certain type and the literal can be represented as such.
    ```
    The literal `3` doesn't have an explicit type on its own. Swift infers its type. If it's used in an expression with a `Double`, Swift treats `3` as a `Double`. If it's assigned to an `Int` variable, it's treated as an `Int`.

---

**Chapter 1 Summary:**

*   Swift is a modern, safe, fast, and expressive programming language.
*   Xcode Playgrounds are excellent for experimenting with Swift.
*   Comments (`//` and `/* ... */`) are crucial for code readability.
*   Constants (`let`) store values that don't change; Variables (`var`) store values that can.
*   Swift is type-safe; every value has a type. Types can be explicit (type annotation) or inferred by Swift.
*   Core data types include `Int`, `Double`, `Float`, `Bool`, `String`, and `Character`.
*   String interpolation (`\(...)`) allows embedding values within strings.
*   Swift offers a rich set of operators: assignment, arithmetic, compound assignment, comparison, ternary conditional, nil-coalescing, range, and logical operators.
*   Numeric type conversions must be explicit (e.g., `Double(myInt)`).

This chapter has laid the groundwork. You now know how to declare storage for data, the basic kinds of data Swift handles, and how to perform operations on that data. In the next chapter, we'll explore how to control the flow of execution in your programs using conditional statements and loops. 