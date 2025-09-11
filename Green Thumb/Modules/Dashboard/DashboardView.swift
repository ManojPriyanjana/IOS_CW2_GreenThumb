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
    static let pageBg = LinearGradient(
        colors: [
            Color.green.opacity(0.08),
            Color.green.opacity(0.04)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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
            ZStack {
                Rectangle()
                    .fill(DashboardDS.pageBg)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Garden overview
                        NavigationLink(destination: PlantListView()) {
                            GardenOverviewCard().gtCard()
                        }
                        .buttonStyle(.plain)

                        // Weather
                        NavigationLink(destination: WeatherView(apiKey: weatherAPIKey)) {
                            WeatherSummaryCard(apiKey: weatherAPIKey).gtCard()
                        }
                        .buttonStyle(.plain)

                        // Tasks
                        NavigationLink(destination: AllTasksView()) {
                            TaskSummaryCard().gtCard()
                        }
                        .buttonStyle(.plain)

                        // Health
                        NavigationLink(destination: HealthOverviewView()) {
                            HealthSummaryCard().gtCard()
                        }
                        .buttonStyle(.plain)

                        // Harvest
                        NavigationLink(destination: HarvestOverviewView()) {
                            HarvestSummaryCard().gtCard()
                        }
                        .buttonStyle(.plain)

                        // Grid tiles (exclude full-width duplicates)
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(items.filter {
                                $0.title != "Weather" &&
                                $0.title != "Tasks" &&
                                $0.title != "Health" &&
                                $0.title != "Harvest" &&
                                $0.title != "My Garden"
                            }) { item in
                                NavigationLink(destination: item.destination) {
                                    DashboardTile(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
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

// Preview removed to avoid compile issues on older Swift toolchains

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

// MARK: - Garden Overview Card

private struct GardenOverviewCard: View {
    @FetchRequest private var plants: FetchedResults<Plant>
    @FetchRequest private var tasks: FetchedResults<CareTask>
    @FetchRequest private var issues: FetchedResults<HealthIssue>
    @FetchRequest private var schedules: FetchedResults<HarvestSchedule>

    init() {
        let plantReq: NSFetchRequest<Plant> = Plant.fetchRequest()
        plantReq.sortDescriptors = [NSSortDescriptor(keyPath: \Plant.plantingDate, ascending: true)]
        _plants = FetchRequest(fetchRequest: plantReq, animation: .default)

        let taskReq: NSFetchRequest<CareTask> = CareTask.fetchRequest()
        taskReq.sortDescriptors = [NSSortDescriptor(keyPath: \CareTask.dueDate, ascending: true)]
        taskReq.predicate = NSPredicate(format: "status != %@", "Completed")
        _tasks = FetchRequest(fetchRequest: taskReq, animation: .default)

        let issueReq: NSFetchRequest<HealthIssue> = HealthIssue.fetchRequest()
        issueReq.sortDescriptors = [NSSortDescriptor(keyPath: \HealthIssue.createdAt, ascending: false)]
        _issues = FetchRequest(fetchRequest: issueReq, animation: .default)

        let schReq = NSFetchRequest<HarvestSchedule>(entityName: "HarvestSchedule")
        let now = Date()
        schReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "status != %@", HarvestStatus.completed.rawValue),
            NSPredicate(format: "expectedStart != nil"),
            NSPredicate(format: "expectedStart <= %@", now as NSDate? ?? NSDate())
        ])
        schReq.sortDescriptors = [NSSortDescriptor(key: "expectedStart", ascending: true)]
        _schedules = FetchRequest(fetchRequest: schReq, animation: .default)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Leading icon
            ZStack {
                RoundedRectangle(cornerRadius: DashboardDS.iconRadius, style: .continuous)
                    .fill(LinearGradient(colors: [Color.green.opacity(0.25), Color.green.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Image(systemName: "sprout.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)
                    .font(.system(size: 28, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("My Garden").font(.headline)

                // Stats grid (2 x 2) for clarity
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 18) {
                        stat(icon: "leaf", title: "Plants", value: "\(plants.count)")
                        stat(icon: "calendar", title: "Tasks Today", value: "\(todayTasks)")
                    }
                    HStack(spacing: 18) {
                        stat(icon: "heart", title: "Open Health", value: "\(openIssues)")
                        stat(icon: "scissors", title: "Harvest Due", value: "\(dueHarvest)")
                    }
                }

                if let highlight = highlightText {
                    Text(highlight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                // Timestamp
                Text(Date(), style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("My Garden summary: \(plants.count) plants, \(todayTasks) tasks today, \(openIssues) open health issues, \(dueHarvest) harvests due")
    }

    private func stat(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(.secondary)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Text(value).font(.subheadline).bold()
        }
    }

    // Derived
    private var todayTasks: Int {
        tasks.filter { t in
            guard let d = t.dueDate else { return false }
            return Calendar.current.isDateInToday(d)
        }.count
    }
    private var openIssues: Int { issues.filter { ($0.status ?? "") != "Resolved" }.count }
    private var dueHarvest: Int { schedules.filter { [.due, .overdue].contains(HarvestRepository.computeStatus(for: $0)) }.count }

    private var highlightText: String? {
        if let nextTask = tasks
            .filter({ $0.dueDate != nil })
            .sorted(by: { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) })
            .first,
           let due = nextTask.dueDate {
            return "Next task: \(nextTask.title ?? "Task") — \(DateFormatter.localizedString(from: due, dateStyle: .medium, timeStyle: .none))"
        }
        if let nextSchedule = schedules
            .sorted(by: { ($0.expectedStart ?? .distantFuture) < ($1.expectedStart ?? .distantFuture) })
            .first,
           let start = nextSchedule.expectedStart {
            return "Next harvest: \(nextSchedule.plant?.name ?? "Plant") — \(DateFormatter.localizedString(from: start, dateStyle: .medium, timeStyle: .none))"
        }
        return nil
    }
}

// MARK: - Inline Health summary card and overview

private struct HealthSummaryCard: View {
    @FetchRequest private var issues: FetchedResults<HealthIssue>

    init() {
        let req: NSFetchRequest<HealthIssue> = HealthIssue.fetchRequest()
        req.sortDescriptors = [
            NSSortDescriptor(keyPath: \HealthIssue.createdAt, ascending: false)
        ]
        _issues = FetchRequest(fetchRequest: req, animation: .default)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: DashboardDS.iconRadius, style: .continuous)
                    .fill(LinearGradient(colors: [Color.red.opacity(0.25), Color.red.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Image(systemName: "heart.text.square")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.red)
                    .font(.system(size: 26, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Health").font(.headline)

                if issues.isEmpty {
                    Text("No issues recorded")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Open: \(openCount) • Resolved: \(resolvedCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let latest = latestOpen ?? issues.first {
                        let date = latest.createdAt.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) } ?? ""
                        Text("Latest: \(latest.subtype?.isEmpty == false ? latest.subtype! : (latest.category ?? "Issue")) \(date.isEmpty ? "" : "— \(date)")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Text(Date(), style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .accessibilityLabel(accessibilitySummary)
    }

    private var openCount: Int { issues.filter { ($0.status ?? "") != "Resolved" }.count }
    private var resolvedCount: Int { issues.filter { ($0.status ?? "") == "Resolved" }.count }
    private var latestOpen: HealthIssue? { issues.first { ($0.status ?? "") != "Resolved" } }

    private var accessibilitySummary: String {
        if issues.isEmpty { return "Health, no issues" }
        return "Health, open \(openCount), resolved \(resolvedCount)"
    }
}

private struct HealthOverviewView: View {
    @State private var query = ""
    @State private var selectedPlantID: NSManagedObjectID?

    @FetchRequest private var issues: FetchedResults<HealthIssue>
    @FetchRequest private var plants: FetchedResults<Plant>

    init() {
        let issueReq: NSFetchRequest<HealthIssue> = HealthIssue.fetchRequest()
        issueReq.sortDescriptors = [
            NSSortDescriptor(keyPath: \HealthIssue.status, ascending: true),
            NSSortDescriptor(keyPath: \HealthIssue.createdAt, ascending: false)
        ]
        _issues = FetchRequest(fetchRequest: issueReq, animation: .default)

        let plantReq: NSFetchRequest<Plant> = Plant.fetchRequest()
        plantReq.sortDescriptors = [NSSortDescriptor(keyPath: \Plant.name, ascending: true)]
        _plants = FetchRequest(fetchRequest: plantReq, animation: .default)
    }

    var body: some View {
        List {
            Section {
                Picker("Plant", selection: $selectedPlantID) {
                    Text("All Plants").tag(Optional<NSManagedObjectID>.none)
                    ForEach(plants) { p in
                        Text(p.name ?? "Plant").tag(Optional(p.objectID))
                    }
                }
            }

            if !openIssuesFiltered.isEmpty {
                Section("Open") { ForEach(openIssuesFiltered, content: row) }
            }
            if !closedIssuesFiltered.isEmpty {
                Section("Resolved") { ForEach(closedIssuesFiltered, content: row) }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Health Overview")
        .searchable(text: $query)
    }

    private var filteredIssues: [HealthIssue] {
        let base = issues.filter { i in
            guard let id = selectedPlantID else { return true }
            return i.plant?.objectID == id
        }
        guard !query.isEmpty else { return base }
        return base.filter {
            ($0.category ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.subtype ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.notes ?? "").localizedCaseInsensitiveContains(query) ||
            ($0.status ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    private var openIssuesFiltered: [HealthIssue] { filteredIssues.filter { ($0.status ?? "") != "Resolved" } }
    private var closedIssuesFiltered: [HealthIssue] { filteredIssues.filter { ($0.status ?? "") == "Resolved" } }

    @ViewBuilder
    private func row(_ i: HealthIssue) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon(for: i.category))
                    .foregroundStyle((i.status ?? "") == "Resolved" ? Color.secondary : Color.red)
                Text(i.subtype?.isEmpty == false ? i.subtype! : (i.category ?? "Issue"))
                    .font(.headline)
                Spacer()
                Text(i.status ?? "Open")
                    .font(.caption)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(((i.status ?? "") == "Resolved") ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            HStack(spacing: 8) {
                Text(i.plant?.name ?? "Plant").font(.caption).foregroundStyle(.secondary)
                if let created = i.createdAt {
                    Text("• \(created.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func icon(for category: String?) -> String {
        switch (category ?? "").lowercased() {
        case "pests":     return "ant"
        case "disease":   return "bandage.fill"
        case "nutrient":  return "leaf"
        case "watering":  return "drop"
        case "physical":  return "wrench.adjustable"
        default:          return "exclamationmark.triangle"
        }
    }
}

// MARK: - Inline Harvest summary card and overview

private struct HarvestSummaryCard: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest private var upcoming: FetchedResults<HarvestSchedule>

    init() {
        let req = NSFetchRequest<HarvestSchedule>(entityName: "HarvestSchedule")
        let now = Date()
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "status != %@", HarvestStatus.completed.rawValue),
            NSPredicate(format: "expectedStart != nil"),
            NSPredicate(format: "expectedStart <= %@", now as NSDate? ?? NSDate())
        ])
        req.sortDescriptors = [NSSortDescriptor(key: "expectedStart", ascending: true)]
        _upcoming = FetchRequest(fetchRequest: req, animation: .default)
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: DashboardDS.iconRadius, style: .continuous)
                    .fill(LinearGradient(colors: [Color.green.opacity(0.25), Color.green.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Image(systemName: "scissors")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)
                    .font(.system(size: 26, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Harvest").font(.headline)

                if upcoming.isEmpty {
                    Text("No schedules due")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 12) {
                        Label("\(overdueCount)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Label("\(dueCount)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let next = nextDue {
                        Text("Next: \(next.plant?.name ?? "Plant") — \(formattedDate(next.expectedStart))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .accessibilityLabel(accessibilitySummary)
    }

    private var nextDue: HarvestSchedule? {
        upcoming
            .sorted { ($0.expectedStart ?? .distantFuture) < ($1.expectedStart ?? .distantFuture) }
            .first
    }

    private var overdueCount: Int { upcoming.filter { HarvestRepository.computeStatus(for: $0) == .overdue }.count }
    private var dueCount: Int { upcoming.filter { HarvestRepository.computeStatus(for: $0) == .due }.count }

    private func formattedDate(_ d: Date?) -> String {
        guard let d else { return "" }
        return DateFormatter.localizedString(from: d, dateStyle: .medium, timeStyle: .none)
    }

    private var accessibilitySummary: String {
        if upcoming.isEmpty { return "Harvest, no schedules due" }
        let overdue = upcoming.filter { HarvestRepository.computeStatus(for: $0) == .overdue }.count
        let due = upcoming.filter { HarvestRepository.computeStatus(for: $0) == .due }.count
        return "Harvest, overdue \(overdue), due \(due)"
    }
}

private struct HarvestOverviewView: View {
    @FetchRequest private var schedules: FetchedResults<HarvestSchedule>

    init() {
        let req = NSFetchRequest<HarvestSchedule>(entityName: "HarvestSchedule")
        req.sortDescriptors = [
            NSSortDescriptor(key: "expectedStart", ascending: true)
        ]
        _schedules = FetchRequest(fetchRequest: req, animation: .default)
    }

    var body: some View {
        List {
            if schedules.isEmpty {
                Text("No harvest schedules").foregroundStyle(.secondary)
            } else {
                ForEach(schedules) { s in
                    NavigationLink {
                        HarvestScheduleDetailView(schedule: s)
                    } label: {
                        ScheduleRowView(schedule: s)
                    }
                }
            }
        }
        .navigationTitle("Harvest Overview")
        .listStyle(.insetGrouped)
    }
}
