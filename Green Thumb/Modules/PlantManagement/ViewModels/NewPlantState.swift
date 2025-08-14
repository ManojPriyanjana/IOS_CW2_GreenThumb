import SwiftUI
import PhotosUI

final class NewPlantState: ObservableObject {
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var imageData: Data? = nil

    @Published var commonName: String = ""
    @Published var scientificName: String = ""
    @Published var location: String = ""
    @Published var potSizeCM: Double = 15
    @Published var lightLevel: LightLevel = .indirect
    @Published var wateringFreqDays: Int = 7
    @Published var fertilizeFreqDays: Int = 30

    @Published var step: Int = 0  // 0..3
    var canContinue: Bool {
        switch step {
        case 0: return imageData != nil
        case 1: return !commonName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return wateringFreqDays > 0
        default: return true
        }
    }

    func reset() {
        selectedItem = nil; imageData = nil; commonName = ""; scientificName = ""; location = ""
        potSizeCM = 15; lightLevel = .indirect; wateringFreqDays = 7; fertilizeFreqDays = 30; step = 0
    }
}
