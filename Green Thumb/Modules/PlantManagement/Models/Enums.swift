import SwiftUI

enum LightLevel: String, CaseIterable, Identifiable { case low, medium, bright, indirect; var id: String { rawValue } }
enum HealthStatus: String, CaseIterable, Identifiable { case healthy, attention, sick; var id: String { rawValue } }
enum CareType: String, CaseIterable, Identifiable { case water, fertilize, prune, repot; var id: String { rawValue } }

enum AppTheme {
    static let brand = Color(red: 0.07, green: 0.55, blue: 0.28)    // natural green
    static let bg = Color(UIColor.systemBackground)
    static let text = Color(UIColor.label)
    static let muted = Color(UIColor.secondaryLabel)
}
