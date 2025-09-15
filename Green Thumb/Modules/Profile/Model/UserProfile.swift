import Foundation
import SwiftUI

// Renamed from `UserProfile` to avoid ambiguity with Core Data entity auto-generated class.
public struct AppUserProfile: Identifiable, Codable, Equatable {
    public let id: UUID
    public var fullName: String
    public var email: String
    public var location: String
    public var gardeningStyle: GardeningStyle
    public var avatarImageData: Data? // optional PNG/JPEG bytes
    public var plantsCount: Int
    public var tasksCompletedThisWeek: Int
    public var harvestCount: Int
    public var bio: String? // optional short bio

    public init(
        id: UUID = UUID(),
        fullName: String = "Your Name",
        email: String = "you@example.com",
        location: String = "Colombo, Sri Lanka",
        gardeningStyle: GardeningStyle = .herbs,
        avatarImageData: Data? = nil,
        plantsCount: Int = 0,
        tasksCompletedThisWeek: Int = 0,
    harvestCount: Int = 0,
    bio: String? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.location = location
        self.gardeningStyle = gardeningStyle
        self.avatarImageData = avatarImageData
        self.plantsCount = plantsCount
        self.tasksCompletedThisWeek = tasksCompletedThisWeek
        self.harvestCount = harvestCount
    self.bio = bio
    }

    public enum GardeningStyle: String, CaseIterable, Codable, Identifiable {
        case flowers = "Flowers"
        case vegetables = "Vegetables"
        case herbs = "Herbs"
        case indoor = "Indoor Plants"
        case mixed = "Mixed"
        public var id: String { rawValue }
    }

    public var avatarImage: Image? {
        guard let data = avatarImageData, let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
    }
}
