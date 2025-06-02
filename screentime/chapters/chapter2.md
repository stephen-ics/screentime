**Chapter 2: Control Flow – Directing Your Code's Path**

In Chapter 1, we learned about the basic building blocks of Swift: constants, variables, data types, and operators. These allow us to store and manipulate data. Now, we need to learn how to make decisions and repeat actions based on that data. This is where *control flow* statements come in. They allow you to control the order in which your code is executed.

Swift provides a variety of control flow statements, including loops (`for-in`, `while`, `repeat-while`) to perform tasks multiple times, and conditional statements (`if`, `switch`, `guard`) to execute different branches of code based on certain conditions.

**2.1 Conditional Statements: Making Decisions**

Conditional statements allow your program to choose between different paths of execution.

**2.1.1 `if`, `else if`, `else`**

The most common way to make a decision is with an `if` statement. It executes a block of code only if a certain condition is true.

```swift
let temperatureInFahrenheit = 75

if temperatureInFahrenheit <= 32 {
    print("It's very cold. Consider wearing a scarf.")
}
// This code will not print because 75 is not <= 32
```

*   The condition (`temperatureInFahrenheit <= 32`) must be an expression that evaluates to a `Bool` (`true` or `false`).
*   The curly braces `{}` define the block of code (the "body") that runs if the condition is true. Braces are required in Swift, even if the body is only a single line. This improves code clarity and avoids potential errors.

You can extend an `if` statement with an `else` clause to provide an alternative block of code that executes if the `if` condition is `false`.

```swift
let temperatureInFahrenheit = 75

if temperatureInFahrenheit <= 32 {
    print("It's very cold. Consider wearing a scarf.")
} else {
    print("It's not that cold. No scarf needed.")
}
// This will print: "It's not that cold. No scarf needed."
```

You can chain multiple conditions together using `else if` to check for various possibilities:

```swift
let temperatureInFahrenheit = 75

if temperatureInFahrenheit <= 32 {
    print("It's very cold. Consider wearing a scarf.")
} else if temperatureInFahrenheit >= 86 {
    print("It's really warm. Protect yourself from the sun.")
} else { // Covers temperatures between 33 and 85 (inclusive)
    print("It's a pleasant day.")
}
// This will print: "It's a pleasant day."
```
Swift evaluates `if` / `else if` conditions in the order they appear. As soon as one condition is found to be true, its corresponding block of code is executed, and the rest of the `else if` / `else` chain is skipped. The final `else` clause is optional and acts as a catch-all if none of the preceding `if` or `else if` conditions are true.

**2.1.2 `switch`**

A `switch` statement provides a more powerful and often cleaner way to make decisions based on the value of a variable or expression, especially when there are multiple possible matches. It considers a value and compares it against several possible matching patterns.

```swift
let someCharacter: Character = "z"

switch someCharacter {
case "a":
    print("The first letter of the alphabet")
case "z":
    print("The last letter of the alphabet")
default: // 'default' is like 'else' - it catches all other cases
    print("Some other character")
}
// Output: The last letter of the alphabet
```

Key features of Swift's `switch` statement:

*   **Exhaustiveness:** `switch` statements in Swift must be *exhaustive*. This means that every possible value of the type being considered must be matched by one of the `case` statements. If it's not possible to list every single value (e.g., for a `String` or `Int`), you must include a `default` case. The `default` case matches any value not explicitly handled by other cases.
*   **No Implicit Fallthrough:** Unlike `switch` statements in C and some other languages, Swift `switch` cases do **not** "fall through" to the next case by default. Once a matching case is found and its code is executed, the `switch` statement finishes. This prevents common bugs. If you *explicitly want* C-style fallthrough behavior, you can use the `fallthrough` keyword.

    ```swift
    let number = 5
    var description = "The number \(number) is"

    switch number {
    case 2, 3, 5, 7, 11, 13, 17, 19: // Compound case: matches multiple values
        description += " a prime number, and also"
        fallthrough // Explicitly fall through to the default case
    default:
        description += " an integer."
    }
    print(description)
    // Output: The number 5 is a prime number, and also an integer.
    ```
    Use `fallthrough` with caution as it can make control flow harder to understand.

*   **Interval Matching (Ranges):** Cases can match ranges of values.

    ```swift
    let approximateCount = 62
    let countedThings = "moons orbiting Saturn"
    var naturalCount: String

    switch approximateCount {
    case 0:
        naturalCount = "no"
    case 1..<5: // Half-open range: 1, 2, 3, 4
        naturalCount = "a few"
    case 5..<12:
        naturalCount = "several"
    case 12..<100:
        naturalCount = "dozens of"
    case 100..<1000:
        naturalCount = "hundreds of"
    default:
        naturalCount = "many"
    }
    print("There are \(naturalCount) \(countedThings).")
    // Output: There are dozens of moons orbiting Saturn.
    ```

