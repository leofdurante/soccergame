import Foundation
import Combine

@MainActor
final class SoloGameViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswer: Int?
    @Published var timeRemaining = GameConstants.questionTimeSeconds
    @Published var isAnswerLocked = false
    @Published var totalScore = 0
    @Published var showingAnswerFeedback = false
    @Published var correctAnswerIndex: Int?
    @Published var isCorrect: Bool?
    
    // Game statistics
    @Published var correctAnswersCount = 0
    @Published var totalTimeSpent: Double = 0.0
    @Published var questionStartTime: Date?
    @Published var gameFinished = false
    
    private var timer: Timer?
    private var feedbackTimer: Timer?
    private var allQuestions: [Question] = []

    deinit {
        timer?.invalidate()
        feedbackTimer?.invalidate()
    }

    /// Load 10 random questions from the full pool. All questions have the same weight.
    func loadQuestions() {
        if let url = Bundle.main.url(forResource: "questions", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            let decoded = Question.decodeResilient(from: data)
            
            // Filter out placeholder questions
            allQuestions = decoded.filter { question in
                    guard question.type == .multipleChoice else { return false }
                    let isPlaceholder = question.text.lowercased().contains("soccer trivia question") &&
                                       question.text.lowercased().contains("which option is correct")
                    let hasGenericOptions = question.options.contains { option in
                        option.lowercased().hasPrefix("option ")
                    }
                    return !isPlaceholder && !hasGenericOptions
                }
                
            print("✅ Loaded \(decoded.count) total questions, \(allQuestions.count) real questions after filtering")
            if allQuestions.isEmpty {
                allQuestions = getDefaultQuestions()
            }
        } else {
            print("❌ Could not find questions.json file")
            allQuestions = getDefaultQuestions()
        }
        
        // Shuffle all questions and take 10 (no difficulty filter; same weight for all)
        questions = Array(allQuestions.shuffled().prefix(10))
        print("🎮 Final question count: \(questions.count) (random, equal weight)")
    }

    func startQuestionTimer() {
        timeRemaining = GameConstants.questionTimeSeconds
        isAnswerLocked = false
        selectedAnswer = nil
        questionStartTime = Date()
        timer?.invalidate()

        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } 
            }
        }
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }

    func selectAnswer(_ index: Int) {
        guard !showingAnswerFeedback else { return }
        selectedAnswer = index
    }
    
    func showAnswerFeedback() {
        guard let question = currentQuestion else { return }
        
        // Calculate time spent on this question
        if let startTime = questionStartTime {
            let timeSpent = Date().timeIntervalSince(startTime)
            totalTimeSpent += timeSpent
        }
        
        // Stop the timer
        timer?.invalidate()
        showingAnswerFeedback = true
        correctAnswerIndex = question.correctAnswer
        
        // Check if answer is correct
        if let selected = selectedAnswer {
            isCorrect = (selected == question.correctAnswer)
            if isCorrect == true {
                // Award points for correct answer
                totalScore += timeRemaining + 10
                correctAnswersCount += 1
            }
        } else {
            // No answer selected = wrong
            isCorrect = false
        }
        
        // Check if this is the last question
        let isLastQuestion = currentQuestionIndex + 1 >= questions.count
        
        // Auto-advance after 3 seconds
        feedbackTimer?.invalidate()
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if isLastQuestion {
                    self.finishGame()
                } else {
                    self.advanceToNextQuestion()
                }
            }
        }
    }
    
    func advanceToNextQuestion() {
        feedbackTimer?.invalidate()
        showingAnswerFeedback = false
        correctAnswerIndex = nil
        isCorrect = nil
        
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
            selectedAnswer = nil
            startQuestionTimer()
        }
    }
    
    func finishGame() {
        feedbackTimer?.invalidate()
        timer?.invalidate()
        showingAnswerFeedback = false
        correctAnswerIndex = nil
        isCorrect = nil
        gameFinished = true
        
        // Calculate final time for last question if not already calculated
        if let startTime = questionStartTime {
            let timeSpent = Date().timeIntervalSince(startTime)
            totalTimeSpent += timeSpent
        }
    }
    
    var averageTimePerAnswer: Double {
        // Calculate average based on questions answered (currentQuestionIndex + 1)
        let questionsAnswered = currentQuestionIndex + 1
        guard questionsAnswered > 0 else { return 0.0 }
        return totalTimeSpent / Double(questionsAnswered)
    }

    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    private func getDefaultQuestions() -> [Question] {
        return [
            Question(
                text: "Which country won the 2022 FIFA World Cup?",
                options: ["Argentina", "France", "Brazil", "Germany"],
                correctAnswer: 0,
                difficulty: "easy"
            ),
            Question(
                text: "Who is the all-time top scorer in World Cup history?",
                options: ["Pelé", "Miroslav Klose", "Ronaldo", "Messi"],
                correctAnswer: 1,
                difficulty: "medium"
            ),
            Question(
                text: "Which club has won the most UEFA Champions League titles?",
                options: ["Real Madrid", "Barcelona", "Bayern Munich", "AC Milan"],
                correctAnswer: 0,
                difficulty: "hard"
            )
        ]
    }
}

