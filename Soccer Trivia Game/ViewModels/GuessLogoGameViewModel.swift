import Foundation
import Combine

@MainActor
final class GuessLogoGameViewModel: ObservableObject {
    @Published var clubs: [ClubProfile] = []
    @Published var currentClubIndex = 0
    @Published var selectedOption: String? = nil
    @Published var currentOptions: [String] = []
    @Published var timeRemaining = GameConstants.questionTimeSeconds
    @Published var totalScore = 0
    @Published var showingAnswerFeedback = false
    @Published var isCorrect: Bool?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var gameFinished = false
    
    @Published var correctAnswersCount = 0
    @Published var totalTimeSpent: Double = 0.0
    @Published var questionStartTime: Date?
    
    /// Blur radius for the logo (higher = harder). Difficulty by popularity: easy = less blur, hard = more blur.
    var blurRadius: CGFloat { 8 }
    
    private var timer: Timer?
    private var feedbackTimer: Timer?
    private let clubService = LocalClubService.shared
    private var correctAnswer: String = ""
    
    deinit {
        timer?.invalidate()
        feedbackTimer?.invalidate()
    }
    
    func loadClubs() async {
        isLoading = true
        errorMessage = nil
        let loaded = clubService.getRandomClubs(count: 10, maxPopularity: nil)
        if loaded.isEmpty {
            errorMessage = "No clubs found. Please ensure clubs.json exists in Resources."
            isLoading = false
            return
        }
        clubs = loaded
        isLoading = false
        startRound()
    }
    
    func startRound() {
        guard currentClubIndex < clubs.count else {
            finishGame()
            return
        }
        timeRemaining = GameConstants.questionTimeSeconds
        selectedOption = nil
        showingAnswerFeedback = false
        isCorrect = nil
        questionStartTime = Date()
        timer?.invalidate()
        generateOptions()
        
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.submitGuess()
                }
            }
        }
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }
    
    private func isRealClubName(_ name: String, id: String) -> Bool {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 2, t != id else { return false }
        if t.uppercased().hasPrefix("Q"), t.dropFirst().allSatisfy(\.isNumber) { return false }
        return true
    }
    
    private func generateOptions() {
        let correct = currentClub
        correctAnswer = correct.name
        var wrong: [String] = []
        let others = clubService.getAllClubs().filter { $0.id != correct.id && isRealClubName($0.name, id: $0.id) }
        for c in others.shuffled().prefix(3) {
            wrong.append(c.name)
        }
        while wrong.count < 3 {
            wrong.append("Unknown Club")
        }
        var all = [correctAnswer] + wrong.prefix(3)
        all.shuffle()
        currentOptions = all
    }
    
    func selectOption(_ option: String) {
        guard !showingAnswerFeedback, selectedOption == nil else { return }
        selectedOption = option
        submitGuess()
    }
    
    func submitGuess() {
        guard !showingAnswerFeedback, let selected = selectedOption else {
            if !showingAnswerFeedback {
                selectedOption = nil
                isCorrect = false
                showingAnswerFeedback = true
                if let startTime = questionStartTime {
                    totalTimeSpent += Date().timeIntervalSince(startTime)
                }
                timer?.invalidate()
                let isLast = currentClubIndex + 1 >= clubs.count
                feedbackTimer?.invalidate()
                feedbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        if isLast { self.finishGame() } else { self.advanceToNextRound() }
                    }
                }
            }
            return
        }
        if let startTime = questionStartTime {
            totalTimeSpent += Date().timeIntervalSince(startTime)
        }
        timer?.invalidate()
        let correct = selected == correctAnswer
        showingAnswerFeedback = true
        isCorrect = correct
        if correct {
            totalScore += 100 + timeRemaining * 2
            correctAnswersCount += 1
        }
        let isLast = currentClubIndex + 1 >= clubs.count
        feedbackTimer?.invalidate()
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if isLast { self.finishGame() } else { self.advanceToNextRound() }
            }
        }
    }
    
    func advanceToNextRound() {
        feedbackTimer?.invalidate()
        showingAnswerFeedback = false
        isCorrect = nil
        selectedOption = nil
        if currentClubIndex + 1 < clubs.count {
            currentClubIndex += 1
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
        if let startTime = questionStartTime {
            totalTimeSpent += Date().timeIntervalSince(startTime)
        }
    }
    
    var averageTimePerAnswer: Double {
        let n = currentClubIndex + 1
        guard n > 0 else { return 0 }
        return totalTimeSpent / Double(n)
    }
    
    var currentClub: ClubProfile {
        guard currentClubIndex < clubs.count else {
            return ClubProfile(id: "0", name: "Unknown", logo: "", source: nil, popularity: nil)
        }
        return clubs[currentClubIndex]
    }
    
    var currentRoundNumber: Int { currentClubIndex + 1 }
    var totalRounds: Int { clubs.count }
}
