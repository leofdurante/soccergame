import Foundation

/// Player profile for Guess the Player game.
/// Loaded from local players.json (Wikidata-sourced: id = QID, name, photo).
struct PlayerProfile: Codable, Identifiable, Hashable {
    /// Unique id: Wikidata QID string (e.g. "Q615") or legacy numeric string.
    let id: String
    let name: String
    let photo: String
    /// Optional: "wikidata"
    let source: String?
    let wikidataId: String?
    let nationality: String?
    let position: String?
    /// Optional; used with `GuessPlayerValidator` (first + last tokens), not as the sole display name.
    let firstname: String?
    let lastname: String?

    /// Canonical display name for gameplay and image lookup.
    /// Prefer `name` when set — it holds the full string (e.g. from JSON or multi-part filenames like `juan_carlos_garcia`).
    /// `firstname`/`lastname` are only hints for validation; using them alone would drop middle names.
    var fullName: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return trimmedName
        }
        if let firstname = firstname, let lastname = lastname, !firstname.isEmpty, !lastname.isEmpty {
            return "\(firstname) \(lastname)"
        }
        return name
    }

    enum CodingKeys: String, CodingKey {
        case id, name, photo, source, wikidataId, nationality, position, firstname, lastname
    }

    init(
        id: String,
        name: String,
        photo: String,
        source: String? = nil,
        wikidataId: String? = nil,
        nationality: String? = nil,
        position: String? = nil,
        firstname: String? = nil,
        lastname: String? = nil
    ) {
        self.id = id
        self.name = name
        self.photo = photo
        self.source = source
        self.wikidataId = wikidataId
        self.nationality = nationality
        self.position = position
        self.firstname = firstname
        self.lastname = lastname
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Accept id as Int (legacy) or String (Wikidata QID)
        if let intId = try? c.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try c.decode(String.self, forKey: .id)
        }
        name = try c.decode(String.self, forKey: .name)
        photo = try c.decode(String.self, forKey: .photo)
        source = try c.decodeIfPresent(String.self, forKey: .source)
        wikidataId = try c.decodeIfPresent(String.self, forKey: .wikidataId)
        nationality = try c.decodeIfPresent(String.self, forKey: .nationality)
        position = try c.decodeIfPresent(String.self, forKey: .position)
        firstname = try c.decodeIfPresent(String.self, forKey: .firstname)
        lastname = try c.decodeIfPresent(String.self, forKey: .lastname)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(photo, forKey: .photo)
        try c.encodeIfPresent(source, forKey: .source)
        try c.encodeIfPresent(wikidataId, forKey: .wikidataId)
        try c.encodeIfPresent(nationality, forKey: .nationality)
        try c.encodeIfPresent(position, forKey: .position)
        try c.encodeIfPresent(firstname, forKey: .firstname)
        try c.encodeIfPresent(lastname, forKey: .lastname)
    }
}
