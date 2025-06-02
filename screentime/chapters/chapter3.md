**Chapter 3: Collections – Organizing and Managing Groups of Data**

In the previous chapters, we learned how to store individual pieces of data using constants and variables, and how to control the flow of our programs. However, most real-world applications need to work with groups of data. You might need to manage a list of user names, a set of unique tags, or a directory of settings where each setting has a name and a value. Swift provides three primary *collection types* for storing and organizing groups of data: **Arrays**, **Sets**, and **Dictionaries**.

These collection types are implemented using *Swift generics*. This means they can be type-safe and store any specific type of data. For example, you can have an array of `Int` values, or an array of `String` values, but you can't mix `Int`s and `String`s in the same array unless you explicitly define it to hold a more general type (like `Any`, which we'll touch on later, though it's generally best to be specific). This type safety helps catch errors at compile time.

A crucial characteristic of Swift's collection types (Arrays, Sets, and Dictionaries) is that they are *value types*. This means when you assign them to a new constant or variable, or pass them to a function, a *copy* of the collection is made. If you then modify the copy, the original collection remains unchanged. This behavior helps prevent unintended side effects and makes reasoning about your code easier. Swift employs an optimization called *Copy-on-Write (CoW)* for these collections. This means that the actual copying of the collection's data is deferred until one of the copies is modified. Until then, multiple copies might share the same underlying storage, making copying efficient if no modifications occur.

Let's explore each collection type in extensive detail.

**3.1 Arrays: Ordered Collections of Elements**

An **Array** is an ordered collection of elements of the same type. "Ordered" means that the elements are stored in a specific sequence, and they maintain that sequence. Each element in an array has an *index*, which is an integer representing its position. Array indices in Swift are *zero-based*, meaning the first element is at index 0, the second at index 1, and so on.

Arrays are one of the most common collection types you'll use. They are suitable when:
*   The order of elements matters.
*   You need to access elements by their position (index).
*   Duplicate elements are allowed.

**3.1.1 Creating Arrays**

There are several ways to create arrays in Swift:

*   **Creating an Empty Array:**
    You can create an empty array by specifying the element type.

    ```swift
    // Syntax: var arrayName = [ElementType]() or var arrayName: [ElementType] = []
    var emptyIntegerArray = [Int]()
    print("emptyIntegerArray is of type [Int] with \(emptyIntegerArray.count) items.") // Output: emptyIntegerArray is of type [Int] with 0 items.

    var emptyStringArray: [String] = []
    print("emptyStringArray has \(emptyStringArray.count) elements.") // Output: emptyStringArray has 0 elements.

    // If context provides type information, you can use []:
    var names: [String] = [] // Explicit type
    let inferredEmptyArray = [] // This creates an empty array of type [Never] initially.
                                // It will get a concrete type if you add elements or use it in a typed context.
                                // It's usually better to be explicit for empty arrays.
    ```

*   **Creating an Array with a Default Value (Repeating Initializer):**
    You can create an array of a certain size where all elements are initialized to the same default value.

    ```swift
    // Syntax: Array(repeating: initialValue, count: numberOfElements)
    var threeDoubles = Array(repeating: 0.0, count: 3)
    print(threeDoubles) // Output: [0.0, 0.0, 0.0]

    var fiveTrues = Array(repeating: true, count: 5)
    print(fiveTrues) // Output: [true, true, true, true, true]
    ```

*   **Creating an Array with an Array Literal:**
    The most common way to create an array is by using an *array literal* – a comma-separated list of values enclosed in square brackets `[]`. Swift infers the array's element type from the types of the values in the literal. All values in an array literal must be of the same type.

    ```swift
    var shoppingList: [String] = ["Eggs", "Milk", "Bread"]
    print(shoppingList) // Output: ["Eggs", "Milk", "Bread"]

    // Type inference works here too:
    var primeNumbers = [2, 3, 5, 7, 11, 13] // Swift infers type [Int]
    print(primeNumbers) // Output: [2, 3, 5, 7, 11, 13]

    var mixedTypes = [1, "Hello"] // COMPILE-TIME ERROR: Array literal cannot contain values of different types.
                                  // Unless you explicitly type it as [Any]
    var heterogeneousArray: [Any] = [1, "Hello", true, 3.14]
    print(heterogeneousArray) // Output: [1, "Hello", true, 3.14]
    // Note: While [Any] is possible, it sacrifices type safety and often requires type casting later.
    // It's generally better to create arrays of a specific, known type.
    ```

