import SwiftUI

struct PlantAvatar: View {
    let plant: Plant
    var body: some View {
        if let data = plant.photo, let ui = UIImage(data: data) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color(.systemGreen).opacity(0.2))
                Image(systemName: "leaf.fill").imageScale(.large).foregroundColor(.green)
            }
        }
    }
}
