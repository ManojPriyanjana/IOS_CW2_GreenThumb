import Foundation
import SwiftUI

/// Simple profile store backed by UserDefaults, using the value-type `AppUserProfile` model.
/// This matches the UI usage in `ProfileView` (parameterless init, update closure).
final class ProfileStore: ObservableObject {
    @Published var profile: AppUserProfile

    private let key = "gt.profile.v1"
    private let ud: UserDefaults

    init(ud: UserDefaults = .standard) {
        self.ud = ud
    if let data = ud.data(forKey: key),
       let loaded = try? JSONDecoder().decode(AppUserProfile.self, from: data) {
            self.profile = loaded
        } else {
        self.profile = AppUserProfile()
            persist()
        }
    }

    /// Mutate and persist atomically
    func update(_ transform: (inout AppUserProfile) -> Void) {
        transform(&profile)
        persist()
    }

    func persist() {
        if let data = try? JSONEncoder().encode(profile) {
            ud.set(data, forKey: key)
        }
    }

    func reset() {
    profile = AppUserProfile()
        ud.removeObject(forKey: key)
        persist()
    }
}