*   **Tuples:** You can use tuples in `switch` statements and test their values against different patterns.

    ```swift
    let somePoint = (1, 1) // A tuple representing (x, y) coordinates

    switch somePoint {
    case (0, 0):
        print("\(somePoint) is at the origin")
    case (_, 0): // Matches any point on the x-axis (y is 0)
        print("\(somePoint) is on the x-axis")
    case (0, _): // Matches any point on the y-axis (x is 0)
        print("\(somePoint) is on the y-axis")
    case (-2...2, -2...2): // Matches if x is between -2 and 2, AND y is between -2 and 2
        print("\(somePoint) is inside the 2x2 box")
    default:
        print("\(somePoint) is outside of the 2x2 box")
    }
    // Output: (1, 1) is inside the 2x2 box
    ```
    The underscore `_` is a wildcard pattern that matches any possible value.

*   **Value Bindings:** A `switch` case can bind the value(s) it matches to temporary constants or variables for use within the case's body. This is useful for extracting parts of a matched value.

    ```swift
    let anotherPoint = (2, 0)

    switch anotherPoint {
    case (let x, 0): // Binds the first element of the tuple to 'x' if the second is 0
        print("on the x-axis with an x value of \(x)")
    case (0, let y): // Binds the second element of the tuple to 'y' if the first is 0
        print("on the y-axis with a y value of \(y)")
    case let (x, y): // Binds both elements to 'x' and 'y' for any other point
        print("somewhere else at (\(x), \(y))")
    }
    // Output: on the x-axis with an x value of 2
    ```
    Here, `let x` creates a new constant `x` that holds the value of the first element of `anotherPoint` if the pattern matches. You could also use `var x` if you needed to modify `x` within the case.

*   **`where` Clauses:** A `case` can have an additional `where` clause to check for more specific conditions.

    ```swift
    let yetAnotherPoint = (1, -1)

    switch yetAnotherPoint {
    case let (x, y) where x == y:
        print("(\(x), \(y)) is on the line x == y")
    case let (x, y) where x == -y:
        print("(\(x), \(y)) is on the line x == -y")
    case let (x, y):
        print("(\(x), \(y)) is just some arbitrary point")
    }
    // Output: (1, -1) is on the line x == -y
    ```
    A `where` clause provides a dynamic filter to the case pattern.

**2.1.3 `guard`**

A `guard` statement is used for early exit from a scope (like a function, loop, or other conditional block) if a condition is not met. It's particularly useful for validating inputs or conditions at the beginning of a function.

```swift
func greet(person: [String: String]) {
    guard let name = person["name"] else {
        // 'name' is nil, so the condition 'let name = person["name"]' is false
        print("Hello, anonymous!")
        return // 'return' exits the function 'greet'
    }

    // If we reach here, 'name' is guaranteed to have a value
    // and is available for use in the rest of the function's scope.
    print("Hello, \(name)!")

    guard let location = person["location"] else {
        print("I hope the weather is nice near you.")
        return
    }

    print("I hope the weather is nice in \(location).")
}

greet(person: ["name": "Alice", "location": "Wonderland"])
// Output:
// Hello, Alice!
// I hope the weather is nice in Wonderland.

greet(person: ["name": "Bob"])
// Output:
// Hello, Bob!
// I hope the weather is nice near you.

greet(person: [:])
// Output:
// Hello, anonymous!
```

Key characteristics of `guard`:

*   **Early Exit:** The `else` block of a `guard` statement *must* exit the current scope. This is typically done with `return` (to exit a function), `break` (to exit a loop), `continue` (to go to the next iteration of a loop), or by calling a function that doesn't return (like `fatalError()`).
*   **Availability After Guard:** If the `guard` condition is true (i.e., the `else` block is not executed), any variables or constants assigned as part of the condition (like `name` in `guard let name = ...`) are available for use in the rest of the code block where the `guard` statement appears. This is a major advantage over `if let`, where the unwrapped optional is only available inside the `if` block.
*   **Improved Readability for Preconditions:** `guard` statements are excellent for checking preconditions at the start of a function, making it clear what requirements must be met for the function to proceed. This avoids deeply nested `if` statements.

**Comparing `guard let` and `if let` (for Optional Unwrapping):**

