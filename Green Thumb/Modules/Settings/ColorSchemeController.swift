import SwiftUI

@MainActor
final class ColorSchemeController: ObservableObject {
    @Published var override: ColorScheme? = nil
    @Published var highContrastEnabled: Bool = false

    func apply(darkModeEnabled: Bool) {
        override = darkModeEnabled ? .dark : nil
    }

    func applyHighContrast(_ enabled: Bool) {
        highContrastEnabled = enabled
    }
}

// MARK: - App-specific High Contrast Environment
private struct GTHighContrastKey: EnvironmentKey { static let defaultValue: Bool = false }

extension EnvironmentValues {
    var gtHighContrastEnabled: Bool {
        get { self[GTHighContrastKey.self] }
        set { self[GTHighContrastKey.self] = newValue }
    }
}

public extension View {
    func gtHighContrast(_ enabled: Bool) -> some View {
        environment(\.gtHighContrastEnabled, enabled)
    }
}
