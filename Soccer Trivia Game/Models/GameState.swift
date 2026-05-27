import Foundation

/// Represents the current state of a game room
enum GameState: String, Codable {
    case lobby
    case inGame
    case results
}

