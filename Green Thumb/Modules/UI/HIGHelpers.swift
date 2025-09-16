import SwiftUI

/// Small helpers to encourage iOS HIG-friendly UI without invasive changes.
public extension View {
    /// Use for section headers in custom views to match system hierarchy semantics.
    func sectionHeaderStyle() -> some View {
        self
            .font(.subheadline.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }

    /// Ensures scrollable content isn't obscured by a custom TabBar.
    /// Prefer using this on `List` or `ScrollView` containers.
    func bottomContentMarginForTabBar(_ value: CGFloat = 100) -> some View {
        self.contentMargins(.bottom, value, for: .scrollContent)
    }
}
