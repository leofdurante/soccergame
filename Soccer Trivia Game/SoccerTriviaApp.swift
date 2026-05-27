import SwiftUI
import FirebaseCore

#if !SOCCERHOLIC
@main
#endif
struct SoccerTriviaApp: App {
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService()
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
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

