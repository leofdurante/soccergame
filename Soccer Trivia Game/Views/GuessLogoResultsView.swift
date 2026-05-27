import SwiftUI

/// Results screen for Guess the Club Logo game
struct GuessLogoResultsView: View {
    let correctAnswers: Int
    let totalRounds: Int
    let finalScore: Int
    let averageTimePerAnswer: Double
    var onMainScreen: (() -> Void)?
    
    @Environment(\.dismiss) var dismiss
    
    private func dismissToHome() {
        SoundManager.shared.playButtonClick()
        onMainScreen?()
        dismiss()
    }
    
    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    Spacer().frame(height: 20)
                    
                    Text("GAME OVER")
                        .retroText(style: RetroTheme.Typography.retroTitle(size: 40), color: RetroTheme.Colors.neonYellow)
                        .padding(.horizontal, 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RetroTheme.Colors.neonYellow, lineWidth: 3)
                                .shadow(color: RetroTheme.Colors.neonYellow.opacity(0.6), radius: 5, x: 0, y: 0)
                        )
                    
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CORRECT GUESSES")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: RetroTheme.Colors.retroGray)
                                Text("\(correctAnswers)/\(totalRounds)")
                                    .retroText(style: RetroTheme.Typography.retroTitle(size: 36), color: RetroTheme.Colors.neonGreen)
                            }
                            Spacer()
                            ZStack {
                                Circle().fill(RetroTheme.Colors.neonGreen.opacity(0.2)).frame(width: 80, height: 80)
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 50)).foregroundColor(RetroTheme.Colors.neonGreen)
                            }
                        }
                        .padding(24)
                        .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkBackground))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.neonGreen, lineWidth: 2).shadow(color: RetroTheme.Colors.neonGreen.opacity(0.6), radius: 8, x: 0, y: 0))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("FINAL SCORE")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: RetroTheme.Colors.retroGray)
                                Text("\(finalScore)")
                                    .retroText(style: RetroTheme.Typography.retroTitle(size: 36), color: RetroTheme.Colors.neonBlue)
                            }
                            Spacer()
                            ZStack {
                                Circle().fill(RetroTheme.Colors.neonBlue.opacity(0.2)).frame(width: 80, height: 80)
                                Image(systemName: "star.fill").font(.system(size: 50)).foregroundColor(RetroTheme.Colors.neonBlue)
                            }
                        }
                        .padding(24)
                        .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkBackground))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.neonBlue, lineWidth: 2).shadow(color: RetroTheme.Colors.neonBlue.opacity(0.6), radius: 8, x: 0, y: 0))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("AVG TIME PER ROUND")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: RetroTheme.Colors.retroGray)
                                Text(String(format: "%.1f", averageTimePerAnswer) + "s")
                                    .retroText(style: RetroTheme.Typography.retroTitle(size: 36), color: RetroTheme.Colors.neonYellow)
                            }
                            Spacer()
                            ZStack {
                                Circle().fill(RetroTheme.Colors.neonYellow.opacity(0.2)).frame(width: 80, height: 80)
                                Image(systemName: "clock.fill").font(.system(size: 50)).foregroundColor(RetroTheme.Colors.neonYellow)
                            }
                        }
                        .padding(24)
                        .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkBackground))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.neonYellow, lineWidth: 2).shadow(color: RetroTheme.Colors.neonYellow.opacity(0.6), radius: 8, x: 0, y: 0))
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        Button(action: dismissToHome) {
                            HStack {
                                Image(systemName: "house.fill").font(.title2)
                                Text("MAIN SCREEN")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: .white)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 40)
                            .frame(maxWidth: .infinity)
                        }
                        .retroButton(color: RetroTheme.Colors.neonBlue)
                        .shadow(color: RetroTheme.Colors.neonBlue.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
    }
}
