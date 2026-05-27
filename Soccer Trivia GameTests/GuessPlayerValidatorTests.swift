//
//  GuessPlayerValidatorTests.swift
//  Soccer Trivia GameTests
//
//  Created for Guess the Player mode validation testing
//

import Testing
@testable import Soccer_Trivia_Game

struct GuessPlayerValidatorTests {
    
    // MARK: - Normalization Tests
    
    @Test("Normalize string removes accents")
    func testNormalizeRemovesAccents() {
        let input = "Mbappé"
        let result = GuessPlayerValidator.normalizeString(input)
        #expect(result == "mbappe")
    }
    
    @Test("Normalize string handles punctuation")
    func testNormalizeHandlesPunctuation() {
        let input = "O'Brien"
        let result = GuessPlayerValidator.normalizeString(input)
        #expect(result == "obrien")
    }
    
    @Test("Normalize string collapses spaces")
    func testNormalizeCollapsesSpaces() {
        let input = "  Kylian   Mbappé  "
        let result = GuessPlayerValidator.normalizeString(input)
        #expect(result == "kylian mbappe")
    }
    
    @Test("Normalize string handles names with dots")
    func testNormalizeHandlesDots() {
        let input = "M. Kanzari"
        let result = GuessPlayerValidator.normalizeString(input)
        #expect(result == "m kanzari")
    }
    
    @Test("Normalize string is case insensitive")
    func testNormalizeCaseInsensitive() {
        let input1 = "KYLIAN MBAPPE"
        let input2 = "kylian mbappe"
        let result1 = GuessPlayerValidator.normalizeString(input1)
        let result2 = GuessPlayerValidator.normalizeString(input2)
        #expect(result1 == result2)
    }
    
    // MARK: - Alias Generation Tests
    
    @Test("Build aliases includes full name")
    func testBuildAliasesIncludesFullName() {
        let player = PlayerProfile(
            id: "1",
            name: "Kylian Mbappé",
            photo: "",
            firstname: "Kylian",
            lastname: "Mbappé"
        )
        
        let aliases = GuessPlayerValidator.buildAliases(player: player)
        #expect(aliases.contains("Kylian Mbappé"))
        #expect(aliases.contains("Kylian"))
        #expect(aliases.contains("Mbappé"))
    }
    
    @Test("Build aliases handles names with dots")
    func testBuildAliasesHandlesDots() {
        let player = PlayerProfile(
            id: "1",
            name: "M. Kanzari",
            photo: "",
            firstname: nil,
            lastname: "Kanzari"
        )
        
        let aliases = GuessPlayerValidator.buildAliases(player: player)
        #expect(aliases.contains("M. Kanzari"))
        #expect(aliases.contains("Kanzari"))
    }
    
    @Test("Build aliases handles missing firstname")
    func testBuildAliasesHandlesMissingFirstname() {
        let player = PlayerProfile(
            id: "1",
            name: "Mbappé",
            photo: "",
            firstname: nil,
            lastname: "Mbappé"
        )
        
        let aliases = GuessPlayerValidator.buildAliases(player: player)
        #expect(aliases.contains("Mbappé"))
        #expect(aliases.count >= 1)
    }
    
    // MARK: - Validation Tests
    
    @Test("Correct guess with full name")
    func testCorrectGuessFullName() {
        let player = PlayerProfile(
            id: "276",
            name: "Kylian Mbappé",
            photo: "",
            firstname: "Kylian",
            lastname: "Mbappé"
        )
        
        #expect(GuessPlayerValidator.isCorrectGuess(input: "Kylian Mbappé", player: player) == true)
        #expect(GuessPlayerValidator.isCorrectGuess(input: "kylian mbappe", player: player) == true)
        #expect(GuessPlayerValidator.isCorrectGuess(input: "Mbappé Kylian", player: player) == true)
    }
    
    @Test("Correct guess with last name only")
    func testCorrectGuessLastNameOnly() {
        let player = PlayerProfile(
            id: "276",
            name: "Kylian Mbappé",
            photo: "",
            firstname: "Kylian",
            lastname: "Mbappé"
        )
        
        #expect(GuessPlayerValidator.isCorrectGuess(input: "Mbappé", player: player) == true)
        #expect(GuessPlayerValidator.isCorrectGuess(input: "mbappe", player: player) == true)
    }
    
    @Test("Correct guess with first name only")
    func testCorrectGuessFirstNameOnly() {
        let player = PlayerProfile(
            id: "276",
            name: "Kylian Mbappé",
            photo: "",
            firstname: "Kylian",
            lastname: "Mbappé"
        )
        
        #expect(GuessPlayerValidator.isCorrectGuess(input: "Kylian", player: player) == true)
    }
    
    @Test("Reject substring matches")
    func testRejectSubstringMatches() {
        let player = PlayerProfile(
            id: "1",
            name: "Ronaldo",
            photo: "",
            firstname: "Cristiano",
            lastname: "Ronaldo"
        )
        
        // "ron" should NOT match "ronaldo" (substring only)
        #expect(GuessPlayerValidator.isCorrectGuess(input: "ron", player: player) == false)
    }
    
    @Test("Reject too short inputs")
    func testRejectTooShortInputs() {
        let player = PlayerProfile(
            id: "1",
            name: "Kylian Mbappé",
            photo: "",
            firstname: "Kylian",
            lastname: "Mbappé"
        )
        
        #expect(GuessPlayerValidator.isCorrectGuess(input: "ab", player: player) == false)
        #expect(GuessPlayerValidator.isCorrectGuess(input: "", player: player) == false)
    }
    
    @Test("Correct guess with name containing dots")
    func testCorrectGuessWithDots() {
        let player = PlayerProfile(
            id: "1",
            name: "M. Kanzari",
            photo: "",
            firstname: nil,
            lastname: "Kanzari"
        )
        
        #expect(GuessPlayerValidator.isCorrectGuess(input: "Kanzari", player: player) == true)
        #expect(GuessPlayerValidator.isCorrectGuess(input: "M. Kanzari", player: player) == true)
    }
    
    @Test("Correct guess accent insensitive")
    func testCorrectGuessAccentInsensitive() {
        let player = PlayerProfile(
            id: "276",
            name: "Kylian Mbappé",
            photo: "",
            firstname: "Kylian",
            lastname: "Mbappé"
        )
        
        #expect(GuessPlayerValidator.isCorrectGuess(input: "mbappe", player: player) == true)
        #expect(GuessPlayerValidator.isCorrectGuess(input: "Mbappe", player: player) == true)
    }
    
    @Test("fullName preserves middle names from snake_case-style profiles")
    func testFullNameThreePartLocalProfile() {
        let player = PlayerProfile(
            id: "juan_carlos_garcia",
            name: "Juan Carlos Garcia",
            photo: "",
            source: "local",
            firstname: "Juan",
            lastname: "Garcia"
        )
        #expect(player.fullName == "Juan Carlos Garcia")
        #expect(GuessPlayerValidator.isCorrectGuess(input: "Juan Carlos Garcia", player: player) == true)
        #expect(GuessPlayerValidator.isCorrectGuess(input: "juan garcia", player: player) == true)
    }
}

