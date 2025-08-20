import Foundation

enum HarvestStatus { case growing, readySoon, bestNow, overdue, completed }

extension Plant {
    private var minDays: Int { Int(self.maturityMinDays) }
    private var maxDays: Int { Int(self.maturityMaxDays) }
    var plantedOn: Date { self.dateAdded ?? Date() }

    var harvestEnabled: Bool {
        maturityMinDays > 0 && maturityMaxDays > 0
    }

    var harvestWindowStart: Date? {
        guard harvestEnabled else { return nil }
        return Calendar.current.date(byAdding: .day, value: minDays, to: plantedOn)
    }

    var harvestWindowEnd: Date? {
        guard harvestEnabled else { return nil }
        return Calendar.current.date(byAdding: .day, value: maxDays, to: plantedOn)
    }

    var harvestStatus: HarvestStatus {
        if let last = lastHarvested, let end = harvestWindowEnd, last >= end { return .completed }
        guard let start = harvestWindowStart, let end = harvestWindowEnd else { return .growing }
        let now = Date()
        if now < start {
            let daysToStart = Calendar.current.dateComponents([.day], from: now.startOfDay, to: start.startOfDay).day ?? 0
            return daysToStart <= 7 ? .readySoon : .growing
        } else if now <= end {
            return .bestNow
        } else {
            return .overdue
        }
    }

    /// 0...1 progress *to the window start* (for the green bar)
    var harvestProgressToStart: Double {
        guard harvestEnabled else { return 0 }
        let total = max(1, minDays)
        let elapsed = max(0, Calendar.current.dateComponents([.day], from: plantedOn.startOfDay, to: Date().startOfDay).day ?? 0)
        return min(1, Double(elapsed) / Double(total))
    }

    var harvestStatusText: String {
        switch harvestStatus {
        case .growing, .readySoon:
            let days = max(0, Calendar.current.dateComponents([.day], from: Date().startOfDay, to: (harvestWindowStart ?? Date()).startOfDay).day ?? 0)
            return "Ready in \(days) day\(days == 1 ? "" : "s")"
        case .bestNow:   return "Best harvested now"
        case .overdue:   return "Overdue"
        case .completed: return "Harvested"
        }
    }

    var harvestDateRangeShort: String {
        guard let s = harvestWindowStart, let e = harvestWindowEnd else { return "" }
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "\(f.string(from: s))–\(f.string(from: e))"
    }
}

fileprivate extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}