**3.1.2 Accessing and Modifying Array Elements**

*   **Getting the Number of Elements (`count`):**
    The `count` property returns the number of elements in the array.

    ```swift
    let numbers = [10, 20, 30, 40, 50]
    print("The array 'numbers' has \(numbers.count) elements.") // Output: The array 'numbers' has 5 elements.

    let emptyArray = [String]()
    print("emptyArray has \(emptyArray.count) elements.") // Output: emptyArray has 0 elements.
    ```

*   **Checking if an Array is Empty (`isEmpty`):**
    The `isEmpty` property returns a boolean value indicating whether the `count` is 0. This is often more efficient than checking `array.count == 0`.

    ```swift
    if numbers.isEmpty {
        print("The numbers array is empty.")
    } else {
        print("The numbers array is not empty.") // This will print
    }

    if emptyArray.isEmpty {
        print("The emptyArray is indeed empty.") // This will print
    }
    ```

*   **Accessing Elements using Subscript Syntax:**
    You can retrieve an element from an array by using *subscript syntax*, passing the index of the element you want to access within square brackets after the array's name. Remember, indices are zero-based.

    ```swift
    var letters = ["A", "B", "C", "D", "E"]

    let firstLetter = letters[0] // "A"
    let thirdLetter = letters[2] // "C"
    print("First: \(firstLetter), Third: \(thirdLetter)") // Output: First: A, Third: C

    // Accessing an index that is out of bounds will cause a RUNTIME ERROR.
    // let outOfBounds = letters[10] // This would crash your program.
    // Always ensure the index is valid: index >= 0 && index < array.count
    ```
    Before accessing an element by index, it's good practice to check if the index is within the valid range:
    ```swift
    let indexToAccess = 2
    if indexToAccess >= 0 && indexToAccess < letters.count {
        let letter = letters[indexToAccess]
        print("Letter at index \(indexToAccess) is \(letter)")
    } else {
        print("Index \(indexToAccess) is out of bounds for letters array.")
    }
    ```

*   **Accessing First and Last Elements (`first`, `last`):**
    Arrays provide `first` and `last` properties to safely access the first and last elements. These properties return an *optional* value of the array's element type because an empty array has no first or last element.

    ```swift
    let names = ["Alice", "Bob", "Charlie"]
    if let firstPerson = names.first {
        print("The first person is \(firstPerson).") // Output: The first person is Alice.
    }

    if let lastPerson = names.last {
        print("The last person is \(lastPerson).") // Output: The last person is Charlie.
    }

    let emptyNames = [String]()
    if let firstInEmpty = emptyNames.first {
        print("First in empty: \(firstInEmpty)") // This won't print
    } else {
        print("emptyNames array has no first element.") // Output: emptyNames array has no first element.
    }
    ```

*   **Modifying Elements using Subscript Syntax:**
    If the array is declared as a variable (`var`), you can change an existing element at a specific index using subscript syntax.

    ```swift
    var colors = ["Red", "Green", "Blue"]
    print("Original colors: \(colors)") // Output: Original colors: ["Red", "Green", "Blue"]

    colors[0] = "Crimson" // Change the first element
    colors[2] = "Navy"    // Change the third element
    print("Modified colors: \(colors)") // Output: Modified colors: ["Crimson", "Green", "Navy"]

    // You cannot use subscript syntax to add a new item to an array at an index that doesn't exist.
    // colors[3] = "Yellow" // RUNTIME ERROR: Index out of range.
    ```

*   **Modifying a Range of Elements:**
    You can modify a range of elements at once. The replacement can have a different number of items than the range it replaces.

    ```swift
    var list = ["a", "b", "c", "d", "e", "f"]
    print("Initial list: \(list)") // Initial list: ["a", "b", "c", "d", "e", "f"]

    list[1...3] = ["X", "Y"] // Replace elements at index 1, 2, 3 with "X", "Y"
    print("After replacing 1...3: \(list)") // Output: After replacing 1...3: ["a", "X", "Y", "e", "f"]
                             // Count is now 5

    list[0..<2] = ["P", "Q", "R", "S"] // Replace elements at index 0, 1 with four new elements
    print("After replacing 0..<2: \(list)") // Output: After replacing 0..<2: ["P", "Q", "R", "S", "Y", "e", "f"]
                                // Count is now 7
    ```

