import SwiftUI

struct TimeRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var requestedMinutes: Double = 30
    @State private var reason: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Header
                    headerSection
                    
                    // Time Request Section
                    timeRequestSection
                    
                    // Reason Section
                    reasonSection
                    
                    Spacer(minLength: DesignSystem.Spacing.xxxLarge)
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .background(DesignSystem.Colors.groupedBackground)
            .navigationTitle("Request More Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.childAccent)
                }
            }
            .safeAreaInset(edge: .bottom) {
                submitButton
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "clock.badge.plus")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(DesignSystem.Colors.childAccent)
            
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("Request More Time")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Ask your parent for additional screen time. Be sure to explain why you need more time!")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.childAccent.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.childAccent.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Time Request Section
    private var timeRequestSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("How much time do you need?")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Time display
                VStack(spacing: DesignSystem.Spacing.small) {
                    Text("\(Int(requestedMinutes)) minutes")
                        .font(DesignSystem.Typography.monospacedLarge)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.childAccent)
                    
                    Text("Additional screen time")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.large)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(DesignSystem.Colors.secondaryBackground)
                )
                
                // Time slider
                VStack(spacing: DesignSystem.Spacing.small) {
                    Slider(value: $requestedMinutes, in: 15...120, step: 15)
                        .accentColor(DesignSystem.Colors.childAccent)
                    
                    HStack {
                        Text("15 min")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text("2 hours")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Reason Section
    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Why do you need more time?")
                .font(DesignSystem.Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Reason text field
                TextEditor(text: $reason)
                    .frame(minHeight: 100)
                    .padding(DesignSystem.Spacing.medium)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.separator, lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if reason.isEmpty {
                                VStack {
                                    HStack {
                                        Text("I need more time because...")
                                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                                            .padding(.top, DesignSystem.Spacing.medium + 8) // Account for TextEditor padding
                                            .padding(.leading, DesignSystem.Spacing.medium + 4) // Account for TextEditor padding
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
                
                // Quick reason suggestions
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Quick suggestions:")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.small) {
                        ReasonSuggestionButton(text: "Finish homework project") {
                            reason = "I need to finish my homework project online"
                        }
                        
                        ReasonSuggestionButton(text: "Video call with friends") {
                            reason = "I want to video call with my friends"
                        }
                        
                        ReasonSuggestionButton(text: "Educational videos") {
                            reason = "I want to watch educational videos"
                        }
                        
                        ReasonSuggestionButton(text: "Creative project") {
                            reason = "I'm working on a creative project"
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: submitRequest) {
                HStack(spacing: DesignSystem.Spacing.buttonIconSpacing) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: DesignSystem.Layout.buttonIconSize, weight: .medium))
                    }
                    
                    Text(isSubmitting ? "Sending..." : "Send Request")
                        .font(DesignSystem.Typography.bodyBold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.buttonHorizontalPadding)
                .padding(.vertical, DesignSystem.Spacing.buttonVerticalPadding)
                .frame(maxWidth: .infinity)
                .frame(minHeight: DesignSystem.Layout.minButtonHeight)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .fill(DesignSystem.Colors.childAccent)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isSubmitting || reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.background)
        }
    }
    
    // MARK: - Actions
    private func submitRequest() {
        isSubmitting = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct ReasonSuggestionButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(DesignSystem.Typography.caption1)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.childAccent)
                .padding(.horizontal, DesignSystem.Spacing.small)
                .padding(.vertical, DesignSystem.Spacing.xSmall)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(DesignSystem.Colors.childAccent.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .stroke(DesignSystem.Colors.childAccent.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
    }
}

// MARK: - Preview
struct TimeRequestView_Previews: PreviewProvider {
    static var previews: some View {
        TimeRequestView()
    }
} 