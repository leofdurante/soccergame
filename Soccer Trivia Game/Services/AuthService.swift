import Foundation
import Combine
import FirebaseAuth

/// Service for handling user authentication
@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let auth = Auth.auth()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for auth state changes
        authStateListener = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    self?.currentUser = User(
                        id: firebaseUser.uid,
                        name: self?.resolveDisplayName(for: firebaseUser) ?? "Player"
                    )
                    self?.isAuthenticated = true
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    /// Sign in anonymously
    func signInAnonymously() async throws {
        let result = try await auth.signInAnonymously()
        let username = resolveDisplayName(for: result.user)
        currentUser = User(id: result.user.uid, name: username)
        isAuthenticated = true
    }

    /// Sign up with email and password
    func signUpWithEmail(email: String, password: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        let username = resolveDisplayName(for: result.user)
        currentUser = User(id: result.user.uid, name: username)
        isAuthenticated = true
    }

    /// Sign in with email and password
    func signInWithEmail(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        let username = resolveDisplayName(for: result.user)
        currentUser = User(id: result.user.uid, name: username)
        isAuthenticated = true
    }
    
    /// Sign out
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    /// Current user's email (from Firebase Auth). Nil for anonymous.
    var currentUserEmail: String? {
        auth.currentUser?.email
    }
    
    /// Generate a random username like "Player 214"
    private func generateRandomUsername() -> String {
        let randomNumber = Int.random(in: 1...999)
        return "Player \(randomNumber)"
    }

    private func resolveDisplayName(for firebaseUser: FirebaseAuth.User) -> String {
        if let displayName = firebaseUser.displayName, !displayName.isEmpty {
            return displayName
        }
        if let email = firebaseUser.email, let name = email.split(separator: "@").first {
            return String(name)
        }
        return generateRandomUsername()
    }
}

