import SwiftUI

struct AuthenticationView: View {
    // MARK: - State
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isParent = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var errorRecovery = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var animateGradient = false
    @State private var showDemoMode = false
    @State private var showEmailVerification = false
    @State private var emailForVerification = ""
    
    // MARK: - Environment
    @EnvironmentObject private var familyAuth: FamilyAuthService
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
                                // Account Type Selector (Sign Up only)
                                if isSignUp {
                                    accountTypeSelector
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                }
                                
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
            if !errorRecovery.isEmpty {
                Button("Learn More") {
                    // Could open a help view or settings
                }
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text(errorMessage)
                if !errorRecovery.isEmpty {
                    Text(errorRecovery)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showEmailVerification) {
            EmailVerificationView(email: emailForVerification)
                .environmentObject(familyAuth)
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
            // Base gradient
            LinearGradient(
                colors: [
                    isParent ? DesignSystem.Colors.parentAccent : DesignSystem.Colors.childAccent,
                    isParent ? DesignSystem.Colors.primaryIndigo : DesignSystem.Colors.primaryBlue
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
            Text(isSignUp ? "Create Account" : "Welcome Back")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(.white)
            
            Text("Manage screen time together")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    // MARK: - Account Type Selector
    private var accountTypeSelector: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("I am a...")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            HStack(spacing: DesignSystem.Spacing.medium) {
                accountTypeButton(
                    title: "Parent",
                    icon: "person.2.fill",
                    isSelected: isParent,
                    color: DesignSystem.Colors.parentAccent
                ) {
                    withAnimation(DesignSystem.Animation.springBounce) {
                        isParent = true
                    }
                }
                
                accountTypeButton(
                    title: "Child",
                    icon: "face.smiling.fill",
                    isSelected: !isParent,
                    color: DesignSystem.Colors.childAccent
                ) {
                    withAnimation(DesignSystem.Animation.springBounce) {
                        isParent = false
                    }
                }
            }
        }
    }
    
    private func accountTypeButton(title: String, icon: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xSmall) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(DesignSystem.Typography.calloutBold)
                    .foregroundColor(isSelected ? .white : DesignSystem.Colors.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
    }
    
    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Name field (Sign Up only)
            if isSignUp {
                CustomTextField(
                    placeholder: "Full Name",
                    text: $name,
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
                placeholder: "Email",
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
                        Text(isSignUp ? "Create Account" : "Sign In")
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
                name = ""
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.xxSmall) {
                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
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
                        
                        Text("Supabase not configured. Using local demo authentication.")
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
                
                #if DEBUG
                // Add test buttons in debug mode
                HStack(spacing: DesignSystem.Spacing.small) {
                    Button("Test Supabase") {
                        testSupabaseConnection()
                    }
                    .font(DesignSystem.Typography.caption1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                    
                    Button("Test Sign Up") {
                        testSupabaseSignUp()
                    }
                    .font(DesignSystem.Typography.caption1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                }
                #endif
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
    
    // MARK: - Test Functions
    #if DEBUG
    private func testSupabaseConnection() {
        Task {
            await SupabaseManager.shared.testSupabaseConnection()
        }
    }
    
    private func testSupabaseSignUp() {
        Task {
            do {
                try await SupabaseManager.shared.testSignUp(
                    email: "test@example.com",
                    password: "testpassword123",
                    name: "Test User",
                    role: .parent
                )
                print("✅ Test sign up completed!")
            } catch {
                print("❌ Test sign up failed: \(error)")
            }
        }
    }
    #endif
    
    // MARK: - Actions
    private func handleAuthentication() {
        // Validate input
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showErrorMessage("Please enter an email", recovery: "An email is required to create or access your account")
            return
        }

        guard !password.isEmpty else {
            showErrorMessage("Please enter your password", recovery: "Password is required for authentication")
            return
        }
        
        if isSignUp && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showErrorMessage("Please enter your name", recovery: "Your name will be displayed in the app and helps personalize your experience")
            return
        }
        
        isLoading = true
        
        _Concurrency.Task {
            do {
                if isSignUp {
                    try await familyAuth.signUpFamily(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password,
                        parentName: name.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    
                    await MainActor.run {
                        isLoading = false
                        // Success - the RootView will handle navigation
                    }
                } else {
                    try await familyAuth.signInFamily(
                        email: email,
                        password: password
                    )
                    
                    await MainActor.run {
                        isLoading = false
                        // Success - the RootView will handle navigation
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    
                    // Handle specific error types with helpful messages
                    if let authError = error as? AuthError {
                        showErrorMessage(
                            authError.localizedDescription,
                            recovery: authError.recoverySuggestion ?? ""
                        )
                    } else {
                        showErrorMessage(
                            "Authentication failed",
                            recovery: "Please check your internet connection and try again"
                        )
                    }
                }
            }
        }
    }
    
    private func showErrorMessage(_ message: String, recovery: String = "") {
        errorMessage = message
        errorRecovery = recovery
        showError = true
    }
}

// MARK: - Custom Components
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.input)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                .stroke(DesignSystem.Colors.separator, lineWidth: 0.5)
        )
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "lock.fill")
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .frame(width: 20)
            
            if showPassword {
                TextField(placeholder, text: $text)
                    .textContentType(.password)
            } else {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
            }
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.input)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                .stroke(DesignSystem.Colors.separator, lineWidth: 0.5)
        )
    }
}

struct SocialSignInButton: View {
    let title: String
    var icon: String? = nil
    var imageName: String? = nil
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.buttonIconSpacing) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.Layout.buttonIconSize))
                } else if let imageName = imageName {
                    Image(imageName)
                        .resizable()
                        .frame(width: DesignSystem.Layout.buttonIconSize, height: DesignSystem.Layout.buttonIconSize)
                }
                
                Text(title)
                    .font(DesignSystem.Typography.bodyBold)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, DesignSystem.Spacing.buttonHorizontalPadding)
            .padding(.vertical, DesignSystem.Spacing.buttonVerticalPadding)
            .frame(maxWidth: .infinity)
            .frame(minHeight: DesignSystem.Layout.minButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(backgroundColor == .black ? Color.clear : DesignSystem.Colors.separator, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(FamilyAuthService.shared)
    }
} 