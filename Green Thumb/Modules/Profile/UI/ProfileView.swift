import SwiftUI
import PhotosUI
import CoreData

// Theme helpers (matches your green theme)
fileprivate extension Color {
    static let primaryGreen = Color(hex: 0x157954)
    static let mintAccent   = Color(hex: 0x56C596)
    static let softMintBG   = Color(hex: 0xCFF4D2)
    static let textPrimary  = Color(hex: 0x1B2320)
    static let textSecondary = Color(hex: 0x3F514B)
    static let dividers     = Color(hex: 0xE5EFE9)
}
fileprivate extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

public struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var store = ProfileStore()

    // Local app settings via AppStorage (simple persistence, no side effects)
    @AppStorage("gt.pref.notifications") private var notificationsOn: Bool = true
    @AppStorage("gt.pref.metric") private var useMetric: Bool = true
    @AppStorage("gt.pref.theme") private var theme: String = "system" // system|light|dark
    @AppStorage("gt.pref.language") private var language: String = Locale.current.language.languageCode?.identifier ?? "en"

    @State private var showEdit = false
    @State private var showDeleteAlert = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                topCard
                badgesRow
                twoStats
                accountSecurityCard
                preferencesCard
                supportAboutCard
                signOutSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.softMintBG.opacity(0.15).ignoresSafeArea())
        .navigationTitle("Profile")
        .toolbar {
            Button { showEdit = true } label: { Image(systemName: "square.and.pencil") }
                .accessibilityLabel("Edit Profile")
        }
        .sheet(isPresented: $showEdit) {
            EditProfileView(profile: store.profile) { updated in
                store.update { $0 = updated }
            }
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { /* hook up when backend ready */ }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action is permanent. Your data will be removed.")
        }
    }

    //  Sections
    private var topCard: some View {
        SectionCard {
            HStack(alignment: .center, spacing: 16) {
                avatar
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.profile.fullName).font(.title2).bold().foregroundColor(.textPrimary)
                    Text(store.profile.email).font(.subheadline).foregroundColor(.textSecondary)
                    if let bio = store.profile.bio, !bio.isEmpty {
                        Text(bio).font(.footnote).foregroundColor(.textSecondary)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(store.profile.location)
                    }
                    .font(.footnote).foregroundColor(.textSecondary)
                }
                Spacer()
                Button { showEdit = true } label: {
                    Image(systemName: "pencil")
                        .padding(8)
                        .background(Color.mintAccent.opacity(0.2))
                        .clipShape(Circle())
                }
                .accessibilityHint("Edit profile")
            }
        }
    }

    private var badgesRow: some View {
        HStack(spacing: 12) {
            badge("Droplet Pro", "drop.fill", .blue)
            badge("New Plant Lover", "sprout.fill", .green)
            badge("Sunlight Guru", "sun.max.fill", .orange)
        }
    }

    private func badge(_ title: String, _ system: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: system).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.dividers, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var twoStats: some View {
        HStack(spacing: 12) {
            StatCard(title: "Plants", value: store.profile.plantsCount, system: "leaf.fill", tint: .green)
            StatCard(title: "Tasks (wk)", value: store.profile.tasksCompletedThisWeek, system: "checkmark.circle.fill", tint: .mint)
        }
    }

    private var accountSecurityCard: some View {
        SectionCard(title: "Account & Security") {
            NavigationLink {
                ForgotPasswordView()
            } label: {
                HStack { rowLabel(system: "key.fill", title: "Change Password", subtitle: "Update your password"); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }
            }
            Toggle(isOn: Binding(
                get: { session.biometricsEnabled },
                set: { session.setBiometricsEnabled($0) }
            )) {
                rowLabel(system: "faceid", title: "Face ID", subtitle: "Unlock app with biometrics")
            }
        }
    }

    private var preferencesCard: some View {
        SectionCard(title: "Preferences") {
            Toggle(isOn: $notificationsOn) { rowLabel(system: "bell.fill", title: "Notifications", subtitle: notificationsOn ? "On" : "Off") }
            Toggle(isOn: $useMetric) { rowLabel(system: "ruler", title: "Units", subtitle: useMetric ? "Metric" : "Imperial") }

            HStack {
                rowLabel(system: "paintbrush.fill", title: "Theme", subtitle: theme.capitalized)
                Spacer()
                Picker("Theme", selection: $theme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }

            HStack {
                rowLabel(system: "globe", title: "Language", subtitle: language.uppercased())
                Spacer()
                Picker("Language", selection: $language) {
                    Text("EN").tag("en")
                    Text("SI").tag("si")
                    Text("TA").tag("ta")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }
        }
    }

    private var connectedFeaturesCard: some View {
        SectionCard(title: "Connected Features") {
            rowButton(system: "calendar", title: "Calendar", subtitle: "Sync harvests & tasks") {
                EventKitService.shared.requestCalendarAccess { _ in }
            }
            rowButton(system: "mappin.and.ellipse", title: "Favorite Nurseries", subtitle: "Find nearby stores") { /* navigate to store list if needed */ }
            rowButton(system: "arkit", title: "AI / AR Tools", subtitle: "Plant identifier, disease scan") { /* navigate to tools */ }
        }
    }

    private var supportAboutCard: some View {
        SectionCard(title: "Support & About") {
            rowButton(system: "questionmark.circle.fill", title: "Help / FAQ", subtitle: "Common questions") { /* open help */ }
            rowButton(system: "envelope.fill", title: "Contact Support", subtitle: "support@greenthumb.app") {
                if let url = URL(string: "mailto:support@greenthumb.app") { UIApplication.shared.open(url) }
            }
            rowButton(system: "info.circle.fill", title: "About & Version", subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") { }
        }
    }

    private var signOutSection: some View {
        VStack(spacing: 8) {
            Button(role: .destructive) { session.signOut() } label: {
                Text("Sign Out").bold().frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            Button("Delete Account") { showDeleteAlert = true }
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 6)
    }

    //  Building blocks
    private var avatar: some View {
        Group {
            if let img = store.profile.avatarImage {
                img.resizable().scaledToFill()
            } else {
                Image(systemName: "leaf.circle.fill").resizable().scaledToFit().foregroundStyle(Color.primaryGreen)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.dividers, lineWidth: 1))
        .accessibilityLabel("Profile picture")
    }

    private func rowLabel(system: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: system).foregroundStyle(.primary).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundColor(.textPrimary)
                Text(subtitle).font(.caption).foregroundColor(.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func rowButton(system: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack { rowLabel(system: system, title: title, subtitle: subtitle); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .accessibilityHint("Opens \(title)")
    }
}

// UI Bits
private struct SectionCard<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title { Text(title).font(.headline).foregroundColor(.textPrimary) }
            content
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.dividers, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

private struct StatCard: View {
    let title: String
    let value: Int
    let system: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: system).foregroundColor(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)").font(.title3).bold().foregroundColor(.textPrimary)
                Text(title).font(.caption).foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.dividers, lineWidth: 1))
    }
}
