import Foundation
import Combine

// Placeholder ViewModel for AR identification pipeline.
@MainActor
final class ARIdentifierViewModel: ObservableObject {
    @Published var lastMessage: String = ""
    @Published var isRunning: Bool = false

    func start() {
        isRunning = true
        lastMessage = "Starting AR session..."
    }

    func stop() {
        isRunning = false
        lastMessage = "Stopped"
    }
}