**3.1.3 Adding Elements to an Array**

*   **Appending an Element (`append(_:)`):**
    Adds a new element to the end of the array.

    ```swift
    var numbersList = [1, 2, 3]
    numbersList.append(4)
    print(numbersList) // Output: [1, 2, 3, 4]
    ```

*   **Appending Elements from Another Array (`append(contentsOf:)`):**
    Adds all elements from another array (of the same type) to the end.

    ```swift
    var moreNumbers = [5, 6]
    numbersList.append(contentsOf: moreNumbers)
    print(numbersList) // Output: [1, 2, 3, 4, 5, 6]

    // You can also use the addition assignment operator (+=)
    var fruits = ["Apple", "Banana"]
    let moreFruits = ["Orange", "Mango"]
    fruits += moreFruits
    print(fruits) // Output: ["Apple", "Banana", "Orange", "Mango"]
    ```

*   **Inserting an Element at a Specific Index (`insert(_:at:)`):**
    Inserts a new element at a specified index. All elements at and after that index are shifted one position to the right.

    ```swift
    var alphabet = ["A", "C", "D"]
    alphabet.insert("B", at: 1) // Insert "B" at index 1
    print(alphabet) // Output: ["A", "B", "C", "D"]

    alphabet.insert("X", at: 0) // Insert "X" at the beginning
    print(alphabet) // Output: ["X", "A", "B", "C", "D"]

    alphabet.insert("Z", at: alphabet.count) // Insert "Z" at the end (equivalent to append)
    print(alphabet) // Output: ["X", "A", "B", "C", "D", "Z"]

    // Inserting at an index greater than 'count' or less than 0 will cause a runtime error.
    ```

*   **Inserting Elements from Another Collection at a Specific Index (`insert(contentsOf:at:)`):**

    ```swift
    var primaryColors = ["Red", "Blue"]
    let secondaryColor = ["Green"]
    primaryColors.insert(contentsOf: secondaryColor, at: 1)
    print(primaryColors) // Output: ["Red", "Green", "Blue"]
    ```

**3.1.4 Removing Elements from an Array**

*   **Removing an Element at a Specific Index (`remove(at:)`):**
    Removes the element at the specified index and returns it. All subsequent elements are shifted one position to the left.

    ```swift
    var techGiants = ["Apple", "Microsoft", "Google", "Amazon"]
    let removedGiant = techGiants.remove(at: 1) // Removes "Microsoft"
    print("Removed: \(removedGiant)")        // Output: Removed: Microsoft
    print("Remaining: \(techGiants)")       // Output: Remaining: ["Apple", "Google", "Amazon"]

    // Removing from an invalid index results in a runtime error.
    ```

*   **Removing the Last Element (`removeLast()`):**
    Removes and returns the last element of the array. This is more efficient than `remove(at: array.count - 1)`.
    Calling `removeLast()` on an empty array will cause a runtime error.

    ```swift
    var seasons = ["Spring", "Summer", "Autumn", "Winter"]
    let lastSeason = seasons.removeLast()
    print("Removed last: \(lastSeason)") // Output: Removed last: Winter
    print(seasons)                      // Output: ["Spring", "Summer", "Autumn"]

    // let emptyArray = [Int]()
    // emptyArray.removeLast() // RUNTIME ERROR
    ```

*   **Removing the First Element (`removeFirst()`):**
    Removes and returns the first element. All other elements are shifted.
    Calling `removeFirst()` on an empty array will cause a runtime error.

    ```swift
    var tasks = ["Task1", "Task2", "Task3"]
    let firstTask = tasks.removeFirst()
    print("Removed first: \(firstTask)") // Output: Removed first: Task1
    print(tasks)                        // Output: ["Task2", "Task3"]
    ```

