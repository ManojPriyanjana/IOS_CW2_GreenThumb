
import SwiftUI
import CoreLocation

// MARK: - Theme (local, no extensions needed)

fileprivate enum GTTheme {
    static let greenA = Color(red: 0.10, green: 0.55, blue: 0.38)   // deep green
    static let greenB = Color(red: 0.55, green: 0.83, blue: 0.45)   // fresh green
    static let accent  = Color(red: 0.18, green: 0.67, blue: 0.47)

    static let chipGradient  = LinearGradient(colors: [greenB.opacity(0.18), greenA.opacity(0.10)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardGradient  = LinearGradient(colors: [greenB.opacity(0.28), greenA.opacity(0.16)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing)
    static let tileGradient  = LinearGradient(colors: [greenB.opacity(0.22), greenA.opacity(0.12)],
                                              startPoint: .top, endPoint: .bottom)
    static let stroke        = Color.black.opacity(0.06)
}

// MARK: - View

public struct WeatherView: View {
    @StateObject private var vm: WeatherViewModel
    @State private var showSearch = false

    // Production init — inject your API key
    public init(apiKey: String) {
        let service  = OpenWeatherClient(apiKey: apiKey)
        let forecast = OpenWeatherForecastClient(apiKey: apiKey)
        let location = LocationProvider()
        _vm = StateObject(wrappedValue: WeatherViewModel(
            service: service,
            forecastService: forecast,
            location: location
        ))
    }

    // Preview/testing init
    public init(mock: Bool) {
        let service  = MockWeatherService()
        let forecast = MockForecastService()
        let location = MockLocationProvider()
        _vm = StateObject(wrappedValue: WeatherViewModel(
            service: service,
            forecastService: forecast,
            location: location
        ))
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerPills()
                content()

                if !vm.suggestions.isEmpty {
                    SuggestionsSection(suggestions: vm.suggestions)
                        .padding(.top, 6)
                }
                if !vm.forecast.isEmpty {
                    ForecastStrip(days: vm.forecast)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 6)
        }
        .background(
            LinearGradient(colors: [GTTheme.greenB.opacity(0.10), GTTheme.greenA.opacity(0.06)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onAppear { if vm.weather == nil && !vm.isLoading { vm.refresh() } }
        .navigationTitle("Weather")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 18) {
                    Button { showSearch = true } label: {
                        Image(systemName: "magnifyingglass").font(.body)
                    }
                    .accessibilityLabel("Search location")

                    Button { vm.refresh() } label: {
                        Image(systemName: "location.circle").font(.body)
                    }
                    .accessibilityLabel("Use current location")
                }
                .tint(GTTheme.accent)
            }
        }
        .sheet(isPresented: $showSearch) {
            PlaceSearchView { coord, name in
                vm.refresh(for: coord, placeName: name)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func content() -> some View {
        if vm.isLoading {
            ProgressView("Fetching weather…")
                .padding()
        } else if let error = vm.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                Text(error).multilineTextAlignment(.center)
                Button("Try again") { vm.refresh() }
                    .buttonStyle(.borderedProminent)
                    .tint(GTTheme.accent)
            }
            .padding()
        } else if let w = vm.weather {
            let title = vm.isUsingCurrentLocation
                ? "\(w.city)\(w.country.map { ", \($0)" } ?? "")"
                : (vm.selectedPlaceName ?? "\(w.city)\(w.country.map { ", \($0)" } ?? "")")

            WeatherCard(
                title: title,
                description: w.description,
                temperatureC: Int(w.temperatureC.rounded()),
                humidity: w.humidity,
                windMS: w.windSpeed,
                timestamp: w.dt
            )
            .accessibilityLabel("\(title), \(Int(w.temperatureC.rounded())) degrees Celsius, \(w.description)")
        } else {
            Text("No data yet. Tap the location button.")
                .foregroundStyle(.secondary)
                .padding()
        }
    }

    @ViewBuilder
    private func headerPills() -> some View {
        HStack(spacing: 8) {
            Label(vm.isUsingCurrentLocation ? "Current location" : (vm.selectedPlaceName ?? "Selected"),
                  systemImage: vm.isUsingCurrentLocation ? "location.fill" : "mappin.and.ellipse")
                .font(.caption)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(GTTheme.chipGradient, in: Capsule())
                .overlay(Capsule().stroke(GTTheme.stroke, lineWidth: 1))

            if let ts = vm.lastUpdated {
                Label(ts.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    .font(.caption)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(GTTheme.chipGradient, in: Capsule())
                    .overlay(Capsule().stroke(GTTheme.stroke, lineWidth: 1))
                    .accessibilityLabel("Last updated \(ts.formatted(date: .complete, time: .shortened))")
            }

            Spacer()

            if !vm.isUsingCurrentLocation {
                Button {
                    vm.refresh()
                } label: {
                    Label("My location", systemImage: "location")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(GTTheme.chipGradient, in: Capsule())
                        .overlay(Capsule().stroke(GTTheme.stroke, lineWidth: 1))
                }
                .tint(GTTheme.accent)
                .accessibilityLabel("Switch to current location")
            }
        }
    }
}

// MARK: - Card

fileprivate struct WeatherCard: View {
    let title: String
    let description: String
    let temperatureC: Int
    let humidity: Int?
    let windMS: Double?
    let timestamp: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2).bold()
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(temperatureC)°C")
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(GTTheme.accent)
                    .shadow(radius: 0.5, y: 0.5)
            }

            HStack(spacing: 24) {
                if let h = humidity {
                    Label("\(h)%", systemImage: "humidity")
                        .accessibilityLabel("Humidity \(h) percent")
                }
                if let w = windMS {
                    Label(String(format: "%.1f m/s", w), systemImage: "wind")
                        .accessibilityLabel("Wind \(w) meters per second")
                }
                Label(timestamp.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GTTheme.cardGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(GTTheme.stroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Suggestions

fileprivate struct SuggestionsSection: View {
    let suggestions: [Suggestion]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tips for your garden")
                .font(.headline)

            ForEach(suggestions) { s in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon(for: s.kind))
                        .imageScale(.large)
                        .foregroundStyle(GTTheme.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.title).font(.subheadline).bold()
                        Text(s.detail).font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(GTTheme.tileGradient, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(GTTheme.stroke, lineWidth: 1))
            }
        }
    }
    private func icon(for k: Suggestion.Kind) -> String {
        switch k {
        case .water:   return "drop.fill"
        case .heat:    return "sun.max.fill"
        case .cold:    return "snowflake"
        case .disease: return "bandage.fill"
        case .wind:    return "wind"
        case .rain:    return "cloud.rain.fill"
        }
    }
}

// MARK: - Forecast strip

fileprivate struct ForecastStrip: View {
    let days: [ForecastDay]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next 5 days").font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(days) { d in
                        VStack(spacing: 6) {
                            Text(d.date, format: .dateTime.weekday(.abbreviated))
                                .font(.caption)
                            Text("\(Int(d.maxC.rounded()))° / \(Int(d.minC.rounded()))°")
                                .font(.subheadline)
                            Label("\(d.rainChance)%", systemImage: "cloud.rain")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(width: 92)
                        .background(GTTheme.tileGradient, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GTTheme.stroke, lineWidth: 1))
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Preview

#Preview("Mock") {
    NavigationStack { WeatherView(mock: true) }
}
