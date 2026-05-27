import Foundation
import Combine
import FirebaseFirestore

/// ViewModel for game logic
@MainActor
class GameViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswer: Int?
    @Published var guessText: String = ""
    @Published var timeRemaining = GameConstants.questionTimeSeconds
    @Published var isAnswerLocked = false
    @Published var showingAnswerFeedback = false
    @Published var isCorrect: Bool? = nil
    @Published var room: Room?
    
    private let firestoreService: FirestoreService
    private let authService: AuthService
    private var timer: Timer?
    private var roomListener: ListenerRegistration?
    private var allQuestions: [Question] = []
    private let roundDurationSeconds = GameConstants.questionTimeSeconds
    private let feedbackRevealDelayNs: UInt64 = 2_000_000_000
    private var roundStartedAt: Date?
    private var hostAdvanceTask: Task<Void, Never>?
    private var isAdvancingRound = false
    private var hasInitializedAuthority = false
    private var lastAdvanceAttemptQuestionIndex: Int?
    
    init(firestoreService: FirestoreService, authService: AuthService) {
        self.firestoreService = firestoreService
        self.authService = authService
    }
    
    deinit {
        timer?.invalidate()
        roomListener?.remove()
        hostAdvanceTask?.cancel()
    }
    
    /// Load Fanaticos questions with a balanced mix of trivia, logo, and player rounds.
    func loadQuestions(difficulty: String, questionCount: Int = 10) async {
        let targetCount = [10, 15, 20].contains(questionCount) ? questionCount : 10
        let triviaTarget = max(1, Int(Double(targetCount) * 0.6))
        let logoTarget = max(1, Int(Double(targetCount) * 0.2))
        let playerTarget = max(1, targetCount - triviaTarget - logoTarget)
        
        var mixed: [Question] = []
        var triviaPool: [Question] = []
        
        // 1) Trivia rounds from JSON
        if let url = Bundle.main.url(forResource: "questions", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            let decoded = Question.decodeResilient(from: data)
            triviaPool = decoded.filter { q in
                guard q.type == .multipleChoice else { return false }
                let isPlaceholder = q.text.lowercased().contains("soccer trivia question") && q.text.lowercased().contains("which option is correct")
                let hasGeneric = q.options.contains { $0.lowercased().hasPrefix("option ") }
                return !isPlaceholder && !hasGeneric
            }
        }
        
        if triviaPool.isEmpty {
            triviaPool = getDefaultQuestions()
        }
        mixed.append(contentsOf: triviaPool.shuffled().prefix(triviaTarget))
        
        // 2) Guess the logo rounds
        let clubService = LocalClubService.shared
        let validClubs = clubService.getAllClubs()
        if !validClubs.isEmpty {
            let logoClubs = validClubs.shuffled().prefix(logoTarget)
            for club in logoClubs {
                let others = validClubs.filter { $0.id != club.id }.shuffled().prefix(3).map(\.name)
                var options = [club.name] + others
                options.shuffle()
                let correctIndex = options.firstIndex(of: club.name) ?? 0
                let payload = Question.LogoPayload(teamName: club.name, imageAssetName: club.logo, imageURL: nil, maskRects: [])
                mixed.append(Question(type: .logoPartial, text: "Guess the club", options: options, correctAnswer: correctIndex, logo: payload))
            }
        }
        
        // 3) Guess the player rounds (multiple choice, local image)
        let playerService = LocalPlayerService.shared
        let allPlayers = (try? playerService.loadPlayers()) ?? []
        let playerPool = Array(allPlayers.shuffled().prefix(playerTarget))
        for player in playerPool {
            let others = allPlayers.filter { $0.id != player.id }.shuffled().prefix(3).map(\.fullName)
            var options = [player.fullName] + others
            options.shuffle()
            let correctIndex = options.firstIndex(of: player.fullName) ?? 0
            let parts = player.fullName.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            let first = String(parts.first ?? "")
            let last = parts.count > 1 ? String(parts[1]) : ""
            let payload = Question.GuessPlayerPayload(
                imageURL: "local:\(player.fullName)",
                canonical: Question.GuessPlayerPayload.Canonical(first: first, last: last),
                aliases: [],
                constraints: Question.GuessPlayerPayload.Constraints(minChars: 2, allowSingleToken: true)
            )
            mixed.append(Question(type: .guessPlayer, text: "Who is this player?", options: options, correctAnswer: correctIndex, guessPlayer: payload))
        }
        
        // Fill shortfall with extra trivia/default questions so we always hit target count.
        if mixed.count < targetCount {
            mixed.append(contentsOf: triviaPool.shuffled().prefix(targetCount - mixed.count))
        }
        if mixed.count < targetCount {
            mixed.append(contentsOf: getDefaultQuestions().shuffled().prefix(targetCount - mixed.count))
        }
        while mixed.count < targetCount, let randomExisting = mixed.randomElement() {
            mixed.append(randomExisting)
        }
        
        self.questions = Array(mixed.shuffled().prefix(targetCount))
        self.allQuestions = questions
        print("🎮 Fanáticos: \(self.questions.count) questions (mix of trivia, logo, player)")
    }
    
    /// Start observing room for game state
    func observeRoom(roomCode: String) {
        roomListener?.remove()
        
        roomListener = firestoreService.observeRoom(roomCode: roomCode) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let room):
                    guard let self = self else { return }
                    self.room = room
                    if let startedAt = room.roundStartedAt {
                        self.roundStartedAt = startedAt
                    }
                    
                    // Only reset when the question index actually changes.
                    if room.currentQuestionIndex != self.currentQuestionIndex {
                        self.currentQuestionIndex = room.currentQuestionIndex
                        self.resetForNewQuestion()
                        self.startQuestionTimer()
                    }
                case .failure(let error):
                    print("Error observing room: \(error)")
                }
            }
        }
    }
    
    /// Start question timer
    func startQuestionTimer() {
        if let deadline = room?.roundDeadlineAt {
            let remaining = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
            timeRemaining = min(roundDurationSeconds, remaining)
        } else {
            timeRemaining = roundDurationSeconds
        }
        isAnswerLocked = false
        selectedAnswer = nil
        guessText = ""
        showingAnswerFeedback = false
        isCorrect = nil
        roundStartedAt = room?.roundStartedAt ?? Date()
        isAdvancingRound = false
        hostAdvanceTask?.cancel()
        hostAdvanceTask = nil
        
        timer?.invalidate()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let deadline = self.room?.roundDeadlineAt {
                    let remaining = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
                    self.timeRemaining = min(self.roundDurationSeconds, remaining)
                } else if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.lockAnswer()
                }
                if self.timeRemaining <= 0 {
                    self.lockAnswer()
                }
            }
        }
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }
    
    var totalPlayersCount: Int {
        room?.players.count ?? 0
    }
    
    var answeredPlayersCount: Int {
        room?.answers.count ?? 0
    }
    
    var allPlayersAnswered: Bool {
        let total = totalPlayersCount
        guard total > 0 else { return false }
        return answeredPlayersCount >= total
    }
    
    var hasCompletedAllQuestions: Bool {
        currentQuestionIndex >= questions.count
    }
    
    var isWaitingForOthers: Bool {
        room?.state == .inGame && hasCompletedAllQuestions
    }

    var isWaitingForRoundAdvance: Bool {
        room?.state == .inGame
            && isAnswerLocked
            && !allPlayersAnswered
            && (room?.currentQuestionIndex == currentQuestionIndex)
            && !hasCompletedAllQuestions
    }
    
    /// Called by host after they lock an answer to advance now-or-at-deadline.
    func hostDidLockAnswer() async {
        await maybeAdvanceRoundIfReady()
        scheduleHostDeadlineAdvanceIfNeeded()
    }
    
    /// Called by host whenever answer map changes.
    func hostDidReceiveAnswerUpdate() async {
        await maybeAdvanceRoundIfReady()
    }
    
    private func scheduleHostDeadlineAdvanceIfNeeded() {
        guard !allPlayersAnswered, !isAdvancingRound else { return }
        hostAdvanceTask?.cancel()
        
        let delayNs: UInt64
        if let roundStartedAt {
            let elapsed = Date().timeIntervalSince(roundStartedAt)
            let remaining = max(0.0, Double(roundDurationSeconds) - elapsed)
            delayNs = UInt64(remaining * 1_000_000_000)
        } else {
            delayNs = UInt64(roundDurationSeconds) * 1_000_000_000
        }
        
        hostAdvanceTask = Task { [weak self] in
            if delayNs > 0 {
                try? await Task.sleep(nanoseconds: delayNs)
            }
            await self?.maybeAdvanceRoundIfReady()
        }
    }
    
    private var hasRoundTimedOut: Bool {
        if let roundStartedAt {
            return Date().timeIntervalSince(roundStartedAt) >= Double(roundDurationSeconds)
        }
        return timeRemaining <= 0
    }
    
    private func maybeAdvanceRoundIfReady() async {
        if isAdvancingRound {
            DiagnosticsLogger.shared.logAuth("advanceRound skipped: already advancing. qIndex=\(currentQuestionIndex)")
            return
        }
        guard allPlayersAnswered || hasRoundTimedOut else {
            DiagnosticsLogger.shared.logAuth("advanceRound skipped: not all answered and not timed out. answers=\(answeredPlayersCount)/\(totalPlayersCount) timeRemaining=\(timeRemaining)")
            return
        }
        guard lastAdvanceAttemptQuestionIndex != currentQuestionIndex else {
            DiagnosticsLogger.shared.logAuth("advanceRound skipped: already attempted for qIndex=\(currentQuestionIndex)")
            return
        }
        
        isAdvancingRound = true
        lastAdvanceAttemptQuestionIndex = currentQuestionIndex
        hostAdvanceTask?.cancel()
        hostAdvanceTask = nil
        
        // Give all players a short moment to see right/wrong feedback.
        try? await Task.sleep(nanoseconds: feedbackRevealDelayNs)
        guard let roomCode = room?.roomCode else {
            DiagnosticsLogger.shared.logAuth("advanceRound aborted: missing roomCode for qIndex=\(currentQuestionIndex)")
            isAdvancingRound = false
            return
        }
        guard let currentQuestion else {
            DiagnosticsLogger.shared.logAuth("advanceRound aborted: missing currentQuestion for qIndex=\(currentQuestionIndex)")
            isAdvancingRound = false
            return
        }
        // If room moved while we were waiting, drop stale advance attempt.
        guard room?.currentQuestionIndex == currentQuestionIndex else {
            DiagnosticsLogger.shared.logAuth("advanceRound aborted: room.currentQuestionIndex=\(room?.currentQuestionIndex ?? -1) local=\(currentQuestionIndex)")
            isAdvancingRound = false
            return
        }
        do {
            _ = try await firestoreService.advanceRoundIfReadyAuthoritative(
                roomCode: roomCode,
                correctAnswerIndex: currentQuestion.correctAnswer
            )
        } catch {
            DiagnosticsLogger.shared.logAuth("advanceRound failed for room=\(roomCode) qIndex=\(currentQuestionIndex) error=\(error.localizedDescription). Attempting forceAdvance fallback.")
            do {
                try await firestoreService.forceAdvanceRoundForHost(
                    roomCode: roomCode,
                    correctAnswerIndex: currentQuestion.correctAnswer
                )
                DiagnosticsLogger.shared.logAuth("forceAdvance fallback succeeded for room=\(roomCode) qIndex=\(currentQuestionIndex)")
            } catch {
                DiagnosticsLogger.shared.logAuth("forceAdvance fallback FAILED for room=\(roomCode) qIndex=\(currentQuestionIndex) error=\(error.localizedDescription)")
            }
        }
        isAdvancingRound = false
    }
    
    /// Select an answer
    func selectAnswer(_ index: Int) {
        guard !isAnswerLocked, let roomCode = room?.roomCode,
              authService.currentUser?.id != nil else { return }
        
        selectedAnswer = index
        isAnswerLocked = true
        
        Task {
            do {
                try await firestoreService.submitAnswerAuthoritative(
                    roomCode: roomCode,
                    questionIndex: currentQuestionIndex,
                    answerIndex: index
                )
            } catch {
                DiagnosticsLogger.shared.logAuth("submitAnswer failed for room=\(roomCode) qIndex=\(currentQuestionIndex) error=\(error.localizedDescription)")
            }
        }
        
        // Provide immediate local feedback based on the correct answer
        if let question = currentQuestion {
            isCorrect = (question.correctAnswer == index)
            showingAnswerFeedback = true
        }
        
        // Stop the local timer once the player has locked an answer
        timer?.invalidate()
    }
    
    /// Submit a guess for guess_player question
    func submitGuess(_ text: String) {
        guard !isAnswerLocked, let roomCode = room?.roomCode,
              let userId = authService.currentUser?.id else { return }
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        guessText = trimmed
        isAnswerLocked = true
        
        // For now, just submit as if it were an answer
        // In a full implementation with WebSocket, this would send a submit_guess message
        Task {
            // Note: FirestoreService doesn't have submitGuess yet
            // This is a placeholder - in production, you'd call a submitGuess method
            print("Submitting guess: \(trimmed)")
            // TODO: Implement submitGuess in FirestoreService or use WebSocket
        }
    }
    
    /// Lock answer when timer ends
    private func lockAnswer() {
        isAnswerLocked = true
        timer?.invalidate()
        
        // When time runs out, still show which option was correct
        if let question = currentQuestion {
            showingAnswerFeedback = true
            if let selected = selectedAnswer {
                isCorrect = (question.correctAnswer == selected)
            } else {
                isCorrect = nil
            }
        }
    }
    
    /// Reset for new question
    private func resetForNewQuestion() {
        selectedAnswer = nil
        guessText = ""
        timeRemaining = roundDurationSeconds
        isAnswerLocked = false
        showingAnswerFeedback = false
        isCorrect = nil
        timer?.invalidate()
        hostAdvanceTask?.cancel()
        hostAdvanceTask = nil
        isAdvancingRound = false
        lastAdvanceAttemptQuestionIndex = nil
    }
    
    /// Get current question
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    /// Check if answer is correct
    func isAnswerCorrect(_ answerIndex: Int) -> Bool {
        guard let question = currentQuestion else { return false }
        return question.correctAnswer == answerIndex
    }
    
    /// Calculate score for current question
    func calculateScore() -> Int {
        guard let question = currentQuestion,
              let selected = selectedAnswer,
              !isAnswerLocked else { return 0 }
        
        if question.correctAnswer == selected {
            // Bonus points for faster answers
            return timeRemaining + 10
        }
        return 0
    }
    
    /// Calculate and update scores for all players after a question
    func calculateAndUpdateScores() async {
        // Authority moved to backend.
    }
    
    /// Move to next question (host only)
    func nextQuestion() async {
        // Authority moved to backend.
    }

    func initializeAuthoritativeRoundIfNeeded(roomCode: String, isHost: Bool) async {
        guard isHost, !hasInitializedAuthority else { return }
        let answerKey = questions.map(\.correctAnswer)
        guard !answerKey.isEmpty else { return }
        do {
            try await firestoreService.startGameAuthoritative(
                roomCode: roomCode,
                answerKey: answerKey,
                roundDurationSec: roundDurationSeconds
            )
            hasInitializedAuthority = true
        } catch {
            print("Failed to initialize authoritative game session: \(error)")
        }
    }
    
    /// Default questions if JSON fails to load
    private func getDefaultQuestions() -> [Question] {
        return [
            Question(
                text: "Which country won the 2022 FIFA World Cup?",
                options: ["Argentina", "France", "Brazil", "Germany"],
                correctAnswer: 0
            ),
            Question(
                text: "Who is the all-time top scorer in World Cup history?",
                options: ["Pelé", "Miroslav Klose", "Ronaldo", "Messi"],
                correctAnswer: 1
            ),
            Question(
                text: "Which club has won the most UEFA Champions League titles?",
                options: ["Real Madrid", "Barcelona", "Bayern Munich", "AC Milan"],
                correctAnswer: 0
            )
        ]
    }
}

