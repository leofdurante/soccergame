import Foundation

/// Service for validating player name guesses
struct GuessPlayerValidator {
    
    /// Normalize a string for comparison
    /// - Lowercase
    /// - Remove diacritics (é → e, ñ → n)
    /// - Remove punctuation (replace with spaces)
    /// - Collapse multiple spaces to single space
    /// - Trim whitespace
    static func normalizeString(_ input: String) -> String {
        // Convert to lowercase
        var normalized = input.lowercased()
        
        // Remove diacritics (accents)
        normalized = normalized.folding(options: .diacriticInsensitive, locale: .current)
        
        // Replace punctuation with spaces
        let punctuation = CharacterSet.punctuationCharacters
        normalized = normalized.components(separatedBy: punctuation).joined(separator: " ")
        
        // Replace hyphens and apostrophes with spaces
        normalized = normalized.replacingOccurrences(of: "-", with: " ")
        normalized = normalized.replacingOccurrences(of: "'", with: " ")
        
        // Collapse multiple spaces to single space
        normalized = normalized.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        // Trim whitespace
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Build aliases for a player profile
    /// - Always includes player.name
    /// - If firstname+lastname exist, includes "firstname lastname"
    /// - Includes lastname alone if exists
    /// - Includes firstname alone if exists
    /// - Handles names with "." (e.g., "M. Kanzari" → extracts "Kanzari")
    static func buildAliases(player: PlayerProfile) -> [String] {
        var aliases: Set<String> = []
        
        // Always include the display name
        aliases.insert(player.name)
        
        // Handle firstname and lastname
        if let firstname = player.firstname, !firstname.isEmpty,
           let lastname = player.lastname, !lastname.isEmpty {
            // Full name: "First Last"
            aliases.insert("\(firstname) \(lastname)")
            
            // Last name alone
            aliases.insert(lastname)
            
            // First name alone
            aliases.insert(firstname)
        } else if let lastname = player.lastname, !lastname.isEmpty {
            // Only lastname available
            aliases.insert(lastname)
        } else if let firstname = player.firstname, !firstname.isEmpty {
            // Only firstname available
            aliases.insert(firstname)
        }
        
        // Handle names with "." pattern (e.g., "M. Kanzari")
        // Extract the last name part after the dot
        if player.name.contains(".") {
            let parts = player.name.components(separatedBy: ".")
            if parts.count > 1 {
                // Get the part after the dot and trim
                let afterDot = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !afterDot.isEmpty {
                    // Split by spaces and take the last part (likely the surname)
                    let nameParts = afterDot.components(separatedBy: .whitespaces)
                    if let lastName = nameParts.last, !lastName.isEmpty {
                        aliases.insert(lastName)
                    }
                    // Also include the full part after dot
                    aliases.insert(afterDot)
                }
            }
        }
        
        // Also check if name itself has multiple parts we can extract
        let nameParts = player.name.components(separatedBy: .whitespaces)
        if nameParts.count > 1 {
            // Include last part as potential surname
            if let lastPart = nameParts.last, !lastPart.isEmpty {
                aliases.insert(lastPart)
            }
        }
        
        return Array(aliases)
    }
    
    /// Check if a guess is correct for a given player
    /// - Parameters:
    ///   - input: User's input text
    ///   - player: Player profile to validate against
    /// - Returns: true if guess is correct, false otherwise
    static func isCorrectGuess(input: String, player: PlayerProfile) -> Bool {
        let normalizedInput = normalizeString(input)
        
        // Reject if too short (less than 3 characters after normalization)
        if normalizedInput.count < 3 {
            return false
        }
        
        // Get all aliases for the player
        let aliases = buildAliases(player: player)
        
        // Normalize all aliases
        let normalizedAliases = aliases.map { normalizeString($0) }
        
        // 1. Check exact match against any normalized alias
        if normalizedAliases.contains(normalizedInput) {
            return true
        }
        
        // 2. Token-based matching
        let inputTokens = tokenize(normalizedInput)
        
        // If we have both firstname and lastname, check if input contains both
        if let firstname = player.firstname, !firstname.isEmpty,
           let lastname = player.lastname, !lastname.isEmpty {
            let normalizedFirst = normalizeString(firstname)
            let normalizedLast = normalizeString(lastname)
            
            // Check if input tokens contain both first and last name
            let hasFirst = inputTokens.contains { token in
                token == normalizedFirst || token.contains(normalizedFirst) || normalizedFirst.contains(token)
            }
            let hasLast = inputTokens.contains { token in
                token == normalizedLast || token.contains(normalizedLast) || normalizedLast.contains(token)
            }
            
            if hasFirst && hasLast {
                return true
            }
            
            // Check single token match (if input is a single token)
            if inputTokens.count == 1 {
                let singleToken = inputTokens[0]
                if singleToken == normalizedFirst || singleToken == normalizedLast {
                    return true
                }
            }
        } else if let lastname = player.lastname, !lastname.isEmpty {
            // Only lastname available - check single token match
            let normalizedLast = normalizeString(lastname)
            if inputTokens.count == 1 && inputTokens[0] == normalizedLast {
                return true
            }
        } else if let firstname = player.firstname, !firstname.isEmpty {
            // Only firstname available - check single token match
            let normalizedFirst = normalizeString(firstname)
            if inputTokens.count == 1 && inputTokens[0] == normalizedFirst {
                return true
            }
        }
        
        // Reject substring-only matches (e.g., "ron" for "ronaldo")
        // We've already checked exact matches and token matches above
        return false
    }
    
    /// Tokenize a normalized string into words
    private static func tokenize(_ normalized: String) -> [String] {
        return normalized.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
    }
}

