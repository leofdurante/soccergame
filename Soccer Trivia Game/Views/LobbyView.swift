import SwiftUI

/// Action to take when the game fullScreenCover is dismissed (so we pop to the right screen).
enum FanaticosAfterCoverAction {
    case goHome
}

/// Lobby screen showing players and waiting for game to start
struct LobbyView: View {
    @ObservedObject var roomViewModel: RoomViewModel
    @State private var showingGame = false
    @State private var activeGameRoomCode: String?
    @State private var afterCoverDismissAction: FanaticosAfterCoverAction?
    @State private var countdown: Int?
    @State private var showingInviteSheet = false
    @State private var inviteFriendProfiles: [UserProfile] = []
    @State private var selectedInviteFriendIds: Set<String> = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Retro gradient background
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Room Code Display
                    VStack(spacing: 12) {
                        Text("ROOM CODE")
                            .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: RetroTheme.Colors.retroGray)
                        
                        Text(roomViewModel.room?.roomCode ?? "----")
                            .retroText(style: RetroTheme.Typography.retroTitle(size: 48), color: RetroTheme.Colors.neonGreen)
                            .fontDesign(.monospaced)
                    }
                    .retroCard()
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Players List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PLAYERS (\(roomViewModel.room?.players.count ?? 0))")
                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: RetroTheme.Colors.neonBlue)
                            .padding(.horizontal, 30)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(roomViewModel.room?.players ?? []) { player in
                                HStack {
                                    // Player icon
                                    ZStack {
                                        Circle()
                                            .fill(RetroTheme.Colors.neonBlue.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "person.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(RetroTheme.Colors.neonBlue)
                                    }
                                    
                                    Text(player.name.uppercased())
                                        .retroText(style: RetroTheme.Typography.retroBody(size: 18), color: RetroTheme.Colors.retroWhite)
                                    
                                    if player.id == roomViewModel.room?.hostId {
                                        Text("(HOST)")
                                            .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.neonGreen)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(RetroTheme.Colors.neonGreen.opacity(0.2))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(RetroTheme.Colors.neonGreen, lineWidth: 1)
                                            )
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(RetroTheme.Colors.darkBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(RetroTheme.Colors.neonBlue.opacity(0.5), lineWidth: 2)
                                )
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    // Question Count Selector (host) / Display (guests)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QUESTIONS")
                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: RetroTheme.Colors.neonYellow)
                        
                        if roomViewModel.isHost {
                            HStack(spacing: 10) {
                                ForEach([10, 15, 20], id: \.self) { count in
                                    Button(action: {
                                        SoundManager.shared.playButtonClick()
                                        Task { await roomViewModel.updateQuestionCount(count) }
                                    }) {
                                        Text("\(count)")
                                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: .white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(questionCountButtonColor(for: count))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(questionCountBorderColor(for: count), lineWidth: 2)
                                    )
                                }
                            }
                        } else {
                            Text("\(roomViewModel.room?.resolvedQuestionCount ?? 10) QUESTIONS")
                                .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroWhite)
                        }
                    }
                    .retroCard()
                    .padding(.horizontal, 30)
                    
                    // Countdown or Start Button
                    if let countdown = countdown {
                        VStack(spacing: 12) {
                            Text("STARTING IN")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 16), color: RetroTheme.Colors.retroGray)
                            Text("\(countdown)")
                                .retroText(style: RetroTheme.Typography.retroTitle(size: 64), color: RetroTheme.Colors.neonGreen)
                        }
                        .retroCard()
                        .padding(.horizontal, 40)
                    } else if roomViewModel.isHost {
                        Button(action: {
                            SoundManager.shared.playGameStart()
                            Task {
                                await roomViewModel.startGame()
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                Text("START GAME")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 22), color: .white)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.title3)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .retroButton(color: RetroTheme.Colors.neonGreen)
                        .disabled(!roomViewModel.canStartGame)
                        .opacity(roomViewModel.canStartGame ? 1.0 : 0.5)
                        .padding(.horizontal, 30)
                        
                        if (roomViewModel.room?.players.count ?? 0) == 1 {
                            Text("NEED AT LEAST 2 PLAYERS TO START")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                        }
                    } else {
                        Text("WAITING FOR HOST TO START...")
                            .retroText(style: RetroTheme.Typography.retroBody(), color: RetroTheme.Colors.retroGray)
                            .retroCard()
                            .padding(.horizontal, 40)
                    }

                    if roomViewModel.isHost {
                        Button(action: {
                            SoundManager.shared.playButtonClick()
                            Task {
                                inviteFriendProfiles = await roomViewModel.loadFriendProfiles()
                                showingInviteSheet = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("INVITE FRIENDS")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: .white)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .retroButton(color: RetroTheme.Colors.neonBlue)
                        .padding(.horizontal, 30)
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
        }
        .onChange(of: roomViewModel.room?.state) { oldValue, newValue in
            if newValue == .inGame {
                if activeGameRoomCode == nil {
                    activeGameRoomCode = roomViewModel.room?.roomCode
                }
                startCountdown()
            } else if newValue == .lobby {
                countdown = nil
                if showingGame {
                    showingGame = false
                }
            }
        }
        .fullScreenCover(isPresented: $showingGame) {
            if let roomCode = activeGameRoomCode {
                GameView(roomCode: roomCode, roomViewModel: roomViewModel, afterCoverDismissAction: $afterCoverDismissAction)
            } else {
                ZStack {
                    RetroTheme.retroGradient.ignoresSafeArea()
                    ProgressView().tint(RetroTheme.Colors.neonGreen)
                }
            }
        }
        .onChange(of: showingGame) { _, isShowing in
            guard !isShowing else { return }
            activeGameRoomCode = nil
            if afterCoverDismissAction == .goHome {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.dismiss()
                }
            }
            afterCoverDismissAction = nil
        }
        .sheet(isPresented: $showingInviteSheet) {
            NavigationStack {
                ZStack {
                    RetroTheme.retroGradient.ignoresSafeArea()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select friends to invite")
                                .retroText(style: RetroTheme.Typography.retroBody(size: 15), color: RetroTheme.Colors.retroWhite)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)

                            ForEach(inviteFriendProfiles) { profile in
                                Button(action: {
                                    if selectedInviteFriendIds.contains(profile.uid) {
                                        selectedInviteFriendIds.remove(profile.uid)
                                    } else {
                                        selectedInviteFriendIds.insert(profile.uid)
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(profile.displayName)
                                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: RetroTheme.Colors.retroWhite)
                                            Text("@\(profile.username)")
                                                .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                                        }
                                        Spacer()
                                        Image(systemName: selectedInviteFriendIds.contains(profile.uid) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedInviteFriendIds.contains(profile.uid) ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.retroGray)
                                    }
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 12).fill(RetroTheme.Colors.darkBackground))
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .navigationTitle("Invite Friends")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            showingInviteSheet = false
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Send") {
                            let ids = Array(selectedInviteFriendIds)
                            Task { await roomViewModel.sendInvitesToFriends(ids) }
                            selectedInviteFriendIds = []
                            showingInviteSheet = false
                        }
                        .disabled(selectedInviteFriendIds.isEmpty)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    /// Exit Fanáticos lobby all the way back to the main home screen.
    private func exitToHome() {
        SoundManager.shared.playButtonClick()
        Task { await roomViewModel.leaveRoomAndSync() }
        // Dismiss LobbyView -> CreateJoinView -> Home
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.dismiss()
        }
    }
    
    private func startCountdown() {
        if activeGameRoomCode == nil {
            activeGameRoomCode = roomViewModel.room?.roomCode
        }
        countdown = 3
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let current = countdown, current > 1 {
                countdown = current - 1
            } else {
                timer.invalidate()
                showingGame = true
            }
        }
    }
    
    private func questionCountButtonColor(for count: Int) -> Color {
        let selected = roomViewModel.room?.resolvedQuestionCount == count
        return selected ? RetroTheme.Colors.neonYellow.opacity(0.25) : RetroTheme.Colors.darkBackground
    }
    
    private func questionCountBorderColor(for count: Int) -> Color {
        let selected = roomViewModel.room?.resolvedQuestionCount == count
        return selected ? RetroTheme.Colors.neonYellow : RetroTheme.Colors.retroGray.opacity(0.4)
    }
}
