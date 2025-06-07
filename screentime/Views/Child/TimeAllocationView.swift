import SwiftUI

struct TimeAllocationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMinutes: Int = 0
    @State private var showingConfirmation = false
    @State private var isProcessing = false
    
    let availableMinutes: Int
    let onTimeUnlocked: ((Int) -> Void)? // Callback to handle time unlock
    
    init(availableMinutes: Int, onTimeUnlocked: ((Int) -> Void)? = nil) {
        self.availableMinutes = availableMinutes
        self.onTimeUnlocked = onTimeUnlocked
        self._selectedMinutes = State(initialValue: min(availableMinutes, 30)) // Default to 30 min or max available
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.xxxLarge) {
                Spacer()
                
                // Header
                headerSection
                
                // Time Selection
                timeSelectionSection
                
                // Quick Selection Buttons
                quickSelectionButtons
                
                Spacer()
                
                // Bottom Action
                bottomActionButton
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.groupedBackground,
                        DesignSystem.Colors.childAccent.opacity(0.02)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("🎮 Unlock Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.childAccent)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Text("⏰")
                .font(.system(size: 64))
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("Unlock Your Screen Time!")
                    .font(DesignSystem.Typography.title1)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("Choose how many minutes to unlock from your \(availableMinutes) available minutes 🚀")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Time Selection Section
    private var timeSelectionSection: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Big time display
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("Selected Time")
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("\(selectedMinutes)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.childAccent)
                    .contentTransition(.numericText())
                
                Text("minutes")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            // Slider
            VStack(spacing: DesignSystem.Spacing.medium) {
                Slider(
                    value: Binding(
                        get: { Double(selectedMinutes) },
                        set: { selectedMinutes = Int($0) }
                    ),
                    in: 5...Double(availableMinutes),
                    step: 5
                )
                .accentColor(DesignSystem.Colors.childAccent)
                
                HStack {
                    Text("5 min")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(availableMinutes) min")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
        .padding(DesignSystem.Spacing.xxLarge)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                .fill(.white)
        )
        .shadow(
            color: DesignSystem.Shadow.card.color.opacity(0.1),
            radius: DesignSystem.Shadow.card.radius,
            x: DesignSystem.Shadow.card.x,
            y: DesignSystem.Shadow.card.y
        )
    }
    
    // MARK: - Quick Selection Buttons
    private var quickSelectionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Text("Quick Select")
                .font(DesignSystem.Typography.bodyBold)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            HStack(spacing: DesignSystem.Spacing.medium) {
                ForEach([15, 30, 60], id: \.self) { minutes in
                    if minutes <= availableMinutes {
                        QuickSelectButton(
                            minutes: minutes,
                            isSelected: selectedMinutes == minutes,
                            action: {
                                selectedMinutes = minutes
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        Button(action: {
            unlockSelectedTime()
        }) {
            HStack(spacing: DesignSystem.Spacing.buttonIconSpacing) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("🚀")
                        .font(.system(size: 20))
                }
                
                Text(isProcessing ? "Unlocking..." : "Unlock \(selectedMinutes) Minutes!")
                    .font(DesignSystem.Typography.bodyBold)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.buttonHorizontalPadding)
            .padding(.vertical, DesignSystem.Spacing.buttonVerticalPadding)
            .frame(maxWidth: .infinity)
            .frame(minHeight: DesignSystem.Layout.minButtonHeight)
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.success,
                        DesignSystem.Colors.success.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.button)
            .shadow(
                color: DesignSystem.Colors.success.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(FunScaleButtonStyle())
        .disabled(isProcessing || selectedMinutes <= 0)
        .opacity(isProcessing ? 0.8 : 1.0)
        .alert("Time Unlocked! 🎉", isPresented: $showingConfirmation) {
            Button("Start Playing!") {
                dismiss()
            }
        } message: {
            Text("You have unlocked \(selectedMinutes) minutes of screen time. Have fun!")
        }
    }
    
    // MARK: - Time Unlock Logic
    private func unlockSelectedTime() {
        guard selectedMinutes > 0 && selectedMinutes <= availableMinutes else { return }
        
        isProcessing = true
        
        // Simulate processing time (replace with actual unlock logic)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
            
            // Call the callback to handle the time unlock
            onTimeUnlocked?(selectedMinutes)
            
            // Show success confirmation
            showingConfirmation = true
        }
    }
}

// MARK: - Supporting Views

struct QuickSelectButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("\(minutes)")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.childAccent)
                
                Text("min")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : DesignSystem.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.childAccent,
                                DesignSystem.Colors.childAccent.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.childAccent.opacity(0.1),
                                DesignSystem.Colors.childAccent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(
                        isSelected ? DesignSystem.Colors.childAccent : DesignSystem.Colors.childAccent.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? DesignSystem.Colors.childAccent.opacity(0.3) : DesignSystem.Shadow.small.color,
                radius: isSelected ? 8 : DesignSystem.Shadow.small.radius,
                x: 0,
                y: isSelected ? 4 : DesignSystem.Shadow.small.y
            )
        }
        .buttonStyle(FunScaleButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Preview
struct TimeAllocationView_Previews: PreviewProvider {
    static var previews: some View {
        TimeAllocationView(availableMinutes: 90)
    }
} 