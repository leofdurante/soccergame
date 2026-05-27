import Foundation

/// Club profile for Guess the Club Logo game.
/// Loaded from local clubs.json (Wikidata-sourced: id = QID, name, logo URL).
struct ClubProfile: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let logo: String
    var source: String?
    /// 1 = very popular (easier), 2 = medium, 3 = less known (harder). Optional; used for difficulty.
    var popularity: Int?
}
