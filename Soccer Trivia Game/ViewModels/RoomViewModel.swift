import Foundation
import Combine
import FirebaseFirestore

/// ViewModel for room management
@MainActor
class RoomViewModel: ObservableObject {
    @Published var room: Room?
    @Published var incomingGameInvites: [GameInvite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isHost = false
    
    private let firestoreService: FirestoreService
    private let profileService = ProfileService.shared
    let authService: AuthService
    private var roomListener: ListenerRegistration?
    private var gameInvitesListener: ListenerRegistration?
    
    init(firestoreService: FirestoreService, authService: AuthService) {
        self.firestoreService = firestoreService
        self.authService = authService
    }
    
    deinit {
        roomListener?.remove()
        gameInvitesListener?.remove()
    }
    
    /// Create a new room
    func createRoom(difficulty: String, questionCount: Int = 10) async {
        guard let userId = authService.currentUser?.id,
              let userName = authService.currentUser?.name else {
            errorMessage = "Not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let roomCode = try await firestoreService.createRoom(
                hostId: userId,
                hostName: userName,
                difficulty: difficulty,
                questionCount: questionCount
            )
            // Set room immediately so the UI can navigate on first tap (listener may not have fired yet).
            let host = User(id: userId, name: userName)
            self.room = Room(
                roomCode: roomCode,
                state: .lobby,
                hostId: userId,
                players: [host],
                currentQuestionIndex: 0,
                answers: [:],
                difficulty: difficulty,
                questionCount: questionCount
            )
            self.isHost = true
            self.isLoading = false
            await observeRoom(roomCode: roomCode)
        } catch {
            errorMessage = "Failed to create room: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Join an existing room
    func joinRoom(roomCode: String) async {
        guard let userId = authService.currentUser?.id,
              let userName = authService.currentUser?.name else {
            errorMessage = "Not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await firestoreService.joinRoom(roomCode: roomCode, userId: userId, userName: userName)
            let room = try await firestoreService.getRoom(roomCode: roomCode)
            self.room = room
            self.isHost = room.hostId == userId
            self.isLoading = false
            await observeRoom(roomCode: roomCode)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    /// Start observing room changes
    private func observeRoom(roomCode: String) async {
        roomListener?.remove()
        
        roomListener = firestoreService.observeRoom(roomCode: roomCode) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let room):
                    self?.room = room
                    self?.isHost = room.hostId == self?.authService.currentUser?.id
                    self?.isLoading = false
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
            }
        }
    }
    
    /// Start the game
    func startGame() async {
        guard canStartGame, let roomCode = room?.roomCode else { return }
        
        isLoading = true
        do {
            try? await firestoreService.clearRematchState(roomCode: roomCode)
            try await firestoreService.updateRoomState(roomCode: roomCode, state: .inGame, roundDurationSeconds: GameConstants.questionTimeSeconds)
        } catch {
            errorMessage = "Failed to start game: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    var canStartGame: Bool {
        guard isHost, !isLoading, let room else { return false }
        return room.state == .lobby && room.players.count >= 2
    }
    
    /// Host-only update for selected Fanaticos question count.
    func updateQuestionCount(_ questionCount: Int) async {
        guard isHost,
              [10, 15, 20].contains(questionCount),
              room?.state == .lobby,
              let roomCode = room?.roomCode else { return }
        
        // Optimistic local update so host UI reflects selection instantly.
        room?.questionCount = questionCount
        
        do {
            try await firestoreService.updateQuestionCount(roomCode: roomCode, questionCount: questionCount)
        } catch {
            errorMessage = "Failed to update question count: \(error.localizedDescription)"
        }
    }
    
    /// Leave the room
    func leaveRoom() {
        roomListener?.remove()
        roomListener = nil
        room = nil
        isHost = false
    }
    
    /// Leave room in Firestore, then clear local room state.
    func leaveRoomAndSync() async {
        let currentRoomCode = room?.roomCode
        let currentUserId = authService.currentUser?.id
        
        if let currentRoomCode, let currentUserId {
            do {
                try await firestoreService.leaveRoom(roomCode: currentRoomCode, userId: currentUserId)
            } catch {
                // We still clear local state so user can exit the flow.
                errorMessage = "Failed to leave room cleanly: \(error.localizedDescription)"
            }
        }
        
        leaveRoom()
    }
    
    var rematchReadyCount: Int {
        room?.rematchReadyCount ?? 0
    }
    
    var rematchTotalPlayers: Int {
        room?.players.count ?? 0
    }
    
    var allPlayersReadyForRematch: Bool {
        room?.allPlayersReadyForRematch ?? false
    }
    
    var currentUserIsReadyForRematch: Bool {
        guard let userId = authService.currentUser?.id else { return false }
        return (room?.rematchConfirmations ?? [:])[userId] == true
    }
    
    /// Toggle current user's rematch readiness in results.
    func toggleRematchConfirmation() async {
        guard let roomCode = room?.roomCode,
              room?.state == .results,
              let userId = authService.currentUser?.id else { return }
        
        do {
            let nextReady = !currentUserIsReadyForRematch
            try await firestoreService.setRematchConfirmation(roomCode: roomCode, userId: userId, isReady: nextReady)
        } catch {
            errorMessage = "Failed to update rematch readiness: \(error.localizedDescription)"
        }
    }
    
    /// Host starts rematch only when all players are ready.
    func startRematchIfAllConfirmed() async {
        guard let roomCode = room?.roomCode,
              isHost else { return }
        
        do {
            _ = try await firestoreService.startRematchAuthoritative(roomCode: roomCode)
        } catch {
            errorMessage = "Failed to start new game: \(error.localizedDescription)"
        }
    }

    // MARK: - Game Invites

    func observeIncomingGameInvites() {
        guard let userId = authService.currentUser?.id else { return }
        gameInvitesListener?.remove()
        gameInvitesListener = firestoreService.observeIncomingGameInvites(for: userId) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let invites):
                    self?.incomingGameInvites = invites
                case .failure(let error):
                    self?.errorMessage = "Failed to load invites: \(error.localizedDescription)"
                    self?.incomingGameInvites = []
                }
            }
        }
    }

    func sendInvitesToFriends(_ friendUids: [String]) async {
        guard let roomCode = room?.roomCode,
              authService.currentUser?.id != nil else { return }
        for uid in Set(friendUids) {
            do {
                try await firestoreService.sendGameInviteAuthoritative(roomCode: roomCode, toUid: uid)
            } catch {
                errorMessage = "Failed to send invite: \(error.localizedDescription)"
            }
        }
    }

    func acceptGameInvite(_ invite: GameInvite) async {
        guard let inviteId = invite.id,
              authService.currentUser?.id != nil else { return }
        do {
            if let roomCode = try await firestoreService.acceptGameInviteAuthoritative(inviteId: inviteId) {
                await joinRoom(roomCode: roomCode)
            } else {
                errorMessage = "Invite is no longer valid."
            }
        } catch {
            errorMessage = "Failed to accept invite: \(error.localizedDescription)"
        }
    }

    func declineGameInvite(_ invite: GameInvite) async {
        guard let inviteId = invite.id,
              let userId = authService.currentUser?.id else { return }
        do {
            try await firestoreService.declineGameInvite(inviteId: inviteId, currentUid: userId)
        } catch {
            errorMessage = "Failed to decline invite: \(error.localizedDescription)"
        }
    }

    func loadFriendProfiles() async -> [UserProfile] {
        guard let uid = authService.currentUser?.id else { return [] }
        guard let profile = try? await profileService.getProfile(uid: uid) else { return [] }
        return (try? await profileService.getProfiles(uids: profile.friendIds)) ?? []
    }
}

