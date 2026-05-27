import SwiftUI

/// Start screen for Quiz Mode
struct QuizStartView: View {
    let playType: PlayType
    let authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToDifficulty = false
    @State private var navigateToMultiplayer = false
    
    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: GameMode.quiz.icon)
                    .font(.system(size: 80))
                    .foregroundColor(RetroTheme.Colors.neonBlue)
                    .shadow(color: RetroTheme.Colors.neonBlue.opacity(0.8), radius: 10, x: 0, y: 0)
                
                Text("QUIZ MODE")
                    .retroText(style: RetroTheme.Typography.retroTitle(size: 36), color: RetroTheme.Colors.neonBlue)
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
                
                Text(GameMode.quiz.description)
                    .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    SoundManager.shared.playButtonClick()
                    if playType == .local {
                        navigateToDifficulty = true
                    } else {
                        navigateToMultiplayer = true
                    }
                }) {
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
                .retroButton(color: RetroTheme.Colors.neonBlue)
                .shadow(color: RetroTheme.Colors.neonBlue.opacity(0.5), radius: 10, x: 0, y: 5)
                
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
        .navigationDestination(isPresented: $navigateToDifficulty) {
            DifficultySelectionView(playType: playType)
        }
        .navigationDestination(isPresented: $navigateToMultiplayer) {
            CreateJoinView(authViewModel: authViewModel, difficulty: .medium)
        }
        .preferredColorScheme(.dark)
    }
}

