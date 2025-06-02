**Chapter 14: Navigation and App Flow – Guiding Users Through Your App**

Effective navigation is crucial for a good user experience. SwiftUI provides several ways to manage how users move between different views in your app.

**14.1 `NavigationView` and `NavigationLink` (for Push/Pop Navigation)**
This is common for master-detail interfaces or hierarchical navigation, often seen with a navigation bar at the top.

*   **`NavigationView`:** A container view that provides a root for a navigation stack. It typically displays a navigation bar.
*   **`NavigationLink`:** A control that presents another view when tapped, pushing it onto the `NavigationView`'s stack.

```swift
struct MasterView: View {
    let items = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        NavigationView { // Root navigation container
            List(items, id: \.self) { item in
                NavigationLink(destination: DetailView(itemName: item)) { // Link to DetailView
                    Text(item)
                }
            }
            .navigationTitle("Master List") // Sets the title in the navigation bar
            // .navigationBarTitleDisplayMode(.inline) // Or .large
        }
    }
}

struct DetailView: View {
    var itemName: String

    var body: some View {
        VStack {
            Text("Details for \(itemName)")
                .font(.largeTitle)
            // Add more detail content here
        }
        .navigationTitle(itemName) // Title for this detail view
    }
}
```
*   **Programmatic Navigation:** You can trigger navigation programmatically using a `NavigationLink` that is activated by a `@State` boolean.

    ```swift
    struct ProgrammaticNavView: View {
        @State private var isActiveLink1 = false
        @State private var selection: String? // For tag-based navigation (iOS 16+)

        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    // Link activated by boolean state
                    NavigationLink(destination: Text("Destination 1"), isActive: $isActiveLink1) {
                        EmptyView() // The link itself is hidden
                    }
                    Button("Go to Destination 1") {
                        isActiveLink1 = true
                    }

                    // Tag-based navigation (more robust, iOS 16+)
                    NavigationLink("Go to Red", destination: Color.red, tag: "Red", selection: $selection)
                    NavigationLink("Go to Blue", destination: Color.blue, tag: "Blue", selection: $selection)
                    Button("Programmatically Go Blue") {
                        selection = "Blue"
                    }
                    if let currentSelection = selection {
                        Text("Current Selection: \(currentSelection)")
                    }
                }
                .navigationTitle("Programmatic Nav")
            }
        }
    }
    ```

**14.2 Modal Presentations (`.sheet`, `.fullScreenCover`)**
Modals present content that temporarily interrupts the user's current flow, often for a specific task or information display.

*   **`.sheet(isPresented:onDismiss:content:)`:** Presents a view as a modal sheet that typically doesn't cover the entire screen (on iPad and Mac, behavior varies on iPhone).

    ```swift
    struct SheetDemoView: View {
        @State private var showingSheet = false

        var body: some View {
            Button("Show Info Sheet") {
                showingSheet = true
            }
            .sheet(isPresented: $showingSheet, onDismiss: {
                print("Sheet dismissed")
            }) {
                // Content of the sheet
                VStack {
                    Text("This is some important information.")
                        .font(.title)
                    Button("Dismiss") {
                        showingSheet = false
                    }
                }
                .padding()
            }
        }
    }
    ```
    To dismiss a sheet from within itself, you can use `@Environment(\.dismiss) var dismiss`.

*   **`.fullScreenCover(isPresented:onDismiss:content:)`:** Presents a view modally that covers the entire screen.

    ```swift
    struct FullScreenCoverDemo: View {
        @State private var showingOnboarding = false
        var body: some View {
            Button("Show Onboarding") { showingOnboarding = true }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView() // A view for the full-screen cover
            }
        }
    }
    struct OnboardingView: View {
        @Environment(\.dismiss) var dismiss // To dismiss the cover
        var body: some View { ZStack { Color.green.ignoresSafeArea(); Button("Done Onboarding") { dismiss() } } }
    }
    ```

**14.3 Tab-Based Navigation (`TabView`)**
`TabView` is used for apps where users can switch between distinct sections or modes.

```swift
struct AppTabView: View {
    @State private var selectedTab = 0 // Or use a specific tag type

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0) // Tag for this tab

            SettingsViewTab() // Assuming SettingsViewTab is a defined View
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(1)

            ProfileViewTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
                .badge(5) // Add a badge to the tab item
        }
    }
}
struct HomeView: View { var body: some View { Text("Home Screen") } }
struct SettingsViewTab: View { var body: some View { Text("Settings Screen") } }
struct ProfileViewTab: View { var body: some View { Text("Profile Screen") } }
```
Each child of the `TabView` becomes a tab. The `.tabItem` modifier defines the tab's icon and text.

