import SwiftUI

/// Difficulty selection screen for Local Quiz mode
struct DifficultySelectionView: View {
    let playType: PlayType
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDifficulty: Difficulty?
    
    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 40)
                
                    Text("SELECT DIFFICULTY")
                    .retroText(style: RetroTheme.Typography.retroTitle(size: 32), color: RetroTheme.Colors.neonBlue)
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
                        .fill(RetroTheme.Colors.neonBlue.opacity(0.3))
                )
                .overlay(
                    Capsule()
                        .stroke(RetroTheme.Colors.neonBlue, lineWidth: 2)
                )
                
                VStack(spacing: 20) {
                    ForEach(Difficulty.selectableCases) { difficulty in
                        Button(action: {
                            SoundManager.shared.playButtonClick()
                            selectedDifficulty = difficulty
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(difficulty.displayName.uppercased())
                                        .retroText(style: RetroTheme.Typography.retroHeadline(size: 24), color: .white)
                                    
                                    Text(getDifficultyDescription(difficulty))
                                        .retroText(style: RetroTheme.Typography.retroBody(size: 14), color: RetroTheme.Colors.retroGray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(RetroTheme.Colors.neonBlue)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(RetroTheme.Colors.darkBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(RetroTheme.Colors.neonBlue.opacity(0.5), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .padding(.vertical, 20)
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
        .navigationDestination(item: $selectedDifficulty) { _ in
            SoloGameView()
        }
        .preferredColorScheme(.dark)
    }
    
    private func getDifficultyDescription(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .random:
            return "Mix of all difficulty levels - ultimate challenge"
        case .easy:
            return "Perfect for beginners - straightforward questions"
        case .medium:
            return "Moderate challenge - test your knowledge"
        case .hard:
            return "Expert level - only for true football fans"
        }
    }
}

