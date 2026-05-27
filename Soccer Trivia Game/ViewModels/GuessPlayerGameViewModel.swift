import Foundation
import Combine

@MainActor
final class GuessPlayerGameViewModel: ObservableObject {
    @Published var players: [PlayerProfile] = []
    @Published var currentPlayerIndex = 0
    @Published var selectedOption: String? = nil
    @Published var currentOptions: [String] = []
    @Published var timeRemaining = GameConstants.questionTimeSeconds
    @Published var totalScore = 0
    @Published var showingAnswerFeedback = false
    @Published var isCorrect: Bool?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Game statistics
    @Published var correctAnswersCount = 0
    @Published var totalTimeSpent: Double = 0.0
    @Published var questionStartTime: Date?
    @Published var gameFinished = false
    
    private var timer: Timer?
    private var feedbackTimer: Timer?
    private let localPlayerService = LocalPlayerService.shared
    private let validator = GuessPlayerValidator.self
    
    // Store correct answer for current question
    private var correctAnswer: String = ""
    
    deinit {
        timer?.invalidate()
        feedbackTimer?.invalidate()
    }
    
    /// Load 10 random players for the game from local JSON
    func loadPlayers() async {
        isLoading = true
        errorMessage = nil
        
        // Load from local JSON file
        do {
            print("🔄 Loading players from local database...")
            let loadedPlayers = localPlayerService.getRandomPlayers(count: 10)
            
            print("📊 Received \(loadedPlayers.count) players from local database")
            
            if loadedPlayers.isEmpty {
                print("❌ No players found in local database")
                errorMessage = "No players found. Please ensure players.json exists in Resources folder."
                isLoading = false
                return
            }
            
            players = loadedPlayers
            print("✅ Successfully loaded \(players.count) players for game")
            isLoading = false
            
            // Start the first round
            startRound()
        } catch {
            print("❌ Failed to load players: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func startRound() {
        guard currentPlayerIndex < players.count else {
            finishGame()
            return
        }
        
        timeRemaining = GameConstants.questionTimeSeconds
        selectedOption = nil
        showingAnswerFeedback = false
        isCorrect = nil
        questionStartTime = Date()
        timer?.invalidate()
        
        // Generate multiple choice options
        generateOptions()
        
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    // Time's up - auto-submit wrong answer
                    self.submitGuess()
                }
            }
        }
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }
    
    /// Generate 4 options (1 correct + 3 wrong) for the current player
    private func generateOptions() {
        let correctPlayer = currentPlayer
        correctAnswer = correctPlayer.fullName
        
        // Get 3 wrong answers from all players in the local database (not just current game players)
        var wrongOptions: [String] = []
        let allPlayers = localPlayerService.getAllPlayers()
        let otherPlayers = allPlayers.filter { $0.id != correctPlayer.id }
        
        // Shuffle and take 3 random players as wrong options
        let shuffledOthers = otherPlayers.shuffled()
        for player in shuffledOthers.prefix(3) {
            wrongOptions.append(player.fullName)
        }
        
        // If we still don't have enough, use players from current game
        if wrongOptions.count < 3 {
            let gameOtherPlayers = players.filter { $0.id != correctPlayer.id && !wrongOptions.contains($0.fullName) }
            for player in gameOtherPlayers.shuffled() {
                wrongOptions.append(player.fullName)
                if wrongOptions.count >= 3 { break }
            }
        }
        
        // Final fallback with known names
        while wrongOptions.count < 3 {
            let fallbackNames = ["Cristiano Ronaldo", "Lionel Messi", "Neymar Jr", "Kylian Mbappé", 
                                "Erling Haaland", "Karim Benzema", "Robert Lewandowski", "Mohamed Salah"]
            for name in fallbackNames.shuffled() {
                if !wrongOptions.contains(name) && name != correctAnswer {
                    wrongOptions.append(name)
                    if wrongOptions.count >= 3 { break }
                }
            }
            // Prevent infinite loop
            if wrongOptions.count < 3 {
                wrongOptions.append("Unknown Player")
            }
        }
        
        // Combine correct answer with wrong options and shuffle
        var allOptions = [correctAnswer] + wrongOptions.prefix(3)
        allOptions.shuffle()
        currentOptions = allOptions
    }
    
    func selectOption(_ option: String) {
        guard !showingAnswerFeedback, selectedOption == nil else {
            return
        }
        selectedOption = option
        submitGuess()
    }
    
    func submitGuess() {
        guard !showingAnswerFeedback, let selected = selectedOption else {
            // If time's up and no option selected, mark as wrong
            if !showingAnswerFeedback {
                selectedOption = nil
                isCorrect = false
                showingAnswerFeedback = true
                
                // Calculate time spent
                if let startTime = questionStartTime {
                    let timeSpent = Date().timeIntervalSince(startTime)
                    totalTimeSpent += timeSpent
                }
                
                timer?.invalidate()
                
                // Auto-advance after 3 seconds
                let isLastQuestion = currentPlayerIndex + 1 >= players.count
                feedbackTimer?.invalidate()
                feedbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        if isLastQuestion {
                            self.finishGame()
                        } else {
                            self.advanceToNextRound()
                        }
                    }
                }
            }
            return
        }
        
        // Calculate time spent on this question
        if let startTime = questionStartTime {
            let timeSpent = Date().timeIntervalSince(startTime)
            totalTimeSpent += timeSpent
        }
        
        // Stop the timer
        timer?.invalidate()
        
        // Check if selected option matches correct answer
        let correct = selected == correctAnswer || validator.isCorrectGuess(input: selected, player: currentPlayer)
        
        showingAnswerFeedback = true
        isCorrect = correct
        
        if correct {
            // Award points: base points + time bonus
            let points = 100 + timeRemaining * 2
            totalScore += points
            correctAnswersCount += 1
        }
        
        // Check if this is the last question
        let isLastQuestion = currentPlayerIndex + 1 >= players.count
        
        // Auto-advance after 3 seconds
        feedbackTimer?.invalidate()
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if isLastQuestion {
                    self.finishGame()
                } else {
                    self.advanceToNextRound()
                }
            }
        }
    }
    
    func advanceToNextRound() {
        feedbackTimer?.invalidate()
        showingAnswerFeedback = false
        isCorrect = nil
        selectedOption = nil
        
        if currentPlayerIndex + 1 < players.count {
            currentPlayerIndex += 1
            startRound()
        } else {
            finishGame()
        }
    }
    
    func finishGame() {
        feedbackTimer?.invalidate()
        timer?.invalidate()
        showingAnswerFeedback = false
        isCorrect = nil
        gameFinished = true
        
        // Calculate final time for last question if not already calculated
        if let startTime = questionStartTime {
            let timeSpent = Date().timeIntervalSince(startTime)
            totalTimeSpent += timeSpent
        }
    }
    
    var averageTimePerAnswer: Double {
        let roundsAnswered = currentPlayerIndex + 1
        guard roundsAnswered > 0 else { return 0.0 }
        return totalTimeSpent / Double(roundsAnswered)
    }
    
    var currentPlayer: PlayerProfile {
        guard currentPlayerIndex < players.count else {
            // Return a placeholder if index is out of bounds
            return PlayerProfile(
                id: "0",
                name: "Unknown",
                photo: "",
                source: nil,
                firstname: nil,
                lastname: nil
            )
        }
        return players[currentPlayerIndex]
    }
    
    var currentRoundNumber: Int {
        currentPlayerIndex + 1
    }
    
    var totalRounds: Int {
        players.count
    }
}

