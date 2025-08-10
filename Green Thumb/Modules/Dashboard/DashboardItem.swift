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
    static var all: [DashboardItem] = [
        DashboardItem(
            title: "Disease Identifier",
            systemImage: "leaf.fill",
            color: .green,
            destination: AnyView(DiseaseIdentifierView())   // <- now exists
        ),
        DashboardItem(
            title: "My Garden",
            systemImage: "sprinkler.and.droplets",
            color: .teal,
            destination: AnyView(Text("My Garden (coming soon)"))
        ),
        DashboardItem(
            title: "Tasks",
            systemImage: "checklist",
            color: .blue,
            destination: AnyView(Text("Tasks (coming soon)"))
        ),
        DashboardItem(
            title: "Weather",
            systemImage: "cloud.sun.fill",
            color: .orange,
            destination: AnyView(Text("Weather (coming soon)"))
        ),
        DashboardItem(
            title: "Store Locator",
            systemImage: "mappin.and.ellipse",
            color: .purple,
            destination: AnyView(Text("Store (coming soon)"))
        ),
        DashboardItem(
            title: "Store Locator",
            systemImage: "mappin.and.ellipse",
            color: .purple,
            destination: AnyView(StoreLocatorView())
        )

        // In your Dashboard items list


    ]
}
