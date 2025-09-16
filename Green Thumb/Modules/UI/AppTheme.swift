import SwiftUI

// MARK: - Modern Theme System
struct AppTheme {
    
    // MARK: - Color Palette
    struct Colors {
        // Primary Brand Colors
        static let primaryGreen = Color(red: 0.2, green: 0.6, blue: 0.4)
        static let secondaryGreen = Color(red: 0.3, green: 0.7, blue: 0.5)
        static let accentGreen = Color(red: 0.1, green: 0.8, blue: 0.6)
        
        // Gradient Colors
        static let primaryGradient = LinearGradient(
            colors: [primaryGreen, secondaryGreen],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient = LinearGradient(
            colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let darkCardGradient = LinearGradient(
            colors: [Color(.systemGray6), Color(.systemGray5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Semantic Colors
        static let surface = Color(.systemBackground)
        static let cardBackground = Color(.secondarySystemBackground)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        
        // Status Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Interactive Colors
        static let buttonPrimary = primaryGreen
        static let buttonSecondary = Color(.systemGray4)
        static let buttonBackground = Color(.systemGray6)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.medium)
        static let title3 = Font.title3.weight(.medium)
        static let headline = Font.headline.weight(.semibold)
        static let subheadline = Font.subheadline.weight(.medium)
        static let body = Font.body
        static let callout = Font.callout
        static let footnote = Font.footnote
        static let caption1 = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
        static let button: CGFloat = 12
        static let card: CGFloat = 16
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Color.black.opacity(0.2), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
}

// MARK: - Modern Card Style
struct ModernCardStyle: ViewModifier {
    @EnvironmentObject private var colorCtl: ColorSchemeController
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(colorCtl.highContrastEnabled ? AppTheme.Colors.surface : AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                            .stroke(
                                colorCtl.highContrastEnabled ? Color(.separator) : Color.clear,
                                lineWidth: colorCtl.highContrastEnabled ? 1 : 0
                            )
                    )
                    .shadow(
                        color: colorCtl.highContrastEnabled ? Color.clear : AppTheme.Shadow.medium.color,
                        radius: colorCtl.highContrastEnabled ? 0 : AppTheme.Shadow.medium.radius,
                        x: AppTheme.Shadow.medium.x,
                        y: AppTheme.Shadow.medium.y
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }
}

// MARK: - Modern Button Style
struct ModernButtonStyle: ButtonStyle {
    var style: ButtonStyleType = .primary
    @EnvironmentObject private var colorCtl: ColorSchemeController
    
    enum ButtonStyleType {
        case primary, secondary, tertiary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                            .stroke(strokeColor, lineWidth: strokeWidth)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return AppTheme.Colors.buttonPrimary
        case .secondary:
            return AppTheme.Colors.buttonBackground
        case .tertiary:
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return AppTheme.Colors.textPrimary
        case .tertiary:
            return AppTheme.Colors.primaryGreen
        }
    }
    
    private var strokeColor: Color {
        switch style {
        case .primary:
            return colorCtl.highContrastEnabled ? AppTheme.Colors.primaryGreen.opacity(0.3) : Color.clear
        case .secondary:
            return colorCtl.highContrastEnabled ? Color(.separator) : Color.clear
        case .tertiary:
            return colorCtl.highContrastEnabled ? Color(.separator) : AppTheme.Colors.primaryGreen.opacity(0.3)
        }
    }
    
    private var strokeWidth: CGFloat {
        return colorCtl.highContrastEnabled ? 1 : (style == .tertiary ? 1 : 0)
    }
}

// MARK: - View Extensions
extension View {
    func modernCard() -> some View {
        self.modifier(ModernCardStyle())
    }
    
    func primaryButton() -> some View {
        self.buttonStyle(ModernButtonStyle(style: .primary))
    }
    
    func secondaryButton() -> some View {
        self.buttonStyle(ModernButtonStyle(style: .secondary))
    }
    
    func tertiaryButton() -> some View {
        self.buttonStyle(ModernButtonStyle(style: .tertiary))
    }
}
