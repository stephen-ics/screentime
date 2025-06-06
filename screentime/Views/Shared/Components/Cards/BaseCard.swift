import SwiftUI

/// A reusable base card component that provides consistent styling and behavior
struct BaseCard<Content: View>: View {
    
    // MARK: - Properties
    let content: Content
    let style: CardStyle
    let action: (() -> Void)?
    
    // MARK: - Initialization
    
    init(
        style: CardStyle = .default,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(ScaleButtonStyle(scale: style.scaleEffect))
            } else {
                cardContent
            }
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var cardContent: some View {
        content
            .padding(style.padding)
            .frame(maxWidth: style.maxWidth, maxHeight: style.maxHeight)
            .background(style.backgroundColor)
            .cornerRadius(style.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .shadow(
                color: style.shadowColor,
                radius: style.shadowRadius,
                x: style.shadowOffset.width,
                y: style.shadowOffset.height
            )
    }
}

// MARK: - Card Style

/// Configuration for card appearance and behavior
struct CardStyle {
    let padding: EdgeInsets
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOffset: CGSize
    let borderColor: Color
    let borderWidth: CGFloat
    let maxWidth: CGFloat?
    let maxHeight: CGFloat?
    let scaleEffect: CGFloat
    
    init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        backgroundColor: Color = DesignSystem.Colors.secondaryBackground,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.medium,
        shadowColor: Color = DesignSystem.Shadow.small.color,
        shadowRadius: CGFloat = DesignSystem.Shadow.small.radius,
        shadowOffset: CGSize = CGSize(
            width: DesignSystem.Shadow.small.x,
            height: DesignSystem.Shadow.small.y
        ),
        borderColor: Color = Color.clear,
        borderWidth: CGFloat = 0,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        scaleEffect: CGFloat = 0.98
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.scaleEffect = scaleEffect
    }
}

// MARK: - Predefined Styles

extension CardStyle {
    /// Default card style
    static let `default` = CardStyle()
    
    /// Compact card style for smaller content
    static let compact = CardStyle(
        padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
        cornerRadius: DesignSystem.CornerRadius.small
    )
    
    /// Large card style for prominent content
    static let large = CardStyle(
        padding: EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20),
        cornerRadius: DesignSystem.CornerRadius.large,
        shadowRadius: DesignSystem.Shadow.medium.radius
    )
    
    /// Featured card style with border
    static let featured = CardStyle(
        borderColor: DesignSystem.Colors.primaryBlue.opacity(0.3),
        borderWidth: 1
    )
    
    /// Error card style
    static let error = CardStyle(
        backgroundColor: DesignSystem.Colors.error.opacity(0.1),
        borderColor: DesignSystem.Colors.error.opacity(0.3),
        borderWidth: 1
    )
    
    /// Success card style
    static let success = CardStyle(
        backgroundColor: DesignSystem.Colors.success.opacity(0.1),
        borderColor: DesignSystem.Colors.success.opacity(0.3),
        borderWidth: 1
    )
    
    /// Warning card style
    static let warning = CardStyle(
        backgroundColor: DesignSystem.Colors.warning.opacity(0.1),
        borderColor: DesignSystem.Colors.warning.opacity(0.3),
        borderWidth: 1
    )
}

// MARK: - Preview

struct BaseCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BaseCard {
                VStack {
                    Text("Default Card")
                        .font(.headline)
                    Text("This is a default card with standard styling")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            BaseCard(style: .compact, action: {}) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Compact Card")
                        .font(.subheadline)
                }
            }
            
            BaseCard(style: .featured) {
                VStack {
                    Text("Featured Card")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("With border styling")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            BaseCard(style: .success) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.success)
                    Text("Success Card")
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.groupedBackground)
        .previewLayout(.sizeThatFits)
    }
} 