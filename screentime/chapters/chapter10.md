**Chapter 10: Concurrency – Performing Multiple Tasks Simultaneously**

Modern applications often need to perform multiple operations at the same time. For example, downloading data from a network while keeping the user interface responsive, or processing large datasets in parallel to speed things up. Swift provides robust support for *concurrency*, allowing you to write code that performs multiple tasks seemingly simultaneously.

Starting with Swift 5.5, a new concurrency model based on `async`/`await` and Actors was introduced, significantly simplifying concurrent programming.

**10.1 Understanding Asynchronous Operations**
Many operations, especially those involving external resources (like network requests or file I/O), can take an unpredictable amount of time. If these operations were performed *synchronously* on the main thread (the thread responsible for UI updates), the app would freeze until the operation completed.
*Asynchronous operations* allow these long-running tasks to be performed in the background without blocking the main thread. When the task is complete, it typically notifies the main thread with the result or error.

**10.2 Asynchronous Functions with `async` and `await`**
Swift's `async`/`await` syntax provides a structured way to write asynchronous code that looks and feels much like synchronous code, making it easier to read and reason about.

*   **`async` (Defining Asynchronous Functions):**
    You mark a function as asynchronous by writing the `async` keyword in its declaration after its parameters, before its return arrow (or before the `throws` keyword if it can also throw errors).

    ```swift
    func fetchWeatherData(for city: String) async throws -> Data {
        // Simulate a network request
        print("Fetching weather data for \(city)...")
        // Pretend this is a network call that takes some time
        // In a real scenario, you'd use URLSession or another networking library here.
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000) // Sleep for 2 seconds to simulate work

        if city == "ErrorCity" {
            struct NetworkError: Error {}
            throw NetworkError()
        }
        return Data("\(city) weather: Sunny, 25°C".utf8)
    }
    ```
    An `async` function can suspend its execution partway through, allowing other code to run while it's waiting for something (e.g., a network response).

*   **`await` (Calling Asynchronous Functions):**
    When you call an `async` function, you must prefix the call with the `await` keyword. This indicates that your code might pause (suspend) at that point until the asynchronous function returns.
    You can only use `await` inside another `async` context (like another `async` function or a `Task`).

    ```swift
    func displayWeather(for city: String) async {
        do {
            let weatherData = try await fetchWeatherData(for: city) // 'await' because fetchWeatherData is async
            if let weatherString = String(data: weatherData, encoding: .utf8) {
                print(weatherString)
            }
        } catch {
            print("Failed to fetch weather for \(city): \(error)")
        }
    }

    // To call an async function from a synchronous context (like top-level code or a non-async function),
    // you usually wrap it in a Task.
    Task {
        await displayWeather(for: "London")
        await displayWeather(for: "Paris")
        await displayWeather(for: "ErrorCity")
    }
    // Output (order of London/Paris might vary due to concurrency, ErrorCity will show an error):
    // Fetching weather data for London...
    // Fetching weather data for Paris...
    // Fetching weather data for ErrorCity...
    // London weather: Sunny, 25°C
    // Paris weather: Sunny, 25°C
    // Failed to fetch weather for ErrorCity: __lldb_expr_31.NetworkError()
    ```
    The `await` keyword effectively marks a suspension point. While `fetchWeatherData` is "away" fetching data, the `displayWeather` function pauses, and other tasks can run. When `fetchWeatherData` completes (either returns a value or throws an error), `displayWeather` resumes execution from where it left off.

**10.3 Structured Concurrency with `Task`**
A `Task` is a unit of work that can be run asynchronously as part of your program. Every `async` function runs as part of some task.

*   **Creating Tasks:**
    You create a task by initializing a `Task` instance with a closure containing the asynchronous code you want to run.

    ```swift
    Task { // Creates a new, top-level task
        print("Task started on thread: \(Thread.current)")
        let image = await downloadImage(named: "photo.jpg")
        print("Image downloaded.")
        // ... process image ...
    }

    func downloadImage(named: String) async -> String { /* ... */ return "ImageData for \(named)" }
    ```
    Tasks can be created within other functions, even non-async ones, to bridge into the `async` world.

