import SwiftUI
import FirebaseCore

#if SOCCERHOLIC
@main
#endif
struct SoccerholicApp: App {
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService()
    
    init() {
        // Initialize Firebase
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: path) {
            // Override bundle ID if needed
            if let currentBundleId = Bundle.main.bundleIdentifier {
                options.bundleID = currentBundleId
                print("📦 Using Bundle ID: \(currentBundleId)")
            }
            FirebaseApp.configure(options: options)
            print("✅ Firebase initialized with GoogleService-Info.plist")
        } else {
            // Fallback: try default configuration
            print("⚠️ GoogleService-Info.plist not found, trying default Firebase configuration")
            FirebaseApp.configure()
            print("✅ Firebase initialized with default configuration")
        }
        print("📦 Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        
        // Verify Firebase is ready
        if FirebaseApp.app() == nil {
            fatalError("❌ Firebase failed to initialize!")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView(authViewModel: AuthViewModel(authService: authService))
                .task {
                    PushNotificationService.shared.configure(authService: authService)
                }
        }
    }
}