*   **Removing All Elements (`removeAll(keepingCapacity:)`):**
    Removes all elements from the array.
    You can optionally specify whether the array should keep its allocated capacity (`keepingCapacity: true`). This can be an optimization if you plan to add a similar number of elements back soon.

    ```swift
    var ingredients = ["Flour", "Sugar", "Eggs"]
    print("Ingredients count before removal: \(ingredients.count), capacity: \(ingredients.capacity)")
    ingredients.removeAll() // Default is keepingCapacity: false
    print("Ingredients after removeAll(): \(ingredients), count: \(ingredients.count), capacity: \(ingredients.capacity)")
    // Output may vary for capacity, but count will be 0.
    // Example: Ingredients count before removal: 3, capacity: 3
    //          Ingredients after removeAll(): [], count: 0, capacity: 0

    var dataPoints = [1.0, 2.5, 3.3]
    print("Capacity before: \(dataPoints.capacity)")
    dataPoints.removeAll(keepingCapacity: true)
    print("dataPoints: \(dataPoints), count: \(dataPoints.count), capacity after keeping: \(dataPoints.capacity)")
    // Example: Capacity before: 3
    //          dataPoints: [], count: 0, capacity after keeping: 3
    ```

*   **Removing a Range of Elements (`removeSubrange(_:)`):**
    Removes elements within a specified range.

    ```swift
    var characters = ["a", "b", "c", "d", "e", "f"]
    characters.removeSubrange(1...3) // Removes "b", "c", "d"
    print(characters) // Output: ["a", "e", "f"]
    ```

*   **Removing First/Last N Elements (`dropFirst(_:)`, `dropLast(_:)` - these return a subsequence, not modify in place):**
    `dropFirst(k)` returns a new subsequence containing all but the first `k` elements.
    `dropLast(k)` returns a new subsequence containing all but the last `k` elements.
    To modify the array itself, you might reassign: `myArray = Array(myArray.dropFirst(k))`.
    Or use `removeFirst(k)` and `removeLast(k)` (note `k` parameter).

    ```swift
    var sequence = [10, 20, 30, 40, 50, 60]
    let withoutFirstTwo = sequence.dropFirst(2)
    print(Array(withoutFirstTwo)) // Output: [30, 40, 50, 60]. 'sequence' is unchanged.

    sequence.removeFirst(2) // Modifies 'sequence' directly
    print(sequence) // Output: [30, 40, 50, 60]

    sequence.removeLast(1)
    print(sequence) // Output: [30, 40, 50]
    ```

**3.1.5 Iterating Over an Array**

You can loop through the elements of an array in several ways:

*   **Using a `for-in` Loop:**
    This is the simplest and most common way to iterate over the elements.

    ```swift
    let teamMembers = ["Sarah", "John", "Mike"]
    for member in teamMembers {
        print("Processing member: \(member)")
    }
    // Output:
    // Processing member: Sarah
    // Processing member: John
    // Processing member: Mike
    ```

*   **Using `for-in` with `enumerated()` to Get Index and Value:**
    If you need both the index and the value of each element, use the `enumerated()` method. It returns a sequence of (index, value) tuples.

    ```swift
    for (index, member) in teamMembers.enumerated() {
        print("Member at index \(index) is \(member)")
    }
    // Output:
    // Member at index 0 is Sarah
    // Member at index 1 is John
    // Member at index 2 is Mike
    ```

*   **Using the `forEach` Method:**
    Arrays have a `forEach` method that calls a given closure for each element in the array.

    ```swift
    teamMembers.forEach { member in
        print("Team member (forEach): \(member)")
    }
    // Or using shorthand argument name $0:
    teamMembers.forEach {
        print("Hello, \($0)!")
    }
    // Output:
    // Team member (forEach): Sarah
    // Team member (forEach): John
    // Team member (forEach): Mike
    // Hello, Sarah!
    // ...
    ```
    While `forEach` is concise, you cannot use `break` or `continue` to exit the loop or skip iterations directly within a `forEach` closure in the same way as a `for-in` loop. You'd need to `return` from the closure to mimic `continue`.

**3.1.6 Common Array Operations**

Arrays come with a rich set of methods for common data manipulation tasks. Many of these are "higher-order functions" because they take other functions (closures) as arguments.

