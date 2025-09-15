import SwiftUI
import FirebaseAuth
import CoreData

struct ProfileDetailView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var ctx

    @State private var displayName: String = ""
    @State private var isEditingName = false
    @State private var isSaving = false
    @State private var message: String?
    @StateObject private var store: CoreDataProfileStore

    private var user: User? { AuthService().currentUser() }

    init(context: NSManagedObjectContext? = nil) {
        let contextToUse = context ?? PersistenceController.shared.container.viewContext
        _store = StateObject(wrappedValue: CoreDataProfileStore(context: contextToUse))
    }

    var body: some View {
        List {
            header()

            Section("Account") {
                HStack { Text("Email"); Spacer(); Text(user?.email ?? "—").foregroundStyle(.secondary) }
                HStack { Text("User ID"); Spacer(); Text(user?.uid ?? "—").foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7) }
                Toggle(isOn: Binding(
                    get: { session.biometricsEnabled },
                    set: { session.setBiometricsEnabled($0) }
                )) {
                    Label("Biometric Unlock", systemImage: "faceid")
                }
            }

            Section("About you") {
                TextField("Location", text: Binding(
                    get: { store.profile.location },
                    set: { store.profile.location = $0 }
                ))
                TextField("Bio", text: Binding(
                    get: { store.profile.bio ?? "" },
                    set: { store.profile.bio = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(1...4)
                Button {
                    store.persist()
                    message = "Saved profile details"
                } label: {
                    Label("Save details", systemImage: "square.and.arrow.down")
                }
            }

            Section {
                Button(role: .destructive) { session.signOut(); dismiss() } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

            if let msg = message {
                Section { Text(msg).font(.footnote).foregroundStyle(.secondary) }
            }
        }
    .navigationTitle("Profile")
    .onAppear { displayName = user?.displayName ?? "" }
    }

    @ViewBuilder
    private func header() -> some View {
        Section {
            HStack(alignment: .center, spacing: 16) {
                avatarView()
                VStack(alignment: .leading, spacing: 6) {
                    if isEditingName {
                        HStack {
                            TextField("Display name", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                            if isSaving { ProgressView().scaleEffect(0.8) }
                            Button("Save") { Task { await saveName() } }
                                .buttonStyle(.borderedProminent)
                                .disabled(isSaving || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Text((user?.displayName?.isEmpty == false ? user?.displayName : nil) ?? "Your name")
                            .font(.headline)
                        Button("Edit name") { isEditingName = true }
                            .font(.subheadline)
                    }
                    Text(user?.email ?? "").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func avatarView() -> some View {
        let initials = initialsFrom(displayName.isEmpty ? (user?.displayName ?? user?.email ?? "?") : displayName)
        ZStack {
            Circle().fill(Color.green.opacity(0.15))
            Text(initials)
                .font(.title2).bold()
                .foregroundStyle(.green)
        }
        .frame(width: 64, height: 64)
        .overlay(Circle().stroke(Color.green.opacity(0.2), lineWidth: 1))
        .accessibilityLabel("Profile avatar")
    }

    private func initialsFrom(_ text: String) -> String {
        let comps = text.split(separator: " ")
        let chars: [Character] = comps.prefix(2).compactMap { $0.first }
        return chars.isEmpty ? "?" : String(chars).uppercased()
    }

    private func saveName() async {
        guard let u = Auth.auth().currentUser else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let change = u.createProfileChangeRequest()
            change.displayName = displayName
            try await change.commitChanges()
            message = "Updated display name"
            isEditingName = false
        } catch {
            message = "Failed to update: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack { ProfileDetailView() }
        .environmentObject(SessionStore())
}
