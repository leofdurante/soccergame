import SwiftUI

/// Placeholder start screen for Guess the Player Mode
struct GuessPlayerStartView: View {
    let playType: PlayType
    @Environment(\.dismiss) private var dismiss
    @State private var showStartConfirmation = false
    
    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: GameMode.guessPlayer.icon)
                    .font(.system(size: 80))
                    .foregroundColor(RetroTheme.Colors.neonGreen)
                    .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.8), radius: 10, x: 0, y: 0)
                
                Text("GUESS THE PLAYER")
                    .retroText(style: RetroTheme.Typography.retroTitle(size: 32), color: RetroTheme.Colors.neonGreen)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Image(systemName: playType.icon)
                    Text(playType.displayName.uppercased())
                        .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: .white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(playType == .multiplayer ? RetroTheme.Colors.neonGreen.opacity(0.3) : RetroTheme.Colors.neonBlue.opacity(0.3))
                )
                .overlay(
                    Capsule()
                        .stroke(playType == .multiplayer ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.neonBlue, lineWidth: 2)
                )
                
                Text(GameMode.guessPlayer.description)
                    .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                NavigationLink(destination: GuessPlayerGameView()) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("START")
                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 24), color: .white)
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 40)
                    .frame(minWidth: 200)
                }
                .retroButton(color: RetroTheme.Colors.neonGreen)
                .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.5), radius: 10, x: 0, y: 5)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    SoundManager.shared.playButtonClick()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("BACK")
                            .retroText(style: RetroTheme.Typography.retroCaption(), color: RetroTheme.Colors.retroWhite)
                    }
                }
            }
        }
    }
}

