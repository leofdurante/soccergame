import SwiftUI

/// Main game screen with questions and answers
struct GameView: View {
    let roomCode: String
    @ObservedObject var roomViewModel: RoomViewModel
    @Binding var afterCoverDismissAction: FanaticosAfterCoverAction?
    @StateObject private var gameViewModel: GameViewModel
    @State private var showingResults = false
    @State private var flagSubmitted = false
    @State private var showFlagThankYou = false
    @State private var flagError: String?
    @Environment(\.dismiss) private var dismiss
    
    init(roomCode: String, roomViewModel: RoomViewModel, afterCoverDismissAction: Binding<FanaticosAfterCoverAction?>) {
        self.roomCode = roomCode
        self.roomViewModel = roomViewModel
        _afterCoverDismissAction = afterCoverDismissAction
        
        let firestoreService = FirestoreService()
        let authService = roomViewModel.authService
        _gameViewModel = StateObject(wrappedValue: GameViewModel(
            firestoreService: firestoreService,
            authService: authService
        ))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if showingResults {
                    if let room = roomViewModel.room {
                        ResultsView(
                            room: room,
                            roomViewModel: roomViewModel,
                            onMainScreen: { afterCoverDismissAction = .goHome }
                        )
                    }
                } else if gameViewModel.isWaitingForOthers {
                    waitingContent
                } else {
                    gameContent
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if let difficulty = roomViewModel.room?.difficulty {
                let selectedQuestionCount = roomViewModel.room?.resolvedQuestionCount ?? 10
                await gameViewModel.loadQuestions(difficulty: difficulty, questionCount: selectedQuestionCount)
                await gameViewModel.initializeAuthoritativeRoundIfNeeded(
                    roomCode: roomCode,
                    isHost: roomViewModel.isHost
                )
            }
            gameViewModel.observeRoom(roomCode: roomCode)
            // Play whistle when game starts (multiplayer)
            SoundManager.shared.playGameStart()
        }
        .onChange(of: roomViewModel.room?.state) { oldValue, newValue in
            if newValue == .results {
                showingResults = true
            } else if newValue == .lobby {
                showingResults = false
                dismiss()
            }
        }
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
                if let q = gameViewModel.currentQuestion, !q.options.isEmpty {
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
    }
    
    private func submitFlag(question: Question) {
        guard let user = roomViewModel.authService.currentUser, !flagSubmitted else { return }
        SoundManager.shared.playButtonClick()
        Task {
            do {
                try await FlagService.shared.submitFlag(
                    questionId: question.id,
                    questionText: question.text,
                    options: question.options,
                    correctAnswerIndex: question.correctAnswer,
                    questionType: question.type.rawValue,
                    mode: "fanaticos",
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
    
    private var gameContent: some View {
        ZStack {
            // Retro gradient background
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Scrollable area: header, question, options only
                ScrollView {
                    VStack(spacing: 18) {
                        // Retro Header with Timer & Question Counter
                        HStack {
                            // Timer
                            VStack(spacing: 4) {
                                Text("TIME")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                                Text("\(gameViewModel.timeRemaining)")
                                    .retroText(
                                        style: RetroTheme.Typography.retroTitle(size: 26),
                                        color: gameViewModel.timeRemaining <= 3 ? RetroTheme.Colors.retroRed : RetroTheme.Colors.neonGreen
                                    )
                            }
                            .retroCard()
                            .frame(width: 88)
                            
                            Spacer()
                            
                            // Question Counter
                            if let question = gameViewModel.currentQuestion {
                                VStack(spacing: 4) {
                                    Text("QUESTION")
                                        .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                                    Text("\(gameViewModel.currentQuestionIndex + 1)/\(gameViewModel.questions.count)")
                                        .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: RetroTheme.Colors.neonYellow)
                                }
                                .retroCard()
                                .frame(width: 104)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)

                        if let question = gameViewModel.currentQuestion {
                            // Question card: show for all except guess-player text-input mode
                            if !(question.type == .guessPlayer && question.options.isEmpty) {
                                VStack(spacing: 20) {
                                    Text(question.text.uppercased())
                                        .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: RetroTheme.Colors.retroWhite)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(2)
                                }
                                .retroCard()
                                .padding(.horizontal, 20)
                            }

                            // Guess Player with text input (legacy)
                            if question.type == .guessPlayer && question.options.isEmpty {
                                GuessPlayerView(
                                    question: question,
                                    guessText: $gameViewModel.guessText,
                                    isSubmitted: $gameViewModel.isAnswerLocked,
                                    onSubmit: {
                                        gameViewModel.submitGuess(gameViewModel.guessText)
                                    }
                                )
                                .padding(.horizontal, 20)
                            } else {
                                // Logo image for Fanáticos "guess the club" (blurred until feedback, like Guess Logo mode)
                                if question.type == .logoPartial, let logo = question.logo {
                                    clubLogoImage(assetName: logo.imageAssetName ?? logo.imageURL ?? "")
                                        .blur(radius: gameViewModel.showingAnswerFeedback ? 0 : 8)
                                        .animation(.easeInOut(duration: 0.3), value: gameViewModel.showingAnswerFeedback)
                                        .padding(.horizontal, 20)
                                }
                                // Player image for Fanáticos "guess the player" (multiple choice)
                                if question.type == .guessPlayer, !question.options.isEmpty, let guessPlayer = question.guessPlayer {
                                    FanaticosPlayerImageView(imageURL: guessPlayer.imageURL)
                                        .padding(.horizontal, 20)
                                }
                                // Answer Options (Multiple Choice) for trivia, logo, or player MC
                                VStack(spacing: 12) {
                                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                        Button(action: {
                                            if !gameViewModel.isAnswerLocked {
                                                SoundManager.shared.playButtonClick()
                                                gameViewModel.selectAnswer(index)
                                            }
                                        }) {
                                            HStack {
                                                // Option letter badge
                                                ZStack {
                                                    Circle()
                                                        .fill(answerBadgeColor(for: index, question: question))
                                                        .frame(width: 34, height: 34)
                                                    
                                                    Text(String(Character(UnicodeScalar(65 + index)!))) // A, B, C, D
                                                        .retroText(
                                                            style: RetroTheme.Typography.retroHeadline(size: 15),
                                                            color: answerTextColor(for: index, question: question)
                                                        )
                                                }
                                                
                                                Text(option)
                                                    .retroText(
                                                        style: RetroTheme.Typography.retroBody(size: 16),
                                                        color: answerTextColor(for: index, question: question)
                                                    )
                                                
                                                Spacer()
                                                
                                                // Feedback icon
                                                if gameViewModel.showingAnswerFeedback {
                                                    if index == question.correctAnswer {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.title2)
                                                            .foregroundColor(RetroTheme.Colors.neonGreen)
                                                            .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.8), radius: 5, x: 0, y: 0)
                                                    } else if gameViewModel.selectedAnswer == index && gameViewModel.isCorrect == false {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.title2)
                                                            .foregroundColor(RetroTheme.Colors.retroRed)
                                                            .shadow(color: RetroTheme.Colors.retroRed.opacity(0.8), radius: 5, x: 0, y: 0)
                                                    }
                                                } else if gameViewModel.selectedAnswer == index {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.title2)
                                                        .foregroundColor(RetroTheme.Colors.neonBlue)
                                                        .shadow(color: RetroTheme.Colors.neonBlue.opacity(0.8), radius: 5, x: 0, y: 0)
                                                }
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(answerBackgroundColor(for: index, question: question))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(
                                                        answerBorderColor(for: index, question: question),
                                                        lineWidth: answerBorderWidth(for: index, question: question)
                                                    )
                                                    .shadow(
                                                        color: answerShadowColor(for: index, question: question),
                                                        radius: 8, x: 0, y: 0
                                                    )
                                            )
                                        }
                                        .disabled(gameViewModel.isAnswerLocked)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
                
                // Leaderboard fixed at bottom, always visible
                if let room = roomViewModel.room {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LEADERBOARD")
                            .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.neonBlue)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(room.leaderboard.prefix(5)) { player in
                                    VStack(spacing: 4) {
                                        Text(player.name.uppercased())
                                            .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroWhite)
                                            .lineLimit(1)
                                        Text("\(player.score)")
                                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: RetroTheme.Colors.neonGreen)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(RetroTheme.Colors.darkBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(RetroTheme.Colors.neonBlue.opacity(0.5), lineWidth: 2)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(maxHeight: 62)
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 12)
                    .background(RetroTheme.Colors.darkBackground.opacity(0.6))
                }
            }
            
            if gameViewModel.isWaitingForRoundAdvance {
                VStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Text("WAITING FOR OTHER PLAYERS...")
                            .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.neonYellow)
                        Text("Answered: \(gameViewModel.answeredPlayersCount)/\(max(gameViewModel.totalPlayersCount, 1))")
                            .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(RetroTheme.Colors.darkBackground.opacity(0.9))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(RetroTheme.Colors.neonBlue.opacity(0.45), lineWidth: 1)
                    )
                    .padding(.bottom, 92)
                    .padding(.horizontal, 20)
                }
                .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button(action: {
                    exitToHome()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                        Text("EXIT")
                            .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroRed)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(RetroTheme.Colors.darkerBackground.opacity(0.9))
                    )
                    .overlay(
                        Capsule()
                            .stroke(RetroTheme.Colors.retroRed.opacity(0.6), lineWidth: 1)
                    )
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .onChange(of: gameViewModel.currentQuestionIndex) { oldValue, newValue in
            if oldValue != newValue {
                gameViewModel.startQuestionTimer()
            }
        }
        .onChange(of: gameViewModel.isAnswerLocked) { _, locked in
            guard locked, roomViewModel.isHost else { return }
            Task {
                await gameViewModel.hostDidLockAnswer()
            }
        }
        .onChange(of: gameViewModel.room?.answers.count) { _, _ in
            guard roomViewModel.isHost else { return }
            Task {
                await gameViewModel.hostDidReceiveAnswerUpdate()
            }
        }
        .onChange(of: roomViewModel.isHost) { _, isHost in
            guard isHost, gameViewModel.isAnswerLocked else { return }
            Task {
                await gameViewModel.hostDidLockAnswer()
            }
        }
        .onAppear {
            gameViewModel.startQuestionTimer()
        }
        #if DEBUG
        .overlay(alignment: .bottomLeading) {
            let stateLabel = roomViewModel.room?.state.rawValue ?? "-"
            VStack(alignment: .leading, spacing: 2) {
                Text("qIndex=\(gameViewModel.currentQuestionIndex) state=\(stateLabel)")
                Text("answers=\(roomViewModel.room?.answers.count ?? 0)/\(roomViewModel.room?.players.count ?? 0) t=\(gameViewModel.timeRemaining)")
            }
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundColor(.white.opacity(0.7))
            .padding(6)
            .background(Color.black.opacity(0.4))
            .cornerRadius(6)
            .padding([.leading, .bottom], 8)
        }
        #endif
    }
    
    private var waitingContent: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                Text("WAITING...")
                    .retroText(style: RetroTheme.Typography.retroTitle(size: 34), color: RetroTheme.Colors.neonYellow)
                
                Text("You finished your game.\nWaiting for other players to finish...")
                    .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroWhite)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                ProgressView()
                    .tint(RetroTheme.Colors.neonYellow)
                
