// Modules/PlantManagement/Views/AddPlant/DetailsStepView.swift
import SwiftUI

struct DetailsStepView: View {
    @ObservedObject var state: NewPlantState

    var body: some View {
        Form {
            // MARK: Basics
            Section {
                TextField("Where is this plant? (e.g., Living Room, Office, Balcony)", text: $state.location)
                    .textInputAutocapitalization(.words)
                    .textContentType(.location)
                    .accessibilityLabel("Plant location")

                PotSizeRow(value: $state.potSizeCM)
                    .accessibilityLabel("Pot size in centimeters")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Light")
                        .font(.subheadline).bold()
                    Picker("Light", selection: $state.lightLevel) {
                        ForEach(LightLevel.allCases) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(lightHelp(state.lightLevel))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Light guidance: \(lightHelp(state.lightLevel))")
                }
                .listRowSeparator(.visible)
            } header: {
                Text("Basics")
            } footer: {
                Text("These details help us calculate care reminders and show relevant tips.")
            }

            // MARK: Care Schedule
            Section {
                LabeledStepperRow(
                    title: "Watering",
                    value: $state.wateringFreqDays,
                    range: 1...30,
                    suffix: "day(s)",
                    help: "Most indoor plants are happy with 7–10 days."
                )

                LabeledStepperRow(
                    title: "Fertilize",
                    value: $state.fertilizeFreqDays,
                    range: 7...120,
                    suffix: "day(s)",
                    help: "Monthly (30 days) is typical in spring/summer."
                )
            } header: {
                Text("Care Schedule")
            } footer: {
                Text("You can change these later from the plant page.")
            }
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { state.step -= 1 }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Next") { state.step += 1 }
            }
        }
    }

    private func lightHelp(_ level: LightLevel) -> String {
        switch level {
        case .low: return "Far from windows or shaded shelves."
        case .medium: return "A few feet from a bright window."
        case .bright: return "Next to a sunny window."
        case .indirect: return "Bright light but not direct sun."
        }
    }
}

// MARK: - Subviews

/// Re-usable labeled stepper with big +/- buttons and helper text.
private struct LabeledStepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String
    var help: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(title) every \(value) \(suffix)")
                    .font(.body).bold()
                    .accessibilityLabel("\(title) every \(value) \(suffix)")

                Spacer()

                HStack(spacing: 0) {
                    Button(action: { value = max(range.lowerBound, value - 1) }) {
                        Image(systemName: "minus")
                            .frame(width: 36, height: 28)
                    }
                    .buttonStyle(.bordered)

                    Divider().frame(height: 28)

                    Button(action: { value = min(range.upperBound, value + 1) }) {
                        Image(systemName: "plus")
                            .frame(width: 36, height: 28)
                    }
                    .buttonStyle(.bordered)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if let help {
                Text(help)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Pot size row that keeps your look but clarifies units.
private struct PotSizeRow: View {
    @Binding var value: Double
    let range: ClosedRange<Double> = 5...60

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pot size (cm)").font(.subheadline).bold()
                Text("\(Int(value)) cm")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            Spacer()
            HStack(spacing: 0) {
                Button(action: { value = max(range.lowerBound, value - 1) }) {
                    Image(systemName: "minus")
                        .frame(width: 36, height: 28)
                }
                .buttonStyle(.bordered)

                Divider().frame(height: 28)

                Button(action: { value = min(range.upperBound, value + 1) }) {
                    Image(systemName: "plus")
                        .frame(width: 36, height: 28)
                }
                .buttonStyle(.bordered)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel("Adjust pot size")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    // Lightweight preview with mock state
    let s = NewPlantState()
    s.location = "Living Room"
    s.potSizeCM = 18
    s.lightLevel = .indirect
    s.wateringFreqDays = 10
    s.fertilizeFreqDays = 30
    return NavigationStack { DetailsStepView(state: s) }
}
