import Foundation
import SwiftUI

/// Represents a trivia question
struct Question: Identifiable, Codable {
    enum QuestionType: String, Codable {
        case multipleChoice = "multiple_choice"
        case lineup = "lineup"
        case logoPartial = "logo_partial"
        case guessPlayer = "guess_player"
    }
    
    struct LineupPayload: Codable {
        let teamName: String
        let formation: String
        let missingPlayers: [String]
        let options: [String]
    }
    
    struct LogoPayload: Codable {
        struct MaskRect: Codable {
            let x: Double
            let y: Double
            let width: Double
            let height: Double
        }
        
        let teamName: String
        let imageAssetName: String?
        let imageURL: String?
        let maskRects: [MaskRect]
    }
    
    struct GuessPlayerPayload: Codable {
        struct Canonical: Codable {
            let first: String
            let last: String
        }
        
        struct Constraints: Codable {
            let minChars: Int
            let allowSingleToken: Bool
        }
        
        let imageURL: String
        let canonical: Canonical
        let aliases: [String]
        let constraints: Constraints
    }
    
    let id: String
    let type: QuestionType
    let text: String
    let options: [String]
    let correctAnswer: Int // Index of correct answer (0-based)
    let category: String
    let difficulty: String? // easy, medium, hard
    let lineup: LineupPayload?
    let logo: LogoPayload?
    let guessPlayer: GuessPlayerPayload?
    
    init(
        id: String = UUID().uuidString,
        type: QuestionType = .multipleChoice,
        text: String,
        options: [String],
        correctAnswer: Int,
        category: String = "Soccer",
        difficulty: String? = nil,
        lineup: LineupPayload? = nil,
        logo: LogoPayload? = nil,
        guessPlayer: GuessPlayerPayload? = nil
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.options = options
        self.correctAnswer = correctAnswer
        self.category = category
        self.difficulty = difficulty
        self.lineup = lineup
        self.logo = logo
        self.guessPlayer = guessPlayer
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case text
        case options
        case correctAnswer
        case category
        case difficulty
        case lineup
        case logo
        case guessPlayer
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        type = try container.decodeIfPresent(QuestionType.self, forKey: .type) ?? .multipleChoice
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        options = try container.decodeIfPresent([String].self, forKey: .options) ?? []
        correctAnswer = try container.decodeIfPresent(Int.self, forKey: .correctAnswer) ?? 0
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Soccer"
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        lineup = try container.decodeIfPresent(LineupPayload.self, forKey: .lineup)
        logo = try container.decodeIfPresent(LogoPayload.self, forKey: .logo)
        guessPlayer = try container.decodeIfPresent(GuessPlayerPayload.self, forKey: .guessPlayer)
    }
    
    /// Decodes an array of questions from JSON data, skipping any element that fails to decode.
    /// Use this when the JSON may contain invalid entries (e.g. type mismatch at one index).
    static func decodeResilient(from data: Data) -> [Question] {
        guard let array = try? JSONSerialization.jsonObject(with: data) as? [Any] else { return [] }
        let decoder = JSONDecoder()
        var result: [Question] = []
        for item in array {
            guard let dict = item as? [String: Any],
                  let itemData = try? JSONSerialization.data(withJSONObject: dict),
                  let q = try? decoder.decode(Question.self, from: itemData) else { continue }
            result.append(q)
        }
        return result
    }
}

/// Difficulty levels for questions
enum Difficulty: String, CaseIterable, Identifiable {
    case random = "random"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .random: return "Random"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    
    var color: Color {
        switch self {
        case .random: return .purple
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    static var selectableCases: [Difficulty] {
        [.random, .easy, .medium, .hard]
    }
}

