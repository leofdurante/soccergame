import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore

/// Service for handling Firestore operations
@MainActor
class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    private let roomsCollection = "rooms"
    private let invitesCollection = "game_invites"
    private let functionsRegion = "us-central1"
    
    /// Generate a random room code (4-6 digits)
    func generateRoomCode() -> String {
        let length = Int.random(in: 4...6)
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let code = (0..<length).map { _ in String(alphabet[Int.random(in: 0..<alphabet.count)]) }
        return code.joined()
    }
    
    /// Create a new room
    func createRoom(hostId: String, hostName: String, difficulty: String, questionCount: Int = 10) async throws -> String {
        let roomCode = generateRoomCode()
        let host = User(id: hostId, name: hostName)
        
        let room = Room(
            roomCode: roomCode,
            state: .lobby,
            hostId: hostId,
            players: [host],
            playerIds: [hostId],
            difficulty: difficulty,
            questionCount: questionCount
        )
        
        let roomRef = db.collection(roomsCollection).document(roomCode)
        try roomRef.setData(from: room)
        
        return roomCode
    }
    
    /// Join an existing room
    func joinRoom(roomCode: String, userId: String, userName: String) async throws {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        
        return try await withCheckedThrowingContinuation { continuation in
            roomRef.getDocument { document, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let document = document, document.exists else {
                    continuation.resume(throwing: FirestoreError.roomNotFound)
                    return
                }
                
                Task { @MainActor in
                    guard var room = try? document.data(as: Room.self) else {
                        continuation.resume(throwing: FirestoreError.roomNotFound)
                        return
                    }
                    
                    // Check if player already exists
                    if room.players.contains(where: { $0.id == userId }) {
                        continuation.resume()
                        return
                    }
                    
                    // Add new player
                    let newPlayer = User(id: userId, name: userName)
                    room.players.append(newPlayer)
                    room.playerIds = Array(Set(room.players.map(\.id))).sorted()
                    
                    do {
                        try roomRef.setData(from: room, merge: true)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Fetch room document once (e.g. after join so UI can show lobby immediately).
    func getRoom(roomCode: String) async throws -> Room {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        let snapshot = try await roomRef.getDocument()
        guard snapshot.exists else { throw FirestoreError.roomNotFound }
        return try snapshot.data(as: Room.self)
    }

    /// Listen to room changes in real-time
    func observeRoom(roomCode: String, completion: @escaping (Result<Room, Error>) -> Void) -> ListenerRegistration {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        
        return roomRef.addSnapshotListener { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                completion(.failure(FirestoreError.roomNotFound))
                return
            }
            
            do {
                let room = try document.data(as: Room.self)
                completion(.success(room))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Update room state. When transitioning to inGame, pass roundDurationSeconds to set first-question round timing (Spark fallback).
    func updateRoomState(roomCode: String, state: GameState, roundDurationSeconds: Int? = nil) async throws {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        var payload: [String: Any] = ["state": state.rawValue]
        if state == .results {
            payload["rematchConfirmations"] = [:]
            payload["rematchRequestedAt"] = FieldValue.delete()
        }
        if state == .inGame {
            let duration = roundDurationSeconds ?? GameConstants.questionTimeSeconds
            let now = Date()
            payload["roundStartedAt"] = Timestamp(date: now)
            payload["roundDeadlineAt"] = Timestamp(date: now.addingTimeInterval(TimeInterval(duration)))
        }
        try await roomRef.updateData(payload)
    }
    
    /// Update selected question count for Fanaticos room.
    func updateQuestionCount(roomCode: String, questionCount: Int) async throws {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        try await roomRef.updateData(["questionCount": questionCount])
    }
    
    /// Update player score
    func updatePlayerScore(roomCode: String, userId: String, score: Int) async throws {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        
        return try await withCheckedThrowingContinuation { continuation in
            roomRef.getDocument { document, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let document = document else {
                    continuation.resume(throwing: FirestoreError.roomNotFound)
                    return
                }
                
                Task { @MainActor in
                    guard var room = try? document.data(as: Room.self) else {
                        continuation.resume(throwing: FirestoreError.roomNotFound)
                        return
                    }
                    
                    // Update player score
                    if let index = room.players.firstIndex(where: { $0.id == userId }) {
                        room.players[index].score = score
                    }
                    
                    do {
                        try roomRef.setData(from: room, merge: true)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Submit answer for current question
    func submitAnswer(roomCode: String, userId: String, answerIndex: Int) async throws {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        try await roomRef.updateData([
            "answers.\(userId)": answerIndex
        ])
    }
    
    /// Update current question index
    func updateQuestionIndex(roomCode: String, index: Int) async throws {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        try await roomRef.updateData([
            "currentQuestionIndex": index,
            "answers": [:] // Clear answers for new question
        ])
    }
    
    /// Mark/unmark a player's rematch readiness in results.
    func setRematchConfirmation(roomCode: String, userId: String, isReady: Bool) async throws {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        var payload: [String: Any] = [
            "rematchRequestedAt": Timestamp(date: Date())
        ]
        if isReady {
            payload["rematchConfirmations.\(userId)"] = true
        } else {
            payload["rematchConfirmations.\(userId)"] = FieldValue.delete()
        }
        try await roomRef.updateData(payload)
    }
    
    /// Clear rematch state for the room.
    func clearRematchState(roomCode: String) async throws {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        try await roomRef.updateData([
            "rematchConfirmations": [:],
            "rematchRequestedAt": FieldValue.delete()
        ])
    }
    
    /// Host starts rematch only when all current players are ready.
    @discardableResult
    func startRematchIfAllConfirmed(roomCode: String, hostId: String) async throws -> Bool {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        let snapshot = try await roomRef.getDocument()
        guard snapshot.exists else { throw FirestoreError.roomNotFound }
        guard var room = try? snapshot.data(as: Room.self) else {
            throw FirestoreError.roomNotFound
        }
        
        guard room.hostId == hostId else { return false }
        guard room.state == .results else { return false }
        guard room.allPlayersReadyForRematch else { return false }
        
        room.state = .lobby
        room.currentQuestionIndex = 0
        room.answers = [:]
        room.rematchConfirmations = [:]
        room.rematchRequestedAt = nil
        room.players = room.players.map { User(id: $0.id, name: $0.name, score: 0) }
        room.playerIds = Array(Set(room.players.map(\.id))).sorted()
        
        try roomRef.setData(from: room, merge: true)
        return true
    }
    
    /// Remove a player from a room. If only one player remains during an active game, end the game.
    func leaveRoom(roomCode: String, userId: String) async throws {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        let snapshot = try await roomRef.getDocument()
        guard snapshot.exists else { return }
        
        guard var room = try? snapshot.data(as: Room.self) else {
            throw FirestoreError.roomNotFound
        }
        
        room.players.removeAll { $0.id == userId }
        room.playerIds = Array(Set(room.players.map(\.id))).sorted()
        room.answers.removeValue(forKey: userId)
        if room.rematchConfirmations == nil { room.rematchConfirmations = [:] }
        room.rematchConfirmations?.removeValue(forKey: userId)
        
        // If room empties out, remove document.
        if room.players.isEmpty {
            try await roomRef.delete()
            return
        }
        
        // Reassign host if needed.
        if room.hostId == userId, let newHost = room.players.first {
            room.hostId = newHost.id
        }
        
        // If game is active and one (or zero) player remains, end game for remaining player.
        if room.state == .inGame && room.players.count <= 1 {
            room.state = .results
            room.answers = [:]
            room.rematchConfirmations = [:]
            room.rematchRequestedAt = nil
        }
        
        try roomRef.setData(from: room, merge: true)
    }

    // MARK: - Game invites

    /// Host sends game invite to a friend.
    func sendGameInvite(roomCode: String, fromUid: String, toUid: String, expiresInSeconds: TimeInterval = 600) async throws {
        guard fromUid != toUid else { return }
        let invitesRef = db.collection(invitesCollection)

        let existing = try await invitesRef
            .whereField("roomCode", isEqualTo: roomCode)
            .whereField("fromUid", isEqualTo: fromUid)
            .whereField("toUid", isEqualTo: toUid)
            .whereField("status", isEqualTo: GameInviteStatus.pending.rawValue)
            .limit(to: 1)
            .getDocuments()
        if !existing.documents.isEmpty { return }

        let now = Date()
        let invite = GameInvite(
            roomCode: roomCode,
            fromUid: fromUid,
            toUid: toUid,
            status: .pending,
            createdAt: now,
            expiresAt: now.addingTimeInterval(expiresInSeconds),
            updatedAt: now
        )
        _ = try invitesRef.addDocument(from: invite)
    }

    func observeIncomingGameInvites(for uid: String, completion: @escaping (Result<[GameInvite], Error>) -> Void) -> ListenerRegistration {
        db.collection(invitesCollection)
            .whereField("toUid", isEqualTo: uid)
            .whereField("status", isEqualTo: GameInviteStatus.pending.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                let now = Date()
                let invites = documents
                    .compactMap { try? $0.data(as: GameInvite.self) }
                    .filter { $0.expiresAt > now }
                    .sorted { $0.createdAt > $1.createdAt }
                completion(.success(invites))
            }
    }

    /// Accept invite and return roomCode for direct join.
    func acceptGameInvite(inviteId: String, currentUid: String) async throws -> String? {
        let inviteRef = db.collection(invitesCollection).document(inviteId)
        let snap = try await inviteRef.getDocument()
        guard snap.exists, var invite = try? snap.data(as: GameInvite.self) else { return nil }
        guard invite.toUid == currentUid, invite.status == .pending else { return nil }

        if invite.expiresAt <= Date() {
            invite.status = .expired
            invite.updatedAt = Date()
            try inviteRef.setData(from: invite, merge: true)
            return nil
        }

        let roomRef = db.collection(roomsCollection).document(invite.roomCode)
        let roomSnap = try await roomRef.getDocument()
        guard roomSnap.exists else {
            invite.status = .expired
            invite.updatedAt = Date()
            try inviteRef.setData(from: invite, merge: true)
            return nil
        }

        invite.status = .accepted
        invite.updatedAt = Date()
        try inviteRef.setData(from: invite, merge: true)
        return invite.roomCode
    }

    func declineGameInvite(inviteId: String, currentUid: String) async throws {
        let inviteRef = db.collection(invitesCollection).document(inviteId)
        let snap = try await inviteRef.getDocument()
        guard snap.exists, var invite = try? snap.data(as: GameInvite.self) else { return }
        guard invite.toUid == currentUid, invite.status == .pending else { return }
        invite.status = .declined
        invite.updatedAt = Date()
        try inviteRef.setData(from: invite, merge: true)
    }

    // MARK: - Authoritative Cloud Functions

    func startGameAuthoritative(roomCode: String, answerKey: [Int], roundDurationSec: Int = GameConstants.questionTimeSeconds) async throws {
        do {
            _ = try await callFunction(
                "startGameAuthoritative",
                data: [
                    "roomCode": roomCode,
                    "answerKey": answerKey,
                    "roundDurationSec": roundDurationSec
                ]
            )
        } catch {
            guard shouldFallbackToClientPath(error) else { throw error }
            // Spark fallback: game is already transitioned to inGame by lobby flow.
            DiagnosticsLogger.shared.logAuth("Fallback to client startGame flow for room \(roomCode).")
        }
    }

    func submitAnswerAuthoritative(roomCode: String, questionIndex: Int, answerIndex: Int) async throws {
        do {
            _ = try await callFunction(
                "submitAnswerAuthoritative",
                data: [
                    "roomCode": roomCode,
                    "questionIndex": questionIndex,
                    "answerIndex": answerIndex
                ]
            )
        } catch {
            guard shouldFallbackToClientPath(error) else { throw error }
            guard let userId = Auth.auth().currentUser?.uid else { throw FirestoreError.unauthenticated }
            DiagnosticsLogger.shared.logAuth("Fallback to client submitAnswer flow for room \(roomCode).")
            try await submitAnswer(roomCode: roomCode, userId: userId, answerIndex: answerIndex)
        }
    }

    @discardableResult
    func advanceRoundIfReadyAuthoritative(roomCode: String, correctAnswerIndex: Int) async throws -> [String: Any] {
        do {
            return try await callFunction("advanceRoundIfReady", data: ["roomCode": roomCode])
        } catch {
            guard shouldFallbackToClientPath(error) else { throw error }
            DiagnosticsLogger.shared.logAuth("Fallback to client advanceRound flow for room \(roomCode).")
            return try await advanceRoundIfReadyLegacy(roomCode: roomCode, correctAnswerIndex: correctAnswerIndex)
        }
    }
    
    /// Last-resort host-only client advance for Spark fallback, used only when authoritative + legacy paths fail.
    func forceAdvanceRoundForHost(roomCode: String, correctAnswerIndex: Int) async throws {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        let snapshot = try await roomRef.getDocument()
        guard snapshot.exists, var room = try? snapshot.data(as: Room.self) else {
            throw FirestoreError.roomNotFound
        }
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.unauthenticated
        }
        guard room.hostId == currentUid, room.state == .inGame else {
            throw FirestoreError.functionCallFailed("forceAdvance only allowed for host in inGame state.")
        }
        
        let now = Date()
        let totalPlayers = room.players.count
        let answeredCount = room.answers.count
        let timedOut = (room.roundDeadlineAt?.timeIntervalSince(now) ?? 1) <= 0
        let shouldAdvance = answeredCount >= totalPlayers || timedOut
        guard shouldAdvance else { return }
        
        room.players = room.players.map { player in
            let answer = room.answers[player.id]
            let nextScore = answer == correctAnswerIndex ? (player.score + 10) : player.score
            return User(id: player.id, name: player.name, score: nextScore)
        }
        
        let nextIndex = room.currentQuestionIndex + 1
        room.answers = [:]
        
        if nextIndex >= room.resolvedQuestionCount {
            room.state = .results
            room.rematchConfirmations = [:]
            room.rematchRequestedAt = nil
            room.roundStartedAt = nil
            room.roundDeadlineAt = nil
        } else {
            room.currentQuestionIndex = nextIndex
            room.roundStartedAt = now
            room.roundDeadlineAt = now.addingTimeInterval(TimeInterval(GameConstants.questionTimeSeconds))
        }
        
        try roomRef.setData(from: room, merge: true)
    }

    @discardableResult
    func startRematchAuthoritative(roomCode: String) async throws -> [String: Any] {
        do {
            return try await callFunction("startRematchAuthoritative", data: ["roomCode": roomCode])
        } catch {
            guard shouldFallbackToClientPath(error) else { throw error }
            guard let hostId = Auth.auth().currentUser?.uid else { throw FirestoreError.unauthenticated }
            let started = try await startRematchIfAllConfirmed(roomCode: roomCode, hostId: hostId)
            if !started {
                throw FirestoreError.functionCallFailed("All players need to be ready to start a new game.")
            }
            DiagnosticsLogger.shared.logAuth("Fallback to client rematch flow for room \(roomCode).")
            return ["ok": true]
        }
    }

    func sendGameInviteAuthoritative(roomCode: String, toUid: String) async throws {
        do {
            _ = try await callFunction(
                "sendGameInviteAuthoritative",
                data: [
                    "roomCode": roomCode,
                    "toUid": toUid
                ]
            )
        } catch {
            guard shouldFallbackToClientPath(error) else { throw error }
            guard let fromUid = Auth.auth().currentUser?.uid else { throw FirestoreError.unauthenticated }
            DiagnosticsLogger.shared.logAuth("Fallback to client sendInvite flow for room \(roomCode).")
            try await sendGameInvite(roomCode: roomCode, fromUid: fromUid, toUid: toUid)
        }
    }

    func acceptGameInviteAuthoritative(inviteId: String) async throws -> String? {
        do {
            let result = try await callFunction(
                "acceptGameInviteAuthoritative",
                data: ["inviteId": inviteId]
            )
            return result["roomCode"] as? String
        } catch {
            guard shouldFallbackToClientPath(error) else { throw error }
            guard let currentUid = Auth.auth().currentUser?.uid else { throw FirestoreError.unauthenticated }
            DiagnosticsLogger.shared.logAuth("Fallback to client acceptInvite flow for invite \(inviteId).")
            return try await acceptGameInvite(inviteId: inviteId, currentUid: currentUid)
        }
    }

    private func callFunction(_ functionName: String, data: [String: Any]) async throws -> [String: Any] {
        guard let user = Auth.auth().currentUser else {
            throw FirestoreError.unauthenticated
        }
        let idToken = try await user.getIDToken()
        guard let projectId = FirebaseApp.app()?.options.projectID else {
            throw FirestoreError.projectNotConfigured
        }
        let endpoint = "https://\(functionsRegion)-\(projectId).cloudfunctions.net/\(functionName)"
        guard let url = URL(string: endpoint) else {
            throw FirestoreError.invalidFunctionURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["data": data], options: [])

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FirestoreError.invalidFunctionResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: responseData, encoding: .utf8) ?? "Unknown function error"
            throw FirestoreError.functionCallFailed(message)
        }

        let object = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        if let error = object?["error"] as? [String: Any] {
            let message = (error["message"] as? String) ?? "Callable function failed"
            throw FirestoreError.functionCallFailed(message)
        }
        return (object?["result"] as? [String: Any]) ?? [:]
    }
    
    private func shouldFallbackToClientPath(_ error: Error) -> Bool {
        if let firestoreError = error as? FirestoreError {
            if case .functionCallFailed(let message) = firestoreError {
                let lower = message.lowercased()
                return lower.contains("404")
                    || lower.contains("not found")
                    || lower.contains("requested entity was not found")
                    || lower.contains("permission")
                    || lower.contains("cloud function")
                    || lower.contains("failed to connect")
                    || lower.contains("network")
            }
            return false
        }
        
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return true
        }
        let description = nsError.localizedDescription.lowercased()
        return description.contains("network")
            || description.contains("timed out")
            || description.contains("could not connect")
    }
    
    private func advanceRoundIfReadyLegacy(roomCode: String, correctAnswerIndex: Int) async throws -> [String: Any] {
        let roomRef = db.collection(roomsCollection).document(roomCode)
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw FirestoreError.unauthenticated
        }
        
        let resultAny = try await db.runTransaction { transaction, errorPointer -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(roomRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return [:]
            }
            
            guard snapshot.exists, var room = try? snapshot.data(as: Room.self) else {
                errorPointer?.pointee = FirestoreError.roomNotFound as NSError
                return [:]
            }
            
            // Legacy fallback is host-driven only.
            guard room.hostId == currentUid,
                  room.players.contains(where: { $0.id == currentUid }) else {
                errorPointer?.pointee = FirestoreError.functionCallFailed("Only the host can advance rounds.") as NSError
                return [:]
            }
            
            guard room.state == .inGame else {
                return ["advanced": false, "state": room.state.rawValue, "index": room.currentQuestionIndex]
            }
            
            let now = Date()
            let totalPlayers = room.players.count
            let answeredCount = room.answers.count
            let timedOut = (room.roundDeadlineAt?.timeIntervalSince(now) ?? 1) <= 0
            let shouldAdvance = answeredCount >= totalPlayers || timedOut
            guard shouldAdvance else {
                return ["advanced": false, "state": room.state.rawValue, "index": room.currentQuestionIndex]
            }
            
            room.players = room.players.map { player in
                let answer = room.answers[player.id]
                let nextScore = answer == correctAnswerIndex ? (player.score + 10) : player.score
                return User(id: player.id, name: player.name, score: nextScore)
            }
            
            let nextIndex = room.currentQuestionIndex + 1
            room.answers = [:]
            
            if nextIndex >= room.resolvedQuestionCount {
                room.state = .results
                room.rematchConfirmations = [:]
                room.rematchRequestedAt = nil
                room.roundStartedAt = nil
                room.roundDeadlineAt = nil
                do {
                    try transaction.setData(from: room, forDocument: roomRef, merge: true)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return [:]
                }
                return ["advanced": true, "state": GameState.results.rawValue, "index": room.currentQuestionIndex]
            }
            
            room.currentQuestionIndex = nextIndex
            room.roundStartedAt = now
            room.roundDeadlineAt = now.addingTimeInterval(TimeInterval(GameConstants.questionTimeSeconds))
            do {
                try transaction.setData(from: room, forDocument: roomRef, merge: true)
            } catch {
                errorPointer?.pointee = error as NSError
                return [:]
            }
            return ["advanced": true, "state": GameState.inGame.rawValue, "index": nextIndex]
        }
        guard let result = resultAny as? [String: Any] else {
            throw FirestoreError.invalidFunctionResponse
        }
        return result
    }
}

enum FirestoreError: LocalizedError {
    case roomNotFound
    case unauthenticated
    case projectNotConfigured
    case invalidFunctionURL
    case invalidFunctionResponse
    case functionCallFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .roomNotFound:
            return "Room not found. Please check the room code."
        case .unauthenticated:
            return "You need to be signed in."
        case .projectNotConfigured:
            return "Firebase project is not configured."
        case .invalidFunctionURL:
            return "Cloud Function URL is invalid."
        case .invalidFunctionResponse:
            return "Invalid response from Cloud Function."
        case .functionCallFailed(let message):
            return "Cloud Function failed: \(message)"
        }
    }
}

