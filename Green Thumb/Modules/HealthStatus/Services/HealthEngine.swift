import Foundation

public struct HealthEngine {
    public init() {}

    public func computeScore(for plant: HealthPlant,
                             weather: HealthWeather?,
                             manual: HealthManualCheck?,
                             disease: HealthDiseaseSnapshot?,
                             taskOverrides: (lastWatered: Date?, lastFertilized: Date?) = (nil, nil))
    -> (score: Double, status: PlantHealthStatus, factors: [HealthFactor]) {

        var score: Double = 100
        var factors: [HealthFactor] = []

        // Watering adherence
        let daysSinceWater = daysSince(date: taskOverrides.lastWatered ?? plant.lastWatered)
        if let rec = positive(plant.recommendedWaterEveryDays), let d = daysSinceWater {
            if d > Double(rec) * 1.5 {
                let impact = min(35, (d - Double(rec) * 1.5) * 4)
                score -= impact
                factors.append(HealthFactor("Under‑watering", impact: impact, detail: "\(Int(d)) days since watered (rec every \(rec)d)"))
            } else if d > Double(rec) * 1.2 {
                let impact = (d - Double(rec) * 1.2) * 3
                score -= impact
                factors.append(HealthFactor("Drying out", impact: impact, detail: "\(Int(d)) days since watered"))
            }
        }

        // Fertilizer
        if let d = daysSince(date: taskOverrides.lastFertilized ?? plant.lastFertilized), d > 45 {
            let impact = min(10, (d - 45) * 0.3)
            score -= impact
            factors.append(HealthFactor("Needs fertilizer", impact: impact, detail: "\(Int(d)) days since fertilized"))
        }

        // Weather
        if let w = weather {
            if !plant.comfortTempC.contains(w.tempC) {
                let dist = distanceToRange(value: w.tempC, range: plant.comfortTempC)
                let impact = min(25, dist * 2.5)
                score -= impact
                factors.append(HealthFactor("Temperature stress", impact: impact, detail: "Now \(Int(w.tempC))°C; comfort \(Int(plant.comfortTempC.lowerBound))–\(Int(plant.comfortTempC.upperBound))°C"))
            }
            if !plant.comfortHumidity.contains(w.humidity) {
                let dist = distanceToRange(value: w.humidity, range: plant.comfortHumidity)
                let impact = min(15, dist * 0.6)
                score -= impact
                factors.append(HealthFactor("Humidity stress", impact: impact, detail: "Now \(Int(w.humidity))%"))
            }
        }

        // Disease
        if let d = disease, let label = d.label, label.lowercased() != "healthy" {
            let conf = d.confidence ?? 0.5
            let impact = min(35, (0.5 + conf) * 25)
            score -= impact
            factors.append(HealthFactor("Possible disease: \(label)", impact: impact, detail: "Model confidence \(Int((conf)*100))%"))
        }

        // Manual
        if let m = manual, !m.symptoms.isEmpty {
            let impact = Double(m.symptoms.count) * 5.0
            score -= impact
            factors.append(HealthFactor("Observed symptoms", impact: impact, detail: m.symptoms.map{$0.rawValue}.joined(separator: ", ")))
        }

        score = max(0, min(100, score))
        let status: PlantHealthStatus = (score >= 80) ? .good : (score >= 65) ? .watch : (score >= 45) ? .atRisk : .critical
        factors.sort { $0.impact > $1.impact }
        return (score, status, factors)
    }

    private func daysSince(date: Date?) -> Double? { guard let date else { return nil }; return Date().timeIntervalSince(date)/86400.0 }
    private func positive(_ i: Int) -> Int? { i > 0 ? i : nil }
    private func distanceToRange(value: Double, range: ClosedRange<Double>) -> Double {
        value < range.lowerBound ? (range.lowerBound - value) : value > range.upperBound ? (value - range.upperBound) : 0
    }
}
