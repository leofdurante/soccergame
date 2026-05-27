import Foundation
import Combine
import FirebaseFirestore

/// Service for submitting and listing flagged questions (admin).
@MainActor
class FlagService: ObservableObject {
    static let shared = FlagService()
    private let db = Firestore.firestore()
    private let collectionName = "flagged_questions"

    private init() {}

    /// Submit a flagged question. Call from any game mode when user taps "Flag".
    func submitFlag(
        questionId: String,
        questionText: String,
        options: [String],
        correctAnswerIndex: Int,
        questionType: String,
        mode: String,
        userId: String,
        userDisplayName: String,
        reason: String? = nil
    ) async throws {
        let flag = FlaggedQuestion(
            questionId: questionId,
            questionText: questionText,
            options: options,
            correctAnswerIndex: correctAnswerIndex,
            questionType: questionType,
            mode: mode,
            userId: userId,
            userDisplayName: userDisplayName,
            reason: reason,
            createdAt: Date()
        )
        let ref = db.collection(collectionName).document()
        try ref.setData(from: flag)
    }

    /// List all flagged questions (for admin). Ordered by createdAt descending.
    func listFlaggedQuestions() async throws -> [FlaggedQuestion] {
        let snapshot = try await db.collection(collectionName)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()
        var list: [FlaggedQuestion] = []
        for doc in snapshot.documents {
            if var flag = try? doc.data(as: FlaggedQuestion.self) {
                flag.firestoreId = doc.documentID
                list.append(flag)
            }
        }
        return list
    }
}
