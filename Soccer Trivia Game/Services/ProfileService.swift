import Foundation
import Combine
import FirebaseFirestore

/// Service for user profiles in Firestore `users/{uid}`. Handles CRUD, unique username, friends, and stats.
@MainActor
class ProfileService: ObservableObject {
    static let shared = ProfileService()
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let usernamesCollection = "usernames"
    private let friendRequestsCollection = "friend_requests"

    private init() {}

    // MARK: - Profile CRUD

    /// Create a new user profile (call after Firebase Auth sign-up). Fails if username is taken.
    func createProfile(uid: String, username: String, email: String, displayName: String) async throws {
        let normalized = normalizeUsername(username)
        guard !normalized.isEmpty else { throw ProfileError.usernameInvalid }
        try await assertUsernameAvailable(username: normalized, excludingUid: nil)

        let now = Date()
        let profile = UserProfile(
            uid: uid,
            username: normalized,
            email: email.lowercased(),
            displayName: displayName.isEmpty ? normalized : displayName,
            homeCountry: nil,
            profileImageURL: nil,
            gamesPlayedFanaticos: 0,
            bestScore: 0,
            winStreak: 0,
            friendIds: [],
            lastPlayedWith: [:],
            isAdmin: false,
            createdAt: now,
            updatedAt: now
        )

        let userRef = db.collection(usersCollection).document(uid)
        try userRef.setData(from: profile)

        let usernameRef = db.collection(usernamesCollection).document(normalized.lowercased())
        try await usernameRef.setData(["uid": uid])
    }