*   **Checking for an Element (`contains(_:)` and `contains(where:)`):**
    `contains(_:)` checks if an array contains a specific element (requires `Element` to be `Equatable`).
    `contains(where:)` checks if any element satisfies a given condition (a closure).

    ```swift
    let programmingLanguages = ["Swift", "Python", "Java", "C++"]
    if programmingLanguages.contains("Swift") {
        print("Swift is in the list.") // Output: Swift is in the list.
    }

    if programmingLanguages.contains(where: { lang in lang.hasPrefix("J") }) {
        print("Found a language starting with J.") // Output: Found a language starting with J.
    }
    // Shorthand: if programmingLanguages.contains(where: { $0.hasPrefix("J") })
    ```

*   **Finding an Element (`first(where:)`, `last(where:)`, `firstIndex(of:)`, `lastIndex(of:)`):**
    `first(where:)` returns the first element that satisfies a condition (optional).
    `last(where:)` returns the last element that satisfies a condition (optional).
    `firstIndex(of:)` returns the first index of a given element (optional, requires `Equatable`).
    `lastIndex(of:)` returns the last index of a given element (optional, requires `Equatable`).

    ```swift
    let scores = [70, 85, 92, 85, 60]
    if let firstHighScore = scores.first(where: { $0 > 90 }) {
        print("First high score: \(firstHighScore)") // Output: First high score: 92
    }

    if let firstIndexOf85 = scores.firstIndex(of: 85) {
        print("First occurrence of 85 is at index \(firstIndexOf85).") // Output: First occurrence of 85 is at index 1.
    }

    if let lastIndexOf85 = scores.lastIndex(of: 85) {
        print("Last occurrence of 85 is at index \(lastIndexOf85).") // Output: Last occurrence of 85 is at index 3.
    }
    ```

*   **Checking if All Elements Satisfy a Condition (`allSatisfy(_:)`):**
    Returns `true` if every element in the array satisfies the given closure condition.

    ```swift
    let positiveNumbers = [1, 2, 3, 4, 5]
    if positiveNumbers.allSatisfy({ $0 > 0 }) {
        print("All numbers are positive.") // Output: All numbers are positive.
    }

    let mixedNumbers = [1, -2, 3]
    if !mixedNumbers.allSatisfy({ $0 > 0 }) {
        print("Not all numbers in mixedNumbers are positive.") // Output: Not all numbers in mixedNumbers are positive.
    }
    ```

*   **Transforming Elements (`map(_:)`, `compactMap(_:)`, `flatMap(_:)` - flatMap is more complex, often used with sequences of sequences or optionals):**
    *   `map(_:)`: Returns a *new* array containing the results of applying a given closure to each element of the original array. The new array can have elements of a different type.
    *   `compactMap(_:)`: Returns a *new* array containing the non-`nil` results of calling the given transformation with each element of this sequence. Useful when the transformation might return an optional.

    ```swift
    let numbersToSquare = [1, 2, 3, 4, 5]
    let squaredNumbers = numbersToSquare.map { number in
        number * number
    }
    print(squaredNumbers) // Output: [1, 4, 9, 16, 25]

    let numberStrings = numbersToSquare.map { number in
        "Number: \(number)"
    }
    print(numberStrings) // Output: ["Number: 1", "Number: 2", "Number: 3", "Number: 4", "Number: 5"]

    let stringsWithPossibleInts = ["1", "two", "3", "4", "five"]
    let actualInts = stringsWithPossibleInts.compactMap { str in
        Int(str) // Int(str) returns an Int? (optional Int)
    }
    print(actualInts) // Output: [1, 3, 4] (elements "two" and "five" resulted in nil and were excluded)
    ```

*   **Filtering Elements (`filter(_:)`):**
    Returns a *new* array containing only the elements that satisfy a given condition (a closure that returns `Bool`).

    ```swift
    let allScores = [65, 72, 88, 91, 53, 72, 95]
    let passingScores = allScores.filter { score in
        score >= 70
    }
    print(passingScores) // Output: [72, 88, 91, 72, 95]
    ```

