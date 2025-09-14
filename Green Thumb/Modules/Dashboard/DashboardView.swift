import SwiftUI
import CoreData

// Main Dashboard screen – mirrors the HTML layout in native SwiftUI without embedding a tab bar.
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var ctx

    // Core Data fetches – lightweight, safe defaults
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CareTask.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \CareTask.createdAt, ascending: true)
        ],
        predicate: NSPredicate(format: "status != %@", "Completed"),
        animation: .default
    ) private var pendingTasks: FetchedResults<CareTask>

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \HealthIssue.createdAt, ascending: false)
        ],
        animation: .default
    ) private var healthIssues: FetchedResults<HealthIssue>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Plant.plantingDate, ascending: true)],
        animation: .default
    ) private var plants: FetchedResults<Plant>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HeaderBar()
                    NavigationLink(destination: WeatherView(apiKey: "15845b53595b293a72d288d11d16cb39")) {
                        DashboardWeatherSummaryCard()
                    }
                    ARCard()
                    NearbyCard()
                    QuickSummaryGrid(pendingTasks: Array(pendingTasks), issues: Array(healthIssues))
                    DiseaseScannerCTA()
                    PlantsGrid(plants: Array(plants))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.05), Color.green.opacity(0.02)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
        }
    }
}

// MARK: - Sections

private struct HeaderBar: View {
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("GreenThumb")
                    .font(.title3).bold()
            }
            Spacer()
            HStack(spacing: 10) {
                CircleIcon(system: "magnifyingglass")
                CircleIcon(system: "bell")
                CircleIcon(system: "person.crop.circle")
            }
        }
    }
}

