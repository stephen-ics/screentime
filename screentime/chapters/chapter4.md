**Chapter 4: Functions and Closures – Encapsulating and Passing Code**

In previous chapters, you've already encountered and used functions like `print()`. Functions are fundamental building blocks in Swift that allow you to encapsulate a piece of code that performs a specific task. By defining functions, you can make your code more organized, reusable, and easier to understand. Closures are a more general concept: they are self-contained blocks of functionality that can be passed around and used in your code. Functions are actually a special type of closure.

**4.1 Defining and Calling Functions**

*   **Basic Function Syntax:**
    You define a function using the `func` keyword, followed by the function name, a list of parameters in parentheses, a return arrow `->` and the return type. If the function doesn't return a value, you can use `Void` or omit the return arrow and type.

    ```swift
    // Function that takes no parameters and returns no value (Void)
    func greetUser() {
        print("Hello, valued user!")
    }
    greetUser() // Calling the function

    // Function that takes one parameter and returns a String
    func greetByName(name: String) -> String {
        return "Hello, \(name)!"
    }
    let greetingMessage = greetByName(name: "Alice")
    print(greetingMessage) // Output: Hello, Alice!

    // Function with multiple parameters
    func addNumbers(a: Int, b: Int) -> Int {
        return a + b
    }
    let sum = addNumbers(a: 5, b: 3)
    print("Sum: \(sum)") // Output: Sum: 8

    // Function that returns no value explicitly (implicitly returns Void)
    func printSum(a: Int, b: Int) {
        print("The sum is \(a + b)")
    }
    printSum(a: 10, b: 7) // Output: The sum is 17
    ```

*   **Function Parameter Names and Argument Labels:**
    Each function parameter has both an *argument label* and a *parameter name*.
    *   The **argument label** is used when calling the function (it appears before the argument value).
    *   The **parameter name** is used in the implementation of the function.
    By default, parameter names are used as their argument labels.

    ```swift
    func power(base: Int, exponent: Int) -> Int { // 'base' and 'exponent' are both argument labels and parameter names
        var result = 1
        for _ in 0..<exponent {
            result *= base
        }
        return result
    }
    print(power(base: 2, exponent: 3)) // Output: 8
    ```

    *   **Specifying Argument Labels:** You can specify a different argument label by writing it before the parameter name, separated by a space.

        ```swift
        func sendMessage(to recipient: String, messageText: String) {
            // Inside the function, use 'recipient' and 'messageText'
            print("Sending to \(recipient): \(messageText)")
        }
        sendMessage(to: "Bob", messageText: "Meeting at 3 PM.") // 'to' and 'messageText' are argument labels
        ```

    *   **Omitting Argument Labels:** If you don't want an argument label for a parameter, use an underscore `_` in place of an explicit argument label.

        ```swift
        func multiply(_ number1: Int, by number2: Int) -> Int {
            return number1 * number2
        }
        let product = multiply(5, by: 4) // No argument label for the first parameter
        print("Product: \(product)") // Output: Product: 20
        ```
        It's common to omit the argument label for the first parameter if the function's name already makes its role clear (e.g., `multiply(5, by: 4)` reads naturally).

*   **Default Parameter Values:**
    You can define a default value for any parameter by assigning a value to it after the parameter's type. If a default value is provided, you can omit that argument when calling the function, and the default value will be used.

    ```swift
    func createGreeting(for person: String, withGreeting greeting: String = "Hello") -> String {
        return "\(greeting), \(person)!"
    }

    print(createGreeting(for: "Maria")) // Uses default greeting: "Hello, Maria!"
    print(createGreeting(for: "Carlos", withGreeting: "Hola")) // Provides a specific greeting: "Hola, Carlos!"
    ```
    Parameters with default values are usually placed at the end of the parameter list for clarity.

*   **Variadic Parameters:**
    A variadic parameter accepts zero or more values of a specified type. You indicate a variadic parameter by inserting three period characters (`...`) after the parameter's type name. The values passed to a variadic parameter are made available within the function's body as an array of the appropriate type.

    ```swift
    func calculateAverage(_ numbers: Double...) -> Double {
        if numbers.isEmpty {
            return 0.0
        }
        var total: Double = 0
        for number in numbers { // 'numbers' is an array [Double] here
            total += number
        }
        return total / Double(numbers.count)
    }

    print(calculateAverage(1.0, 2.0, 3.0, 4.0, 5.0)) // Output: 3.0
    print(calculateAverage(10.5, 20.5))           // Output: 15.5
    print(calculateAverage())                      // Output: 0.0
    ```
    A function can have at most one variadic parameter, and it must usually be the last parameter in the list if there are others (unless subsequent parameters have labels).

