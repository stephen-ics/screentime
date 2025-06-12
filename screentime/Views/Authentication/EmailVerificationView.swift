import SwiftUI

/// Email verification view shown after signup when email confirmation is required
struct EmailVerificationView: View {
    
    // MARK: - Properties
    let email: String
    @State private var isResending = false
    @State private var showSuccessMessage = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var resendCooldown = 0
    @State private var timer: Timer?
    @State private var animateIcon = false
    @State private var verificationCheckTimer: Timer?
    @State private var isCheckingVerification = false
    
    // MARK: - Environment
    @EnvironmentObject private var familyAuth: FamilyAuthService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Services
    private let logger = Logger.shared
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            VStack(spacing: DesignSystem.Spacing.xxxLarge) {
                Spacer()
                
                // Email Icon Animation
                emailIconSection
                
                // Content
                contentSection
                
                // Action Buttons
                actionButtonsSection
                
                Spacer()
                
                // Footer
                footerSection
            }
            .padding(DesignSystem.Spacing.large)
        }
        .onAppear {
            startIconAnimation()
            startResendCooldown()
            startVerificationPolling()
        }
        .onDisappear {
            timer?.invalidate()
            verificationCheckTimer?.invalidate()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Email Sent", isPresented: $showSuccessMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A new verification email has been sent to \(email)")
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                DesignSystem.Colors.primaryBlue,
                DesignSystem.Colors.primaryIndigo
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Email Icon Section
    
    private var emailIconSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ZStack {
                // Background circle
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                // Envelope icon
                Image(systemName: "envelope.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                
                // Check mark overlay (when verified)
                if familyAuth.currentProfile?.emailVerified == true {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                        .background(Color.white.clipShape(Circle()))
                        .offset(x: 30, y: -30)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Text("Check Your Email")
                .font(DesignSystem.Typography.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("We've sent a verification link to:")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Text(email)
                    .font(DesignSystem.Typography.calloutBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(.white.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.small)
            }
            
            Text("Click the link in the email to verify your account and start using ScreenTime.")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Resend Email Button
            Button(action: resendVerificationEmail) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    if isResending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primaryBlue))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    
                    Text(resendButtonText)
                }
            }
            .buttonStyle(EmailVerificationSecondaryButtonStyle(isEnabled: !isResending && resendCooldown == 0))
            .disabled(isResending || resendCooldown > 0)
            
            // Continue Button (if already verified)
            if familyAuth.currentProfile?.emailVerified == true {
                Button(action: { dismiss() }) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Continue to App")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: true))
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Divider
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, DesignSystem.Spacing.xxLarge)
            
            // Help text
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("Didn't receive the email?")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(.white.opacity(0.7))
                
                VStack(spacing: DesignSystem.Spacing.xSmall) {
                    Text("• Check your spam/junk folder")
                    Text("• Make sure \(email) is correct")
                    Text("• Try resending the email")
                }
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(.white.opacity(0.6))
            }
            
            // Back to sign in
            Button("Back to Sign In") {
                dismiss()
            }
            .font(DesignSystem.Typography.callout)
            .foregroundColor(.white.opacity(0.8))
            .padding(.top, DesignSystem.Spacing.small)
        }
    }
    
    // MARK: - Helper Properties
    
    private var resendButtonText: String {
        if resendCooldown > 0 {
            return "Resend in \(resendCooldown)s"
        } else if isResending {
            return "Sending..."
        } else {
            return "Resend Email"
        }
    }
    
    // MARK: - Actions
    
    private func startIconAnimation() {
        withAnimation {
            animateIcon = true
        }
    }
    
    private func startResendCooldown() {
        resendCooldown = 60 // 60 second cooldown
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func resendVerificationEmail() {
        guard !isResending && resendCooldown == 0 else { return }
        
        isResending = true
        
        Task {
            do {
                try await familyAuth.resendVerificationEmail(email: email)
                
                await MainActor.run {
                    isResending = false
                    showSuccessMessage = true
                    startResendCooldown()
                }
            } catch {
                await MainActor.run {
                    isResending = false
                    errorMessage = "Failed to resend verification email. Please try again."
                    showError = true
                }
            }
        }
    }
    
    private func startVerificationPolling() {
        verificationCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task {
                await checkVerification()
            }
        }
    }
    
    private func checkVerification() async {
        guard !isCheckingVerification else { return }
        isCheckingVerification = true
        
        do {
            let isVerified = try await familyAuth.checkVerification(email: email)
            await MainActor.run {
                isCheckingVerification = false
                if isVerified {
                    logger.authSuccess("✅ Email verified! User is now signed in.")
                    // Stop polling since we're verified
                    verificationCheckTimer?.invalidate()
                    verificationCheckTimer = nil
                    // Dismiss this view - user will be taken to dashboard automatically
                    dismiss()
                } else {
                    // Continue polling - this is normal until user clicks verification link
                    logger.info(.auth, "⏳ Email not verified yet, continuing to poll...")
                }
            }
        } catch {
            await MainActor.run {
                isCheckingVerification = false
                // Don't show error for polling failures - they're expected until verification
                logger.info(.auth, "⏳ Verification check failed (expected until email is verified): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview

struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        EmailVerificationView(email: "test@example.com")
            .environmentObject(FamilyAuthService.shared)
    }
}

// MARK: - Button Styles

struct EmailVerificationSecondaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyBold)
            .foregroundColor(isEnabled ? DesignSystem.Colors.primaryBlue : DesignSystem.Colors.tertiaryText)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(.white)
                    .opacity(isEnabled ? 1.0 : 0.6)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct EmailVerificationTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.callout)
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
} 