import Foundation

/// Lightweight local profile model for non-auth fields (bio, location, etc.).
/// Renamed to avoid conflict with the main `UserProfile` (profile screen model).
struct LocalProfile: Codable, Equatable {
    var bio: String = ""
    var location: String = ""
}

/// Simple UserDefaults-backed store for profile fields that aren't managed by Firebase.
final class UserDefaultsProfileStore {
    private let key = "gt.user.profile"
    private let ud: UserDefaults

    init(ud: UserDefaults = .standard) {
        self.ud = ud
    }

        func load() -> LocalProfile {
            guard let data = ud.data(forKey: key),
                  let profile = try? JSONDecoder().decode(LocalProfile.self, from: data) else {
                return LocalProfile()
            }
            return profile
        }

        func save(_ profile: LocalProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            ud.set(data, forKey: key)
        }
    }

    func clear() {
        ud.removeObject(forKey: key)
    }
}
