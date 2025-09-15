import Foundation
import CoreData
import SwiftUI

/// Core Data-backed store for the UserProfile entity.
/// Bridges between the NSManagedObject `UserProfile` (from the model) and the value type `AppUserProfile` used by the UI.
final class CoreDataProfileStore: ObservableObject {
    @Published var profile: AppUserProfile

    private let ctx: NSManagedObjectContext
    private var objectID: NSManagedObjectID?

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.ctx = context

        // Try fetch or create a single profile row
        if let existing = try? Self.fetchOne(in: context) {
            self.objectID = existing.objectID
            self.profile = Self.toValue(existing)
        } else {
            let created = Self.insertDefault(in: context)
            self.objectID = created.objectID
            self.profile = Self.toValue(created)
            try? context.save()
        }
    }

    // MARK: Public API
    func update(_ transform: (inout AppUserProfile) -> Void) {
        transform(&profile)
        persist()
    }

    func persist() {
        guard let obj = (try? existingObject()) ?? Self.insertDefault(in: ctx) else { return }
        Self.apply(profile, to: obj)
        do { try ctx.save() } catch { print("[Profile] Save failed: \(error)") }
        objectID = obj.objectID
    }

    // MARK: Helpers
    private func existingObject() throws -> UserProfile? {
        if let id = objectID, let obj = try? ctx.existingObject(with: id) as? UserProfile {
            return obj
        }
        return try Self.fetchOne(in: ctx)
    }

    static func fetchOne(in ctx: NSManagedObjectContext) throws -> UserProfile? {
        let req: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        req.fetchLimit = 1
        return try ctx.fetch(req).first
    }

    @discardableResult
    static func insertDefault(in ctx: NSManagedObjectContext) -> UserProfile {
        let obj = UserProfile(context: ctx)
        obj.id = UUID()
        obj.fullName = "Your Name"
        obj.email = "you@example.com"
        obj.location = "Colombo, Sri Lanka"
        obj.gardeningStyle = AppUserProfile.GardeningStyle.herbs.rawValue
        obj.plantsCount = 0
        obj.tasksCompletedThisWeek = 0
        obj.harvestCount = 0
        return obj
    }

    static func toValue(_ obj: UserProfile) -> AppUserProfile {
        AppUserProfile(
            id: obj.id ?? UUID(),
            fullName: obj.fullName ?? "Your Name",
            email: obj.email ?? "you@example.com",
            location: obj.location ?? "",
            gardeningStyle: AppUserProfile.GardeningStyle(rawValue: obj.gardeningStyle ?? "Herbs") ?? .herbs,
            avatarImageData: obj.avatarImage,
            plantsCount: Int(obj.plantsCount),
            tasksCompletedThisWeek: Int(obj.tasksCompletedThisWeek),
            harvestCount: Int(obj.harvestCount),
            bio: obj.bio
        )
    }

    static func apply(_ value: AppUserProfile, to obj: UserProfile) {
        obj.id = value.id
        obj.fullName = value.fullName
        obj.email = value.email
        obj.location = value.location
        obj.gardeningStyle = value.gardeningStyle.rawValue
        obj.avatarImage = value.avatarImageData
        obj.plantsCount = Int64(value.plantsCount)
        obj.tasksCompletedThisWeek = Int64(value.tasksCompletedThisWeek)
        obj.harvestCount = Int64(value.harvestCount)
    obj.bio = value.bio
    }
}
