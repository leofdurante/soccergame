import Foundation
import Combine
import UIKit
import UserNotifications
import FirebaseFirestore

extension Notification.Name {
    static let didReceiveAPNsToken = Notification.Name("didReceiveAPNsToken")
}

@MainActor
final class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    private let profileService = ProfileService.shared
    private let firestoreService = FirestoreService()
    private var authService: AuthService?
    private var authCancellable: AnyCancellable?
    private var tokenObserver: NSObjectProtocol?
    private var friendReqListener: ListenerRegistration?
    private var invitesListener: ListenerRegistration?
    private var seenFriendRequestIds: Set<String> = []
    private var seenInviteIds: Set<String> = []

    private override init() {
        super.init()
    }

    func configure(authService: AuthService) {
        self.authService = authService
        UNUserNotificationCenter.current().delegate = self

        if tokenObserver == nil {
            tokenObserver = NotificationCenter.default.addObserver(
                forName: .didReceiveAPNsToken,
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard let token = note.userInfo?["token"] as? String else { return }
                Task { await self?.persistToken(token) }
            }
        }

        authCancellable = authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                Task { @MainActor in
                    guard let self else { return }
                    self.handleAuthChanged(uid: user?.id)
                }
            }

        requestAuthorizationAndRegister()
    }

    private func requestAuthorizationAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    private func persistToken(_ token: String) async {
        guard let uid = authService?.currentUser?.id else { return }
        try? await profileService.updatePushToken(uid: uid, token: token)
    }

    private func handleAuthChanged(uid: String?) {
        friendReqListener?.remove()
        invitesListener?.remove()
        seenFriendRequestIds = []
        seenInviteIds = []

        guard let uid else { return }
        friendReqListener = profileService.observeIncomingFriendRequests(for: uid) { [weak self] result in
            guard let self else { return }
            if case let .success(requests) = result {
                let ids = Set(requests.compactMap(\.id))
                let newIds = ids.subtracting(self.seenFriendRequestIds)
                if !newIds.isEmpty, !self.seenFriendRequestIds.isEmpty {
                    self.presentLocal(title: "New friend request", body: "Someone sent you a friend request.")
                }
                self.seenFriendRequestIds = ids
            }
        }

        invitesListener = firestoreService.observeIncomingGameInvites(for: uid) { [weak self] result in
            guard let self else { return }
            if case let .success(invites) = result {
                let ids = Set(invites.compactMap(\.id))
                let newIds = ids.subtracting(self.seenInviteIds)
                if !newIds.isEmpty, !self.seenInviteIds.isEmpty {
                    self.presentLocal(title: "New game invite", body: "You got invited to a Soccerholic room.")
                }
                self.seenInviteIds = ids
            }
        }
    }

    private func presentLocal(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

