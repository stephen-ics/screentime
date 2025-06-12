import SwiftUI

/// Main authentication view for family-based authentication system
struct FamilyAuthenticationView: View {
    // MARK: - State
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var parentName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var animateGradient = false
    @State private var showDemoMode = false
    
    // MARK: - Environment
    @EnvironmentObject private var familyAuthService: FamilyAuthService
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Animated Background
            backgroundGradient
            
            VStack(spacing: 0) {
                // Demo Mode Banner
                demoBanner
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xxLarge) {
                        // Logo and Welcome
                        headerSection
                            .padding(.top, showDemoMode ? DesignSystem.Spacing.medium : DesignSystem.Spacing.xxxLarge)
                        
                        // Form Card
                        GlassCard {
                            VStack(spacing: DesignSystem.Spacing.large) {
                                // Form Fields
                                formFields
                                
                                // Action Buttons
                                actionButtons
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        
                        // Toggle Sign In/Up
                        toggleAuthMode
                            .padding(.bottom, DesignSystem.Spacing.xxxLarge)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
            
            // Check if we're in demo mode
            let isSupabaseConfigured = SupabaseManager.shared.client != nil
            withAnimation(.easeInOut(duration: 0.5)) {
                showDemoMode = !isSupabaseConfigured
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        ZStack {
            // Base gradient - family friendly blue/purple theme
            LinearGradient(
                colors: [
                    DesignSystem.Colors.primaryBlue,
                    DesignSystem.Colors.primaryIndigo
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            
            // Overlay pattern
            GeometryReader { geometry in
                ForEach(0..<20) { index in
                    Circle()
                        .fill(Color.white.opacity(0.02))
                        .frame(width: CGFloat.random(in: 50...200))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 2)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // App Icon
            AppIconDisplay(size: 100)
                .shadow(
                    color: DesignSystem.Shadow.large.color,
                    radius: DesignSystem.Shadow.large.radius,
                    x: DesignSystem.Shadow.large.x,
                    y: DesignSystem.Shadow.large.y
                )
            
            // Welcome Text
            Text(isSignUp ? "Create Family Account" : "Welcome Back")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(.white)
            
            Text(isSignUp 
                 ? "One account for your whole family"
                 : "Sign in to manage your family's screen time")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Parent Name field (Sign Up only)
            if isSignUp {
                CustomTextField(
                    placeholder: "Parent Name",
                    text: $parentName,
                    icon: "person.fill",
                    keyboardType: .default,
                    textContentType: .name
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }

            // Email field
            CustomTextField(
                placeholder: "Family Email",
                text: $email,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            
            // Password field
            CustomSecureField(
                placeholder: "Password",
                text: $password,
                showPassword: $showPassword
            )
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Primary Action
            Button(action: handleAuthentication) {
                HStack(spacing: DesignSystem.Spacing.buttonIconSpacing) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(isSignUp ? "Create Family Account" : "Sign In")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: !isLoading, isLoading: isLoading))
            .disabled(isLoading)
            
            // Divider
            HStack {
                Rectangle()
                    .fill(DesignSystem.Colors.separator)
                    .frame(height: 1)
                
                Text("OR")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .padding(.horizontal, DesignSystem.Spacing.small)
                
                Rectangle()
                    .fill(DesignSystem.Colors.separator)
                    .frame(height: 1)
            }
            .padding(.vertical, DesignSystem.Spacing.xSmall)
            
            // Social Sign In
            socialSignInButtons
        }
    }
    
    // MARK: - Social Sign In
    private var socialSignInButtons: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            SocialSignInButton(
                title: "Continue with Apple",
                icon: "apple.logo",
                backgroundColor: .black,
                foregroundColor: .white
            ) {
                // Handle Apple Sign In
            }
            
            SocialSignInButton(
                title: "Continue with Google",
                imageName: "google",
                backgroundColor: DesignSystem.Colors.secondaryBackground,
                foregroundColor: DesignSystem.Colors.primaryText
            ) {
                // Handle Google Sign In
            }
        }
    }
    
    // MARK: - Toggle Auth Mode
    private var toggleAuthMode: some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.springSmooth) {
                isSignUp.toggle()
                // Clear form
                email = ""
                password = ""
                parentName = ""
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.xxSmall) {
                Text(isSignUp ? "Already have a family account?" : "Need a family account?")
                    .foregroundColor(.white.opacity(0.8))
                
                Text(isSignUp ? "Sign In" : "Sign Up")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(TextButtonStyle(color: .white))
    }
    
    // MARK: - Demo Mode Banner
    @ViewBuilder
    private var demoBanner: some View {
        if showDemoMode {
            VStack(spacing: DesignSystem.Spacing.small) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Demo Mode")
                            .font(DesignSystem.Typography.calloutBold)
                            .foregroundColor(.primary)
                        
                        Text("Supabase not configured. Using demo authentication.")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Setup") {
                        // Could navigate to setup instructions
                    }
                    .font(DesignSystem.Typography.caption1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(DesignSystem.Colors.separator),
                alignment: .bottom
            )
        }
    }
    
    // MARK: - Actions
    private func handleAuthentication() {
        // Validate input
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showErrorMessage("Please enter a family email")
            return
        }

        guard !password.isEmpty else {
            showErrorMessage("Please enter your password")
            return
        }
        
        if isSignUp && parentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showErrorMessage("Please enter the parent's name")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await familyAuthService.signUpFamily(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password,
                        parentName: parentName.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                } else {
                    try await familyAuthService.signInFamily(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines), 
                        password: password
                    )
                }
                
                await MainActor.run {
                    isLoading = false
                    // Success - the RootView will handle navigation based on auth state
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showErrorMessage(error.localizedDescription)
                }
            }
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Preview

#if DEBUG
struct FamilyAuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FamilyAuthenticationView()
                .environmentObject(FamilyAuthService.shared)
                .previewDisplayName("Family Auth")
                .preferredColorScheme(.dark)
            
            FamilyAuthenticationView()
                .environmentObject(FamilyAuthService.shared)
                .previewDisplayName("Family Auth Light")
                .preferredColorScheme(.light)
        }
    }
}
#endif 