    /// Fetch profile by uid. Returns nil if not found.
    func getProfile(uid: String) async throws -> UserProfile? {
        let ref = db.collection(usersCollection).document(uid)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: UserProfile.self)
    }

    /// Update profile fields. Preserves username uniqueness if username is being changed.
    func updateProfile(uid: String, displayName: String?, homeCountry: String?, profileImageURL: String?, username: String?) async throws {
        let ref = db.collection(usersCollection).document(uid)
        guard var current = try await getProfile(uid: uid) else { throw ProfileError.profileNotFound }

        if let name = displayName { current.displayName = name }
        if let country = homeCountry { current.homeCountry = country }
        if let url = profileImageURL { current.profileImageURL = url }

        if let newUsername = username, !newUsername.isEmpty {
            let normalized = normalizeUsername(newUsername)
            guard !normalized.isEmpty else { throw ProfileError.usernameInvalid }
            try await assertUsernameAvailable(username: normalized, excludingUid: uid)
            let oldNormalized = current.username.lowercased()
            current.username = normalized
            // Remove old usernames doc and add new one (transaction would be better; simple for now)
            if oldNormalized != normalized.lowercased() {
                try await db.collection(usernamesCollection).document(oldNormalized).delete()
            }
            try await db.collection(usernamesCollection).document(normalized.lowercased()).setData(["uid": uid])
        }

        current.updatedAt = Date()
        try ref.setData(from: current, merge: true)
    }

    /// Check if a username is already taken (optionally exclude one uid, e.g. current user when editing).
    func isUsernameTaken(_ username: String, excludingUid: String? = nil) async throws -> Bool {
        let normalized = normalizeUsername(username).lowercased()
        guard !normalized.isEmpty else { return true }
        let ref = db.collection(usernamesCollection).document(normalized)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists, let uid = snapshot.get("uid") as? String else { return false }
        if let exclude = excludingUid, uid == exclude { return false }
        return true
    }

    private func assertUsernameAvailable(username: String, excludingUid: String?) async throws {
        let taken = try await isUsernameTaken(username, excludingUid: excludingUid)
        if taken { throw ProfileError.usernameTaken }
    }

    private func normalizeUsername(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Search (for add friend)

    /// Search users by username (prefix or exact). Excludes current user and already-added friends.
    func searchByUsername(query: String, currentUid: String, friendIds: [String]) async throws -> [UserProfile] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.count >= 2 else { return [] }

        let ref = db.collection(usersCollection)
        // Firestore: query where username >= x and username <= x + "\u{f8ff}"
        let end = normalized + "\u{f8ff}"
        let snapshot = try await ref
            .whereField("username", isGreaterThanOrEqualTo: normalized)
            .whereField("username", isLessThanOrEqualTo: end)
            .limit(to: 20)
            .getDocuments()

        var results: [UserProfile] = []
        for doc in snapshot.documents {
            guard let profile = try? doc.data(as: UserProfile.self),
                  profile.uid != currentUid,
                  !friendIds.contains(profile.uid) else { continue }
            results.append(profile)
        }
        return results
    }

    /// Search user by exact email. Excludes current user and already-added friends.
    func searchByEmail(email: String, currentUid: String, friendIds: [String]) async throws -> [UserProfile] {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.contains("@") else { return [] }

        let snapshot = try await db.collection(usersCollection)
            .whereField("email", isEqualTo: normalized)
            .limit(to: 5)
            .getDocuments()

        var results: [UserProfile] = []
        for doc in snapshot.documents {
            guard let profile = try? doc.data(as: UserProfile.self),
                  profile.uid != currentUid,
                  !friendIds.contains(profile.uid) else { continue }
            results.append(profile)
        }
        return results
    }

    // MARK: - Friends

    /// Add a friend (append to current user's friendIds). Does not require mutual add.
    func addFriend(currentUid: String, friendUid: String) async throws {
        let userRef = db.collection(usersCollection).document(currentUid)
        let snapshot = try await userRef.getDocument()
        guard snapshot.exists, var data = snapshot.data(), var friendIds = data["friendIds"] as? [String] else {
            throw ProfileError.profileNotFound
        }
        if friendIds.contains(friendUid) { return }
        friendIds.append(friendUid)
        data["friendIds"] = friendIds
        data["updatedAt"] = Timestamp(date: Date())
        try await userRef.updateData(data)
    }

    /// Store APNs push token for current user.
    func updatePushToken(uid: String, token: String) async throws {
        try await db.collection(usersCollection).document(uid).setData([
            "pushToken": token,
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }

    // MARK: - Friend requests

    /// Send friend request (from current user to target user).
    func sendFriendRequest(fromUid: String, toUid: String) async throws {
        guard fromUid != toUid else { return }

        if let current = try await getProfile(uid: fromUid), current.friendIds.contains(toUid) {
            return
        }

        let requests = db.collection(friendRequestsCollection)
        let existing = try await requests
            .whereField("fromUid", isEqualTo: fromUid)
            .whereField("toUid", isEqualTo: toUid)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .limit(to: 1)
            .getDocuments()
        if !existing.documents.isEmpty { return }

        let reverse = try await requests
            .whereField("fromUid", isEqualTo: toUid)
            .whereField("toUid", isEqualTo: fromUid)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .limit(to: 1)
            .getDocuments()
        if let doc = reverse.documents.first {
            try await acceptFriendRequest(requestId: doc.documentID, currentUid: fromUid)
            return
        }

        let now = Date()
        let payload = FriendRequest(
            fromUid: fromUid,
            toUid: toUid,
            status: .pending,
            createdAt: now,
            updatedAt: now
        )
        _ = try requests.addDocument(from: payload)
    }

    func observeIncomingFriendRequests(for uid: String, completion: @escaping (Result<[FriendRequest], Error>) -> Void) -> ListenerRegistration {
        db.collection(friendRequestsCollection)
            .whereField("toUid", isEqualTo: uid)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                guard let docs = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                let requests: [FriendRequest] = docs.compactMap { try? $0.data(as: FriendRequest.self) }
                    .sorted(by: { $0.createdAt > $1.createdAt })
                completion(.success(requests))
            }
    }

    func acceptFriendRequest(requestId: String, currentUid: String) async throws {
        let reqRef = db.collection(friendRequestsCollection).document(requestId)
        let snap = try await reqRef.getDocument()
        guard snap.exists, var req = try? snap.data(as: FriendRequest.self) else { return }
        guard req.toUid == currentUid, req.status == .pending else { return }

        req.status = .accepted
        req.updatedAt = Date()
        try reqRef.setData(from: req, merge: true)

        let currentRef = db.collection(usersCollection).document(req.toUid)
        let otherRef = db.collection(usersCollection).document(req.fromUid)
        try await currentRef.updateData([
            "friendIds": FieldValue.arrayUnion([req.fromUid]),
            "updatedAt": Timestamp(date: Date())
        ])
        try await otherRef.updateData([
            "friendIds": FieldValue.arrayUnion([req.toUid]),
            "updatedAt": Timestamp(date: Date())
        ])
    }

    func declineFriendRequest(requestId: String, currentUid: String) async throws {
        let reqRef = db.collection(friendRequestsCollection).document(requestId)
        let snap = try await reqRef.getDocument()
        guard snap.exists, var req = try? snap.data(as: FriendRequest.self) else { return }
        guard req.toUid == currentUid, req.status == .pending else { return }

        req.status = .declined
        req.updatedAt = Date()
        try reqRef.setData(from: req, merge: true)
    }

    /// Remove a friend.
    func removeFriend(currentUid: String, friendUid: String) async throws {
        let userRef = db.collection(usersCollection).document(currentUid)
        let snapshot = try await userRef.getDocument()
        guard snapshot.exists, var data = snapshot.data(), var friendIds = data["friendIds"] as? [String] else {
            throw ProfileError.profileNotFound
        }
        friendIds.removeAll { $0 == friendUid }
        data["friendIds"] = friendIds
        data["updatedAt"] = Timestamp(date: Date())
        try await userRef.updateData(data)
    }

    /// Fetch profiles for multiple uids (e.g. friend list). Missing uids are skipped.
    func getProfiles(uids: [String]) async throws -> [UserProfile] {
        guard !uids.isEmpty else { return [] }
        var results: [UserProfile] = []
        for uid in uids {
            if let profile = try await getProfile(uid: uid) {
                results.append(profile)
            }
        }
        return results
    }

    // MARK: - Stats (after Fanáticos game ends)

    /// Update stats and lastPlayedWith for all participants when a Fanáticos game ends.
    /// participantIds = room.players.map(\.id), scores = room.players.reduce(into:) { $0[$1.id] = $1.score }, winnerId = room.winner?.id
    func updateStatsAfterGame(participantIds: [String], scores: [String: Int], winnerId: String?) async throws {
        let now = Date().timeIntervalSince1970
        for uid in participantIds {
            guard let profile = try await getProfile(uid: uid) else { continue }
            let score = scores[uid] ?? 0
            var newGamesPlayed = profile.gamesPlayedFanaticos + 1
            var newBest = max(profile.bestScore, score)
            var newStreak = profile.winStreak
            if uid == winnerId {
                newStreak += 1
            } else {
                newStreak = 0
            }
            var lastPlayedWith = profile.lastPlayedWith
            for otherId in participantIds where otherId != uid {
                lastPlayedWith[otherId] = now
            }
            try await db.collection(usersCollection).document(uid).updateData([
                "gamesPlayedFanaticos": newGamesPlayed,
                "bestScore": newBest,
                "winStreak": newStreak,
                "lastPlayedWith": lastPlayedWith,
                "updatedAt": Timestamp(date: Date())
            ])
        }
    }
}

enum ProfileError: LocalizedError {
    case usernameTaken
    case usernameInvalid
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .usernameTaken: return "This username is already taken."
        case .usernameInvalid: return "Username is invalid."
        case .profileNotFound: return "Profile not found."
        }
    }
}
