**Chapter 16: Networking Basics – Communicating with the Web**

Many modern apps need to communicate with web services to fetch data, post updates, or interact with APIs. Swift provides robust tools for networking, primarily through the `URLSession` framework.

**16.1 Understanding URLs and HTTP(S)**
*   **URL (Uniform Resource Locator):** An address for a resource on the web (e.g., `https://www.apple.com/swift`).
*   **HTTP/HTTPS:** The protocols used for communication between clients (your app) and web servers. HTTPS is the secure version.
*   **HTTP Methods:**
    *   `GET`: Retrieve data from a server (e.g., fetching a webpage or JSON data).
    *   `POST`: Send data to a server to create a new resource (e.g., submitting a form).
    *   `PUT`: Send data to update an existing resource.
    *   `DELETE`: Remove a resource from the server.
    *   Others: `PATCH`, `HEAD`, `OPTIONS`, etc.
*   **HTTP Headers:** Key-value pairs sent with requests and responses (e.g., `Content-Type: application/json`, `Authorization: Bearer <token>`).
*   **HTTP Status Codes:** Indicate the result of a request (e.g., `200 OK`, `404 Not Found`, `500 Internal Server Error`).
*   **JSON (JavaScript Object Notation):** A common, lightweight data-interchange format used by many web APIs. Swift's `Codable` protocol works very well with JSON.

**16.2 `URLSession`: The Core of Networking**
`URLSession` is Apple's framework for making network requests.

*   **Shared Session (`URLSession.shared`):**
    A singleton session for basic requests. It's convenient but less configurable.

*   **Custom Sessions:**
    You can create custom `URLSession` instances with specific configurations (`URLSessionConfiguration`), like setting timeouts, caching policies, or custom headers for all requests made by that session.

*   **Types of Tasks:**
    *   **Data Task (`dataTask(with:completionHandler:)` or `data(for:)` with `async/await`):**
        Fetches data (e.g., JSON, XML, images) into memory (`Data` object). This is the most common type of task.
    *   **Upload Task (`uploadTask(with:from:completionHandler:)` or `upload(for:from:)`):**
        Uploads data from a file or `Data` object to a server, often with `POST` or `PUT`.
    *   **Download Task (`downloadTask(with:completionHandler:)` or `download(for:delegate:)`):**
        Downloads a file directly to a temporary location on disk, suitable for large files.

**16.3 Making a `GET` Request (Fetching JSON with `async/await`)**
Using the newer `async/await` APIs with `URLSession` simplifies networking code considerably.

```swift
struct Post: Codable, Identifiable { // A Codable struct to match the JSON structure
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

enum NetworkError: Error {
    case badURL
    case requestFailed(Error)
    case decodingError(Error)
    case invalidResponseStatus(Int)
    case unknown
}

func fetchPosts() async throws -> [Post] {
    guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
        throw NetworkError.badURL
    }

    // Create a URLRequest (can customize with HTTP method, headers, body)
    var request = URLRequest(url: url)
    request.httpMethod = "GET" // Default for data(for:) is GET, but good to be explicit

    print("Fetching posts from: \(url)")

    do {
        // Perform the network request asynchronously
        // data(for:) returns a tuple (Data, URLResponse)
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check the HTTP response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown // Should ideally be an HTTPURLResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponseStatus(httpResponse.statusCode)
        }

        // Decode the JSON data into an array of Post objects
        let jsonDecoder = JSONDecoder()
        let posts = try jsonDecoder.decode([Post].self, from: data)
        return posts
    } catch let error as NetworkError {
        print("NetworkError during fetch: \(error)")
        throw error // Re-throw our specific network error
    } catch {
        print("General error during fetch or decoding: \(error)")
        throw NetworkError.requestFailed(error) // Wrap other errors
    }
}

// Example usage:
Task {
    do {
        let posts = try await fetchPosts()
        print("Fetched \(posts.count) posts.")
        if let firstPost = posts.first {
            print("First post title: \(firstPost.title)")
        }
    } catch {
        print("Failed to fetch posts in Task: \(error)")
    }
}
```

**16.4 Making a `POST` Request (Sending JSON with `async/await`)**

```swift
struct NewPost: Codable { // Data to send
    let title: String
    let body: String
    let userId: Int
}

struct CreatedPostResponse: Codable { // Expected response structure
    let id: Int
    // Potentially other fields returned by the server like title, body, userId
}

func createPost(postData: NewPost) async throws -> CreatedPostResponse {
    guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
        throw NetworkError.badURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Set content type header

    // Encode the NewPost object to JSON data
    let jsonEncoder = JSONEncoder()
    do {
        request.httpBody = try jsonEncoder.encode(postData)
    } catch {
        throw NetworkError.decodingError(error) // Or a new .encodingError
    }

    print("Creating post with title: \(postData.title)")

    do {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        print("Create post response status: \(httpResponse.statusCode)")
        // Typically a 201 Created status for successful POST
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponseStatus(httpResponse.statusCode)
        }

        let jsonDecoder = JSONDecoder()
        let createdPost = try jsonDecoder.decode(CreatedPostResponse.self, from: data)
        return createdPost
    } catch let error as NetworkError {
        print("NetworkError during createPost: \(error)")
        throw error
    } catch {
        print("General error during createPost: \(error)")
        throw NetworkError.requestFailed(error)
    }
}

// Example usage:
Task {
    let myNewPost = NewPost(title: "My Test Post", body: "This is the content.", userId: 1)
    do {
        let createdResponse = try await createPost(postData: myNewPost)
        print("Successfully created post with ID: \(createdResponse.id)")
    } catch {
        print("Failed to create post: \(error)")
    }
}
```

**16.5 Handling Network Errors and Reachability**
*   Always check for errors returned by `URLSession` tasks.
*   Check HTTP status codes from the `URLResponse` (cast to `HTTPURLResponse`).
*   Consider using a dedicated networking error enum (like `NetworkError` above) for clarity.
*   **Reachability:** To check if the device has an active internet connection before making a request, you can use the `Network` framework (iOS 12+).
    ```swift
    import Network

    // func checkReachability() {
    //     let monitor = NWPathMonitor()
    //     monitor.pathUpdateHandler = { path in
    //         if path.status == .satisfied {
    //             print("Network connection is available.")
    //         } else {
    //             print("No network connection.")
    //         }
    //     }
    //     let queue = DispatchQueue(label: "NetworkMonitor")
    //     monitor.start(queue: queue)
    // }
    ```

**16.6 Security (HTTPS, App Transport Security)**
*   **HTTPS:** Always prefer HTTPS over HTTP for secure communication.
*   **App Transport Security (ATS):** An iOS feature that enforces secure connections. By default, it blocks non-HTTPS connections. If you must connect to an HTTP server (not recommended), you'll need to configure exceptions in your app's `Info.plist` file.

**16.7 Other Networking Considerations**
*   **Authentication:** Many APIs require authentication (e.g., API keys, OAuth tokens). These are typically sent in HTTP headers (`Authorization`).
*   **Caching:** `URLSession` has built-in caching mechanisms, configurable via `URLSessionConfiguration`.
*   **Background Sessions:** For long-running uploads or downloads that should continue even if the app is backgrounded.
*   **Third-party Libraries:** Libraries like Alamofire can simplify networking tasks, though `URLSession` with `async/await` is quite powerful on its own.

--- 