*   **Reducing Elements (`reduce(_:_:)`):**
    Combines all elements in an array into a single value by applying a given closure. It takes an initial value and a closure that combines the accumulated value with each element.

    ```swift
    let values = [1, 2, 3, 4, 5]
    let sum = values.reduce(0) { (currentResult, newValue) -> Int in
        currentResult + newValue
    }
    print("Sum: \(sum)") // Output: Sum: 15 (0+1=1, 1+2=3, 3+3=6, 6+4=10, 10+5=15)

    // Shorthand version:
    let product = values.reduce(1, *) // Initial value 1, closure is the multiplication operator
    print("Product: \(product)") // Output: Product: 120 (1*1=1, 1*2=2, 2*3=6, 6*4=24, 24*5=120)

    let sentenceParts = ["Hello", "Swift", "World"]
    let fullSentence = sentenceParts.reduce("") { (currentString, part) -> String in
        if currentString.isEmpty {
            return part
        } else {
            return currentString + " " + part
        }
    }
    print(fullSentence) // Output: Hello Swift World
    ```

*   **Sorting Elements (`sort()`, `sorted()`):**
    *   `sort()`: Sorts the array *in place*. The elements must conform to the `Comparable` protocol (like `Int`, `String`, `Double`).
    *   `sorted()`: Returns a *new* array with the elements sorted, leaving the original array unchanged.

    ```swift
    var unsortedNumbers = [5, 1, 4, 2, 3]
    unsortedNumbers.sort() // Sorts in place (ascending)
    print("Sorted numbers (in place): \(unsortedNumbers)") // Output: Sorted numbers (in place): [1, 2, 3, 4, 5]

    let moreUnsortedNumbers = [10, -2, 7, 0]
    let sortedCopy = moreUnsortedNumbers.sorted() // Returns a new sorted array
    print("Original: \(moreUnsortedNumbers)") // Output: Original: [10, -2, 7, 0]
    print("Sorted copy: \(sortedCopy)")      // Output: Sorted copy: [-2, 0, 7, 10]

    // To sort in descending order:
    unsortedNumbers.sort(by: >) // Using the greater-than operator as the closure
    print("Descending sort (in place): \(unsortedNumbers)") // Output: Descending sort (in place): [5, 4, 3, 2, 1]

    let descendingCopy = moreUnsortedNumbers.sorted(by: >)
    print("Descending sorted copy: \(descendingCopy)") // Output: Descending sorted copy: [10, 7, 0, -2]

    // Sorting custom objects (assuming a 'Person' struct with 'age' and 'name')
    struct Person { let name: String; let age: Int }
    var people = [Person(name: "Alice", age: 30), Person(name: "Bob", age: 25), Person(name: "Charlie", age: 35)]

    // Sort by age (ascending)
    people.sort { person1, person2 in
        person1.age < person2.age
    }
    // Or shorthand: people.sort { $0.age < $1.age }
    print(people.map { $0.name }) // Output: ["Bob", "Alice", "Charlie"]
    ```

*   **Reversing Elements (`reverse()`, `reversed()`):**
    *   `reverse()`: Reverses the elements of the array *in place*.
    *   `reversed()`: Returns a *new* `ReversedCollection` (which can be converted to an Array) with the elements in reverse order, leaving the original array unchanged.

    ```swift
    var sequenceToReverse = [1, 2, 3, 4, 5]
    sequenceToReverse.reverse()
    print("Reversed in place: \(sequenceToReverse)") // Output: Reversed in place: [5, 4, 3, 2, 1]

    let originalSequence = ["a", "b", "c"]
    let reversedCopySequence = originalSequence.reversed() // This is a ReversedCollection<[String]>
    print("Reversed copy: \(Array(reversedCopySequence))") // Output: Reversed copy: ["c", "b", "a"]
    print("Original unchanged: \(originalSequence)")   // Output: Original unchanged: ["a", "b", "c"]
    ```

*   **Shuffling Elements (`shuffle()`, `shuffled()`):** (Requires Swift 4.2+)
    *   `shuffle()`: Shuffles the elements of the array *in place*.
    *   `shuffled()`: Returns a *new* array with the elements in a random order.

    ```swift
    var deck = ["Ace", "King", "Queen", "Jack"]
    deck.shuffle()
    print("Shuffled deck (in place): \(deck)") // Output: (Order will vary) e.g., ["Queen", "Jack", "Ace", "King"]

    let cards = [1, 2, 3, 4, 5]
    let shuffledCards = cards.shuffled()
    print("Shuffled copy: \(shuffledCards)") // Output: (Order will vary)
    print("Original cards: \(cards)")     // Output: [1, 2, 3, 4, 5]
    ```