*   **In-Out Parameters (`inout`):**
    Function parameters are constants by default. Trying to modify a function parameter from within the body of that function results in a compile-time error. If you want a function to modify a parameter's value, and you want those changes to persist *after* the function call has ended, define that parameter as an *in-out parameter*.

    You write `inout` directly before a parameter's type. When calling a function with an `inout` parameter, you place an ampersand (`&`) directly before a variable's name to indicate that it can be modified by the function.

    ```swift
    func swapTwoInts(_ a: inout Int, _ b: inout Int) {
        let temporaryA = a
        a = b
        b = temporaryA
    }

    var someInt = 3
    var anotherInt = 107
    print("Before swap: someInt is \(someInt), anotherInt is \(anotherInt)")
    swapTwoInts(&someInt, &anotherInt)
    print("After swap: someInt is \(someInt), anotherInt is \(anotherInt)")
    // Output:
    // Before swap: someInt is 3, anotherInt is 107
    // After swap: someInt is 107, anotherInt is 3
    ```
    In-out parameters cannot have default values, and variadic parameters cannot be marked as `inout`. You can only pass a variable (`var`) as the argument for an in-out parameter. You cannot pass a constant (`let`) or a literal value.

**4.2 Function Types**

Every function in Swift has a specific *function type*, made up of the parameter types and the return type of the function.

*   For example, the function `func add(a: Int, b: Int) -> Int` has a function type of `(Int, Int) -> Int`.
*   A function `func sayHello() -> Void` has a function type of `() -> Void`.

You can use function types just like any other type in Swift:

*   **Assigning Function Types to Variables/Constants:**

    ```swift
    func multiply(a: Int, b: Int) -> Int {
        return a * b
    }
    var mathOperation: (Int, Int) -> Int // Declaring a variable of a function type
    mathOperation = addNumbers // 'addNumbers' from earlier example
    print("Result of mathOperation (add): \(mathOperation(2, 3))") // Output: 5

    mathOperation = multiply
    print("Result of mathOperation (multiply): \(mathOperation(2, 3))") // Output: 6
    ```

*   **Function Types as Parameter Types:**
    You can pass a function as an argument to another function.

    ```swift
    func performMathOperation(_ operation: (Int, Int) -> Int, on a: Int, and b: Int) -> Int {
        return operation(a, b)
    }

    let resultSum = performMathOperation(addNumbers, on: 10, and: 5)
    print("Using function as parameter (sum): \(resultSum)") // Output: 15

    let resultProduct = performMathOperation(multiply, on: 10, and: 5)
    print("Using function as parameter (product): \(resultProduct)") // Output: 50
    ```

*   **Function Types as Return Types:**
    You can have a function that returns another function.

    ```swift
    func stepForward(_ input: Int) -> Int {
        return input + 1
    }
    func stepBackward(_ input: Int) -> Int {
        return input - 1
    }

    func chooseStepFunction(goForwards: Bool) -> (Int) -> Int {
        if goForwards {
            return stepForward
        } else {
            return stepBackward
        }
    }

    var currentValue = 3
    let moveNearerToZero = chooseStepFunction(goForwards: currentValue > 0) // Returns stepBackward

    print("Current value: \(currentValue)")
    while currentValue != 0 {
        currentValue = moveNearerToZero(currentValue)
        print("Now: \(currentValue)")
    }
    // Output:
    // Current value: 3
    // Now: 2
    // Now: 1
    // Now: 0
    ```

**4.3 Nested Functions**

You can define functions inside the bodies of other functions, known as *nested functions*. Nested functions are hidden from the outside world by default but can be called by their enclosing function. An enclosing function can also return one of its nested functions to allow it to be used in another scope.

