//  DesignTokens.swift
//  Green Thumb
//
//  Lightweight, standalone design tokens and helpers inspired by the provided UI references.
//  Pure SwiftUI, no dependencies on app models to keep compilation safe.

import SwiftUI

// MARK: - Color Helpers
public extension Color {
    /// Create a Color from a 0xRRGGBB hex integer
    init(hex: Int, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Tokens
public enum GTTokens {
    // Palette tuned for a calm, modern green app
    public enum Colors {
        // Brand
        public static let brand = Color(hex: 0x2E7D32)      // deep green
        public static let brandAccent = Color(hex: 0x43A047) // vibrant green
        public static let brandSoft = Color(hex: 0xE8F5E9)   // mint background

        // Neutrals
        public static let background = Color(hex: 0xF7FAF7)
        public static let surface = Color.white
        public static let surfaceSecondary = Color(hex: 0xF1F5F1)
        public static let stroke = Color(hex: 0xE3EAE3)

        // Text
        public static let textPrimary = Color(hex: 0x1B1F1B)
        public static let textSecondary = Color(hex: 0x4A554A)
        public static let textTertiary = Color(hex: 0x7C8A7C)

        // States
        public static let success = Color(hex: 0x2E7D32)
        public static let warning = Color(hex: 0xFFB300)
        public static let danger = Color(hex: 0xD32F2F)
    }

    public enum Spacing { // points
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let s: CGFloat = 12
        public static let m: CGFloat = 16
        public static let l: CGFloat = 20
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    public enum Radius { // corner radii
        public static let small: CGFloat = 10
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 22
        public static let pill: CGFloat = 999
    }

    public enum Shadows {
        public static let card = ShadowStyle(color: .black.opacity(0.05), radius: 10, y: 4)
        public static let elevated = ShadowStyle(color: .black.opacity(0.12), radius: 16, y: 10)
    }

    public enum Typography {
        public static let title = Font.system(.title2, design: .rounded).weight(.bold)
        public static let subtitle = Font.system(.headline, design: .rounded).weight(.semibold)
        public static let body = Font.system(.body, design: .rounded)
        public static let caption = Font.system(.caption, design: .rounded)
        public static let number = Font.system(.title3, design: .rounded).weight(.bold)
    }

    public struct ShadowStyle {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat
        public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
            self.color = color; self.radius = radius; self.x = x; self.y = y
        }
    }
}

// MARK: - Convenience Modifiers
public extension View {
    func gtCardShadow(_ style: GTTokens.ShadowStyle = GTTokens.Shadows.card) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
