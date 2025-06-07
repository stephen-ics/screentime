import SwiftUI
import Combine
import FamilyControls

/// ViewModel for managing approved apps for a child profile
final class ApprovedAppsViewModel: ObservableObject {
    // The child profile this ViewModel manages apps for
    private let childProfile: Profile
    
    // --- Published Properties for UI State ---
    @Published var availableApps: [SupabaseApprovedApp] = []
    @Published var selectedApps: Set<SupabaseApprovedApp> = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showSuccessMessage = false
    
    // Search functionality
    @Published var searchText = ""
    @Published var filteredApps: [SupabaseApprovedApp] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(childProfile: Profile) {
        self.childProfile = childProfile
        
        // Set up search filtering
        $searchText
            .combineLatest($availableApps)
            .map { searchText, apps in
                if searchText.isEmpty {
                    return apps
                } else {
                    return apps.filter { app in
                        app.name.localizedCaseInsensitiveContains(searchText) ||
                        app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
                    }
                }
            }
            .assign(to: \.filteredApps, on: self)
            .store(in: &cancellables)
    }
    
    /// Loads the approved apps for the child
    func loadApprovedApps() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Simulate loading approved apps from repository
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay for demo
            
            // For demo purposes, create some mock apps
            let mockApps = SupabaseApprovedApp.mockApps(userId: childProfile.id)
            
            await MainActor.run {
                self.availableApps = mockApps
                self.selectedApps = Set(mockApps.filter { $0.isEnabled })
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Saves the current app selections
    func saveApprovedApps() async {
        await MainActor.run {
            isSaving = true
            errorMessage = nil
            showSuccessMessage = false
        }
        
        do {
            // Simulate saving to repository
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay for demo
            
            // Update the available apps to reflect enabled/disabled state
            let updatedApps = availableApps.map { app in
                if selectedApps.contains(app) {
                    return app.enabling()
                } else {
                    return app.disabling()
                }
            }
            
            await MainActor.run {
                self.availableApps = updatedApps
                self.showSuccessMessage = true
                self.isSaving = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isSaving = false
            }
        }
    }
    
    /// Toggles the selection state of an app
    func toggleAppSelection(_ app: SupabaseApprovedApp) {
        if selectedApps.contains(app) {
            selectedApps.remove(app)
        } else {
            selectedApps.insert(app)
        }
    }
    
    /// Removes an app from the approved list
    func removeApprovedApp(_ app: SupabaseApprovedApp) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Simulate removing from repository
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay for demo
            
            await MainActor.run {
                self.availableApps.removeAll { $0.id == app.id }
                self.selectedApps.remove(app)
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Updates the daily limit for an app
    func updateDailyLimit(for app: SupabaseApprovedApp, minutes: Int32) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Simulate updating in repository
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay for demo
            
            let updatedApp = app.settingDailyLimit(minutes: minutes)
            
            await MainActor.run {
                if let index = self.availableApps.firstIndex(where: { $0.id == app.id }) {
                    self.availableApps[index] = updatedApp
                }
                
                // Update selected apps set if it contains this app
                if self.selectedApps.contains(app) {
                    self.selectedApps.remove(app)
                    self.selectedApps.insert(updatedApp)
                }
                
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Clears any error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Clears the success message
    func clearSuccessMessage() {
        showSuccessMessage = false
    }
    
    /// Gets apps grouped by category
    var appsByCategory: [SupabaseApprovedApp.AppCategory: [SupabaseApprovedApp]] {
        Dictionary(grouping: filteredApps) { $0.category }
    }
    
    /// Whether there are any unsaved changes
    var hasUnsavedChanges: Bool {
        let currentlyEnabled = Set(availableApps.filter { $0.isEnabled })
        return currentlyEnabled != selectedApps
    }
} 