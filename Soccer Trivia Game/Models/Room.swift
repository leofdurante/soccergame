import Foundation
import FirebaseFirestore

/// Represents a game room
struct Room: Identifiable, Codable {
    @DocumentID var id: String?
    var roomCode: String
    var state: GameState
    var hostId: String
    var players: [User]
    /// Denormalized member list for Firestore rules (rules can't iterate object arrays reliably).
    var playerIds: [String]
    var currentQuestionIndex: Int
    var answers: [String: Int] // userId: selectedAnswerIndex
    var difficulty: String? // easy, medium, hard
    var questionCount: Int? // 10, 15, 20 for Fanaticos
    var rematchConfirmations: [String: Bool]? // userId: ready
    var rematchRequestedAt: Date?
    var roundStartedAt: Date?
    var roundDeadlineAt: Date?
    var createdAt: Date
    
    init(
        id: String? = nil,
        roomCode: String,
        state: GameState = .lobby,
        hostId: String,
        players: [User] = [],
        playerIds: [String] = [],
        currentQuestionIndex: Int = 0,
        answers: [String: Int] = [:],
        difficulty: String? = nil,
        questionCount: Int? = 10,
        rematchConfirmations: [String: Bool]? = [:],
        rematchRequestedAt: Date? = nil,
        roundStartedAt: Date? = nil,
        roundDeadlineAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.roomCode = roomCode
        self.state = state
        self.hostId = hostId
        self.players = players
        self.playerIds = playerIds.isEmpty ? players.map(\.id) : playerIds
        self.currentQuestionIndex = currentQuestionIndex
        self.answers = answers
        self.difficulty = difficulty
        self.questionCount = questionCount
        self.rematchConfirmations = rematchConfirmations
        self.rematchRequestedAt = rematchRequestedAt
        self.roundStartedAt = roundStartedAt
        self.roundDeadlineAt = roundDeadlineAt
        self.createdAt = createdAt
    }
}

extension Room {
    /// Effective question count with safe defaults and allowed values.
    var resolvedQuestionCount: Int {
        guard let questionCount else { return 10 }
        return [10, 15, 20].contains(questionCount) ? questionCount : 10
    }
    
    /// Returns the host user
    var host: User? {
        players.first { $0.id == hostId }
    }
    
    /// Returns players sorted by score (descending)
    var leaderboard: [User] {
        players.sorted { $0.score > $1.score }
    }
    
    /// Returns the winner (player with highest score)
    var winner: User? {
        leaderboard.first
    }
    
    /// Number of players currently marked ready for rematch.
    var rematchReadyCount: Int {
        let confirmations = rematchConfirmations ?? [:]
        return players.filter { confirmations[$0.id] == true }.count
    }
    
    /// True only when all current players are ready for rematch.
    var allPlayersReadyForRematch: Bool {
        guard !players.isEmpty else { return false }
        return rematchReadyCount == players.count
    }
}