```swift
func processTransaction(amount: Double, isCredit: Bool) -> String {
    func applyFee(baseAmount: Double) -> Double { // Nested function
        return baseAmount * 1.02 // Apply a 2% fee
    }

    func formatCurrency(_ value: Double) -> String { // Another nested function
        return String(format: "$%.2f", value)
    }

    let finalAmount = isCredit ? amount : applyFee(baseAmount: amount)
    return "Transaction: \(formatCurrency(finalAmount)) \(isCredit ? "(Credit)" : "(Debit with fee)")"
}

print(processTransaction(amount: 100.0, isCredit: false)) // Output: Transaction: $102.00 (Debit with fee)
print(processTransaction(amount: 50.0, isCredit: true))  // Output: Transaction: $50.00 (Credit)
```
Nested functions can capture values from their enclosing scope (more on capturing with closures).

**4.4 Closures**

Closures are self-contained blocks of functionality that can be passed around and used in your code. They can *capture* and store references to any constants and variables from the context in which they are defined. Swift's closures are similar to blocks in C and Objective-C and lambdas in other programming languages.

Functions, as we've discussed, are actually a special case of closures. There are three forms of closures:

1.  **Global functions:** Closures that have a name and do not capture any values.
2.  **Nested functions:** Closures that have a name and can capture values from their enclosing function.
3.  **Closure expressions:** Unnamed closures written in a lightweight syntax that can capture values from their surrounding context.

We'll focus on *closure expressions* here, as they provide concise ways to write inline functionality.

*   **Closure Expression Syntax:**
    The general form of a closure expression is:
    ```
    { (parameters) -> returnType in
        statements
    }
    ```

    Example: The `sorted(by:)` method on arrays takes a closure that defines how to compare two elements.

    ```swift
    let names = ["Chris", "Alex", "Ewa", "Barry", "Daniella"]

    // Using a regular function for sorting
    func backward(_ s1: String, _ s2: String) -> Bool {
        return s1 > s2
    }
    var reversedNames = names.sorted(by: backward)
    print(reversedNames) // Output: ["Ewa", "Daniella", "Chris", "Barry", "Alex"]

    // Using a closure expression inline
    reversedNames = names.sorted(by: { (s1: String, s2: String) -> Bool in
        return s1 > s2
    })
    print(reversedNames) // Same output

    // Swift can infer types from context
    reversedNames = names.sorted(by: { s1, s2 in return s1 > s2 })

    // Implicit returns from single-expression closures
    // If the closure body is a single expression, the 'return' keyword can be omitted.
    reversedNames = names.sorted(by: { s1, s2 in s1 > s2 })

    // Shorthand Argument Names
    // Swift automatically provides shorthand argument names to inline closures ($0, $1, $2, etc.)
    reversedNames = names.sorted(by: { $0 > $1 })

    // Operator Methods
    // If the closure is just an operator, you can use the operator directly (like > for strings)
    reversedNames = names.sorted(by: >)
    print(reversedNames) // Still the same output
    ```

*   **Trailing Closures:**
    If a function's last argument is a closure, you can write it as a *trailing closure* after the function call's parentheses. If the closure is the *only* argument, you can omit the parentheses entirely.

    ```swift
    func someFunctionThatTakesAClosure(closure: () -> Void) {
        // function body
        closure()
    }

    // Calling without trailing closure:
    someFunctionThatTakesAClosure(closure: {
        print("Closure executed (no trailing).")
    })

    // Calling with trailing closure:
    someFunctionThatTakesAClosure() {
        print("Closure executed (trailing).")
    }

    // If closure is the only argument, parentheses can be omitted:
    reversedNames = names.sorted { $0 > $1 } // 'by:' label is also omitted
    print(reversedNames)

    // Example: map function with trailing closure
    let digitNames = [0: "Zero", 1: "One", 2: "Two", 3: "Three", 4: "Four"]
    let numbers = [1, 2, 3]
    let strings = numbers.map { (number) -> String in
        var output = ""
        // ... logic to convert number to string using digitNames ...
        output = digitNames[number] ?? ""
        return output
    }
    print(strings) // Output: ["One", "Two", "Three"]
    ```

