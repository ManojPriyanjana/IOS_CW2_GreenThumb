import SwiftUI

public enum GTTheme {
    public static let green = Color(red: 0.52, green: 0.70, blue: 0.57)     // background tint
    public static let deepGreen = Color(red: 0.12, green: 0.35, blue: 0.28) // headings
    public static let card = Color(.secondarySystemBackground)
    public static let accentYellow = Color(red: 1.00, green: 0.86, blue: 0.30)
    public static let accent = Color(red: 0.20, green: 0.55, blue: 0.45)     // primary buttons
    public static let softShadow: CGFloat = 8

    public static func heroGradient(in scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: scheme == .dark
                ? [deepGreen.opacity(0.7), green.opacity(0.5)]
                : [green.opacity(0.5), .white.opacity(0.4)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

public struct GTPrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(GTTheme.accentYellow, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .shadow(color: .black.opacity(0.08), radius: GTTheme.softShadow, y: 6)
    }
}
