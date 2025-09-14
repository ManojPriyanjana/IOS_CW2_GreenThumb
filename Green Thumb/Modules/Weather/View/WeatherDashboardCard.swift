import SwiftUI
import CoreLocation

/// A compact Weather summary card for the Dashboard.
/// Fetches current weather for the user's location and shows temp + condition.
struct WeatherDashboardCard: View {
    @StateObject private var vm: WeatherViewModel
    private let onTap: () -> Void
    private let isButton: Bool

    init(onTap: @escaping () -> Void, isButton: Bool = true) {
        let service  = OpenWeatherClient(apiKey: WeatherConfig.apiKey)
        let forecast = OpenWeatherForecastClient(apiKey: WeatherConfig.apiKey)
        let location = LocationProvider()
        _vm = StateObject(wrappedValue: WeatherViewModel(
            service: service,
            forecastService: forecast,
            location: location
        ))
        self.onTap = onTap
        self.isButton = isButton
    }

    var body: some View {
        Group {
            if isButton {
                Button(action: onTap) { card }
                    .buttonStyle(.plain)
            } else {
                card
            }
        }
        .onAppear { if vm.weather == nil && !vm.isLoading { vm.refresh() } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var card: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [Color.orange.opacity(0.25), Color.orange.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Image(systemName: "cloud.sun.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                    .font(.system(size: 28, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Weather")
                    .font(.headline)

                if vm.isLoading {
                    Text("Fetching…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if let error = vm.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else if let w = vm.weather {
                    HStack(spacing: 8) {
                        Text("\(Int(w.temperatureC.rounded()))°C")
                            .font(.subheadline)
                            .bold()
                        Text(w.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text("Tap to view")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let ts = vm.lastUpdated {
                    Text(ts, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
    }

    private var accessibilitySummary: String {
        if let w = vm.weather {
            return "Weather, \(Int(w.temperatureC.rounded())) degrees Celsius, \(w.description)."
        }
        if let err = vm.errorMessage { return "Weather error: \(err)" }
        if vm.isLoading { return "Weather loading" }
        return "Weather"
    }
}

#Preview {
    WeatherDashboardCard(onTap: {})
        .padding()
}
