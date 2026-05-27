import Foundation
import Combine
import FirebaseAuth

/// ViewModel for authentication
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var errorDetails: String?
    /// True when user is authenticated but has no Firestore profile (needs one-time username setup).
    @Published var needsUsernameSetup = false
    
    let authService: AuthService
    private let profileService = ProfileService.shared
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func emailValidationMessage(_ email: String) -> String? {
        let normalized = normalizeEmail(email)
        guard !normalized.isEmpty else { return "Email is required." }
        guard normalized.contains("@"), normalized.contains(".") else {
            return "Enter a valid email address."
        }
        return nil
    }
    
    func passwordValidationMessage(_ password: String) -> String? {
        let trimmed = password.trimmingCharacters(in: .newlines)
        guard !trimmed.isEmpty else { return "Password is required." }
        guard trimmed.count >= 6 else { return "Password must be at least 6 characters." }
        return nil
    }
    
    func usernameValidationMessage(_ username: String, required: Bool = true) -> String? {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if !required, trimmed.isEmpty { return nil }
        guard !trimmed.isEmpty else { return "Username is required." }
        guard trimmed.count >= 2 else { return "Username must be at least 2 characters." }
        let pattern = "^[a-zA-Z0-9._]+$"
        let matches = trimmed.range(of: pattern, options: .regularExpression) != nil
        guard matches else { return "Use only letters, numbers, dots, and underscores." }
        return nil
    }
    
    func canSubmitAuth(email: String, password: String, username: String, isSignUp: Bool) -> Bool {
        if emailValidationMessage(email) != nil { return false }
        if passwordValidationMessage(password) != nil { return false }
        if isSignUp, usernameValidationMessage(username) != nil { return false }
        return true
    }
    
    /// Sign in anonymously
    func signIn() async {
        isLoading = true
        errorMessage = nil
        errorDetails = nil
        needsUsernameSetup = false
        
        do {
            DiagnosticsLogger.shared.logAuth("Anonymous sign-in started.")
            try await authService.signInAnonymously()
            DiagnosticsLogger.shared.logAuth("Anonymous sign-in succeeded.")
            await checkProfileExists()
        } catch {
            handleAuthError(error, isSignUp: false, operation: "anonymous_sign_in")
        }
        
        isLoading = false
    }

    /// Sign up with email, password, and a unique username. Creates Firestore profile after auth.
    func signUpWithEmail(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = nil
        errorDetails = nil
        needsUsernameSetup = false

        do {
            let normalizedEmail = normalizeEmail(email)
            let trimmedPassword = password.trimmingCharacters(in: .newlines)
            let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
            if let invalid = emailValidationMessage(normalizedEmail)
                ?? passwordValidationMessage(trimmedPassword)
                ?? usernameValidationMessage(trimmed) {
                errorMessage = invalid
                isLoading = false
                return
            }

            // Create auth account first. This avoids Firestore reads while logged out.
            DiagnosticsLogger.shared.logAuth("Email sign-up started. email=\(maskedEmail(normalizedEmail))")
            try await authService.signUpWithEmail(email: normalizedEmail, password: trimmedPassword)
            guard let user = authService.currentUser else { return }
            let displayName = user.name
            let emailValue = authService.currentUserEmail ?? normalizedEmail
            try await profileService.createProfile(uid: user.id, username: trimmed.lowercased(), email: emailValue, displayName: displayName)
            DiagnosticsLogger.shared.logAuth("Email sign-up succeeded. uid=\(user.id)")
            needsUsernameSetup = false
        } catch {
            if let profileError = error as? ProfileError {
                // Account may already be created; keep user in flow to finish username setup.
                needsUsernameSetup = true
                errorMessage = "Your account was created, but profile setup needs one more step. Choose your username to continue."
                errorDetails = "Profile setup failed after auth creation.\nOperation: email_sign_up\nDetail: \(profileError.localizedDescription)"
                DiagnosticsLogger.shared.logAuth("Email sign-up profile error: \(profileError.localizedDescription)")
            } else {
                handleAuthError(error, isSignUp: true, operation: "email_sign_up")
            }
        }

        isLoading = false
    }

    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        errorDetails = nil
        needsUsernameSetup = false

        do {
            let normalizedEmail = normalizeEmail(email)
            let trimmedPassword = password.trimmingCharacters(in: .newlines)
            if let invalid = emailValidationMessage(normalizedEmail) ?? passwordValidationMessage(trimmedPassword) {
                errorMessage = invalid
                isLoading = false
                return
            }
            DiagnosticsLogger.shared.logAuth("Email sign-in started. email=\(maskedEmail(normalizedEmail))")
            try await authService.signInWithEmail(email: normalizedEmail, password: trimmedPassword)
            DiagnosticsLogger.shared.logAuth("Email sign-in succeeded. uid=\(authService.currentUser?.id ?? "unknown")")
            await checkProfileExists()
        } catch {
            handleAuthError(error, isSignUp: false, operation: "email_sign_in")
        }

        isLoading = false
    }

    /// User-friendly message for Firebase Auth and other auth errors.
    static func formattedAuthError(_ error: Error, isSignUp: Bool) -> String {
        let nsError = error as NSError
        let code = (nsError.userInfo[NSUnderlyingErrorKey] as? NSError)?.code ?? nsError.code
        // Firebase Auth error codes (AuthErrorCode)
        switch code {
        case 17009: return "Wrong password. Please try again."
        case 17011: return "No account found with this email. Create an account to sign up."
        case 17006: return "Email/password sign-in is currently unavailable. Please try again later."
        case 17008: return "Please enter a valid email address."
        case 17026: return "Too many attempts. Please try again later."
        case 17010: return "This account has been disabled. Contact support."
        case 17020: return "Network error. Check your connection and try again."
        case 17007: return "This email is already in use. Sign in or use another email."
        case 17034: return "Please enter your email."
        case 17036: return "Please enter a password (at least 6 characters)."
        case 17005: return "Please enter a valid email address."
        default:
            let raw = error.localizedDescription
            if raw.contains("password") || raw.lowercased().contains("invalid") {
                return "Invalid email or password. Please try again."
            }
            if raw.contains("network") || raw.contains("connection") {
                return "Network error. Check your connection and try again."
            }
            return isSignUp ? "Could not create account. Please try again." : "Sign in failed. Please check your email and password."
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            DiagnosticsLogger.shared.logAuth("Sign-out succeeded.")
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            errorDetails = error.localizedDescription
            DiagnosticsLogger.shared.logAuth("Sign-out failed: \(error.localizedDescription)")
        }
    }
    
    var currentUser: User? {
        authService.currentUser
    }
    
    var isAuthenticated: Bool {
        authService.isAuthenticated
    }

    /// Call when authenticated to see if user has a Firestore profile. Sets needsUsernameSetup if not.
    func checkProfileExists() async {
        guard let uid = authService.currentUser?.id else { return }
        do {
            let profile = try await profileService.getProfile(uid: uid)
            needsUsernameSetup = (profile == nil)
            if needsUsernameSetup {
                DiagnosticsLogger.shared.logAuth("Authenticated user missing profile. uid=\(uid)")
            }
        } catch {
            needsUsernameSetup = true
            DiagnosticsLogger.shared.logAuth("Profile existence check failed. uid=\(uid) error=\(error.localizedDescription)")
        }
    }

    /// One-time username setup for users who signed in before profiles existed (or as guest). Creates profile.
    func submitUsernameSetup(username: String) async {
        guard let user = authService.currentUser else { return }
        isLoading = true
        errorMessage = nil
        errorDetails = nil
        do {
            let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
            if let invalid = usernameValidationMessage(trimmed) {
                errorMessage = invalid
                isLoading = false
                return
            }
            if try await profileService.isUsernameTaken(trimmed, excludingUid: nil) {
                errorMessage = "That username is already taken. Try another one."
                isLoading = false
                return
            }
            let email = authService.currentUserEmail ?? ""
            try await profileService.createProfile(uid: user.id, username: trimmed.lowercased(), email: email, displayName: user.name)
            DiagnosticsLogger.shared.logAuth("Username setup succeeded. uid=\(user.id)")
            needsUsernameSetup = false
        } catch {
            errorMessage = "Could not finish your profile setup. Please try again."
            errorDetails = error.localizedDescription
            DiagnosticsLogger.shared.logAuth("Username setup failed: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func handleAuthError(_ error: Error, isSignUp: Bool, operation: String) {
        let nsError = error as NSError
        let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError
        let code = underlying?.code ?? nsError.code
        let domain = underlying?.domain ?? nsError.domain
        let rawDescription = underlying?.localizedDescription ?? nsError.localizedDescription

        let userFacing = Self.formattedAuthError(error, isSignUp: isSignUp)
        errorMessage = "\(userFacing) (code: \(code))"
        errorDetails = """
        Operation: \(operation)
        Code: \(code)
        Domain: \(domain)
        Description: \(rawDescription)
        """

        DiagnosticsLogger.shared.logAuth("\(operation) failed. code=\(code) domain=\(domain) desc=\(rawDescription)")
        print("❌ Auth Error [\(operation)] code=\(code) domain=\(domain) desc=\(rawDescription)")
    }

    private func maskedEmail(_ email: String) -> String {
        let parts = email.split(separator: "@", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return "***" }
        let user = parts[0]
        if user.count <= 2 { return "***@\(parts[1])" }
        let prefix = user.prefix(2)
        return "\(prefix)***@\(parts[1])"
    }
    
    private func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

