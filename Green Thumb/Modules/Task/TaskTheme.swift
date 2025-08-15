import SwiftUI

enum TaskTheme {
    static let brand = Color("BrandGreen", bundle: .main) // if you have an asset
    static let brandFallback = Color.green
    static let bg = Color(.systemBackground)
    static let muted = Color(.secondaryLabel)
    static let divider = Color(.separator)
}
