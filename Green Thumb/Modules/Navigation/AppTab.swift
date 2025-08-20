import SwiftUI

/// All tabs used in the app + their labels/icons
enum AppTab: CaseIterable, Hashable {
    case dashboard, plants, stores, profile, settings

    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .plants:    return "Plants"
        case .stores:    return "Stores"
        case .profile:   return "Tasks"
        case .settings:  return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "house.fill"
        case .plants:    return "leaf.fill"
        case .stores:    return "mappin.and.ellipse"
        case .profile:   return "checkmark.circle.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}
