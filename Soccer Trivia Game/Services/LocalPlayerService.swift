import Foundation

/// Service to load players for Guess the Player mode using bundled images.
class LocalPlayerService {
    static let shared = LocalPlayerService()
    
    private var cachedPlayers: [PlayerProfile]?

    private init() {}
    
    /// Load all players based on local image files in the app bundle.
    /// Files are expected to be lowercase snake_case versions of the player names
    /// (e.g. `lionel_messi.jpg` or `lionel_messi.png`).
    func loadPlayers() throws -> [PlayerProfile] {
        // Return cached if available
        if let cached = cachedPlayers {
            return cached
        }
        
        // Discover all supported image files in the bundle. Player images live under a `Players` folder
        // (e.g. Resources/Players), but Xcode may flatten groups at build time, so we use
        // a filename-based heuristic: snake_case image files are treated as player photos.
        let exts = ["jpg", "jpeg", "png"]
        var allImageUrls: [URL] = []
        for ext in exts {
            let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            allImageUrls.append(contentsOf: urls)
        }
        print("🔍 Found \(allImageUrls.count) player image candidates in bundle (jpg/jpeg/png)")
        
        let urls = allImageUrls.filter { url in
            let name = url.deletingPathExtension().lastPathComponent
            // Heuristic: player images use snake_case; skip files without an underscore
            return name.contains("_")
        }
        
        guard !urls.isEmpty else {
            throw NSError(
                domain: "LocalPlayerService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No player images found. Ensure your Players folder (with .jpg files) is added to the app target."]
            )
        }
        
        // Map filenames like "lionel_messi.jpg" into PlayerProfile instances
        let players: [PlayerProfile] = urls.compactMap { url in
            let filename = url.deletingPathExtension().lastPathComponent // e.g. "lionel_messi"
            let parts = filename.split(separator: "_")
            guard !parts.isEmpty else { return nil }

            let words = parts.map { part -> String in
                guard let first = part.first else { return "" }
                return String(first).uppercased() + part.dropFirst()
            }.filter { !$0.isEmpty }

            guard !words.isEmpty else { return nil }

            let fullName = words.joined(separator: " ")
            let firstName = words.first
            let lastName = words.count > 1 ? words.last : nil

            return PlayerProfile(
                id: filename,
                name: fullName,
                photo: "", // Not used for local image lookup
                source: "local",
                wikidataId: nil,
                nationality: nil,
                position: nil,
                firstname: firstName,
                lastname: lastName
            )
        }.sorted { $0.fullName < $1.fullName }

        cachedPlayers = players

        print("✅ Loaded \(players.count) players from local images (snake_case JPGs)")
        return players
    }
    
    /// Get random players from local list
    /// - Parameter count: Number of players to return
    /// - Returns: Array of randomly selected PlayerProfile objects
    func getRandomPlayers(count: Int = 10) -> [PlayerProfile] {
        guard let allPlayers = try? loadPlayers(), !allPlayers.isEmpty else {
            print("⚠️ No players available from local images")
            return []
        }

        if allPlayers.count <= count {
            print("ℹ️ Only \(allPlayers.count) players available from local images, returning all.")
            return allPlayers.shuffled()
        }

        return Array(allPlayers.shuffled().prefix(count))
    }
    
    /// Get all players (useful for generating wrong answer options)
    /// - Returns: Array of all PlayerProfile objects
    func getAllPlayers() -> [PlayerProfile] {
        return (try? loadPlayers()) ?? []
    }
}