*   **Capturing Values:**
    A closure can *capture* constants and variables from the surrounding context in which it is defined. The closure can then refer to and modify the values of those constants and variables from within its body, even if the original scope that defined the constants and variables no longer exists.
    The most common form of capturing is when a nested function captures values from its enclosing function.

    ```swift
    func makeIncrementer(forIncrement amount: Int) -> () -> Int {
        var runningTotal = 0
        func incrementer() -> Int { // This nested function is a closure
            runningTotal += amount // Captures 'runningTotal' and 'amount'
            return runningTotal
        }
        return incrementer
    }

    let incrementByTen = makeIncrementer(forIncrement: 10)
    print(incrementByTen()) // Output: 10 (runningTotal is now 10)
    print(incrementByTen()) // Output: 20 (runningTotal is now 20)

    let incrementBySeven = makeIncrementer(forIncrement: 7)
    print(incrementBySeven()) // Output: 7 (This has its own 'runningTotal')

    print(incrementByTen()) // Output: 30 (This continues with its own 'runningTotal')
    ```
    Swift handles all memory management of captured values. If you assign a closure to a property of a class instance, and the closure captures that instance (e.g., by accessing `self.someProperty`), you create a *strong reference cycle* between the closure and the instance. Swift uses *capture lists* to break these cycles (e.g., `[weak self]`). This is a more advanced topic.

*   **Escaping Closures (`@escaping`):**
    A closure is said to *escape* a function when the closure is passed as an argument to the function, but is called *after* the function returns. This can happen if the closure is stored in a variable that exists outside the function or is part of an asynchronous operation.
    When you declare a function that takes a closure as one of its parameters, you write `@escaping` before the parameter's type to indicate that the closure is allowed to escape.

    ```swift
    var completionHandlers: [() -> Void] = [] // Array to store escaping closures

    func someFunctionWithEscapingClosure(completionHandler: @escaping () -> Void) {
        completionHandlers.append(completionHandler)
        print("Function body executed, completion handler stored.")
    }

    func someFunctionWithNonescapingClosure(closure: () -> Void) {
        print("Function with non-escaping closure called.")
        closure() // Called immediately
        print("Function with non-escaping closure finished.")
    }

    someFunctionWithEscapingClosure { print("Escaping closure called!") }
    someFunctionWithEscapingClosure { print("Another escaping closure called!") }

    print("About to call stored completion handlers...")
    for handler in completionHandlers {
        handler() // Call them later
    }
    // Output:
    // Function body executed, completion handler stored.
    // Function body executed, completion handler stored.
    // About to call stored completion handlers...
    // Escaping closure called!
    // Another escaping closure called!

    someFunctionWithNonescapingClosure { print("Non-escaping closure is running.") }
    // Output:
    // Function with non-escaping closure called.
    // Non-escaping closure is running.
    // Function with non-escaping closure finished.
    ```
    Marking a closure with `@escaping` means you have to be mindful of memory management, especially `self` capture in class methods. Non-escaping closures offer some performance optimizations because the compiler knows they won't outlive the function call.

*   **Autoclosures (`@autoclosure`):**
    An autoclosure is a closure that is automatically created to wrap an expression that's being passed as an argument to a function. It doesn't take any arguments, and when it's called, it returns the value of the expression that's wrapped inside of it. This syntactic convenience lets you omit braces around a function's parameter when that parameter is a closure that takes no arguments and returns a value.

    ```swift
    var customersInLine = ["Chris", "Alex", "Ewa", "Barry", "Daniella"]
    print(customersInLine.count) // Prints "5"

    // The 'remove(at:)' method takes an Int.
    // The closure here is executed only if 'customersInLine' is not empty.
    let customerProvider = { customersInLine.remove(at: 0) } // Explicit closure
    print("Now serving \(customerProvider())!") // Prints "Now serving Chris!"

    // Using @autoclosure
    // 'customerProvider' parameter is an autoclosure.
    // It takes an expression 'String' and wraps it in a closure '() -> String'.
    func serve(customer customerProvider: @autoclosure () -> String) {
        print("Now serving \(customerProvider())!")
    }
    serve(customer: customersInLine.remove(at: 0)) // No braces needed around customersInLine.remove(at: 0)
                                                // Prints "Now serving Alex!"
    ```
    Autoclosures are often used in operations that should be delayed (like the `&&` and `||` operators, or an `assert` function where the message expression is only evaluated if the assertion fails). Use `@autoclosure` with care as it can make code less clear if overused. Adding `@escaping` to an `@autoclosure` (`@autoclosure @escaping`) allows the autoclosure to escape.

--- 