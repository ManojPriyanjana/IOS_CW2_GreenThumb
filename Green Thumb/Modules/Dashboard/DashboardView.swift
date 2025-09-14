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
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink(destination: WeatherView(apiKey: "15845b53595b293a72d288d11d16cb39")) {
                    DashboardWeatherSummaryCard()
                }
                ARCard()
                NearbyCard()
                QuickSummaryGrid(
                    pendingTasks: Array(pendingTasks),
                    issues: Array(healthIssues),
                    plantsCount: plants.count
                )
                DiseaseScannerCTA()
                PlantsGrid(plants: Array(plants))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.05), Color.green.opacity(0.02)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Dashboard")
        .toolbarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 14) {
                    Button { /* TODO: search action */ } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    Button { /* TODO: notifications action */ } label: {
                        Image(systemName: "bell")
                    }
                    Button { /* TODO: profile action */ } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Sections

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
    let plantsCount: Int

    var overdueCount: Int { pendingTasks.filter { ($0.dueDate ?? .distantFuture) < Calendar.current.startOfDay(for: Date()) }.count }
    var todayCount: Int { pendingTasks.filter { Calendar.current.isDateInToday($0.dueDate ?? .distantPast) }.count }
    var upcomingCount: Int { max(0, pendingTasks.count - overdueCount - todayCount) }
    var openIssues: Int { issues.filter { ($0.status ?? "Open") != "Resolved" }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                NavigationLink(destination: AllTasksView(initialFilter: "overdue")) {
                    SummaryTile(title: "Overdue tasks", value: overdueCount, icon: "exclamationmark.triangle.fill", tint: .red, emphasis: true)
                }.buttonStyle(.plain)
                NavigationLink(destination: AllTasksView(initialFilter: "today")) {
                    SummaryTile(title: "Today tasks", value: todayCount, icon: "sun.max.fill", tint: .orange, emphasis: true)
                }.buttonStyle(.plain)
                NavigationLink(destination: AllTasksView(initialFilter: "upcoming")) {
                    SummaryTile(title: "Upcoming tasks", value: upcomingCount, icon: "clock.fill", tint: .blue, emphasis: true)
                }.buttonStyle(.plain)
                NavigationLink(destination: HealthIssuesOverviewView()) {
                    SummaryTile(title: "Health issues", value: openIssues, icon: "heart.text.square.fill", tint: .pink, emphasis: true)
                }.buttonStyle(.plain)
                NavigationLink(destination: AllTasksView(initialFilter: nil)) {
                    SummaryTile(title: "All tasks", value: pendingTasks.count, icon: "checklist", tint: .green, emphasis: true)
                }.buttonStyle(.plain)
                NavigationLink(destination: PlantListView()) {
                    SummaryTile(title: "Plants", value: plantsCount, icon: "leaf", tint: .mint, emphasis: true)
                }.buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Color.green.opacity(0.85), Color.teal.opacity(0.8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

private struct SummaryTile: View {
    let title: String
    let value: Int
    let icon: String
    let tint: Color
    var emphasis: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(emphasis ? .white : tint)
            Text("\(value)")
                .font(.title3).bold()
                .foregroundStyle(emphasis ? .white : .primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(emphasis ? .white.opacity(0.9) : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    .frame(minHeight: 96)
        .background(
            Group {
                if emphasis {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                }
            }
        )
        .overlay(
            Group {
                if emphasis {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.12), lineWidth: 1)
                }
            }
        )
        .shadow(color: Color.black.opacity(emphasis ? 0.0 : 0.05), radius: 6, x: 0, y: 3)
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

// Inline aggregated Health Issues list to avoid cross-target scope issues
private struct HealthIssuesOverviewView: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \HealthIssue.status,    ascending: true),
            NSSortDescriptor(keyPath: \HealthIssue.createdAt, ascending: false)
        ],
        animation: .default
    ) private var issues: FetchedResults<HealthIssue>

    @State private var query = ""
    @State private var showOpenOnly = true

    var body: some View {
        List(filtered) { i in row(i) }
            .listStyle(.insetGrouped)
            .navigationTitle("Health Issues")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Toggle(isOn: $showOpenOnly) { Text("Open only") }
                }
            }
            .searchable(text: $query)
    }

    private var filtered: [HealthIssue] {
        let base = showOpenOnly ? issues.filter { ($0.status ?? "") != "Resolved" } : Array(issues)
        guard !query.isEmpty else { return base }
        return base.filter {
            ($0.category ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.subtype ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.notes ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.status ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    @ViewBuilder
    private func row(_ i: HealthIssue) -> some View {
        let isResolved = (i.status ?? "") == "Resolved"
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon(for: i.category))
                    .foregroundStyle(isResolved ? Color.secondary : Color.red)
                Text(i.subtype?.isEmpty == false ? i.subtype! : (i.category ?? "Issue"))
                    .font(.headline)
                Spacer()
                Text(i.status ?? "Open")
                    .font(.caption)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(isResolved ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            if let notes = i.notes, !notes.isEmpty {
                Text(notes).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
            }
            HStack(spacing: 8) {
                if let created = i.createdAt {
                    Text("Reported: \(created.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let resolved = i.resolvedAt {
                    Text("• Resolved: \(resolved.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

private func icon(for category: String?) -> String {
    switch (category ?? "").lowercased() {
    case "pest": return "ant"
    case "fungus": return "aqi.high"
    case "deficiency": return "drop.triangle"
    default: return "exclamationmark.triangle"
    }
}