private struct CircleIcon: View {
    let system: String
    var body: some View {
        Button {} label: {
            Image(systemName: system)
                .font(.subheadline)
                .frame(width: 34, height: 34)
                .background(.thinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct ARCard: View {
    @State private var showComingSoon = false
    var body: some View {
        Button {
            showComingSoon = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("AR Plant Identifier")
                        .font(.headline)
                    Text("Coming soon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arkit")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.green.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .alert("Coming Soon", isPresented: $showComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("AR Plant Identifier isn’t available yet. Stay tuned!")
        }
    }
}

// Live weather summary for the Dashboard using the shared WeatherViewModel
private struct DashboardWeatherSummaryCard: View {
    @StateObject private var vm: WeatherViewModel

    init() {
        let api = "15845b53595b293a72d288d11d16cb39"
        let service  = OpenWeatherClient(apiKey: api)
        let forecast = OpenWeatherForecastClient(apiKey: api)
        let location = LocationProvider()
        _vm = StateObject(wrappedValue: WeatherViewModel(
            service: service,
            forecastService: forecast,
            location: location
        ))
    }

    var body: some View {
        HStack(spacing: 12) {
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
                // Title: Location name if available, else generic label
                if let w = vm.weather {
                    let loc = vm.isUsingCurrentLocation
                        ? "\(w.city)\(w.country.map { ", \($0)" } ?? "")"
                        : (vm.selectedPlaceName ?? "\(w.city)\(w.country.map { ", \($0)" } ?? "")")
                    Text(loc)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("Weather").font(.headline)
                }
                if vm.isLoading {
                    Text("Fetching…").font(.subheadline).foregroundStyle(.secondary)
                } else if let err = vm.errorMessage {
                    Text(err).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                } else if let w = vm.weather {
                    HStack(spacing: 8) {
                        Text("\(Int(w.temperatureC.rounded()))°C").font(.subheadline).bold()
                        Text(w.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    }
                    // Extra details: humidity, wind, last updated
                    HStack(spacing: 14) {
                        if let h = w.humidity {
                            Label("\(h)%", systemImage: "humidity")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let ws = w.windSpeed {
                            Label(String(format: "%.1f m/s", ws), systemImage: "wind")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let ts = vm.lastUpdated ?? Optional(w.dt) {
                            Label(ts.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Tap to view").font(.subheadline).foregroundStyle(.secondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .onAppear { if vm.weather == nil && !vm.isLoading { vm.refresh() } }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        if let w = vm.weather {
            let loc = vm.isUsingCurrentLocation
                ? "\(w.city)\(w.country.map { ", \($0)" } ?? "")"
                : (vm.selectedPlaceName ?? "\(w.city)\(w.country.map { ", \($0)" } ?? "")")
            return "Weather for \(loc), \(Int(w.temperatureC.rounded())) degrees Celsius, \(w.description)."
        }
        if let err = vm.errorMessage { return "Weather error: \(err)" }
        if vm.isLoading { return "Weather loading" }
        return "Weather"
    }
}

private struct NearbyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Nearby")
                    .font(.headline)
                Spacer()
                NavigationLink("View all") { StoreLocatorView(initialQuery: nil) }
                    .font(.subheadline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NavigationLink(destination: StoreLocatorView(initialQuery: "plant nursery")) {
                        NearbyRow(title: "Plant Nursery", icon: "leaf.fill", color: .green)
                    }
                    NavigationLink(destination: StoreLocatorView(initialQuery: "garden center")) {
                        NearbyRow(title: "Garden Center", icon: "tree.fill", color: .mint)
                    }
                    NavigationLink(destination: StoreLocatorView(initialQuery: "agro shop")) {
                        NearbyRow(title: "Agro Shop", icon: "bag.fill", color: .blue)
                    }
                    NavigationLink(destination: StoreLocatorView(initialQuery: "fertilizer")) {
                        NearbyRow(title: "Fertilizer", icon: "drop.fill", color: .orange)
                    }
                    NavigationLink(destination: StoreLocatorView(initialQuery: "hardware")) {
                        NearbyRow(title: "Hardware", icon: "wrench.and.screwdriver", color: .gray)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct NearbyRow: View {
    let title: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct QuickSummaryGrid: View {
    let pendingTasks: [CareTask]
    let issues: [HealthIssue]

    var overdueCount: Int { pendingTasks.filter { ($0.dueDate ?? .distantFuture) < Calendar.current.startOfDay(for: Date()) }.count }
    var todayCount: Int { pendingTasks.filter { Calendar.current.isDateInToday($0.dueDate ?? .distantPast) }.count }
    var upcomingCount: Int { max(0, pendingTasks.count - overdueCount - todayCount) }
    var openIssues: Int { issues.filter { ($0.status ?? "Open") != "Resolved" }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your day")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                SummaryTile(title: "Overdue", value: overdueCount, icon: "exclamationmark.triangle.fill", tint: .red)
                SummaryTile(title: "Today", value: todayCount, icon: "sun.max.fill", tint: .orange)
                SummaryTile(title: "Upcoming", value: upcomingCount, icon: "clock.fill", tint: .blue)
                SummaryTile(title: "Health", value: openIssues, icon: "heart.text.square.fill", tint: .pink)
                SummaryTile(title: "Tasks", value: pendingTasks.count, icon: "checklist", tint: .green)
                SummaryTile(title: "Plants", value: 0, icon: "leaf", tint: .mint)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct SummaryTile: View {
    let title: String
    let value: Int
    let icon: String
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text("\(value)")
                .font(.title3).bold()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

private struct DiseaseScannerCTA: View {
    var body: some View {
        NavigationLink {
            DiseaseIdentifierView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "camera.macro")
                    .font(.title2)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan for diseases").font(.headline).foregroundStyle(.white)
                    Text("Use AI to detect plant issues early").font(.caption).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(14)
            .background(
                LinearGradient(colors: [Color.green.opacity(0.85), Color.teal.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

private struct PlantsGrid: View {
    let plants: [Plant]
    var display: [Plant] { Array(plants.prefix(6)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your plants").font(.headline)
                Spacer()
                NavigationLink("See all") { PlantListView() }
                    .font(.subheadline)
            }
            if display.isEmpty {
                ContentUnavailableView("No plants yet", image: "leaf", description: Text("Tap + in Plants tab to add your first plant."))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(display, id: \.objectID) { p in
                        PlantTile(plant: p)
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct PlantTile: View {
    let plant: Plant
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color(.tertiarySystemFill))
                if let data = plant.photoData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "leaf")
                        .font(.title)
                        .foregroundStyle(.green)
                }
            }
            .frame(height: 90)
            .clipped()
            Text(plant.name ?? "Plant")
                .font(.subheadline).bold()
            Text(plant.category ?? "Category")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemBackground)))
    }
}