*   **Partitioning Elements (`partition(by:)`):**
    Reorders the elements of the collection such that all the elements that match the given predicate are after all the elements that don't match. Returns the index of the first element in the reordered collection that matches the predicate. Modifies in place.

    ```swift
    var numbersToPartition = [30, 10, 20, 50, 40, 60, 5]
    let pivotIndex = numbersToPartition.partition { $0 > 35 }
    // Elements <= 35 will be before elements > 35
    print("Partitioned array: \(numbersToPartition)") // e.g., [5, 10, 20, 30, 40, 60, 50] (order of elements within partitions is not guaranteed)
    print("Pivot index: \(pivotIndex)")             // e.g., 4 (index of 40)
    ```

*   **Getting Subsequences (`prefix(_:)`, `suffix(_:)`, `dropFirst(_:)`, `dropLast(_:)`):**
    These methods return an `ArraySlice`, which is a view onto the original array's storage. It's efficient as it doesn't copy data immediately. You can convert an `ArraySlice` to a new `Array` if needed.

    ```swift
    let fullNumbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    let firstThree = fullNumbers.prefix(3)
    print(Array(firstThree)) // Output: [0, 1, 2]

    let lastThree = fullNumbers.suffix(3)
    print(Array(lastThree)) // Output: [7, 8, 9]

    let withoutFirstTwoAgain = fullNumbers.dropFirst(2)
    print(Array(withoutFirstTwoAgain)) // Output: [2, 3, 4, 5, 6, 7, 8, 9]

    let withoutLastTwo = fullNumbers.dropLast(2)
    print(Array(withoutLastTwo)) // Output: [0, 1, 2, 3, 4, 5, 6, 7]

    // Slicing with ranges also gives an ArraySlice
    let slice = fullNumbers[2...5] // type is ArraySlice<Int>
    print(Array(slice)) // Output: [2, 3, 4, 5]
    ```

**3.1.7 Multidimensional Arrays**

You can create an array of arrays (or an array of arrays of arrays, etc.) to represent multidimensional grids or matrices.

```swift
var ticTacToeBoard: [[Character]] = [
    [" ", " ", " "], // Row 0
    [" ", " ", " "], // Row 1
    [" ", " ", " "]  // Row 2
]

// Accessing an element:
ticTacToeBoard[0][0] = "X" // Top-left
ticTacToeBoard[1][1] = "O" // Center
ticTacToeBoard[2][0] = "X" // Bottom-left

// Print the board
for row in ticTacToeBoard {
    print(row)
}
// Output:
// ["X", " ", " "]
// [" ", "O", " "]
// ["X", " ", " "]

var threeDimensionalArray: [[[Int]]] = [
    [ [1, 2], [3, 4] ],
    [ [5, 6], [7, 8] ]
]
print(threeDimensionalArray[0][1][0]) // Output: 3
```

**3.1.8 Array Performance Considerations (Simplified)**

*   **Accessing by Index (`array[i]`):** Very fast, O(1) - constant time. It takes roughly the same amount of time regardless of the array's size.
*   **Appending an Element (`append(_:)`):** Generally fast, O(1) on average (amortized constant time). Sometimes, if the array's internal storage is full, it needs to be resized, which can take O(n) time (proportional to the number of elements). But this happens infrequently enough that the average time is constant.
*   **Inserting or Deleting at the Beginning/Middle (`insert(_:at: 0)`, `remove(at: 0)`):** Slow, O(n). All subsequent elements need to be shifted.
*   **Inserting or Deleting at the End (`append`, `removeLast()`):** Fast, O(1) on average for append, O(1) for `removeLast()`.
*   **Searching (`contains(_:)`, `firstIndex(of:)`):** Slow, O(n) on average, as it might have to check every element.
*   `map`, `filter`, `reduce`: These typically iterate through all elements, so they are O(n).

Understanding these characteristics helps you choose the right operations for performance-sensitive code.

*(Section 3.2 Sets and 3.3 Dictionaries will follow with similar depth)*

--- 