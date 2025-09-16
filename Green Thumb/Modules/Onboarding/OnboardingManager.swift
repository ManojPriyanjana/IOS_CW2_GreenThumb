import Foundation

@MainActor
class OnboardingManager: ObservableObject {
    @Published var isOnboardingComplete: Bool
    
    private let userDefaults = UserDefaults.standard
    private let onboardingCompletedKey = "OnboardingCompleted"
    
    init() {
        self.isOnboardingComplete = userDefaults.bool(forKey: onboardingCompletedKey)
    }
    
    func completeOnboarding() {
        isOnboardingComplete = true
        userDefaults.set(true, forKey: onboardingCompletedKey)
    }
    
    func resetOnboarding() {
        isOnboardingComplete = false
        userDefaults.removeObject(forKey: onboardingCompletedKey)
    }
}
