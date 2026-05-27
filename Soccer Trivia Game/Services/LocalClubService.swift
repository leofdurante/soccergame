import Foundation

/// Service to load football clubs from local JSON for Guess the Club Logo mode.
class LocalClubService {
    static let shared = LocalClubService()
    
    private var cachedClubs: [ClubProfile]?
    
    private init() {}
    
    func loadClubs() throws -> [ClubProfile] {
        if let cached = cachedClubs {
            return cached
        }
        guard let url = Bundle.main.url(forResource: "clubs", withExtension: "json") else {
            throw NSError(
                domain: "LocalClubService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "clubs.json not found in bundle. Please ensure the file exists in Resources folder."]
            )
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let clubs = try decoder.decode([ClubProfile].self, from: data)
        cachedClubs = clubs
        print("✅ Loaded \(clubs.count) clubs from local JSON")
        return clubs
    }
    
    /// Only clubs with valid logo (HTTP URL or bundle path like "club-logos/arsenal") and a real display name (not a QID).
    private func validClubs(_ clubs: [ClubProfile]) -> [ClubProfile] {
        clubs.filter { club in
            guard !club.logo.isEmpty else { return false }
            if club.logo.hasPrefix("http") {
                guard let u = URL(string: club.logo), u.scheme != nil, u.host != nil else { return false }
            } else {
                // Bundle path: e.g. "club-logos/arsenal" (no extension; app adds .png)
                guard club.logo.contains("/"), !club.logo.hasPrefix("Q") else { return false }
            }
            let name = club.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard name.count >= 2, name != club.id else { return false }
            if name.uppercased().hasPrefix("Q"), name.dropFirst().allSatisfy(\.isNumber) { return false }
            return true
        }
    }
    
    /// Get random clubs for a game. Only returns clubs with valid logo and real names (no QIDs).
    func getRandomClubs(count: Int = 10, maxPopularity: Int? = nil) -> [ClubProfile] {
        guard var all = try? loadClubs(), !all.isEmpty else { return [] }
        all = validClubs(all)
        if let maxP = maxPopularity {
            all = all.filter { ($0.popularity ?? 2) <= maxP }
        }
        if all.isEmpty { return [] }
        guard all.count >= count else {
            return Array(all.shuffled())
        }
        return Array(all.shuffled().prefix(count))
    }
    
    /// All clubs with valid logo and real name (for wrong-answer options).
    func getAllClubs() -> [ClubProfile] {
        let all = (try? loadClubs()) ?? []
        return validClubs(all)
    }
}
