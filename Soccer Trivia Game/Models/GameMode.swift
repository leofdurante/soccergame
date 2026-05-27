    import Foundation

/// Represents the different game modes available
enum GameMode: String, Identifiable, CaseIterable {
    case fanaticos = "fanaticos"
    case quiz = "quiz"
    case guessLogo = "guess_logo"
    case guessPlayer = "guess_player"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .fanaticos:
            return "Soccerholic Mode"
        case .quiz:
            return "Quiz Mode"
        case .guessLogo:
            return "Guess the Club Logo"
        case .guessPlayer:
            return "Guess the Player"
        }
    }
    
    var description: String {
        switch self {
        case .fanaticos:
            return "Real-time multiplayer soccer trivia"
        case .quiz:
            return "Classic trivia questions"
        case .guessLogo:
            return "Identify the club from its blurred logo"
        case .guessPlayer:
            return "Identify players from photos"
        }
    }
    
    var icon: String {
        switch self {
        case .fanaticos:
            return "trophy.fill"
        case .quiz:
            return "questionmark.circle.fill"
        case .guessLogo:
            return "shield.fill"
        case .guessPlayer:
            return "person.fill.viewfinder"
        }
    }
}

