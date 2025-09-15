import Foundation

/// Represents a plant 3D asset you can place in AR.
/// For now we support local .usdz files bundled with the app; you can extend to remote later.
struct PlantModel: Identifiable, Hashable {
    let id: String
    let displayName: String
    /// Resource filename inside the app bundle, e.g. "Monstera.usdz"
    let usdzName: String
    /// A suggested scale to make the model look realistic in meters.
    let scale: Float
}

enum ARModelLibrary {
    /// Update these names to match your .usdz assets when you add them to the project.
    static let all: [PlantModel] = [
    PlantModel(id: "banana", displayName: "Banana Tree", usdzName: "Banana_tree.usdz", scale: 0.7),
    PlantModel(id: "mango", displayName: "Mango Tree", usdzName: "Mango_Tree.usdz", scale: 0.7),
    PlantModel(id: "rose", displayName: "Red Rose", usdzName: "Red_rose.usdz", scale: 0.5),
    PlantModel(id: "monstera", displayName: "Monstera Deliciosa", usdzName: "Monstera_Deliciosa_Potted_Mid-Century_plant.usdz", scale: 0.6)
    ]
}