*   **Task Cancellation:**
    Tasks can be cancelled. Swift's concurrency model provides a cooperative cancellation mechanism.
    *   You can cancel a task using its `cancel()` method.
    *   Inside an `async` function, you should periodically check for cancellation using `Task.isCancelled` or by calling `Task.checkCancellation()` (which throws a `CancellationError` if the task is cancelled).

    ```swift
    func processLargeFile() async throws {
        print("Starting to process large file...")
        for i in 0..<1000 {
            // Simulate work
            try await Task.sleep(nanoseconds: 10_000_000) // Sleep 10ms

            // Check for cancellation
            // Option 1:
            // if Task.isCancelled {
            //     print("File processing was cancelled.")
            //     throw CancellationError() // Or perform cleanup and return
            // }
            // Option 2:
            try Task.checkCancellation()

            if i % 100 == 0 { print("Processed \(i) lines...") }
        }
        print("Finished processing large file.")
    }

    let fileProcessingTask = Task {
        do {
            try await processLargeFile()
        } catch is CancellationError {
            print("Task was explicitly cancelled.")
        } catch {
            print("An error occurred: \(error)")
        }
    }

    Task { // Simulate cancelling after a short delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        print("Requesting cancellation...")
        fileProcessingTask.cancel()
    }
    ```

*   **Task Groups (`async let`, `withTaskGroup`):**
    For running multiple child tasks concurrently and collecting their results:
    *   **`async let`:** Used when you have a fixed number of child tasks to run in parallel. You define asynchronous constants, and their values are computed concurrently. You `await` them when you need their result.

        ```swift
        func fetchMultipleUserDetails() async throws -> (String, String) {
            async let user1Details = fetchUserData(id: "user1") // Starts immediately
            async let user2Details = fetchUserData(id: "user2") // Starts immediately, concurrently with user1

            // 'await' here when you need the results. Execution suspends until both are complete.
            let details1 = try await user1Details
            let details2 = try await user2Details
            return (details1, details2)
        }
        func fetchUserData(id: String) async throws -> String { /* ... */
            try await Task.sleep(nanoseconds: UInt64.random(in: 1...3) * 100_000_000)
            return "Details for \(id)"
        }
        Task { try await print(fetchMultipleUserDetails()) }
        ```
    *   **`withTaskGroup`:** Used for a dynamic number of child tasks. You create a task group and add child tasks to it. You can then iterate over the results of the child tasks as they complete.

        ```swift
        func processURLs(_ urls: [URL]) async -> [Data] {
            var allData: [Data] = []
            await withTaskGroup(of: Data?.self) { group in // Data? because download might fail
                for url in urls {
                    group.addTask { // Add a child task to the group
                        return await downloadData(from: url)
                    }
                }
                // As child tasks complete, iterate over their results
                for await resultData in group {
                    if let data = resultData {
                        allData.append(data)
                    }
                }
            }
            return allData
        }
        func downloadData(from url: URL) async -> Data? { /* ... */ return Data("Data from \(url)".utf8) }
        ```

**10.4 Actors: Protecting Shared Mutable State**
When multiple concurrent tasks try to access and modify the same piece of data (mutable state), you can run into data races and other concurrency problems. *Actors* are a new type in Swift (like classes, structs, enums) designed to solve this by isolating their state and ensuring that only one piece of code can access that state at a time, even in a concurrent environment.

*   **Defining an Actor:**
    You define an actor with the `actor` keyword.

    ```swift
    actor TemperatureLogger {
        let label: String
        var measurements: [Int]
        private var max: Int // Internal state

        init(label: String, measurement: Int) {
            self.label = label
            self.measurements = [measurement]
            self.max = measurement
        }

        // Methods on an actor are implicitly isolated.
        // Accessing actor properties or calling methods requires 'await' from outside the actor.
        func update(with measurement: Int) {
            measurements.append(measurement)
            if measurement > max {
                max = measurement
            }
        }

        func getCurrentMax() -> Int {
            return max // Accessing 'max' from within the actor is synchronous
        }
    }
    ```

