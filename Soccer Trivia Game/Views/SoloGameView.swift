import SwiftUI

enum SoloResultsFollowUp {
    case goHome
}

struct SoloGameView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = SoloGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToResults = false
    @State private var afterResultsAction: SoloResultsFollowUp?
    @State private var flagSubmitted = false
    @State private var showFlagThankYou = false
    @State private var flagError: String?

    var body: some View {
        ZStack {
            // Retro gradient background
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Retro Header with Timer & Score
                    HStack {
                        // Timer
                        VStack(spacing: 4) {
                            Text("TIME")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                            Text("\(viewModel.timeRemaining)")
                                .retroText(
                                    style: RetroTheme.Typography.retroTitle(size: 32),
                                    color: viewModel.timeRemaining <= 3 ? RetroTheme.Colors.retroRed : RetroTheme.Colors.neonGreen
                                )
                        }
                        .retroCard()
                        .frame(width: 100)
                        
                        Spacer()
                        
                        // Question Counter
                        VStack(spacing: 4) {
                            Text("QUESTION")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                            Text("\(viewModel.currentQuestionIndex + 1)/10")
                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 24), color: RetroTheme.Colors.neonYellow)
                        }
                        .retroCard()
                        .frame(width: 120)
                        
                        Spacer()
                        
                        // Score
                        VStack(spacing: 4) {
                            Text("SCORE")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                            Text("\(viewModel.totalScore)")
                                .retroText(style: RetroTheme.Typography.retroTitle(size: 32), color: RetroTheme.Colors.neonBlue)
                        }
                        .retroCard()
                        .frame(width: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    if let question = viewModel.currentQuestion {
                        // Question Card
                        VStack(spacing: 20) {
                            Text(question.text.uppercased())
                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 22), color: RetroTheme.Colors.retroWhite)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .retroCard()
                        .padding(.horizontal, 20)

                        // Answer Options
                        VStack(spacing: 16) {
                            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                Button(action: {
                                    if !viewModel.showingAnswerFeedback {
                                        SoundManager.shared.playButtonClick()
                                        viewModel.selectAnswer(index)
                                        viewModel.showAnswerFeedback()
                                    }
                                }) {
                                    HStack {
                                        // Option letter badge
                                        ZStack {
                                            Circle()
                                                .fill(getAnswerBadgeColor(index: index, viewModel: viewModel))
                                                .frame(width: 40, height: 40)
                                            
                                            Text(String(Character(UnicodeScalar(65 + index)!))) // A, B, C, D
                                                .retroText(
                                                    style: RetroTheme.Typography.retroHeadline(size: 18),
                                                    color: getAnswerTextColor(index: index, viewModel: viewModel)
                                                )
                                        }
                                        
                                        Text(option)
                                            .retroText(
                                                style: RetroTheme.Typography.retroBody(size: 18),
                                                color: getAnswerTextColor(index: index, viewModel: viewModel)
                                            )
                                        
                                        Spacer()
                                        
                                        // Show feedback icons
                                        if viewModel.showingAnswerFeedback {
                                            if index == viewModel.correctAnswerIndex {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(RetroTheme.Colors.neonGreen)
                                                    .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.8), radius: 5, x: 0, y: 0)
                                                    .transition(.scale.combined(with: .opacity))
                                            } else if viewModel.selectedAnswer == index && viewModel.isCorrect == false {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(RetroTheme.Colors.retroRed)
                                                    .shadow(color: RetroTheme.Colors.retroRed.opacity(0.8), radius: 5, x: 0, y: 0)
                                                    .transition(.scale.combined(with: .opacity))
                                            }
                                        } else if viewModel.selectedAnswer == index {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(RetroTheme.Colors.neonBlue)
                                                .shadow(color: RetroTheme.Colors.neonBlue.opacity(0.8), radius: 5, x: 0, y: 0)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(getAnswerBackgroundColor(index: index, viewModel: viewModel))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                getAnswerBorderColor(index: index, viewModel: viewModel),
                                                lineWidth: getAnswerBorderWidth(index: index, viewModel: viewModel)
                                            )
                                            .shadow(
                                                color: getAnswerShadowColor(index: index, viewModel: viewModel),
                                                radius: 8, x: 0, y: 0
                                            )
                                    )
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.showingAnswerFeedback)
                                }
                                .disabled(viewModel.showingAnswerFeedback)
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        Text("NO QUESTIONS AVAILABLE")
                            .retroText(style: RetroTheme.Typography.retroHeadline(), color: RetroTheme.Colors.retroRed)
                            .retroCard()
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    exitToHome()
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("EXIT")
                            .retroText(style: RetroTheme.Typography.retroCaption(), color: RetroTheme.Colors.retroRed)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let q = viewModel.currentQuestion {
                    Button(action: { submitFlag(question: q) }) {
                        Image(systemName: flagSubmitted ? "flag.fill" : "flag")
                            .foregroundColor(flagSubmitted ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.retroGray)
                    }
                    .disabled(flagSubmitted)
                }
            }
        }
        .alert("Flag submitted", isPresented: $showFlagThankYou) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Thanks. We'll review this question.")
        }
        .alert("Flag failed", isPresented: Binding(get: { flagError != nil }, set: { if !$0 { flagError = nil } })) {
            Button("OK", role: .cancel) { flagError = nil }
        } message: {
            if let msg = flagError { Text(msg) }
        }
        .onAppear {
            SoundManager.shared.playGameStart()
            viewModel.loadQuestions()
            viewModel.startQuestionTimer()
        }
        .onChange(of: viewModel.gameFinished) { _, finished in
            if finished {
                navigateToResults = true
            }
        }
        .navigationDestination(isPresented: $navigateToResults) {
            SoloResultsView(
                correctAnswers: viewModel.correctAnswersCount,
                totalQuestions: viewModel.questions.count,
                finalScore: viewModel.totalScore,
                averageTimePerAnswer: viewModel.averageTimePerAnswer,
                onMainScreen: { afterResultsAction = .goHome }
            )
        }
        .onChange(of: navigateToResults) { _, showing in
            if !showing, afterResultsAction == .goHome {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.dismiss()
                }
                afterResultsAction = nil
            }
        }
    }
    
    /// Exit Solo game all the way back to the main home screen.
    private func exitToHome() {
        SoundManager.shared.playButtonClick()
        // Dismiss SoloGameView -> SoloQuizStartView -> Home
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.dismiss()
        }
    }
    
    private func submitFlag(question: Question) {
        guard let user = authViewModel.currentUser, !flagSubmitted else { return }
        SoundManager.shared.playButtonClick()
        Task {
            do {
                try await FlagService.shared.submitFlag(
                    questionId: question.id,
                    questionText: question.text,
                    options: question.options,
                    correctAnswerIndex: question.correctAnswer,
                    questionType: question.type.rawValue,
                    mode: "solo",
                    userId: user.id,
                    userDisplayName: user.name
                )
                await MainActor.run {
                    flagSubmitted = true
                    showFlagThankYou = true
                }
            } catch {
                await MainActor.run { flagError = error.localizedDescription }
            }
        }
    }

    // MARK: - Answer Feedback Helpers
    
    private func getAnswerBadgeColor(index: Int, viewModel: SoloGameViewModel) -> Color {
        if viewModel.showingAnswerFeedback {
            if index == viewModel.correctAnswerIndex {
                return RetroTheme.Colors.neonGreen.opacity(0.5)
            } else if viewModel.selectedAnswer == index && viewModel.isCorrect == false {
                return RetroTheme.Colors.retroRed.opacity(0.5)
            }
        } else if viewModel.selectedAnswer == index {
            return RetroTheme.Colors.neonBlue.opacity(0.3)
        }
        return RetroTheme.Colors.darkBackground
    }
    
    private func getAnswerTextColor(index: Int, viewModel: SoloGameViewModel) -> Color {
        if viewModel.showingAnswerFeedback {
            if index == viewModel.correctAnswerIndex {
                return RetroTheme.Colors.neonGreen
            } else if viewModel.selectedAnswer == index && viewModel.isCorrect == false {
                return RetroTheme.Colors.retroRed
            }
        } else if viewModel.selectedAnswer == index {
            return RetroTheme.Colors.neonBlue
        }
        return RetroTheme.Colors.retroWhite
    }
    
    private func getAnswerBackgroundColor(index: Int, viewModel: SoloGameViewModel) -> Color {
        if viewModel.showingAnswerFeedback {
            if index == viewModel.correctAnswerIndex {
                return RetroTheme.Colors.neonGreen.opacity(0.25)
            } else if viewModel.selectedAnswer == index && viewModel.isCorrect == false {
                return RetroTheme.Colors.retroRed.opacity(0.25)
            }
        } else if viewModel.selectedAnswer == index {
            return RetroTheme.Colors.neonBlue.opacity(0.15)
        }
        return RetroTheme.Colors.darkBackground
    }
    
    private func getAnswerBorderColor(index: Int, viewModel: SoloGameViewModel) -> Color {
        if viewModel.showingAnswerFeedback {
            if index == viewModel.correctAnswerIndex {
                return RetroTheme.Colors.neonGreen
            } else if viewModel.selectedAnswer == index && viewModel.isCorrect == false {
                return RetroTheme.Colors.retroRed
            }
        } else if viewModel.selectedAnswer == index {
            return RetroTheme.Colors.neonBlue
        }
        return RetroTheme.Colors.retroGray.opacity(0.3)
    }
    
    private func getAnswerBorderWidth(index: Int, viewModel: SoloGameViewModel) -> CGFloat {
        if viewModel.showingAnswerFeedback {
            if index == viewModel.correctAnswerIndex || (viewModel.selectedAnswer == index && viewModel.isCorrect == false) {
                return 3
            }
        } else if viewModel.selectedAnswer == index {
            return 3
        }
        return 2
    }
    
    private func getAnswerShadowColor(index: Int, viewModel: SoloGameViewModel) -> Color {
        if viewModel.showingAnswerFeedback {
            if index == viewModel.correctAnswerIndex {
                return RetroTheme.Colors.neonGreen.opacity(0.8)
            } else if viewModel.selectedAnswer == index && viewModel.isCorrect == false {
                return RetroTheme.Colors.retroRed.opacity(0.8)
            }
        } else if viewModel.selectedAnswer == index {
            return RetroTheme.Colors.neonBlue.opacity(0.6)
        }
        return Color.clear
    }
}

#Preview {
    NavigationStack {
        SoloGameView()
    }
}

