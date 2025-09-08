import SwiftUI

/// Reusable status badge for harvest schedules.
/// Internal (default) so it can reference the internal `HarvestStatus` type.
struct StatusChip: View {
    let status: HarvestStatus

    init(status: HarvestStatus) { self.status = status }

    private var color: Color {
        switch status {
        case .planned:   return .gray
        case .due:       return .green
        case .overdue:   return .orange
        case .completed: return .blue
        }
    }

    var body: some View {
        Text(status.rawValue)
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(Text("Status: \(status.rawValue)"))
    }
}

/// Formatting helper used across Harvesting views (internal by default).
extension Double {
    var clean: String {
        truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", self)
        : String(self)
    }
}
