import SwiftUI

@MainActor
final class ColorSchemeController: ObservableObject {
    @Published var override: ColorScheme? = nil

    func apply(darkModeEnabled: Bool) {
        override = darkModeEnabled ? .dark : nil
    }
}
