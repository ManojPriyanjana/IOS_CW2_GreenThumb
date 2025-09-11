import SwiftUI
import CoreData

// MARK: - Dashboard Design Tokens & Card Surface (file scope)

private enum DashboardDS {
    static let cardRadius: CGFloat = 18
    static let iconRadius: CGFloat = 14
    static let stroke = Color.black.opacity(0.06)
    static let shadow = Color.black.opacity(0.06)
    static let surface = LinearGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let brand = Color.green
    static let accent = Color.orange
    static let tileBg = LinearGradient(colors: [Color.gray.opacity(0.10), Color.gray.opacity(0.06)], startPoint: .top, endPoint: .bottom)
}

private struct DashboardCardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(DashboardDS.surface, in: RoundedRectangle(cornerRadius: DashboardDS.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DashboardDS.cardRadius, style: .continuous).stroke(DashboardDS.stroke, lineWidth: 1))
            .shadow(color: DashboardDS.shadow, radius: 10, y: 4)
    }
}

private extension View {
    func gtCard() -> some View { modifier(DashboardCardSurface()) }
}

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
                            .gtCard()
                    }
                    .buttonStyle(.plain)

                    // Full-width Tasks summary card
                    NavigationLink(destination: AllTasksView()) {
                        TaskSummaryCard()
                            .gtCard()
                    }
                    .buttonStyle(.plain)

                    // Grid tiles
                    LazyVGrid(columns: columns, spacing: 16) {
                        // Existing tiles (excluding Weather & Tasks to avoid duplication)
                        ForEach(items.filter { $0.title != "Weather" && $0.title != "Tasks" }) { item in
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
    HStack(alignment: .center, spacing: 14) {
            ZStack {
    RoundedRectangle(cornerRadius: DashboardDS.iconRadius, style: .continuous)
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
        .padding(.vertical, 2)
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

// MARK: - Inline Task summary card for Dashboard

private struct TaskSummaryCard: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest private var pending: FetchedResults<CareTask>

    init() {
        let req: NSFetchRequest<CareTask> = CareTask.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(keyPath: \CareTask.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \CareTask.createdAt, ascending: true)
        ]
        req.predicate = NSPredicate(format: "status != %@", "Completed")
        _pending = FetchRequest(fetchRequest: req, animation: .default)
    }

    var body: some View {
    HStack(spacing: 14) {
            ZStack {
    RoundedRectangle(cornerRadius: DashboardDS.iconRadius, style: .continuous)
            .fill(LinearGradient(colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 56, height: 56)
                Image(systemName: "checklist")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
                    .font(.system(size: 26, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Tasks").font(.headline)

                if pending.isEmpty {
                    Text("No pending tasks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    // Summary counts
                    HStack(spacing: 12) {
                        Label("\(overdueCount)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Label("\(todayCount)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label("\(upcomingCount)", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let next = nextDue {
                        Text("Next: \(next.title ?? "Task") — \(formattedDate(next.dueDate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                if let ts = lastUpdated {
                    Text(ts, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 2)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Derived values

    private var lastUpdated: Date? { Date() }

    private var overdueCount: Int { pending.filter { isOverdue($0.dueDate) }.count }
    private var todayCount: Int { pending.filter { isToday($0.dueDate) }.count }
    private var upcomingCount: Int { pending.filter { isUpcoming($0.dueDate) }.count }

    private var nextDue: CareTask? {
        pending
            .filter { $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first
    }

    private func isOverdue(_ d: Date?) -> Bool {
        guard let d else { return false }
        return d < Calendar.current.startOfDay(for: Date())
    }
    private func isToday(_ d: Date?) -> Bool {
        guard let d else { return false }
        return Calendar.current.isDateInToday(d)
    }
    private func isUpcoming(_ d: Date?) -> Bool {
        guard let d else { return false }
        return d > endOfDay(Date())
    }

    private func endOfDay(_ date: Date) -> Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
    }

    private func formattedDate(_ d: Date?) -> String {
        guard let d else { return "" }
        return DateFormatter.localizedString(from: d, dateStyle: .medium, timeStyle: .none)
    }

    private var accessibilitySummary: String {
        if pending.isEmpty { return "Tasks, no pending tasks" }
        return "Tasks, overdue \(overdueCount), today \(todayCount), upcoming \(upcomingCount)"
    }
}
