import Foundation
import CoreData

/// Thin repository to read/write the single UserProfile entity in Core Data.
struct ProfileRepository {
	let ctx: NSManagedObjectContext

	init(ctx: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
		self.ctx = ctx
	}

	func loadOrCreate() throws -> AppUserProfile {
		if let existing = try fetchManaged() {
			return CoreDataProfileStore.toValue(existing)
		}
		let obj = CoreDataProfileStore.insertDefault(in: ctx)
		try ctx.save()
		return CoreDataProfileStore.toValue(obj)
	}

	func save(_ value: AppUserProfile) throws {
		let obj = try fetchManaged() ?? CoreDataProfileStore.insertDefault(in: ctx)
		CoreDataProfileStore.apply(value, to: obj)
		try ctx.save()
	}

	private func fetchManaged() throws -> UserProfile? {
		let req: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
		req.fetchLimit = 1
		return try ctx.fetch(req).first
	}
}

