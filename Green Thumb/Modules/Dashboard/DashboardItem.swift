import SwiftUI

struct DashboardItem: Identifiable, Hashable, Equatable {
    let id = UUID()
    let title: String
    let systemImage: String
    let color: Color
    let destination: AnyView

    static func == (lhs: DashboardItem, rhs: DashboardItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension DashboardItem {
    // MARK: - Tiles shown on the dashboard
    static var all: [DashboardItem] = [

        // Plant Management entry
        DashboardItem(
            title: "My Garden",
            systemImage: "sprinkler.and.droplets",
            color: .teal,
            destination: AnyView(MyGardenView())   // Connects to your PlantManagement module
        ),

        // Quick access to the Add Plant wizard (optional but handy)
        DashboardItem(
            title: "Add Plant",
            systemImage: "plus.circle.fill",
            color: .green,
            destination: AnyView(AddPlantFlowView())
        ),

        // Disease detection
        DashboardItem(
            title: "Disease Identifier",
            systemImage: "leaf.fill",
            color: .green,
            destination: AnyView(DiseaseIdentifierView())
        ),

        // Tasks (hook up to real view later)
        DashboardItem(
            title: "Tasks",
            systemImage: "checklist",
            color: .blue,
            destination: AnyView(Text("Tasks (coming soon)"))
        ),

        // Weather
        DashboardItem(
            title: "Weather",
            systemImage: "cloud.sun.fill",
            color: .orange,
            destination: AnyView(WeatherView(apiKey: "15845b53595b293a72d288d11d16cb39"))
        ),

        // Store Locator
        DashboardItem(
            title: "Store Locator",
            systemImage: "mappin.and.ellipse",
            color: .purple,
            destination: AnyView(StoreLocatorView())
        ),
        DashboardItem(
            title: "Harvest",
            systemImage: "scissors",
            color: Color.green,                    // or your theme color
            destination: AnyView(HarvestListView())
        )
        
    ]

    // Previews
    static let previewItem = DashboardItem(
        title: "My Garden",
        systemImage: "sprinkler.and.droplets",
        color: .teal,
        destination: AnyView(EmptyView())
    )
}
