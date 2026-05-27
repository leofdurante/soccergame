import Foundation
import FirebaseFirestore

/// User profile stored in Firestore `users/{uid}`. Used for profile tab, friends, and search.
struct UserProfile: Identifiable, Codable, Equatable {
    var uid: String
    var username: String
    var email: String
    var displayName: String
    var homeCountry: String?
    var profileImageURL: String?
    var gamesPlayedFanaticos: Int
    var bestScore: Int
    var winStreak: Int
    var friendIds: [String]
    /// Map of friendUid -> timestamp (seconds since 1970) for "last game played with"
    var lastPlayedWith: [String: Double]
    var isAdmin: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        uid: String,
        username: String,
        email: String,
        displayName: String,
        homeCountry: String? = nil,
        profileImageURL: String? = nil,
        gamesPlayedFanaticos: Int = 0,
        bestScore: Int = 0,
        winStreak: Int = 0,
        friendIds: [String] = [],
        lastPlayedWith: [String: Double] = [:],
        isAdmin: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.uid = uid
        self.username = username
        self.email = email
        self.displayName = displayName
        self.homeCountry = homeCountry
        self.profileImageURL = profileImageURL
        self.gamesPlayedFanaticos = gamesPlayedFanaticos
        self.bestScore = bestScore
        self.winStreak = winStreak
        self.friendIds = friendIds
        self.lastPlayedWith = lastPlayedWith
        self.isAdmin = isAdmin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var id: String { uid }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uid = try c.decode(String.self, forKey: .uid)
        username = try c.decode(String.self, forKey: .username)
        email = try c.decode(String.self, forKey: .email)
        displayName = try c.decode(String.self, forKey: .displayName)
        homeCountry = try c.decodeIfPresent(String.self, forKey: .homeCountry)
        profileImageURL = try c.decodeIfPresent(String.self, forKey: .profileImageURL)
        gamesPlayedFanaticos = try c.decode(Int.self, forKey: .gamesPlayedFanaticos)
        bestScore = try c.decode(Int.self, forKey: .bestScore)
        winStreak = try c.decode(Int.self, forKey: .winStreak)
        friendIds = try c.decode([String].self, forKey: .friendIds)
        lastPlayedWith = try c.decode([String: Double].self, forKey: .lastPlayedWith)
        isAdmin = try c.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case username
        case email
        case displayName
        case homeCountry
        case profileImageURL
        case gamesPlayedFanaticos
        case bestScore
        case winStreak
        case friendIds
        case lastPlayedWith
        case isAdmin
        case createdAt
        case updatedAt
    }
}
