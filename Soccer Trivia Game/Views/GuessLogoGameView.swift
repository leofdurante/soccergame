import SwiftUI

enum GuessLogoResultsFollowUp {
    case goHome
}

struct GuessLogoGameView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = GuessLogoGameViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToResults = false
    @State private var afterResultsAction: GuessLogoResultsFollowUp?
    @State private var flagSubmitted = false
    @State private var showFlagThankYou = false
    @State private var flagError: String?
    
    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.errorMessage != nil && viewModel.clubs.isEmpty {
                errorRetryView
            } else {
                logoGameScrollContent
            }
        }
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
                Button(action: submitFlagLogo) {
                    Image(systemName: flagSubmitted ? "flag.fill" : "flag")
                        .foregroundColor(flagSubmitted ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.retroGray)
                }
                .disabled(flagSubmitted)
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
            Task { await viewModel.loadClubs() }
        }
        .onChange(of: viewModel.gameFinished) { _, finished in
            if finished { navigateToResults = true }
        }
        .navigationDestination(isPresented: $navigateToResults) {
            GuessLogoResultsView(
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
    
    /// Exit Guess Logo game all the way back to the main home screen.
    private func exitToHome() {
        SoundManager.shared.playButtonClick()
        // Dismiss GuessLogoGameView -> GuessLogoStartView -> Home
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.dismiss()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(RetroTheme.Colors.neonYellow)
                .scaleEffect(1.5)
            Text("LOADING CLUBS...")
                .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: RetroTheme.Colors.retroGray)
            if let msg = viewModel.errorMessage {
                Text(msg)
                    .retroText(style: RetroTheme.Typography.retroBody(size: 14), color: RetroTheme.Colors.retroRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    private var errorRetryView: some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(RetroTheme.Colors.retroRed)
            Text("ERROR")
                .retroText(style: RetroTheme.Typography.retroTitle(size: 32), color: RetroTheme.Colors.retroRed)
            if let msg = viewModel.errorMessage {
                Text(msg)
                    .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button(action: {
                SoundManager.shared.playButtonClick()
                Task { await viewModel.loadClubs() }
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
    }
    
    private var logoGameScrollContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                logoGameStatsRow
                Text("GUESS THE CLUB LOGO")
                    .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                    .padding(.top, 4)
                logoImageView
                logoOptionsSection
                if viewModel.showingAnswerFeedback {
                    logoFeedbackView
                }
                Spacer(minLength: 10)
            }
            .padding(.vertical, 12)
        }
    }
    
    private var logoGameStatsRow: some View {
        HStack(spacing: 8) {
            VStack(spacing: 2) {
                Text("TIME")
                    .retroText(style: RetroTheme.Typography.retroCaption(size: 10), color: RetroTheme.Colors.retroGray)
                Text("\(viewModel.timeRemaining)")
                    .retroText(
                        style: RetroTheme.Typography.retroTitle(size: 24),
                        color: viewModel.timeRemaining <= 5 ? RetroTheme.Colors.retroRed : RetroTheme.Colors.neonYellow
                    )
            }
            .retroCard()
            .frame(maxWidth: .infinity)
            VStack(spacing: 2) {
                Text("ROUND")
                    .retroText(style: RetroTheme.Typography.retroCaption(size: 10), color: RetroTheme.Colors.retroGray)
                Text("\(viewModel.currentRoundNumber)/\(viewModel.totalRounds)")
                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: RetroTheme.Colors.neonYellow)
            }
            .retroCard()
            .frame(maxWidth: .infinity)
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
    }
    
    private var logoImageView: some View {
        let logoURL: URL? = {
            let s = viewModel.currentClub.logo
            guard !s.isEmpty else { return nil }
            if s.hasPrefix("http") {
                let s2 = s.hasPrefix("http://") ? "https://" + String(s.dropFirst(7)) : s
                guard let u = URL(string: s2), u.scheme != nil, u.host != nil else { return nil }
                return u
            }
            // Bundle path: e.g. "club-logos/arsenal" -> resolve to file URL (matches project path Soccer Trivia Game/Resources/club-logos/)
            let parts = s.split(separator: "/", omittingEmptySubsequences: false)
            guard parts.count >= 2, let name = parts.last.map(String.init), !name.isEmpty else { return nil }
            let fileName = name + ".png"
            let base = Bundle.main.bundleURL
            // Try paths that match typical bundle layout (project has Soccer Trivia Game/Resources/club-logos/)
            let pathsToTry: [URL] = [
                base.appendingPathComponent("Soccer Trivia Game").appendingPathComponent("Resources").appendingPathComponent("club-logos").appendingPathComponent(fileName),
                base.appendingPathComponent("Resources").appendingPathComponent("club-logos").appendingPathComponent(fileName),
                base.appendingPathComponent("club-logos").appendingPathComponent(fileName),
            ]
            for url in pathsToTry {
                if FileManager.default.fileExists(atPath: url.path) {
                    return url
                }
            }
            // Fallback: search bundle for the PNG by filename (finds it wherever Xcode put it)
            if let found = Self.findImageInBundle(name: name, ext: "png") {
                return found
            }
            return nil
        }()
        return Group {
            if let url = logoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(RetroTheme.Colors.neonYellow)
                            .frame(width: 200, height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .blur(radius: viewModel.showingAnswerFeedback ? 0 : viewModel.blurRadius)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.showingAnswerFeedback)
                    case .failure:
                        Image(systemName: "shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(RetroTheme.Colors.retroGray)
                            .frame(width: 220, height: 220)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(RetroTheme.Colors.retroGray)
                    .frame(width: 220, height: 220)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RetroTheme.Colors.darkBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RetroTheme.Colors.retroGray.opacity(0.5), lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private var logoOptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SELECT THE CLUB")
                .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
            VStack(spacing: 8) {
                ForEach(Array(viewModel.currentOptions.enumerated()), id: \.offset) { index, option in
                    let isSelected = viewModel.selectedOption == option
                    let isCorrect = option == viewModel.currentClub.name
                    let showFeedback = viewModel.showingAnswerFeedback
                    Button(action: {
                        if !viewModel.showingAnswerFeedback && viewModel.selectedOption == nil {
                            SoundManager.shared.playButtonClick()
                            viewModel.selectOption(option)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text(String(Character(UnicodeScalar(65 + index)!)))
                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: .white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(RetroTheme.Colors.darkBackground))
                            Text(option)
                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 15), color: .white)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            if showFeedback {
                                if isCorrect {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(RetroTheme.Colors.neonGreen)
                                } else if isSelected && !isCorrect {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(RetroTheme.Colors.retroRed)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(RetroTheme.Colors.darkBackground.opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    showFeedback && isCorrect ? RetroTheme.Colors.neonGreen :
                                    showFeedback && isSelected ? RetroTheme.Colors.retroRed :
                                    RetroTheme.Colors.retroGray.opacity(0.5),
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.showingAnswerFeedback)
                    .opacity(viewModel.showingAnswerFeedback && !isSelected && !isCorrect ? 0.6 : 1)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var logoFeedbackView: some View {
        VStack(spacing: 6) {
            if viewModel.isCorrect == true {
                Text("CORRECT!")
                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: RetroTheme.Colors.neonGreen)
            } else {
                Text("WRONG")
                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: RetroTheme.Colors.retroRed)
                Text("Answer: \(viewModel.currentClub.name)")
                    .retroText(style: RetroTheme.Typography.retroBody(size: 14), color: RetroTheme.Colors.retroGray)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 10).fill(RetroTheme.Colors.darkBackground.opacity(0.5)))
        .padding(.horizontal, 20)
        .transition(.scale.combined(with: .opacity))
    }
    
    private func submitFlagLogo() {
        guard let user = authViewModel.currentUser, !flagSubmitted else { return }
        SoundManager.shared.playButtonClick()
        let club = viewModel.currentClub
        let options = viewModel.currentOptions
        let correctIndex = options.firstIndex(of: club.name) ?? 0
        Task {
            do {
                try await FlagService.shared.submitFlag(
                    questionId: club.id,
                    questionText: "Guess the club",
                    options: options,
                    correctAnswerIndex: correctIndex,
                    questionType: "logo_partial",
                    mode: "guess_logo",
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
    
    /// Search the main bundle for an image file by name (finds it regardless of folder structure).
    private static func findImageInBundle(name: String, ext: String) -> URL? {
        let fileName = "\(name).\(ext)"
        guard let enumerator = FileManager.default.enumerator(
            at: Bundle.main.bundleURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }
        for case let url as URL in enumerator {
            if url.lastPathComponent == fileName {
                return url
            }
        }
        return nil
    }
}
