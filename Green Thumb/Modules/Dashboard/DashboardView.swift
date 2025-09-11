import SwiftUI

struct DashboardView: View {
    private let items = DashboardItem.all
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]
    private let weatherAPIKey = "15845b53595b293a72d288d11d16cb39" // TODO: move to secure config

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Full-width Weather summary card
                    NavigationLink(destination: WeatherView(apiKey: weatherAPIKey)) {
                        WeatherSummaryCard(apiKey: weatherAPIKey)
                    }
                    .buttonStyle(.plain)

                    // Grid tiles
                    LazyVGrid(columns: columns, spacing: 16) {
                        // Existing tiles (excluding the old Weather tile to avoid duplication)
                        ForEach(items.filter { $0.title != "Weather" }) { item in
                            NavigationLink(destination: item.destination) {
                                DashboardTile(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}

// MARK: - Inline Weather summary card for Dashboard

private struct WeatherSummaryCard: View {
    @StateObject private var vm: WeatherViewModel

    init(apiKey: String) {
        let service  = OpenWeatherClient(apiKey: apiKey)
        let forecast = OpenWeatherForecastClient(apiKey: apiKey)
        let location = LocationProvider()
        _vm = StateObject(wrappedValue: WeatherViewModel(
            service: service,
            forecastService: forecast,
            location: location
        ))
    }

    var body: some View {
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

            VStack(alignment: .leading, spacing: 6) {
                // Title and optional location
                Text("Weather").font(.headline)
                if let w = vm.weather {
                    Text("\(w.city)\(w.country.map { ", \($0)" } ?? "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Main content
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
                    VStack(alignment: .leading, spacing: 4) {
                        // Temperature + description
                        HStack(spacing: 8) {
                            Text("\(Int(w.temperatureC.rounded()))°C")
                                .font(.subheadline)
                                .bold()
                            Text(w.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        // High / Low from forecast (if available)
                        if let day = vm.forecast.first {
                            Text("H: \(Int(day.maxC.rounded()))°  L: \(Int(day.minC.rounded()))°")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Humidity • Wind • Rain chance
                        HStack(spacing: 14) {
                            if let h = w.humidity {
                                Label("\(h)%", systemImage: "humidity").font(.caption).foregroundStyle(.secondary)
                            }
                            if let ws = w.windSpeed {
                                Label(String(format: "%.1f m/s", ws), systemImage: "wind").font(.caption).foregroundStyle(.secondary)
                            }
                            if let rain = vm.forecast.first?.rainChance {
                                Label("\(rain)%", systemImage: "cloud.rain").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Tap to view")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Last updated time
                if let ts = vm.lastUpdated {
                    Text(ts, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear { if vm.weather == nil && !vm.isLoading { vm.refresh() } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        if let w = vm.weather {
            var bits: [String] = []
            bits.append("\(Int(w.temperatureC.rounded())) degrees Celsius")
            bits.append(w.description)
            if let h = w.humidity { bits.append("humidity \(h) percent") }
            if let ws = w.windSpeed { bits.append(String(format: "wind %.1f meters per second", ws)) }
            if let rain = vm.forecast.first?.rainChance { bits.append("rain chance \(rain) percent") }
            return "Weather, " + bits.joined(separator: ", ") + "."
        }
        if let err = vm.errorMessage { return "Weather error: \(err)" }
        if vm.isLoading { return "Weather loading" }
        return "Weather"
    }
}
