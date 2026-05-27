import Foundation

/// Represents a player in the game
struct User: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var score: Int
    
    init(id: String, name: String, score: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
    }
}

