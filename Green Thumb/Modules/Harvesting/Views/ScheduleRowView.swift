import SwiftUI

struct ScheduleRowView: View {
    @ObservedObject var schedule: HarvestSchedule

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .imageScale(.large)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.plant?.name ?? "Plant")
                    .font(.headline)

                let start = schedule.expectedStart?.formatted(date: .abbreviated, time: .omitted) ?? "—"
                let end = schedule.expectedEnd?.formatted(date: .abbreviated, time: .omitted)
                Text(end != nil ? "Window: \(start) → \(end!)" : "Target: \(start)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Uses shared StatusChip from HarvestingUIShared.swift
            StatusChip(status: HarvestRepository.computeStatus(for: schedule))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