                Button(action: {
                    exitToHome()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                            .font(.caption)
                        Text("EXIT ROOM")
                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: .white)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
                }
                .retroButton(color: RetroTheme.Colors.retroRed.opacity(0.8))
                .frame(maxWidth: 220)
                
                Spacer()
            }
            .padding(.vertical, 30)
        }
    }
    
    /// Exit Fanáticos game all the way back to the main home screen.
    private func exitToHome() {
        SoundManager.shared.playButtonClick()
        Task { await roomViewModel.leaveRoomAndSync() }
        afterCoverDismissAction = .goHome
        // Dismiss only the game cover; LobbyView handles pop-to-home.
        dismiss()
    }

    // MARK: - Answer Feedback Helpers (Fanáticos)
    
    private func answerBadgeColor(for index: Int, question: Question) -> Color {
        // Before feedback is revealed, keep all options neutral
        guard gameViewModel.showingAnswerFeedback else {
            return RetroTheme.Colors.darkBackground
        }
        
        let selected = gameViewModel.selectedAnswer
        
        if index == question.correctAnswer {
            return RetroTheme.Colors.neonGreen.opacity(0.3)
        } else if let selected, index == selected {
            return RetroTheme.Colors.retroRed.opacity(0.3)
        }
        return RetroTheme.Colors.darkBackground
    }
    
    private func answerTextColor(for index: Int, question: Question) -> Color {
        // Before feedback is revealed, keep all options neutral
        guard gameViewModel.showingAnswerFeedback else {
            return RetroTheme.Colors.retroWhite
        }
        
        let selected = gameViewModel.selectedAnswer
        
        if index == question.correctAnswer {
            return RetroTheme.Colors.neonGreen
        } else if let selected, index == selected {
            return RetroTheme.Colors.retroRed
        }
        return RetroTheme.Colors.retroWhite
    }
    
    private func answerBackgroundColor(for index: Int, question: Question) -> Color {
        // Before feedback is revealed, keep all options neutral
        guard gameViewModel.showingAnswerFeedback else {
            return RetroTheme.Colors.darkBackground
        }
        
        let selected = gameViewModel.selectedAnswer
        
        if index == question.correctAnswer {
            return RetroTheme.Colors.neonGreen.opacity(0.15)
        } else if let selected, index == selected {
            return RetroTheme.Colors.retroRed.opacity(0.15)
        }
        return RetroTheme.Colors.darkBackground
    }
    
    private func answerBorderColor(for index: Int, question: Question) -> Color {
        // Before feedback is revealed, keep all options neutral
        guard gameViewModel.showingAnswerFeedback else {
            return RetroTheme.Colors.retroGray.opacity(0.3)
        }
        
        let selected = gameViewModel.selectedAnswer
        
        if index == question.correctAnswer {
            return RetroTheme.Colors.neonGreen
        } else if let selected, index == selected {
            return RetroTheme.Colors.retroRed
        }
        return RetroTheme.Colors.retroGray.opacity(0.3)
    }
    
    private func answerBorderWidth(for index: Int, question: Question) -> CGFloat {
        guard gameViewModel.showingAnswerFeedback else {
            return 2
        }
        
        let selected = gameViewModel.selectedAnswer
        
        if index == question.correctAnswer || (selected != nil && index == selected) {
            return 3
        }
        return 2
    }
    
    private func answerShadowColor(for index: Int, question: Question) -> Color {
        guard gameViewModel.showingAnswerFeedback else {
            return Color.clear
        }
        
        let selected = gameViewModel.selectedAnswer
        
        if index == question.correctAnswer {
            return RetroTheme.Colors.neonGreen.opacity(0.6)
        } else if let selected, index == selected {
            return RetroTheme.Colors.retroRed.opacity(0.6)
        }
        return Color.clear
    }
    
    // MARK: - Fanáticos logo/player assets
    
    private func clubLogoImage(assetName: String) -> some View {
        let logoURL: URL? = {
            guard !assetName.isEmpty else { return nil }
            if assetName.hasPrefix("http") {
                guard let u = URL(string: assetName), u.scheme != nil, u.host != nil else { return nil }
                return u
            }
            let parts = assetName.split(separator: "/", omittingEmptySubsequences: false)
            guard parts.count >= 2, let name = parts.last.map(String.init), !name.isEmpty else { return nil }
            let fileName = name + ".png"
            let base = Bundle.main.bundleURL
            let pathsToTry: [URL] = [
                base.appendingPathComponent("Soccer Trivia Game").appendingPathComponent("Resources").appendingPathComponent("club-logos").appendingPathComponent(fileName),
                base.appendingPathComponent("Resources").appendingPathComponent("club-logos").appendingPathComponent(fileName),
                base.appendingPathComponent("club-logos").appendingPathComponent(fileName),
            ]
            for url in pathsToTry {
                if FileManager.default.fileExists(atPath: url.path) { return url }
            }
            if let found = Self.findLogoInBundle(name: name, ext: "png") { return found }
            return nil
        }()
        return Group {
            if let url = logoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(RetroTheme.Colors.neonYellow).frame(width: 180, height: 180)
                    case .success(let image):
                        image.resizable().scaledToFit().frame(width: 200, height: 200)
                    case .failure:
                        Image(systemName: "shield.fill").font(.system(size: 60)).foregroundColor(RetroTheme.Colors.retroGray).frame(width: 200, height: 200)
                    @unknown default: EmptyView()
                    }
                }
            } else {
                Image(systemName: "shield.fill").font(.system(size: 60)).foregroundColor(RetroTheme.Colors.retroGray).frame(width: 200, height: 200)
            }
        }
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.retroGray.opacity(0.5), lineWidth: 2))
    }
    
    private static func findLogoInBundle(name: String, ext: String) -> URL? {
        let fileName = "\(name).\(ext)"
        guard let enumerator = FileManager.default.enumerator(at: Bundle.main.bundleURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { return nil }
        for case let url as URL in enumerator {
            if url.lastPathComponent == fileName { return url }
        }
        return nil
    }
}

// MARK: - Fanáticos player image (local or URL)
private struct FanaticosPlayerImageView: View {
    let imageURL: String
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 280)
                    .clipped()
            } else if isLoading {
                ProgressView().tint(RetroTheme.Colors.neonYellow).frame(width: 200, height: 200)
            } else {
                Image(systemName: "person.fill").font(.system(size: 60)).foregroundColor(RetroTheme.Colors.retroGray).frame(width: 200, height: 200)
            }
        }
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.retroGray.opacity(0.5), lineWidth: 2))
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        if imageURL.hasPrefix("local:") {
            let name = String(imageURL.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            if let localImage = PlayerImageResolver.image(for: name) {
                await MainActor.run { image = localImage; isLoading = false }
                return
            }
        }
        if let url = URL(string: imageURL), url.scheme != nil {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let loaded = UIImage(data: data) {
                    await MainActor.run { image = loaded; isLoading = false }
                    return
                }
            } catch { }
        }
        await MainActor.run { isLoading = false }
    }
}

