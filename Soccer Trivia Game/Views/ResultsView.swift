import SwiftUI

/// Results screen showing final scores and winner
struct ResultsView: View {
    let room: Room
    @ObservedObject var roomViewModel: RoomViewModel
    var onMainScreen: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    
    /// Dismiss cover and let LobbyView pop all the way to Home (Main Screen).
    private func dismissToHome() {
        SoundManager.shared.playButtonClick()
        Task { await roomViewModel.leaveRoomAndSync() }
        onMainScreen?()
        dismiss()
    }
    
    var body: some View {
        ZStack {
            // Retro gradient background
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            ScrollView {
                    VStack(spacing: 40) {
                        // Winner Announcement
                        if let winner = room.winner {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(RetroTheme.Colors.neonYellow.opacity(0.2))
                                        .frame(width: 140, height: 140)
                                        .shadow(color: RetroTheme.Colors.neonYellow.opacity(0.6), radius: 20, x: 0, y: 0)
                                    
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 100))
                                        .foregroundColor(RetroTheme.Colors.neonYellow)
                                        .shadow(color: RetroTheme.Colors.neonYellow.opacity(0.8), radius: 10, x: 0, y: 0)
                                }
                                
                                Text("WINNER!")
                                    .retroText(style: RetroTheme.Typography.retroTitle(size: 40), color: RetroTheme.Colors.neonYellow)
                                    .padding(.horizontal, 30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(RetroTheme.Colors.neonYellow, lineWidth: 3)
                                            .shadow(color: RetroTheme.Colors.neonYellow.opacity(0.6), radius: 5, x: 0, y: 0)
                                    )
                                
                                Text(winner.name.uppercased())
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 28), color: RetroTheme.Colors.neonGreen)
                                
                                Text("\(winner.score) POINTS")
                                    .retroText(style: RetroTheme.Typography.retroBody(size: 20), color: RetroTheme.Colors.retroGray)
                            }
                            .retroCard()
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                        }
                        
                        // Final Leaderboard
                        VStack(alignment: .leading, spacing: 16) {
                            Text("FINAL SCORES")
                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 24), color: RetroTheme.Colors.neonBlue)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(room.leaderboard.enumerated()), id: \.element.id) { index, player in
                                    HStack {
                                        // Rank badge
                                        ZStack {
                                            Circle()
                                                .fill(index == 0 ? RetroTheme.Colors.neonYellow.opacity(0.3) : RetroTheme.Colors.darkBackground)
                                                .frame(width: 50, height: 50)
                                            
                                            Text("\(index + 1)")
                                                .retroText(
                                                    style: RetroTheme.Typography.retroHeadline(size: 24),
                                                    color: index == 0 ? RetroTheme.Colors.neonYellow : RetroTheme.Colors.retroGray
                                                )
                                        }
                                        
                                        // Player Info
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(player.name.uppercased())
                                                .retroText(
                                                    style: RetroTheme.Typography.retroBody(size: 18),
                                                    color: index == 0 ? RetroTheme.Colors.neonYellow : RetroTheme.Colors.retroWhite
                                                )
                                            
                                            if index == 0 {
                                                Text("🏆 CHAMPION")
                                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.neonYellow)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Score
                                        Text("\(player.score)")
                                            .retroText(
                                                style: RetroTheme.Typography.retroHeadline(size: 24),
                                                color: index == 0 ? RetroTheme.Colors.neonYellow : RetroTheme.Colors.neonGreen
                                            )
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(RetroTheme.Colors.darkBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                index == 0 ? RetroTheme.Colors.neonYellow : RetroTheme.Colors.neonBlue.opacity(0.5),
                                                lineWidth: index == 0 ? 3 : 2
                                            )
                                            .shadow(
                                                color: index == 0 ? RetroTheme.Colors.neonYellow.opacity(0.6) : Color.clear,
                                                radius: 8, x: 0, y: 0
                                            )
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .retroCard()
                        .padding(.horizontal, 20)
                        
                        // Main Screen button
                        VStack(spacing: 12) {
                            Button(action: dismissToHome) {
                                HStack {
                                    Image(systemName: "house.fill")
                                        .font(.title2)
                                    Text("MAIN SCREEN")
                                        .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: .white)
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            }
                            .retroButton(color: RetroTheme.Colors.neonBlue)
                            
                            VStack(spacing: 10) {
                                Text("NEW GAME READY: \(roomViewModel.rematchReadyCount)/\(max(roomViewModel.rematchTotalPlayers, 1))")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(room.players) { player in
                                        let isReady = (room.rematchConfirmations ?? [:])[player.id] == true
                                        HStack(spacing: 8) {
                                            Image(systemName: isReady ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(isReady ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.retroGray)
                                            Text(player.name.uppercased())
                                                .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroWhite)
                                            Spacer()
                                        }
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(RetroTheme.Colors.darkBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(RetroTheme.Colors.retroGray.opacity(0.4), lineWidth: 1)
                                )
                                
                                if roomViewModel.isHost {
                                    if roomViewModel.allPlayersReadyForRematch {
                                        Button(action: {
                                            SoundManager.shared.playButtonClick()
                                            Task { await roomViewModel.startRematchIfAllConfirmed() }
                                        }) {
                                            HStack {
                                                Image(systemName: "arrow.clockwise.circle.fill")
                                                    .font(.title3)
                                                Text("START NEW GAME")
                                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: .white)
                                            }
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 16)
                                        }
                                        .retroButton(color: RetroTheme.Colors.neonGreen)
                                    } else {
                                        Button(action: {
                                            SoundManager.shared.playButtonClick()
                                            Task { await roomViewModel.toggleRematchConfirmation() }
                                        }) {
                                            HStack {
                                                Image(systemName: roomViewModel.currentUserIsReadyForRematch ? "checkmark.circle.fill" : "circle")
                                                    .font(.title3)
                                                Text(roomViewModel.currentUserIsReadyForRematch ? "YOU ARE READY" : "READY")
                                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: .white)
                                            }
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 16)
                                        }
                                        .retroButton(color: RetroTheme.Colors.neonYellow)
                                        
                                        Text("Host can start when everyone is ready.")
                                            .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                                    }
                                } else {
                                    Button(action: {
                                        SoundManager.shared.playButtonClick()
                                        Task { await roomViewModel.toggleRematchConfirmation() }
                                    }) {
                                        HStack {
                                            Image(systemName: roomViewModel.currentUserIsReadyForRematch ? "checkmark.circle.fill" : "circle")
                                                .font(.title3)
                                            Text(roomViewModel.currentUserIsReadyForRematch ? "YOU ARE READY" : "READY")
                                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: .white)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                    }
                                    .retroButton(color: roomViewModel.currentUserIsReadyForRematch ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.neonYellow)
                                    
                                    if roomViewModel.currentUserIsReadyForRematch {
                                        Text("Waiting for host to start new game...")
                                            .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                                    }
                                }
                                
                                if let errorMessage = roomViewModel.errorMessage, !errorMessage.isEmpty {
                                    Text(errorMessage)
                                        .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroRed)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        .task {
            await updateProfileStats()
        }
    }

    /// Update Firestore user profiles (games played, best score, win streak, lastPlayedWith) for all participants.
    private func updateProfileStats() async {
        let participantIds = room.players.map(\.id)
        let scores = Dictionary(uniqueKeysWithValues: room.players.map { ($0.id, $0.score) })
        let winnerId = room.winner?.id
        do {
            try await ProfileService.shared.updateStatsAfterGame(participantIds: participantIds, scores: scores, winnerId: winnerId)
        } catch {
            print("Failed to update profile stats: \(error)")
        }
    }
}