Both `guard let` and `if let` are used to safely unwrap optionals (which we'll cover in detail in a later chapter, but you saw a glimpse with `person["name"]` which might or might not exist).

*   `if let optional = someOptional { ... }`: The unwrapped `optional` is only available *inside* the curly braces of the `if` statement.
*   `guard let optional = someOptional else { return }`: The unwrapped `optional` is available *after* the `guard` statement, in the same scope. The `else` block *must* exit.

`guard` promotes a "happy path" coding style where you handle error conditions or invalid states upfront and then the rest of the function can proceed with the assumption that these conditions have been met.

**2.2 Loops: Repeating Code**

Loops allow you to execute a block of code multiple times.

**2.2.1 `for-in` Loop**

The `for-in` loop is used to iterate over a sequence, such as items in an array, characters in a string, ranges of numbers, or key-value pairs in a dictionary.

*   **Iterating Over a Range:**

    ```swift
    for index in 1...5 { // Iterates from 1 up to and including 5
        print("\(index) times 5 is \(index * 5)")
    }
    // Output:
    // 1 times 5 is 5
    // ...
    // 5 times 5 is 25
    ```

*   **Iterating Over an Array (Collections will be covered in Chapter 3):**

    ```swift
    let names = ["Anna", "Alex", "Brian", "Jack"]
    for name in names {
        print("Hello, \(name)!")
    }
    // Output:
    // Hello, Anna!
    // Hello, Alex!
    // Hello, Brian!
    // Hello, Jack!
    ```

*   **Iterating Over a Dictionary (Chapter 3):**

    ```swift
    let numberOfLegs = ["spider": 8, "ant": 6, "cat": 4]
    for (animalName, legCount) in numberOfLegs {
        print("\(animalName)s have \(legCount) legs")
    }
    // Output (order may vary as dictionaries are unordered):
    // cats have 4 legs
    // ants have 6 legs
    // spiders have 8 legs
    ```

*   **Iterating Over a String's Characters:**

    ```swift
    let greeting = "Hello"
    for character in greeting {
        print(character)
    }
    // Output:
    // H
    // e
    // l
    // l
    // o
    ```

*   **If You Don't Need the Value from the Sequence:**
    If you only need to repeat a block of code a certain number of times and don't need the actual value from the sequence in each iteration, you can use an underscore `_` in place of the loop variable.

    ```swift
    let base = 3
    let power = 4
    var answer = 1
    for _ in 1...power { // We don't need 'index', just the number of repetitions
        answer *= base
    }
    print("\(base) to the power of \(power) is \(answer)") // Output: 3 to the power of 4 is 81
    ```

**2.2.2 `while` Loop**

A `while` loop performs a set of statements *as long as* a condition is true. The condition is evaluated *before* each execution of the loop's body.

```swift
var countdown = 5
while countdown > 0 {
    print("\(countdown)...")
    countdown -= 1 // Decrease countdown by 1
}
print("Blast off!")
// Output:
// 5...
// 4...
// 3...
// 2...
// 1...
// Blast off!
```
If the condition is `false` at the very beginning, the loop body will not execute at all.

**2.2.3 `repeat-while` Loop**

The `repeat-while` loop is similar to a `while` loop, but the condition is evaluated *after* each execution of the loop's body. This means the loop body is always executed at least once.

```swift
var numberToGuess = 7
var currentGuess: Int

repeat {
    currentGuess = Int.random(in: 1...10) // Generate a random number between 1 and 10
    print("Guessed: \(currentGuess)")
} while currentGuess != numberToGuess

print("Correct! The number was \(numberToGuess).")
// Example Output (will vary due to random numbers):
// Guessed: 3
// Guessed: 9
// Guessed: 1
// Guessed: 7
// Correct! The number was 7.
```
The code inside the `repeat` block is executed, and then the `while` condition (`currentGuess != numberToGuess`) is checked. If it's true, the loop repeats. If it's false, the loop terminates.

**2.3 Loop Control Statements: Modifying Loop Behavior**

Sometimes you need more fine-grained control over how a loop executes.

*   **`continue`:**
    The `continue` statement tells a loop to stop what it's doing in the current iteration and immediately start the next iteration of the loop.

    ```swift
    let puzzleInput = "great minds think alike."
    var puzzleOutput = ""
    let vowels: [Character] = ["a", "e", "i", "o", "u", " "] // also removing spaces

    for character in puzzleInput {
        if vowels.contains(character) {
            continue // Skip vowels and spaces, go to next character
        }
        puzzleOutput.append(character)
    }
    print(puzzleOutput) // Output: grtmndsthnklk.
    ```

*   **`break`:**
    The `break` statement immediately terminates the execution of the entire control flow statement it belongs to (e.g., a `switch` statement or a loop).

    ```swift
    let targetNumber = 7
    var found = false
    for i in 1...100 {
        if i == targetNumber {
            found = true
            print("Found \(targetNumber) at iteration \(i).")
            break // Exit the for-in loop immediately
        }
        print("Checking \(i)...") // This won't print for i >= targetNumber
    }
    if found {
        print("Search successful.")
    }
    // Output:
    // Checking 1...
    // ...
    // Checking 6...
    // Found 7 at iteration 7.
    // Search successful.
    ```

*   **Labeled Statements (for nested loops/switches):**
    If you have nested loops or `switch` statements, `break` and `continue` normally apply to the innermost loop or switch they are part of. To `break` out of or `continue` an outer loop/switch, you can use a *statement label*. A label is a name you give to a loop or conditional statement, followed by a colon.

    ```swift
    gameLoop: while true { // Label the outer while loop as 'gameLoop'
        let command = "move_north" // Simulate getting a command

        switch command {
        case "exit_game":
            print("Exiting game...")
            break gameLoop // Break out of the 'gameLoop' (the outer while loop)

        case "move_north", "move_south":
            print("Player moves \(command).")
            // Imagine more game logic here
            if Bool.random() { // Simulate a random event causing loop to restart
                print("Random event! Restarting command processing.")
                continue gameLoop // Continue the next iteration of 'gameLoop'
            }
            print("Move successful.")

        default:
            print("Unknown command: \(command)")
        }
        print("End of command processing turn.") // This might be skipped by continue/break
        break gameLoop // For this example, break after one command processing cycle
    }
    print("Game loop ended.")
    ```
    In this example, `break gameLoop` will terminate the `while true` loop, not just the `switch` statement. `continue gameLoop` will start the next iteration of the `while true` loop. Labels make it clear which control statement you are targeting.

**2.4 Checking API Availability (`#available`)**

Sometimes you'll write code that needs to use APIs only available in newer versions of an operating system (like iOS or macOS) or Swift itself. To safely use these APIs and ensure your app runs on older OS versions without crashing, you can use an availability condition with `#available`.

```swift
if #available(iOS 15, macOS 12, *) {
    // Use iOS 15 APIs and macOS 12 APIs
    print("Running on iOS 15+ or macOS 12+ (or other future platforms).")
    // Example: newShinyAPICall()
} else {
    // Fallback for older versions
    print("Running on an older OS. Using fallback methods.")
    // Example: oldReliableAPICall()
}
```
*   The arguments to `#available` are a list of platform names and versions.
*   The last argument, `*`, is required and indicates that on any other platform not listed, the code in the `if` block will execute if the OS version is the minimum deployment target of your app or newer.
*   The `#available` condition returns a `Bool`.
*   You can also use `#available` in `guard` statements:

    ```swift
    guard #available(iOS 15, *) else {
        // Fallback and exit scope
        print("This feature requires iOS 15 or later.")
        return
    }
    // Proceed with iOS 15 specific APIs
    print("iOS 15 features enabled.")
    ```

This is particularly important when adopting new SwiftUI features or framework capabilities that are tied to specific OS releases.

---

**Chapter 2 Summary:**

*   **Conditional Statements** allow your code to make decisions:
    *   `if`, `else if`, `else`: For simple to moderately complex branching logic.
    *   `switch`: For powerful pattern matching against a value, offering exhaustive checks, range matching, tuple matching, value binding, and `where` clauses. Swift's `switch` cases don't fall through by default.
    *   `guard`: For early exit if a condition isn't met, often used for validating preconditions. Values bound in a `guard` condition are available in the subsequent scope.
*   **Looping Statements** allow your code to repeat tasks:
    *   `for-in`: Iterates over sequences like ranges, arrays, dictionary elements, or string characters.
    *   `while`: Repeats a block of code as long as a condition is true (condition checked *before* iteration).
    *   `repeat-while`: Repeats a block of code as long as a condition is true (condition checked *after* iteration, so body always executes at least once).
*   **Loop Control Statements** modify loop behavior:
    *   `continue`: Skips the rest of the current loop iteration and starts the next one.
    *   `break`: Exits the loop (or `switch` statement) entirely.
    *   **Labeled Statements**: Allow `break` and `continue` to target specific outer loops or switches in nested structures.
*   **API Availability Check (`#available`)**: Safely use APIs that are specific to certain OS versions or Swift versions, providing fallbacks for older systems.

With control flow, you can now write programs that react differently to varying inputs and situations, and that can perform repetitive tasks efficiently. The combination of variables, operators, and control flow forms the core logic of almost any program.

--- 