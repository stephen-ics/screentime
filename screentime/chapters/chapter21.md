**Chapter 21: `screentime` App – Demystifying `ViewModels`**

The `ViewModels` directory is intended to house the ViewModels of your application, following the MVVM (Model-View-ViewModel) architectural pattern. Even if this directory was initially empty or sparsely populated during your "vibecoding" phase, understanding its intended role is crucial for structuring a maintainable SwiftUI application.

**21.1 Role of ViewModels in MVVM (Recap)**
As discussed in Chapter 18, the ViewModel acts as an intermediary:
*   **Prepares Data for the View:** It takes raw data from Models (or Services that use Models) and transforms/formats it into a state that the View can easily display. This might involve combining data from multiple sources, filtering, sorting, or converting data types.
*   **Handles Presentation Logic:** It contains logic related to how data is presented and how the UI should behave, without directly manipulating UI elements.
*   **Responds to View Actions:** It exposes functions that Views can call in response to user interactions (e.g., button taps, form submissions). These functions then typically interact with Services or update Models.
*   **Manages State for the View:** It holds the state relevant to a specific view or set of views using `@Published` properties. When these properties change, any subscribing Views automatically update.
*   **Decouples Views from Models:** Views don't know about the intricacies of the Model layer; they only interact with the ViewModel. This makes Views simpler and more reusable, and Models can change without directly impacting Views.

**21.2 Characteristics of a ViewModel**
*   **Class Type:** ViewModels are almost always classes because they need to be reference types that can be shared and observed.
*   **`ObservableObject` Conformance:** They conform to the `ObservableObject` protocol to allow SwiftUI views to subscribe to their changes.
*   **`@Published` Properties:** Properties that the View needs to display or react to are marked with the `@Published` property wrapper. This automatically announces changes to these properties.
*   **Dependency on Services/Models:** ViewModels typically hold references to (or create instances of) services (like `AuthenticationService`, `CoreDataManager`) to fetch or modify data. They might also work directly with Model objects.
*   **No SwiftUI Imports (Ideally):** A pure ViewModel should ideally not `import SwiftUI`. Its job is to manage data and logic, not UI elements. This improves testability and separation. (Sometimes, for convenience with types like `Color` or `Image` that might be part of the data it prepares, this rule is bent, but it's a good ideal).

**21.3 Example Structure of a ViewModel**
Let's imagine a ViewModel for your `AuthenticationView`.

```swift
// In ViewModels/AuthenticationViewModel.swift (New File)
import Foundation // For basic types, not SwiftUI
import Combine    // For ObservableObject, @Published

class AuthenticationViewModel: ObservableObject {
    // Dependencies (injected or created)
    private var authService: AuthenticationService // Assuming you have this service

    // State exposed to the View
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isAuthenticated = false // This might mirror a state in authService

    private var cancellables = Set<AnyCancellable>() // To manage subscriptions

    init(authService: AuthenticationService = AuthenticationService()) { // Default initializer with dependency
        self.authService = authService

        // Subscribe to changes in the authService's authentication state
        // Assuming authService has an @Published isAuthenticated property or similar publisher
        authService.$isAuthenticated // or authService.authenticationStatePublisher
            .receive(on: DispatchQueue.main) // Ensure UI updates are on the main thread
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
    }

    // Actions called by the View
    func loginUser() {
        isLoading = true
        errorMessage = nil

        // Use a real async operation if authService.login is async
        Task {
            do {
                let success = try await authService.login(email: email, password: password)
                DispatchQueue.main.async { // Ensure UI updates are on the main thread
                    self.isLoading = false
                    if success {
                        // isAuthenticated will be updated via the publisher from authService
                        print("Login successful")
                    } else {
                        self.errorMessage = "Invalid email or password." // Or an error from the service
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription // Or a more user-friendly message
                }
            }
        }
    }

    func signUpUser() {
        isLoading = true
        errorMessage = nil
        // Similar logic for sign up, calling authService.signUp(...)
        Task {
            do {
                let success = try await authService.signUp(email: email, password: password)
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        print("Sign up successful, attempting login...")
                        self.loginUser() // Optionally log in immediately after sign up
                    } else {
                        self.errorMessage = "Sign up failed. Please try again."
                    }
                }
            } catch {
                 DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Add other functions like password reset, etc.
}
```

**21.4 How Views Use ViewModels**
In your SwiftUI View:

```swift
// In Views/Authentication/AuthenticationView.swift
import SwiftUI

struct AuthenticationView: View {
    // The ViewModel is typically a @StateObject if the view owns it,
    // or @ObservedObject if it's passed in.
    // For a screen like Authentication, it often owns its ViewModel.
    @StateObject private var viewModel = AuthenticationViewModel()
    @EnvironmentObject var appAuthService: AuthenticationService // If it was injected at App level

    // If you decide to inject authService into AuthenticationViewModel instead of it creating one:
    // @StateObject private var viewModel: AuthenticationViewModel

    // init(appAuthService: AuthenticationService) {
    //      _viewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: appAuthService))
    // }


    var body: some View {
        VStack {
            TextField("Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            SecureField("Password", text: $viewModel.password)

            if viewModel.isLoading {
                ProgressView()
            } else {
                Button("Login") {
                    viewModel.loginUser()
                }
                Button("Sign Up") {
                    viewModel.signUpUser()
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
        // The RootView would observe viewModel.isAuthenticated (or a global auth state)
        // to switch away from AuthenticationView upon successful login.
    }
}
```

**21.5 Potential ViewModels for Your `screentime` App**
Based on your `Views` and `Models` structure, here are some ViewModels you might create:

*   `ParentDashboardViewModel`: Manages data for `ParentDashboardView` (list of children, overall usage stats, pending tasks/requests).
*   `ChildDashboardViewModel`: Manages data for `ChildDashboardView` (current screen time balance, list of assigned tasks, approved apps).
*   `TaskListViewModel`: For `TaskListView` (fetching and displaying tasks, handling completion).
*   `AddTaskViewModel`: For `AddTaskView` (handling input for a new task, saving it).
*   `ApprovedAppsViewModel`: For `ApprovedAppsView` (managing the list of approved/restricted apps).
*   `AnalyticsViewModel`: For `AnalyticsView` (fetching and preparing usage data for charts/display).
*   `AccountViewModel`: For `AccountView` (loading user profile, handling updates via `EditProfileView`).
*   `EditProfileViewModel`: For `EditProfileView`.
*   `NotificationPreferencesViewModel`, `PrivacySettingsViewModel`.
*   `ChildDetailViewModel`: For `ChildDetailView` (showing specific data for a selected child).
*   ...and potentially ViewModels for your custom components if they have significant logic.

**2.6 Benefits of Using ViewModels**
*   **Testability:** ViewModels can be tested independently of the UI because they don't contain UI code. You can write unit tests to verify their logic.
*   **Separation of Concerns:** Keeps UI code (Views) clean and focused on presentation, while data manipulation and presentation logic reside in the ViewModel.
*   **Reusability:** ViewModels can potentially be reused by multiple Views if those Views need to display similar data or perform similar actions (though often a ViewModel is specific to one primary View/screen).
*   **Collaboration:** Designers can work on Views while developers work on ViewModels and Models with clearer boundaries.

Even if your `ViewModels` directory is currently empty, as you continue to develop and refine your `screentime` app, populating it with `ObservableObject` classes that serve your views will be a key step towards a more robust and maintainable codebase.

--- 