*   **Actor Isolation:**
    *   All access to an actor's properties and methods from *outside* the actor must be done asynchronously using `await`. This allows the actor to ensure that only one operation is modifying its state at any given time, preventing data races.
    *   Access to properties or methods from *within* the actor itself (e.g., one actor method calling another on `self`, or accessing `self.property`) is synchronous and doesn't require `await`.

    ```swift
    let logger = TemperatureLogger(label: "RoomSensor", measurement: 20)

    Task {
        await logger.update(with: 22) // 'await' needed to call 'update'
        await logger.update(with: 19)
        let currentMax = await logger.getCurrentMax() // 'await' needed to call 'getCurrentMax'
        print("Current max from logger: \(currentMax)") // Output: 22

        // print(logger.max) // COMPILE-TIME ERROR: Actor-isolated property 'max' can only be
                           //                       accessed from within the actor or an async context
    }
    ```

*   **`nonisolated` Keyword:**
    Sometimes, an actor might have properties or methods that don't actually access or modify the actor's mutable state (e.g., a constant property or a method that only works with its input parameters). You can mark these with the `nonisolated` keyword to allow them to be accessed synchronously from outside the actor without `await`.

    ```swift
    actor DataStore {
        var records: [String] = []
        nonisolated let storeID: UUID // Constant, doesn't need actor isolation

        init() {
            self.storeID = UUID()
        }
        func addRecord(_ record: String) {
            records.append(record)
        }
        nonisolated func getHelpText() -> String { // Doesn't access 'records' or other mutable state
            return "This is a data store. Store ID: \(storeID)"
        }
    }
    let store = DataStore()
    print(store.storeID) // OK: storeID is nonisolated
    print(store.getHelpText()) // OK: getHelpText is nonisolated

    Task {
        await store.addRecord("Record 1")
        // print(store.records) // ERROR: 'records' is actor-isolated
    }
    ```

*   **Main Actor (`@MainActor`):**
    UI updates in iOS, macOS, etc., must typically happen on the main thread. The `@MainActor` is a global actor that represents the main UI thread. You can mark classes, structs, functions, or properties with `@MainActor` to indicate that their code must run on the main thread. The compiler will help enforce this.

    ```swift
    @MainActor // This class and all its members will run on the main actor
    class UserInterfaceViewModel {
        var statusMessage: String = "Loading..."

        func updateStatus(_ newMessage: String) {
            // This will automatically run on the main thread
            self.statusMessage = newMessage
            // ... update UI label ...
            print("UI Updated (on main thread): \(statusMessage)")
        }
    }

    func fetchDataAndUpdateUI() async {
        // Simulate background data fetch
        let data = await Task { /* some background work */ ; return "Data Loaded!" }.value

        // Now update the UI via the MainActor-isolated ViewModel
        let viewModel = UserInterfaceViewModel()
        await viewModel.updateStatus(data) // 'await' to hop to the MainActor
    }
    Task { await fetchDataAndUpdateUI() }
    ```
    Using `@MainActor` helps prevent common UI-related concurrency bugs.

**10.5 Sendable Types (`Sendable` protocol)**
The `Sendable` protocol indicates that a type's values can be safely copied and shared across concurrency domains (e.g., between actors or tasks running on different threads) without risking data races.
*   Value types (structs, enums) are implicitly `Sendable` if all their stored properties are also `Sendable`.
*   Actors are `Sendable`.
*   Classes can be `Sendable` if they are immutable or manage their own internal synchronization (e.g., are `final` and all stored properties are immutable `Sendable` types, or use internal locking).
*   Functions and closures are `Sendable` if they capture only `Sendable` values.
The compiler helps check `Sendable` conformance, especially when passing data between actors or into detached tasks.

--- 