import Foundation
import SwiftUI

public struct HealthPlant: Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var species: String
    public var isOutdoor: Bool
    public var recommendedWaterEveryDays: Int
    public var lastWatered: Date?
    public var lastFertilized: Date?
    public var latitude: Double?
    public var longitude: Double?
    public var comfortTempC: ClosedRange<Double> = 18...30
    public var comfortHumidity: ClosedRange<Double> = 40...70

    public init(id: UUID,
                name: String,
                species: String,
                isOutdoor: Bool,
                recommendedWaterEveryDays: Int,
                lastWatered: Date?,
                lastFertilized: Date?,
                latitude: Double? = nil,
                longitude: Double? = nil,
                comfortTempC: ClosedRange<Double> = 18...30,
                comfortHumidity: ClosedRange<Double> = 40...70) {
        self.id = id
        self.name = name
        self.species = species
        self.isOutdoor = isOutdoor
        self.recommendedWaterEveryDays = recommendedWaterEveryDays
        self.lastWatered = lastWatered
        self.lastFertilized = lastFertilized
        self.latitude = latitude
        self.longitude = longitude
        self.comfortTempC = comfortTempC
        self.comfortHumidity = comfortHumidity
    }
}

public struct HealthWeather { public var tempC: Double; public var humidity: Double; public var condition: String }

public enum HealthManualSymptom: String, CaseIterable, Identifiable {
    case wilting, yellowing, brownSpots, leafDrop, pestsSeen, stunted
    public var id: String { rawValue }
}

public struct HealthManualCheck {
    public var date: Date
    public var symptoms: Set<HealthManualSymptom>
    public var note: String?
    public init(date: Date = Date.now, symptoms: Set<HealthManualSymptom> = [], note: String? = nil) {
        self.date = date; self.symptoms = symptoms; self.note = note
    }
}

public struct HealthDiseaseSnapshot { public var label: String?; public var confidence: Double? }

public enum PlantHealthStatus: String { case good = "Good", watch = "Watch", atRisk = "At Risk", critical = "Critical" }

public struct HealthFactor: Identifiable {
    public let id = UUID()
    public var title: String
    public var impact: Double
    public var detail: String
    public init(_ title: String, impact: Double, detail: String) { self.title = title; self.impact = impact; self.detail = detail }
}

public struct PlantHealthRecord: Identifiable {
    public let id = UUID()
    public var plantId: UUID
    public var date: Date
    public var score: Double
    public var status: PlantHealthStatus
    public var factors: [HealthFactor]
    public var note: String?
}
