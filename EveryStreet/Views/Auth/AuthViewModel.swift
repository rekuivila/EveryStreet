import Foundation
import AuthenticationServices

@Observable
final class AuthViewModel {
    var isAuthenticated = false
    var currentUser: AppUser?
    var isLoading = false
    var errorMessage: String?

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            // TODO Phase 2: Forward credential to Supabase auth
            let user = AppUser(
                id: credential.user,
                username: "explorer_\(String(credential.user.prefix(6)))",
                email: credential.email ?? "",
                zipCode: ""
            )
            currentUser = user
            isAuthenticated = true

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        // TODO Phase 2: Implement Supabase email/password auth
        throw AuthError.notImplemented
    }

    #if DEBUG
    func signInAsTestUser() {
        currentUser = AppUser(
            id: "dev-user-001",
            username: "test_walker",
            email: "test@everystreet.app",
            zipCode: "94105"
        )
        isAuthenticated = true
    }
    #endif

    func signOut() {
        isAuthenticated = false
        currentUser = nil
    }
}

enum AuthError: LocalizedError {
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notImplemented: return "Email sign-in is coming soon."
        }
    }
}
