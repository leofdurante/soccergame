import Foundation
import FirebaseFirestore

/// A question flagged by a user as wrong or containing an error. Stored in Firestore for admin review.
struct FlaggedQuestion: Identifiable, Codable {
    var questionId: String
    var questionText: String
    var options: [String]
    var correctAnswerIndex: Int
    var questionType: String
    var mode: String
    var userId: String
    var userDisplayName: String
    var reason: String?
    var createdAt: Date
    /// Set when loading from Firestore (document ID).
    var firestoreId: String?

    var id: String { firestoreId ?? (questionId + "_" + userId) }

    init(
        questionId: String,
        questionText: String,
        options: [String],
        correctAnswerIndex: Int,
        questionType: String,
        mode: String,
        userId: String,
        userDisplayName: String,
        reason: String? = nil,
        createdAt: Date = Date(),
        firestoreId: String? = nil
    ) {
        self.firestoreId = firestoreId
        self.questionId = questionId
        self.questionText = questionText
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
        self.questionType = questionType
        self.mode = mode
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.reason = reason
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        questionId = try c.decode(String.self, forKey: .questionId)
        questionText = try c.decode(String.self, forKey: .questionText)
        options = try c.decode([String].self, forKey: .options)
        correctAnswerIndex = try c.decode(Int.self, forKey: .correctAnswerIndex)
        questionType = try c.decode(String.self, forKey: .questionType)
        mode = try c.decode(String.self, forKey: .mode)
        userId = try c.decode(String.self, forKey: .userId)
        userDisplayName = try c.decode(String.self, forKey: .userDisplayName)
        reason = try c.decodeIfPresent(String.self, forKey: .reason)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        firestoreId = nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(questionId, forKey: .questionId)
        try c.encode(questionText, forKey: .questionText)
        try c.encode(options, forKey: .options)
        try c.encode(correctAnswerIndex, forKey: .correctAnswerIndex)
        try c.encode(questionType, forKey: .questionType)
        try c.encode(mode, forKey: .mode)
        try c.encode(userId, forKey: .userId)
        try c.encode(userDisplayName, forKey: .userDisplayName)
        try c.encodeIfPresent(reason, forKey: .reason)
        try c.encode(createdAt, forKey: .createdAt)
    }

    enum CodingKeys: String, CodingKey {
        case questionId
        case questionText
        case options
        case correctAnswerIndex
        case questionType
        case mode
        case userId
        case userDisplayName
        case reason
        case createdAt
    }
}
