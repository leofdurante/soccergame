import Foundation
import FirebaseFirestore

enum FriendRequestStatus: String, Codable {
    case pending
    case accepted
    case declined
    case cancelled
}

struct FriendRequest: Identifiable, Codable {
    @DocumentID var id: String?
    var fromUid: String
    var toUid: String
    var status: FriendRequestStatus
    var createdAt: Date
    var updatedAt: Date
}

