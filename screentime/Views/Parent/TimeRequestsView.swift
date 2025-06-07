import SwiftUI

struct TimeRequestsView: View {
    @State private var pendingRequests: [TimeRequest] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(pendingRequests) { request in
                    TimeRequestCard(
                        request: request,
                        onApprove: { approveRequest(request) },
                        onDeny: { denyRequest(request) }
                    )
                }
            }
            .navigationTitle("Time Requests")
            .refreshable {
                loadPendingRequests()
            }
        }
        .onAppear {
            loadPendingRequests()
        }
    }
    
    private func loadPendingRequests() {
        // During transition: create placeholder requests for demo
        // In production: load from SupabaseDataRepository
        pendingRequests = []
    }
    
    private func approveRequest(_ request: TimeRequest) {
        // During transition: simplified approval
        pendingRequests.removeAll { $0.id == request.id }
    }
    
    private func denyRequest(_ request: TimeRequest) {
        // During transition: simplified denial
        pendingRequests.removeAll { $0.id == request.id }
    }
}

// MARK: - Time Request Card

struct TimeRequestCard: View {
    let request: TimeRequest
    let onApprove: () -> Void
    let onDeny: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Time Request")
                    .font(.headline)
                Spacer()
                Text(request.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Requested: \(Int(request.requestedSeconds / 60)) minutes")
                .font(.subheadline)
            
            if let message = request.responseMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button("Approve") {
                    onApprove()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Deny") {
                    onDeny()
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    TimeRequestsView()
} 