import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var wantsBiometrics = true
    @Published var isBusy = false

    func clear() {
        email = ""; password = ""
    }
}
