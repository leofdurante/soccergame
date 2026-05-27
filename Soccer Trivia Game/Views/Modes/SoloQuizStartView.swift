import SwiftUI

/// Start screen for Solo Quiz mode (no difficulty selection; all questions have equal weight).
struct SoloQuizStartView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                
                Text("SOLO QUIZ")
                    .retroText(style: RetroTheme.Typography.retroTitle(size: 36), color: RetroTheme.Colors.neonBlue)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)
                
                Text("Answer 10 random trivia questions. All questions have the same weight.")
                    .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                NavigationLink(destination: SoloGameView()) {
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
        .preferredColorScheme(.dark)
    }
}
