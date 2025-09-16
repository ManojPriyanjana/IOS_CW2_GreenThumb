import SwiftUI

public struct WeatherShopStyleView: View {
    @Environment(\.colorScheme) private var scheme
    // Inject your existing VM if you like; here I keep it simple for UI
    @State private var searchText = ""
    @State private var showSearch = false

    // Sample props you can bind from your WeatherViewModel
    public var title: String
    public var description: String
    public var tempC: Int
    public var humidity: Int
    public var wind: Double
    public var lastUpdated: Date
    public var forecast: [(day: String, hi: Int, lo: Int, rain: Int)]

    public init(
        title: String = "Artificial Aloe Vera Plant", // replaced by city
        description: String = "Clear Sky",
        tempC: Int = 29,
        humidity: Int = 62,
        wind: Double = 3.6,
        lastUpdated: Date = .now,
        forecast: [(String, Int, Int, Int)] = [
            ("Tue", 31, 22, 10), ("Wed", 32, 23, 30),
            ("Thu", 33, 24, 60), ("Fri", 34, 25, 20), ("Sat", 32, 23, 10)
        ]
    ) {
        self.title = title
        self.description = description
        self.tempC = tempC
        self.humidity = humidity
        self.wind = wind
        self.lastUpdated = lastUpdated
        self.forecast = forecast
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerBar
                heroCard
                metricsRow
                fiveDayStrip
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(GTTheme.heroGradient(in: scheme).opacity(0.35))
        .navigationBarHidden(true)
    }

    // MARK: Header
    private var headerBar: some View {
        HStack {
            Text("Weather")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(GTTheme.deepGreen)
            Spacer()
            Button { showSearch = true } label {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Button(action: {}) {
                Image(systemName: "paperplane")
                    .font(.title2)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.top, 6)
        .sheet(isPresented: $showSearch) {
            // Present your PlaceSearchView here
            Text("Search sheet placeholder").padding()
        }
    }

    // MARK: Hero product-style card
    private var heroCard: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(GTTheme.card)
                .shadow(color: .black.opacity(0.08), radius: GTTheme.softShadow, y: 6)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    // “Pot image” placeholder -> weather illustration circle
                    ZStack {
                        Circle()
                            .fill(GTTheme.accentYellow)
                            .frame(width: 92, height: 92)
                            .shadow(color: .black.opacity(0.08), radius: GTTheme.softShadow, y: 6)
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.black.opacity(0.85))
                    }
                    Spacer()
                    Text("\(tempC)°C")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title) // city, country
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 24) {
                    Label("\(humidity)%", systemImage: "humidity")
                    Label(String(format: "%.1f m/s", wind), systemImage: "wind")
                    Label(lastUpdated.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Button("Add to dashboard") { /* hook up */ }
                    .buttonStyle(GTPrimaryButtonStyle())
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
    }

    // MARK: metrics row (two small “product” cards)
    private var metricsRow: some View {
        HStack(spacing: 14) {
            miniCard(title: "Feels like", value: "\(tempC + 1)°C", icon: "thermometer.sun")
            miniCard(title: "UV index", value: "7 (High)", icon: "sun.max.trianglebadge.exclamationmark")
        }
    }

    private func miniCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon).imageScale(.large)
                Spacer()
            }
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: GTTheme.softShadow, y: 4)
    }

    // MARK: five-day
    private var fiveDayStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Next 5 days")
                .font(.headline)
                .foregroundStyle(GTTheme.deepGreen)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(forecast.enumerated()), id: \.offset) { _, item in
                        VStack(spacing: 10) {
                            Text(item.day).font(.caption)
                            ZStack {
                                RoundedRectangle(cornerRadius: 16).fill(GTTheme.card)
                                    .frame(width: 120, height: 90)
                                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                                VStack(spacing: 4) {
                                    Image(systemName: "cloud.sun.rain.fill")
                                        .font(.title3)
                                    Text("\(item.hi)° / \(item.lo)°").font(.subheadline)
                                    Label("\(item.rain)%", systemImage: "cloud.rain")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

#Preview {
    NavigationStack { WeatherShopStyleView(title: "Colombo, LK") }
}
