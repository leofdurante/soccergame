import SwiftUI
import UIKit

enum GuessPlayerResultsFollowUp {
    case goHome
}

struct GuessPlayerGameView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = GuessPlayerGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToResults = false
    @State private var afterResultsAction: GuessPlayerResultsFollowUp?
    @State private var flagSubmitted = false
    @State private var showFlagThankYou = false
    @State private var flagError: String?
    
    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                // Loading State
                VStack(spacing: 20) {
                    ProgressView()
                        .tint(RetroTheme.Colors.neonGreen)
                        .scaleEffect(1.5)
                    
                    Text("LOADING PLAYERS...")
                        .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: RetroTheme.Colors.retroGray)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .retroText(style: RetroTheme.Typography.retroBody(size: 14), color: RetroTheme.Colors.retroRed)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 16)
                    }
                }
            } else if viewModel.errorMessage != nil && viewModel.players.isEmpty {
                // Error State
                VStack(spacing: 30) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(RetroTheme.Colors.retroRed)
                    
                    Text("ERROR")
                        .retroText(style: RetroTheme.Typography.retroTitle(size: 32), color: RetroTheme.Colors.retroRed)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Button(action: {
                        SoundManager.shared.playButtonClick()
                        Task {
                            await viewModel.loadPlayers()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("RETRY")
                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: .white)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 40)
                    }
                    .retroButton(color: RetroTheme.Colors.neonBlue)
                }
            } else {
                // Game View
                ScrollView {
                    VStack(spacing: 12) {
                        // Retro Header with Timer & Score
                        HStack(spacing: 8) {
                            // Timer
                            VStack(spacing: 2) {
                                Text("TIME")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 10), color: RetroTheme.Colors.retroGray)
                                Text("\(viewModel.timeRemaining)")
                                    .retroText(
                                        style: RetroTheme.Typography.retroTitle(size: 24),
                                        color: viewModel.timeRemaining <= 5 ? RetroTheme.Colors.retroRed : RetroTheme.Colors.neonGreen
                                    )
                            }
                            .retroCard()
                            .frame(maxWidth: .infinity)
                            
                            // Round Counter
                            VStack(spacing: 2) {
                                Text("ROUND")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 10), color: RetroTheme.Colors.retroGray)
                                Text("\(viewModel.currentRoundNumber)/\(viewModel.totalRounds)")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: RetroTheme.Colors.neonYellow)
                            }
                            .retroCard()
                            .frame(maxWidth: .infinity)
                            
                            // Score
                            VStack(spacing: 2) {
                                Text("SCORE")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 10), color: RetroTheme.Colors.retroGray)
                                Text("\(viewModel.totalScore)")
                                    .retroText(style: RetroTheme.Typography.retroTitle(size: 24), color: RetroTheme.Colors.neonBlue)
                            }
                            .retroCard()
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Player Photo (loaded from local bundle images/Players)
                        Group {
                            if let localImage = PlayerImageResolver.image(for: viewModel.currentPlayer.fullName) {
                                Image(uiImage: localImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 260, maxHeight: 280)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                viewModel.showingAnswerFeedback
                                                    ? (viewModel.isCorrect == true ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.retroRed)
                                                    : RetroTheme.Colors.neonBlue,
                                                lineWidth: 3
                                            )
                                            .shadow(
                                                color: viewModel.showingAnswerFeedback
                                                    ? (viewModel.isCorrect == true ? RetroTheme.Colors.neonGreen.opacity(0.6) : RetroTheme.Colors.retroRed.opacity(0.6))
                                                    : RetroTheme.Colors.neonBlue.opacity(0.6),
                                                radius: 8, x: 0, y: 0
                                            )
                                    )
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(RetroTheme.Colors.retroGray)
                                    .frame(maxWidth: 260, maxHeight: 280)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(RetroTheme.Colors.darkBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(RetroTheme.Colors.retroGray, lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.vertical, 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.showingAnswerFeedback)
                        
                        // Multiple Choice Options
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SELECT THE CORRECT PLAYER")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                            
                            VStack(spacing: 8) {
                                ForEach(Array(viewModel.currentOptions.enumerated()), id: \.offset) { index, option in
                                    let isSelected = viewModel.selectedOption == option
                                    let isCorrect = option == viewModel.currentPlayer.fullName
                                    let showFeedback = viewModel.showingAnswerFeedback
                                    
                                    Button(action: {
                                        if !viewModel.showingAnswerFeedback && viewModel.selectedOption == nil {
                                            SoundManager.shared.playButtonClick()
                                            viewModel.selectOption(option)
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            // Option letter (A, B, C, D)
                                            Text(String(Character(UnicodeScalar(65 + index)!))) // A = 65
                                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: .white)
                                                .frame(width: 32, height: 32)
                                                .background(
                                                    Circle()
                                                        .fill(RetroTheme.Colors.darkBackground)
                                                )
                                            
                                            // Option text
                                            Text(option)
                                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 15), color: .white)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Spacer()
                                            
                                            // Feedback icon
                                            if showFeedback {
                                                if isCorrect {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(RetroTheme.Colors.neonGreen)
                                                } else if isSelected && !isCorrect {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(RetroTheme.Colors.retroRed)
                                                }
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(RetroTheme.Colors.darkBackground)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    showFeedback
                                                        ? (isCorrect ? RetroTheme.Colors.neonGreen : (isSelected ? RetroTheme.Colors.retroRed : RetroTheme.Colors.retroGray))
                                                        : (isSelected ? RetroTheme.Colors.neonBlue : RetroTheme.Colors.retroGray),
                                                    lineWidth: showFeedback && (isCorrect || isSelected) ? 2.5 : 2
                                                )
                                        )
                                        .shadow(
                                            color: showFeedback && isCorrect
                                                ? RetroTheme.Colors.neonGreen.opacity(0.5)
                                                : (showFeedback && isSelected && !isCorrect ? RetroTheme.Colors.retroRed.opacity(0.5) : Color.clear),
                                            radius: 8, x: 0, y: 0
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(viewModel.showingAnswerFeedback)
                                    .opacity(viewModel.showingAnswerFeedback && !isSelected && !isCorrect ? 0.6 : 1.0)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Feedback Message
                        if viewModel.showingAnswerFeedback {
                            VStack(spacing: 6) {
                                if viewModel.isCorrect == true {
                                    Text("✓ CORRECT!")
                                        .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: RetroTheme.Colors.neonGreen)
                                    
                                    Text("Player: \(viewModel.currentPlayer.fullName)")
                                        .retroText(style: RetroTheme.Typography.retroBody(size: 14), color: RetroTheme.Colors.retroGray)
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text("✗ WRONG!")
                                        .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: RetroTheme.Colors.retroRed)
                                    
                                    Text("Correct: \(viewModel.currentPlayer.fullName)")
                                        .retroText(style: RetroTheme.Typography.retroBody(size: 14), color: RetroTheme.Colors.retroGray)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(RetroTheme.Colors.darkBackground.opacity(0.5))
                            )
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 10)
                    }
                    .padding(.vertical, 12)
                }
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
                if !viewModel.players.isEmpty {
                    Button(action: submitFlagPlayer) {
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
            Task {
                await viewModel.loadPlayers()
            }
        }
        .onChange(of: viewModel.gameFinished) { _, finished in
            if finished {
                navigateToResults = true
            }
        }
        .navigationDestination(isPresented: $navigateToResults) {
            GuessPlayerResultsView(
                correctAnswers: viewModel.correctAnswersCount,
                totalRounds: viewModel.totalRounds,
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
    
    /// Exit Guess Player game all the way back to the main home screen.
    private func exitToHome() {
        SoundManager.shared.playButtonClick()
        // Dismiss GuessPlayerGameView -> GuessPlayerStartView -> Home
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.dismiss()
        }
    }
    
    private func submitFlagPlayer() {
        guard let user = authViewModel.currentUser, !flagSubmitted else { return }
        SoundManager.shared.playButtonClick()
        let player = viewModel.currentPlayer
        let options = viewModel.currentOptions
        let correctIndex = options.firstIndex(of: player.fullName) ?? 0
        Task {
            do {
                try await FlagService.shared.submitFlag(
                    questionId: player.id,
                    questionText: "Who is this player?",
                    options: options,
                    correctAnswerIndex: correctIndex,
                    questionType: "guess_player",
                    mode: "guess_player",
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
}

#Preview {
    NavigationStack {
        GuessPlayerGameView()
            .environmentObject(AuthViewModel(authService: AuthService()))
    }
}

