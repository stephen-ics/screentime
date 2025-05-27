import SwiftUI

struct TimeRequestsView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var pendingRequests: [TimeRequest] = []
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            if pendingRequests.isEmpty {
                Text("No pending time requests")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(pendingRequests, id: \.id) { request in
                    TimeRequestRow(
                        request: request,
                        onApprove: { approveRequest(request) },
                        onDeny: { denyRequest(request) }
                    )
                }
            }
        }
        .navigationTitle("Time Requests")
        .onAppear {
            loadPendingRequests()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadPendingRequests() {
        guard let parentEmail = authService.currentUser?.email else { return }
        pendingRequests = SharedDataManager.shared.getPendingRequests(forParentEmail: parentEmail)
    }
    
    private func approveRequest(_ request: TimeRequest) {
        if SharedDataManager.shared.approveTimeRequest(request.id) {
            pendingRequests.removeAll { $0.id == request.id }
        } else {
            errorMessage = "Failed to approve request"
            showError = true
        }
    }
    
    private func denyRequest(_ request: TimeRequest) {
        if SharedDataManager.shared.denyTimeRequest(request.id) {
            pendingRequests.removeAll { $0.id == request.id }
        } else {
            errorMessage = "Failed to deny request"
            showError = true
        }
    }
}

struct TimeRequestRow: View {
    let request: TimeRequest
    let onApprove: () -> Void
    let onDeny: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Request from \(request.childEmail)")
                .font(.headline)
            
            Text("Requesting \(request.requestedMinutes) minutes")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: onApprove) {
                    Label("Approve", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Spacer()
                
                Button(action: onDeny) {
                    Label("Deny", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
} 