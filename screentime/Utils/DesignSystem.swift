import SwiftUI

// MARK: - Design System
enum DesignSystem {
    
    // MARK: - Colors
    enum Colors {
        // Primary Brand Colors - Refined with better contrast
        static let primaryBlue = Color(hex: "0A84FF")  // Slightly more vibrant
        static let primaryIndigo = Color(hex: "5E5CE6") // More refined indigo
        
        // Semantic Colors - Enhanced vibrancy
        static let success = Color(hex: "32D74B")
        static let warning = Color(hex: "FF9F0A")
        static let error = Color(hex: "FF453A")
        static let info = Color(hex: "64D2FF")
        
        // Neutral Colors
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
        static let groupedBackground = Color(UIColor.systemGroupedBackground)
        
        // Text Colors
        static let primaryText = Color(UIColor.label)
        static let secondaryText = Color(UIColor.secondaryLabel)
        static let tertiaryText = Color(UIColor.tertiaryLabel)
        static let quaternaryText = Color(UIColor.quaternaryLabel)
        
        // Component Colors
        static let separator = Color(UIColor.separator)
        static let opaqueSeparator = Color(UIColor.opaqueSeparator)
        
        // Parent/Child Specific - More refined
        static let parentAccent = Color(hex: "5E5CE6") // Refined Indigo
        static let childAccent = Color(hex: "40C8E0") // Vibrant Cyan
        
        // Task Priority Colors
        static let highPriority = Color(hex: "FF453A")
        static let mediumPriority = Color(hex: "FF9F0A")
        static let lowPriority = Color(hex: "32D74B")
    }
    
    // MARK: - Typography - Refined with perfect proportions
    enum Typography {
        // Large Titles - Adjusted for better visual hierarchy
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let largeTitleRegular = Font.system(size: 34, weight: .regular, design: .rounded)
        
        // Titles - Better scaling
        static let title1 = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        // Body - Improved readability
        static let bodyLarge = Font.system(size: 19, weight: .regular, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)
        
        // Supporting - Better proportions
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let calloutBold = Font.system(size: 16, weight: .semibold, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        
        // Monospaced (for timers) - Optimized for circular displays
        static let monospacedDigit = Font.system(size: 28, weight: .medium, design: .monospaced)
        static let monospacedLarge = Font.system(size: 42, weight: .semibold, design: .monospaced)
        static let monospacedXLarge = Font.system(size: 48, weight: .bold, design: .monospaced)
    }
    
    // MARK: - Spacing - Golden ratio inspired spacing
    enum Spacing {
        static let xxxSmall: CGFloat = 2
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
        static let xxxLarge: CGFloat = 64
        
        // Component specific - Refined
        static let cardPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 32
        static let listItemSpacing: CGFloat = 16
        static let buttonPadding: CGFloat = 16
        static let iconSpacing: CGFloat = 12
    }
    
    // MARK: - Corner Radius - More refined curves
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let pill: CGFloat = 100
        
        // Component specific
        static let card: CGFloat = 20
        static let button: CGFloat = 14
        static let input: CGFloat = 12
        static let badge: CGFloat = 8
    }
    
    // MARK: - Shadows - More subtle and refined
    enum Shadow {
        static let small = ShadowStyle(
            color: Color.black.opacity(0.04),
            radius: 8,
            x: 0,
            y: 2
        )
        
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.06),
            radius: 16,
            x: 0,
            y: 4
        )
        
        static let large = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 24,
            x: 0,
            y: 8
        )
        
        static let card = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 20,
            x: 0,
            y: 4
        )
        
        static let elevated = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 32,
            x: 0,
            y: 12
        )
    }
    
    // MARK: - Animation - Refined timing
    enum Animation {
        static let springBounce = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let springSmooth = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.9)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let gentle = SwiftUI.Animation.easeInOut(duration: 0.35)
    }
    
    // MARK: - Layout - Better proportions
    enum Layout {
        static let maxContentWidth: CGFloat = 428
        static let minButtonHeight: CGFloat = 52  // Increased for better touch target
        static let minTouchTarget: CGFloat = 48
        static let keyboardOffset: CGFloat = 20
        static let circleTimerSize: CGFloat = 280  // Optimized for timer display
        static let iconSize: CGFloat = 24
        static let tabBarHeight: CGFloat = 88
    }
    
    // MARK: - Metrics - New addition for consistent sizing
    enum Metrics {
        static let borderWidth: CGFloat = 1
        static let dividerHeight: CGFloat = 0.5
        static let progressBarHeight: CGFloat = 8
        static let indicatorSize: CGFloat = 4
    }
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // New: Adaptive color for better contrast
    func adaptiveOpacity(_ opacity: Double) -> Color {
        self.opacity(opacity)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(padding: CGFloat = DesignSystem.Spacing.cardPadding) -> some View {
        self
            .padding(padding)
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .shadow(
                color: DesignSystem.Shadow.card.color,
                radius: DesignSystem.Shadow.card.radius,
                x: DesignSystem.Shadow.card.x,
                y: DesignSystem.Shadow.card.y
            )
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.bodyBold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.minButtonHeight)
            .background(DesignSystem.Colors.primaryBlue)
            .cornerRadius(DesignSystem.CornerRadius.button)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.bodyBold)
            .foregroundColor(DesignSystem.Colors.primaryBlue)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.minButtonHeight)
            .background(DesignSystem.Colors.primaryBlue.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.button)
    }
    
    // New: Subtle scale effect on tap
    func interactiveScale() -> some View {
        self.scaleEffect(1.0)
            .animation(DesignSystem.Animation.quick, value: true)
    }
}

// MARK: - Custom Components
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Spacing.cardPadding)
            .background(
                ZStack {
                    DesignSystem.Colors.secondaryBackground.opacity(0.9)
                    VisualEffectBlur(blurStyle: .systemMaterial)
                }
            )
            .cornerRadius(DesignSystem.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.separator.opacity(0.3), lineWidth: 0.5)
            )
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Gradient Definitions - Enhanced
extension LinearGradient {
    static let parentGradient = LinearGradient(
        colors: [
            DesignSystem.Colors.parentAccent,
            DesignSystem.Colors.parentAccent.opacity(0.85),
            DesignSystem.Colors.primaryIndigo.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let childGradient = LinearGradient(
        colors: [
            DesignSystem.Colors.childAccent,
            DesignSystem.Colors.childAccent.opacity(0.85),
            DesignSystem.Colors.primaryBlue.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [
            DesignSystem.Colors.success,
            DesignSystem.Colors.success.opacity(0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // New: Subtle background gradient
    static let subtleBackground = LinearGradient(
        colors: [
            Color.white.opacity(0.05),
            Color.white.opacity(0.02)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Button Styles
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
} 