import Foundation

/// Represents the play type (Multiplayer or Local)
enum PlayType: String, Identifiable, CaseIterable {
    case multiplayer = "multiplayer"
    case local = "local"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .multiplayer:
            return "Multiplayer"
        case .local:
            return "Local"
        }
    }
    
    var icon: String {
        switch self {
        case .multiplayer:
            return "person.2.fill"
        case .local:
            return "iphone"
        }
    }
}

