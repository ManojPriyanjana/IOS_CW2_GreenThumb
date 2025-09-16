import SwiftUI

/// Lightweight design primitives aligned with iOS Human Interface Guidelines.
/// - Non-invasive: opt-in, avoids app-wide appearance changes.
public enum DS {
    // Spacing scale (multiples of 4)
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let s: CGFloat = 12
        public static let m: CGFloat = 16
        public static let l: CGFloat = 20
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    // Corners and radii
    public enum Radius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
    }

    // Sizes
    public enum Size {
        /// Minimum tappable target size per HIG
        public static let minTap: CGFloat = 44
        public static let minHit: CGFloat = 44
        public static let chipHeight: CGFloat = 32
        public static let toolbarHeight: CGFloat = 44
    }
}

// MARK: - Card Modifier
public struct CardBackground: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(DS.Spacing.m)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
    }
}

public extension View {
    /// Apply a Material card background with standard padding and corner radius.
    func cardBackground() -> some View { modifier(CardBackground()) }
}

// MARK: - Primary Button Style
public struct PrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: DS.Size.minTap)
            .contentShape(Rectangle())
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                    .fill(Color.accentColor)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Section Header Helper
public struct SectionHeader: View {
    let title: String
    let systemImage: String?
    public init(_ title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }
    public var body: some View {
        HStack(spacing: DS.Spacing.s) {
            if let systemImage { Image(systemName: systemImage).foregroundStyle(.secondary) }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Spacing.m)
        .padding(.top, DS.Spacing.s)
    }
}

// MARK: - Chips
public struct Chip: View {
    let title: String
    let isSelected: Bool
    public init(_ title: String, isSelected: Bool) {
        self.title = title
        self.isSelected = isSelected
    }
    public var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.horizontal, DS.Spacing.m)
            .frame(height: DS.Size.chipHeight)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color(.separator).opacity(0.4), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .accessibilityLabel(Text(title))
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