**14.4 Alerts and Confirmation Dialogs**
*   **`.alert()`:** Presents an alert to the user.
    There are several forms of the `.alert()` modifier. One common one takes a title, an `isPresented` binding, and an optional `actions` closure.

    ```swift
    struct AlertDemoView: View {
        @State private var showingAlert = false
        @State private var alertMessage = ""

        var body: some View {
            VStack {
                Button("Perform Risky Action") {
                    alertMessage = "Are you sure you want to proceed?"
                    showingAlert = true
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .destructive) { /* Handle action */ }
                Button("Cancel", role: .cancel) {}
                // Add more buttons if needed
            }
        }
    }
    ```
    The `role` parameter on `Button` helps the system style buttons appropriately (e.g., `.destructive` often appears red).

*   **`.confirmationDialog()`:** (iOS 15+) Presents a set of choices to the user, often as an action sheet from the bottom on iPhone.

    ```swift
    struct ConfirmationDialogDemo: View {
        @State private var showDialog = false
        var body: some View {
            Button("Choose Option") { showDialog = true }
            .confirmationDialog("Select an Option", isPresented: $showDialog, titleVisibility: .visible) {
                Button("Option A") { print("Chose A") }
                Button("Option B") { print("Chose B") }
                Button("Delete", role: .destructive) { print("Chose Delete") }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This is an important choice.") // Optional message
            }
        }
    }
    ```

**14.5 NavigationStack (iOS 16+) and `NavigationPath`**
`NavigationStack` is a more flexible and powerful replacement for `NavigationView` introduced in iOS 16. It allows for programmatic control over the navigation path using a `NavigationPath` binding.

*   **`NavigationStack(path:root:)`:**
    The `path` parameter binds to a `NavigationPath` instance (or an array of hashable data) that represents the current navigation stack.

*   **`.navigationDestination(for:destination:)`:**
    This modifier is used within a `NavigationStack` to define the destination view for a specific data type. When an item of that data type is added to the `NavigationPath`, SwiftUI navigates to the corresponding destination.

```swift
// Data models (must be Hashable for path-based navigation)
struct Recipe: Identifiable, Hashable {
    let id = UUID()
    var name: String
}
struct Ingredient: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: String
}

@available(iOS 16.0, *)
struct ModernNavView: View {
    @State private var path = NavigationPath() // Manages the navigation stack

    let recipes = [Recipe(name: "Pancakes"), Recipe(name: "Omelette")]

    var body: some View {
        NavigationStack(path: $path) { // Bind the path
            List {
                ForEach(recipes) { recipe in
                    // NavigationLink value pushes the data to the path
                    NavigationLink(recipe.name, value: recipe)
                }
            }
            .navigationTitle("Recipes")
            // Define destinations for different data types
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe, path: $path)
            }
            .navigationDestination(for: Ingredient.self) { ingredient in
                IngredientDetailView(ingredient: ingredient)
            }
            .toolbar {
                Button("Go to Pancakes Ingredient") {
                    // Programmatic navigation
                    path.append(recipes[0]) // Navigate to Pancakes Recipe
                    // Assuming RecipeDetailView will navigate to its first ingredient
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct RecipeDetailView: View {
    var recipe: Recipe
    @Binding var path: NavigationPath // Can further manipulate the path

    // Sample ingredients for the recipe
    let ingredients = [Ingredient(name: "Flour", quantity: "2 cups"), Ingredient(name: "Eggs", quantity: "2")]

    var body: some View {
        VStack {
            Text("Recipe: \(recipe.name)")
                .font(.largeTitle)
            List(ingredients) { ingredient in
                NavigationLink(ingredient.name, value: ingredient)
            }
            Button("Go to First Ingredient Programmatically") {
                if let firstIngredient = ingredients.first {
                    path.append(firstIngredient)
                }
            }
            Button("Go Home (Pop to Root)") {
                path = NavigationPath() // Or path.removeLast(path.count)
            }
        }
        .navigationTitle(recipe.name)
    }
}

@available(iOS 16.0, *)
struct IngredientDetailView: View {
    var ingredient: Ingredient
    var body: some View {
        Text("Ingredient: \(ingredient.name) (\(ingredient.quantity))")
            .navigationTitle(ingredient.name)
    }
}
```
`NavigationStack` offers better state restoration, deep linking capabilities, and more robust programmatic control.

**14.6 Managing App Entry Point and Initial View (`App` protocol)**
SwiftUI apps typically have an entry point defined by a structure conforming to the `App` protocol.
```swift
import SwiftUI

@main // Marks this as the app's entry point
struct MyAppNameApp: App { // Conforms to the App protocol
    var body: some Scene { // Describes the app's content and behavior
        WindowGroup { // A container for a window in your app
            ContentView() // The initial view to display
        }
    }
}
// Where ContentView is your root SwiftUI view, perhaps containing a TabView or NavigationView.
```

--- 