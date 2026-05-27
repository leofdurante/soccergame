import Foundation
import UIKit

/// Helper responsible for resolving local player images from the app bundle.
enum PlayerImageResolver {
    /// Convert a player name into the same lowercase snake_case format
    /// used by the player image filenames.
    ///
    /// Example:
    /// "Lionel Messi" -> "lionel_messi"
    /// "Luka Modrić"  -> "luka_modri"
    static func baseName(for fullName: String) -> String {
        // Trim spaces and lowercase
        var working = fullName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Remove accents/diacritics so "é" -> "e", "ö" -> "o", etc.
        working = working.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        
        // Replace any character outside [a-z0-9] with underscores
        let mapped = working.map { ch -> Character in
            if ch >= "a" && ch <= "z" { return ch }
            if ch >= "0" && ch <= "9" { return ch }
            return "_"
        }
        
        var result = String(mapped)
        
        // Collapse multiple underscores
        while result.contains("__") {
            result = result.replacingOccurrences(of: "__", with: "_")
        }
        
        // Trim leading/trailing underscores
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        
        return result.isEmpty ? "player" : result
    }
    
    /// Returns the full path for a local image in a Players folder, if it exists.
    static func imagePath(for fullName: String) -> String? {
        let base = baseName(for: fullName)
        
        let exts = ["jpg", "jpeg", "png"]
        
        // Try common subdirectory names for each extension
        for ext in exts {
            if let path = Bundle.main.path(forResource: base, ofType: ext, inDirectory: "images/Players") {
                return path
            }
            if let path = Bundle.main.path(forResource: base, ofType: ext, inDirectory: "Players") {
                return path
            }
            if let path = Bundle.main.path(forResource: base, ofType: ext, inDirectory: "Resources/Players") {
                return path
            }
        }
        
        // Fallback: search all supported image types in bundle and match by filename
        for ext in exts {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                if let match = urls.first(where: { $0.deletingPathExtension().lastPathComponent.lowercased() == base }) {
                    return match.path
                }
            }
        }
        
        return nil
    }
    
    /// Check whether a local image exists for the given player name.
    static func hasImage(for fullName: String) -> Bool {
        imagePath(for: fullName) != nil
    }
    
    /// Load a UIImage for the given player name from the local bundle, if available.
    static func image(for fullName: String) -> UIImage? {
        guard let path = imagePath(for: fullName) else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

