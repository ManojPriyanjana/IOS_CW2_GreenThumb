import SwiftUI

struct TaskRowView: View {
    let item: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1)
                Image(systemName: item.type.systemImage).imageScale(.medium)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.type.label).font(.headline)
                    Spacer()
                    if let due = item.dueDate {
                        Text(due, style: .date).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes).font(.subheadline).foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    if item.isCompleted {
                        Label("Completed", systemImage: "checkmark.circle.fill").font(.caption)
                    } else if let due = item.dueDate, due < Date() {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill").font(.caption)
                    }
                    if item.isWeatherAware {
                        Label("Weather-aware", systemImage: "cloud.sun.rain.fill").font(.caption)
                    }
                }.foregroundStyle(.secondary)
            }

            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                    .imageScale(.large)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(radius: 1, y: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(item.type.label), \(item.title)"))
    }
}
