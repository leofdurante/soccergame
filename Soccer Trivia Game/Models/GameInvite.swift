import Foundation
import FirebaseFirestore

enum GameInviteStatus: String, Codable {
    case pending
    case accepted
    case declined
    case expired
    case cancelled
}

struct GameInvite: Identifiable, Codable {
    @DocumentID var id: String?
    var roomCode: String
    var fromUid: String
    var toUid: String
    var status: GameInviteStatus
    var createdAt: Date
    var expiresAt: Date
    var updatedAt: Date
}

