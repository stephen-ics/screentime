import SwiftUI

// MARK: - Custom Button Component
struct CustomButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void
    var style: ButtonStyleType = .primary
    var isLoading: Bool = false
    var isEnabled: Bool = true
    
    enum ButtonStyleType {
        case primary
        case secondary
        case text
        case compact
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.buttonIconSpacing) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: DesignSystem.Layout.buttonIconSize, weight: .medium))
                    }
                    
                    Text(title)
                        .font(buttonFont)
                }
            }
            .foregroundColor(textColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: style == .text || style == .compact ? nil : .infinity)
            .frame(minHeight: minHeight)
            .background(backgroundView)
            .overlay(overlayView)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(ScaleButtonStyle(scale: scaleAmount))
    }
    
    // MARK: - Computed Properties
    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return isEnabled ? DesignSystem.Colors.primaryBlue : DesignSystem.Colors.primaryBlue.opacity(0.5)
        case .text:
            return isEnabled ? DesignSystem.Colors.primaryBlue : DesignSystem.Colors.primaryBlue.opacity(0.5)
        case .compact:
            return isEnabled ? DesignSystem.Colors.primaryText : DesignSystem.Colors.tertiaryText
        }
    }
    
    private var buttonFont: Font {
        switch style {
        case .primary, .secondary:
            return DesignSystem.Typography.bodyBold
        case .text:
            return DesignSystem.Typography.callout
        case .compact:
            return DesignSystem.Typography.calloutBold
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .primary, .secondary:
            return DesignSystem.Spacing.buttonHorizontalPadding
        case .text:
            return DesignSystem.Spacing.small
        case .compact:
            return DesignSystem.Spacing.medium
        }
    }
    
    private var verticalPadding: CGFloat {
        switch style {
        case .primary, .secondary:
            return DesignSystem.Spacing.buttonVerticalPadding
        case .text:
            return DesignSystem.Spacing.xSmall
        case .compact:
            return DesignSystem.Spacing.small
        }
    }
    
    private var minHeight: CGFloat {
        switch style {
        case .primary, .secondary:
            return DesignSystem.Layout.minButtonHeight
        case .text:
            return 0
        case .compact:
            return DesignSystem.Layout.minCompactButtonHeight
        }
    }
    
    private var scaleAmount: CGFloat {
        switch style {
        case .primary, .secondary:
            return 0.97
        case .text:
            return 1.0
        case .compact:
            return 0.95
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                .fill(isEnabled ? DesignSystem.Colors.primaryBlue : DesignSystem.Colors.primaryBlue.opacity(0.5))
        case .secondary:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                .fill(DesignSystem.Colors.primaryBlue.opacity(isEnabled ? 0.1 : 0.05))
        case .text:
            Color.clear
        case .compact:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(DesignSystem.Colors.primaryBlue.opacity(0.1))
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        switch style {
        case .secondary:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                .stroke(DesignSystem.Colors.primaryBlue.opacity(isEnabled ? 0.3 : 0.1), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

// MARK: - Icon Button Component
struct CustomIconButton: View {
    let icon: String
    var size: CGFloat = 44
    var backgroundColor: Color = DesignSystem.Colors.primaryBlue
    var foregroundColor: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.9))
    }
}

// MARK: - Preview
struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomButton(title: "Primary Button", icon: "plus.circle.fill", action: {})
            
            CustomButton(title: "Secondary Button", action: {}, style: .secondary)
            
            CustomButton(title: "Text Button", action: {}, style: .text)
            
            CustomButton(title: "Compact", action: {}, style: .compact)
            
            CustomButton(title: "Loading...", action: {}, isLoading: true)
            
            CustomButton(title: "Disabled", action: {}, isEnabled: false)
            
            HStack {
                CustomIconButton(icon: "plus", action: {})
                CustomIconButton(icon: "heart.fill", backgroundColor: .red, action: {})
                CustomIconButton(icon: "star.fill", backgroundColor: .orange, action: {})
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 